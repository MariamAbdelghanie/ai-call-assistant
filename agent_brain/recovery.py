"""Anlaşılmayan bilgi ve hayatî risk akışları için dil bağımsız kurallar."""

from __future__ import annotations

from dataclasses import dataclass

from .models import Language


@dataclass
class ClarificationTracker:
    """Üç başarısız denemeden sonra doğrulanmamış verinin kaydedilmesini engeller."""

    attempts: int = 0
    maximum_attempts: int = 3

    def next_prompt(self, language: Language) -> tuple[str, bool]:
        self.attempts += 1
        should_stop_capture = self.attempts >= self.maximum_attempts
        variant = min(self.attempts, 3)
        prompts = {
            Language.TURKISH: (
                "Üzgünüm, bu bilgiyi anlayamadım. Lütfen yavaşça tekrar eder misiniz?",
                "Bilgiyi doğrulayamadım. Kısa cümlelerle, önce arama nedeninizi sonra mesajınızı söyler misiniz?",
                "Bu bilgiyi doğrulayamadığım için kaydedemem. İsterseniz yalnızca geri arama talebi bırakabilirsiniz.",
            ),
            Language.ENGLISH: (
                "Sorry, I did not understand that information. Could you repeat it slowly?",
                "I could not verify that. Please state the reason for calling first, then your message in short sentences.",
                "I cannot save information I could not verify. You may leave only a callback request.",
            ),
            Language.ARABIC: (
                "عذرًا، لم أفهم هذه المعلومة. هل يمكنك تكرارها ببطء؟",
                "لم أتمكن من التحقق من المعلومة. اذكر سبب الاتصال ثم رسالتك بجمل قصيرة من فضلك.",
                "لا يمكنني حفظ معلومات لم أتحقق منها. يمكنك ترك طلب معاودة اتصال فقط.",
            ),
        }
        return prompts[language][variant - 1], should_stop_capture


LIFE_THREATENING_KEYWORDS = (
    "hayati", "kanama", "bilinç", "nefes alam", "kalp krizi",
    "life threatening", "bleeding", "unconscious", "cannot breathe", "heart attack",
    "حياة", "نزيف", "فاقد الوعي", "لا أستطيع التنفس", "نوبة قلبية",
)


def is_life_threatening(text: str) -> bool:
    normalized = (text or "").casefold()
    return any(keyword in normalized for keyword in LIFE_THREATENING_KEYWORDS)


def emergency_guidance(language: Language) -> str:
    return {
        Language.TURKISH: "Hayati tehlike varsa lütfen hemen 112 Acil Çağrı Merkezi'ni arayın.",
        Language.ENGLISH: "If there is an immediate danger to life, please call emergency services at 112 now.",
        Language.ARABIC: "إذا كانت هناك خطورة فورية على الحياة، يرجى الاتصال بالرقم 112 فورًا.",
    }[language]
