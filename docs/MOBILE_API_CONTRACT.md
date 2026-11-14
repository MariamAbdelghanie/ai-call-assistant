# Mobil yönetim API sözleşmesi

Bu sözleşme telefon sahibinin uygulaması ile yerel yönetim backend'i arasındaki
entegrasyonu tanımlar. API, varsayılan olarak yalnızca `127.0.0.1` üzerinde
dinler. Ağdan erişim açılırsa her istek `X-Admin-Token` başlığıyla
`ADMIN_API_TOKEN` değerini taşımalıdır.

> Bu yönetim token'ı gerçek son kullanıcı girişi değildir. Üretimde mobil
> kullanıcı için Firebase Authentication veya eşdeğer bir oturum sistemi
> eklenmeden token mobil uygulamaya gömülmemelidir.

## Ayarlar

### `GET /api/config`

Asistanın aktiflik durumu, karşılama metni ve çalışma saatlerini döndürür.

### `POST /api/config`

Gövde, yalnızca değiştirilecek alanları içeren JSON nesnesidir:

```json
{
  "assistant_enabled": true,
  "greeting_text": "Merhaba, size nasıl yardımcı olabilirim?",
  "work_start": "09:00",
  "work_end": "18:00"
}
```

Saatler `HH:MM` biçiminde olmalıdır. Geçersiz değerler `400` ile reddedilir.

## Çağrılar

### `GET /api/calls`

Çağrıları en yeni kayıt ilk sırada olacak biçimde döndürür. Her kayıt
`call_id`, `caller_name`, `caller_number`, `summary_tr`, `is_urgent`,
`callback_requested`, `called_back` ve isteğe bağlı randevu bilgisini içerir.

### `POST /api/calls/{call_id}/returned`

Çağrıyı geri arandı olarak işaretler.

```json
{ "called_back": true }
```

Kayıt yoksa `404` döner.

### `POST /api/calls/delete-all`

Tüm yerel çağrı kayıtlarını siler. Yanlışlıkla silmeyi önlemek için gövdede
açık onay zorunludur:

```json
{ "confirmed": true }
```

`confirmed` alanı yoksa veya `true` değilse API `400` döner ve hiçbir kayıt
silinmez.

## Sağlık denetimi

`GET /api/health`, anahtar değerlerini asla döndürmeden yapılandırma
eksiklerini bildirir. Mobil arayüz bu bilgiyi yalnızca teknik yönetim ekranında
göstermelidir.
