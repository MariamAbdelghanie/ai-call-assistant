import re
import os
import sys
import json
import datetime
import certifi
import requests
from pathlib import Path
from dotenv import load_dotenv
from backend.records import CallRecord, JsonCallRepository, RecordNotFound, StorageError

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

os.environ["SSL_CERT_FILE"] = certifi.where()
os.environ["REQUESTS_CA_BUNDLE"] = certifi.where()
os.environ["GRPC_DEFAULT_SSL_ROOTS_FILE_PATH"] = certifi.where()

load_dotenv()

CALL_LOGS_FILE = Path(__file__).parent / "call_logs.json"
CONFIG_FILE = Path(__file__).parent / "agent_config.json"
CALL_LOG_REPOSITORY = JsonCallRepository(CALL_LOGS_FILE)

TURKISH_DAYS = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
]

URGENT_KEYWORDS = (
    "acil", "hastane", "kaza", "ambulans", "hayati", "yangın", "kanama",
    "urgent", "emergency", "hospital", "accident", "ambulance",
    "عاجل", "طارئ", "طوارئ", "مستشفى", "حادث", "اسعاف", "إسعاف",
)


def get_work_hours() -> tuple[int, int]:
    start_h, end_h = 9, 17
    if CONFIG_FILE.exists():
        try:
            cfg = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
            start_h = int(str(cfg.get("work_start", "09:00")).split(":")[0])
            end_h = int(str(cfg.get("work_end", "17:00")).split(":")[0])
        except Exception:
            pass
    return start_h, end_h


NOTIFY_LABELS = {
    "tr": {"caller": "Arayan", "purpose": "Arama Nedeni", "summary": "Mesaj / Özet",
           "callback": "Geri Dönüş İsteği", "appointment": "Randevu", "yes": "Evet", "no": "Hayır",
           "urgent": "ACİL ÇAĞRI", "title": "Yeni Cagri Ozeti", "title_urgent": "ACIL CAGRI"},
    "ar": {"caller": "المتصل", "purpose": "سبب الاتصال", "summary": "الرسالة / الملخص",
           "callback": "طلب معاودة الاتصال", "appointment": "الموعد", "yes": "نعم", "no": "لا",
           "urgent": "مكالمة عاجلة", "title": "Yeni Cagri Ozeti (AR)", "title_urgent": "ACIL CAGRI (AR)"},
    "en": {"caller": "Caller", "purpose": "Reason", "summary": "Message / Summary",
           "callback": "Callback Requested", "appointment": "Appointment", "yes": "Yes", "no": "No",
           "urgent": "URGENT CALL", "title": "New Call Summary", "title_urgent": "URGENT CALL"},
}


def _norm_name(text: str) -> str:
    """Türkçe/Arapça harf farklarını ve aksanları kaldırarak karşılaştırma için sadeleştirir."""
    import unicodedata
    t = (text or "").replace("İ", "i").replace("I", "ı").lower().replace("ı", "i")
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c))


def _name_tokens_match(spoken: str, stored_text: str, threshold: float = 0.75) -> bool:
    """Söylenen ismin her parçası randevu metnindeki bir kelimeye yeterince benziyor mu?
    (STT 'Elif' yerine 'İlif' yazsa bile eşleşir.)"""
    from difflib import SequenceMatcher
    spoken_tokens = [t for t in _norm_name(spoken).split() if len(t) >= 2]
    stored_words = [w for w in re.split(r"[^\w]+", _norm_name(stored_text)) if len(w) >= 2]
    if not spoken_tokens or not stored_words:
        return False
    return all(
        any(SequenceMatcher(None, tok, w).ratio() >= threshold for w in stored_words)
        for tok in spoken_tokens
    )


class CalendarAndNotesService:
    def __init__(self):
        self.google_creds_path = os.getenv("GOOGLE_CREDENTIALS_PATH", "firebase-credentials.json")
        self.calendar_id = os.getenv("GOOGLE_CALENDAR_ID", "mariamabdelghanie@gmail.com")
        self.firebase_creds_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
        self.ntfy_topic = os.getenv("NTFY_TOPIC", "mariam-calls-8f3k2x9q")

        self.calendar_service = self._init_google_calendar()
        self.firestore_db = self._init_firebase()

    def _init_google_calendar(self):
        if not os.path.exists(self.google_creds_path):
            return None
        try:
            from google.oauth2 import service_account
            from googleapiclient.discovery import build

            SCOPES = ["https://www.googleapis.com/auth/calendar"]
            creds = service_account.Credentials.from_service_account_file(
                self.google_creds_path, scopes=SCOPES
            )
            service = build("calendar", "v3", credentials=creds)
            print("[Success] Connected to Google Calendar API!")
            return service
        except Exception as e:
            print(f"[Warning] Failed to load Google Calendar credentials: {e}")
            return None

    def _init_firebase(self):
        if not os.path.exists(self.firebase_creds_path):
            return None
        try:
            import firebase_admin
            from firebase_admin import credentials, firestore

            if not firebase_admin._apps:
                cred = credentials.Certificate(self.firebase_creds_path)
                firebase_admin.initialize_app(cred)
            db = firestore.client()
            print("[Success] Connected to Firebase Firestore!")
            return db
        except Exception as e:
            print(f"[Warning] Failed to load Firebase credentials: {e}")
            return None

    def get_available_slots(self, date_str: str) -> str:
        day_name = ""
        try:
            dt = datetime.date.fromisoformat(date_str.strip())
            day_name = TURKISH_DAYS[dt.weekday()]
        except Exception:
            pass

        work_start, work_end = get_work_hours()
        work_range_str = f"{work_start:02d}:00-{work_end:02d}:00"

        if self.calendar_service:
            try:
                start_of_day = f"{date_str}T{work_start:02d}:00:00+03:00"
                end_of_day = f"{date_str}T{work_end:02d}:00:00+03:00"
                events_result = (
                    self.calendar_service.events()
                    .list(
                        calendarId=self.calendar_id,
                        timeMin=start_of_day,
                        timeMax=end_of_day,
                        singleEvents=True,
                        orderBy="startTime",
                    )
                    .execute()
                )
                events = events_result.get("items", [])
                if not events:
                    return (
                        f"{date_str} ({day_name}) tarihinde çalışma saatleri ({work_range_str}) içinde "
                        f"Telefon sahibi tamamen MÜSAİT. Saat {work_end:02d}:00'den sonra randevu verilmemektedir."
                    )
                busy_list = []
                for event in events:
                    start_raw = event["start"].get("dateTime", event["start"].get("date", ""))
                    end_raw = event["end"].get("dateTime", event["end"].get("date", ""))
                    start_hm = start_raw[11:16] if "T" in start_raw else start_raw
                    end_hm = end_raw[11:16] if "T" in end_raw else end_raw
                    busy_list.append(f"{start_hm}-{end_hm}")
                return (
                    f"{date_str} ({day_name}) tarihinde çalışma saatleri ({work_range_str}) içinde "
                    f"Telefon sahibinin DOLU olduğu saat aralıkları: {', '.join(busy_list)}. "
                    f"Bu saatler dışındaki {work_range_str} arası saatlerde MÜSAİTTİR. "
                    f"(GİZLİLİK KURALI: Neden dolu olduğunu, ders veya kişi adını asla söylemeyin; saat {work_end:02d}:00 sonrası için randevu vermeyin)."
                )
            except Exception as e:
                print(f"[Error] Google Calendar query error: {e}")

        return "Takvime şu anda erişilemiyor. Randevuyu kesinleşmiş gibi göstermeyin; yalnızca arayanın mesajını ve geri dönüş talebini alın."

    def get_live_week_context(self) -> str:
        today = datetime.date.today()
        end_date = today + datetime.timedelta(days=6)
        work_start, work_end = get_work_hours()
        events_by_date: dict[str, list[str]] = {}

        if self.calendar_service:
            try:
                start_iso = f"{today.isoformat()}T00:00:00+03:00"
                end_iso = f"{end_date.isoformat()}T23:59:59+03:00"
                events_result = (
                    self.calendar_service.events()
                    .list(
                        calendarId=self.calendar_id,
                        timeMin=start_iso,
                        timeMax=end_iso,
                        singleEvents=True,
                        orderBy="startTime",
                    )
                    .execute()
                )
                for event in events_result.get("items", []):
                    start_raw = event["start"].get("dateTime", event["start"].get("date", ""))
                    end_raw = event["end"].get("dateTime", event["end"].get("date", ""))
                    ev_date = start_raw[:10]
                    start_hm = start_raw[11:16] if "T" in start_raw else start_raw
                    end_hm = end_raw[11:16] if "T" in end_raw else end_raw
                    if "T" in start_raw:
                        try:
                            ev_hour = int(start_hm[:2])
                            if ev_hour >= work_end or ev_hour < work_start:
                                continue
                        except Exception:
                            pass
                    events_by_date.setdefault(ev_date, []).append(f"{start_hm}-{end_hm} (Meşgul)")
            except Exception as e:
                print(f"[Error] Google Calendar week context error: {e}")

        lines = [
            f"Mesai: {work_start:02d}:00-{work_end:02d}:00."
        ]
        for offset in range(0, 7):
            d = today + datetime.timedelta(days=offset)
            d_str = d.isoformat()
            day_tr = TURKISH_DAYS[d.weekday()]
            label = f"Bugün ({day_tr})" if offset == 0 else (f"Yarın ({day_tr})" if offset == 1 else f"{d_str} ({day_tr})")
            day_events = events_by_date.get(d_str, [])
            if day_events:
                lines.append(f"{label}: Dolu={', '.join(day_events)} (diğer mesai saatleri boş)")
            else:
                lines.append(f"{label}: Tamamen müsait")
        return " | ".join(lines)

    def book_appointment(self, caller_name: str, reason: str, start_iso: str, duration_minutes: int = 30) -> str:
        clean_iso = start_iso.strip()
        if len(clean_iso) == 16:
            clean_iso += ":00"
        if "+" not in clean_iso and "Z" not in clean_iso:
            clean_iso += "+03:00"
        try:
            start_dt = datetime.datetime.fromisoformat(clean_iso)
        except ValueError:
            return "HATA: Geçersiz tarih/saat formatı. Randevu oluşturulamadı."

        work_start, work_end = get_work_hours()
        if start_dt.hour < work_start or start_dt.hour >= work_end:
            return (
                f"MESAİ DIŞI SAAT: Telefon sahibinin çalışma ve randevu saatleri {work_start:02d}:00 ile {work_end:02d}:00 arasındadır. "
                f"Saat {work_end:02d}:00'den sonra veya {work_start:02d}:00'dan önce randevu oluşturulamaz. "
                f"Lütfen arayana çalışma saatlerinin {work_end:02d}:00'de bittiğini söyleyin; "
                f"isterse {work_start:02d}:00-{work_end:02d}:00 arasında bir saat seçebileceğini veya telefon sahibine hemen bir mesaj bırakabileceğini belirtin."
            )

        end_dt = start_dt + datetime.timedelta(minutes=duration_minutes)

        if self.calendar_service:
            try:
                existing = (
                    self.calendar_service.events()
                    .list(
                        calendarId=self.calendar_id,
                        timeMin=start_dt.isoformat(),
                        timeMax=end_dt.isoformat(),
                        singleEvents=True,
                    )
                    .execute()
                    .get("items", [])
                )
                if existing:
                    conflict_titles = ", ".join(ev.get("summary", "") for ev in existing)
                    if caller_name and caller_name.strip().lower() in conflict_titles.lower():
                        return (
                            f"BAŞARILI: {start_dt.strftime('%Y-%m-%d %H:%M')} saatindeki "
                            f"randevunuz zaten takvimde kayıtlı ve onaylıdır."
                        )
                    return (
                        f"BAŞARISIZ - BU SAAT DOLU: {start_dt.strftime('%Y-%m-%d %H:%M')} saatinde telefon sahibi müsait değil (programı dolu). "
                        f"Gizlilik gereği neden dolu olduğunu söylemeden, sadece bu saatin dolu olduğunu belirtip {work_start:02d}:00-{work_end:02d}:00 arasında başka bir boş saat önerin."
                    )

                safe_caller = caller_name.strip() if caller_name and caller_name.strip() else "İsimsiz Arayan"
                event = {
                    "summary": f"Randevu: {safe_caller} - {reason}",
                    "description": f"AI Call System tarafından oluşturuldu.\nArayan: {safe_caller}\nKonu: {reason}",
                    "start": {"dateTime": start_dt.isoformat(), "timeZone": "Europe/Istanbul"},
                    "end": {"dateTime": end_dt.isoformat(), "timeZone": "Europe/Istanbul"},
                    "colorId": "10",
                }
                created = (
                    self.calendar_service.events()
                    .insert(calendarId=self.calendar_id, body=event)
                    .execute()
                )
                return f"BAŞARILI: Randevu Google Takvim'e kaydedildi: {start_dt.strftime('%Y-%m-%d %H:%M')} ({created.get('htmlLink', '')})"
            except Exception as e:
                print(f"[Error] Google Calendar booking error: {e}")

        return "HATA: Takvime erişilemediği için randevu oluşturulamadı. Randevuyu kesinleşmiş gibi göstermeyin; arayanın geri dönüş talebini ve mesajını kaydedin."

    def cancel_appointment(self, date_str: str = "", time_hm: str = "", caller_name: str = "") -> str:
        if not self.calendar_service:
            return "HATA: Takvime şu anda erişilemiyor, randevu silinemedi."

        clean_caller = (caller_name or "").strip().lower()
        if not clean_caller or clean_caller in ("isimsiz", "isimsiz arayan", "bilinmiyor", "arayan kişi"):
            return (
                "DOĞRULAMA GEREKLİ: Güvenlik nedeniyle randevu iptali yapmadan önce "
                "randevu sahibinin adını doğrulamanız gerekir. Lütfen arayana adını sorun."
            )

        # Kimlik doğrulama: ad + soyad + tarih + saat zorunlu
        if len([t for t in clean_caller.split() if len(t) >= 2]) < 2:
            return (
                "DOĞRULAMA GEREKLİ: İptal için randevu sahibinin ADINI VE SOYADINI birlikte öğrenmelisiniz. "
                "Arayana adını ve soyadını sorun."
            )
        # Kimlik doğrulama: ad + tarih + saat üçü de zorunlu
        if not (date_str or "").strip() or not (time_hm or "").strip():
            return (
                "DOĞRULAMA GEREKLİ: İptal için randevunun tarihini ve saatini de öğrenmelisiniz. "
                "Arayana randevusunun hangi gün ve saatte olduğunu sorun; bilgiler eşleşmeden iptal etmeyin."
            )

        try:
            today = datetime.date.today()
            clean_date = (date_str or "").strip()[:10]
            if clean_date:
                time_min = f"{clean_date}T00:00:00+03:00"
                time_max = f"{clean_date}T23:59:59+03:00"
            else:
                time_min = f"{today.isoformat()}T00:00:00+03:00"
                time_max = f"{(today + datetime.timedelta(days=7)).isoformat()}T23:59:59+03:00"

            items = (
                self.calendar_service.events()
                .list(
                    calendarId=self.calendar_id,
                    timeMin=time_min,
                    timeMax=time_max,
                    singleEvents=True,
                    orderBy="startTime",
                )
                .execute()
                .get("items", [])
            )

            clean_time = (time_hm or "").strip()[:5]
            caller_tokens = [tok for tok in clean_caller.split() if len(tok) >= 2]

            candidates = []
            time_matched_other_owner = False

            for ev in items:
                if ev.get("recurringEventId"):
                    continue
                summary = ev.get("summary", "")
                desc = ev.get("description", "")
                start_raw = ev["start"].get("dateTime", ev["start"].get("date", ""))
                ev_date = start_raw[:10]
                ev_hm = start_raw[11:16] if "T" in start_raw else ""

                time_match = ev_hm == clean_time
                # Ad eşleşmesi: verilen ismin tüm parçaları randevuda geçmeli
                owner_match = bool(caller_tokens) and _name_tokens_match(caller_name, f"{summary} {desc}")
                # Yalnızca asistanın oluşturduğu randevular telefonla iptal edilebilir
                created_by_assistant = "ai call system" in desc.lower()
                if not created_by_assistant:
                    continue

                if time_match and owner_match:
                    candidates.append((ev, ev_date, ev_hm, summary))
                elif clean_time and ev_hm == clean_time and not owner_match:
                    time_matched_other_owner = True

            if not candidates:
                if time_matched_other_owner:
                    return (
                        f"YETKİSİZ İPTAL TALEBİ: Belirtilen saatte ({clean_time}) '{caller_name}' adına kayıtlı bir randevu bulunmamaktadır. "
                        f"Güvenlik ve gizlilik kuralları gereği yalnızca randevu sahibi kendi randevusunu iptal edebilir; o saatte kimin randevusu olduğunu kesinlikle söylemeyin."
                    )
                return (
                    f"BULUNAMADI: Takvimde '{caller_name}' adına kayıtlı silinebilecek bir randevu bulunamadı."
                )

            target_ev, target_date, target_hm, _ = candidates[-1]
            self.calendar_service.events().delete(
                calendarId=self.calendar_id,
                eventId=target_ev["id"],
            ).execute()
            return (
                f"BAŞARILI: Sayın {caller_name}, {target_date} saat {target_hm} tarihindeki randevunuz "
                f"kimlik doğrulamanız yapılarak Google Takvim'den tamamen silindi ve iptal edildi."
            )
        except Exception as e:
            print(f"[Error] Google Calendar cancel error: {e}")
            return "HATA: Randevu silinirken bir hata oluştu."

    def save_call_summary(
        self,
        caller_name: str,
        caller_purpose: str,
        summary_tr: str,
        appointment_info: str = "",
        call_id: str = "",
        notify: bool = True,
        is_urgent: bool = False,
        callback_requested: bool = False,
        caller_number: str = "",
        lang: str = "tr",
        recording_consent: bool = True,
    ) -> dict:
        lang = lang if lang in NOTIFY_LABELS else "tr"
        combined_lower = f"{caller_purpose} {summary_tr}".lower()
        if any(k in combined_lower for k in URGENT_KEYWORDS):
            is_urgent = True

        safe_name = (caller_name or "").strip() or "İsimsiz Arayan"
        record_id = call_id or datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        called_back = False
        try:
            for existing in CALL_LOG_REPOSITORY.list_records():
                if existing.call_id == record_id:
                    called_back = existing.called_back
                    break
            stored_record = CALL_LOG_REPOSITORY.upsert(CallRecord.create(
                call_id=record_id,
                caller_name=safe_name,
                caller_number=caller_number or "VoIP / Web",
                caller_purpose=caller_purpose or "Mesaj Bırakma",
                summary_tr=summary_tr,
                appointment_info=appointment_info,
                is_urgent=bool(is_urgent),
                callback_requested=bool(callback_requested),
                called_back=called_back,
                lang=lang,
                recording_consent=bool(recording_consent),
            ))
        except (StorageError, ValueError) as e:
            raise RuntimeError(f"Çağrı özeti güvenli biçimde kaydedilemedi: {e}") from e
        record = stored_record.to_dict()

        if self.firestore_db:
            try:
                if call_id:
                    doc_ref = self.firestore_db.collection("call_summaries").document(call_id)
                else:
                    doc_ref = self.firestore_db.collection("call_summaries").document()
                doc_ref.set(record)
                print(f"[Success] Saved call summary to Firebase document ID: {doc_ref.id}")
            except Exception as e:
                print(f"[Error] Firebase save error: {e}")

        if notify:
            self.send_notification(
                safe_name,
                caller_purpose,
                summary_tr,
                appointment_info,
                is_urgent=record["is_urgent"],
                callback_requested=record["callback_requested"],
                lang=lang,
            )
        return record

    def mark_call_returned(self, call_id: str, called_back: bool = True) -> bool:
        try:
            CALL_LOG_REPOSITORY.mark_called_back(call_id, bool(called_back))
            if self.firestore_db:
                try:
                    self.firestore_db.collection("call_summaries").document(call_id).update(
                        {"called_back": bool(called_back)}
                    )
                except Exception:
                    pass
            return True
        except (RecordNotFound, StorageError):
            return False

    def delete_call_log(self, call_id: str) -> bool:
        try:
            CALL_LOG_REPOSITORY.delete(call_id)
            if self.firestore_db:
                try:
                    self.firestore_db.collection("call_summaries").document(call_id).delete()
                except Exception:
                    pass
            return True
        except (RecordNotFound, StorageError):
            return False

    def send_notification(
        self,
        caller_name: str,
        purpose: str,
        summary_tr: str,
        appointment_info: str,
        is_urgent: bool = False,
        callback_requested: bool = False,
        lang: str = "tr",
    ):
        # Yalnızca .env'deki gizli konuya gönder (herkese açık sabit konu kaldırıldı)
        topics = [self.ntfy_topic] if self.ntfy_topic else []
        L = NOTIFY_LABELS.get(lang, NOTIFY_LABELS["tr"])

        prefix = f"🚨 [{L['urgent']}] " if is_urgent else ""
        cb_text = L["yes"] if callback_requested else L["no"]
        message = (
            f"{prefix}{L['caller']}: {caller_name}\n"
            f"{L['purpose']}: {purpose}\n"
            f"{L['summary']}: {summary_tr}\n"
            f"{L['callback']}: {cb_text}"
        )
        if appointment_info:
            message += f"\n{L['appointment']}: {appointment_info}"

        # ntfy başlıkları HTTP header olduğu için ASCII tutuluyor
        title = L["title_urgent"] if is_urgent else L["title"]
        priority = "urgent" if is_urgent else "high"
        tags = "rotating_light,warning,telephone_receiver" if is_urgent else "telephone_receiver,robot"

        for topic in topics:
            try:
                requests.post(
                    f"https://ntfy.sh/{topic}",
                    data=message.encode("utf-8"),
                    headers={
                        "Title": title,
                        "Priority": priority,
                        "Tags": tags,
                    },
                    timeout=5,
                )
                print(f"[Notification] Push notification sent to https://ntfy.sh/{topic} (urgent={is_urgent})")
            except Exception as e:
                print(f"[Warning] Could not send push notification to {topic}: {e}")
