# Agent brain katmanı

`agent_brain/`, LiveKit, Cascade ve Gemini Live'dan bağımsız konuşma iş
kurallarını barındırır. `agent.py` ses oturumunu ve LiveKit araçlarını yönetir;
bu paket ise çağrı durumu, güvenli kayıt, acil bildirim ve sahip dilindeki özet
için test edilebilir sözleşmedir.

## Dil kuralı

`agent_config.json` içindeki `owner_language` sahibin bildirim/özet dilidir.
Arayanın dili bundan bağımsızdır. Diller farklıysa LLM, yalnızca sahibin özeti
için çeviri üretir; isim, telefon, tarih ve saatler aynen korunur.

## Test

```powershell
python -m unittest discover -s tests -v
```

Canlı sistemde `save_call_note` yalnızca arayanın teyidinden sonra çağrılmalıdır.
`agent.py` sistem talimatı bu kuralı uygular; paket içindeki `CallSession` ise
metin tabanlı entegrasyon ve gelecekteki sağlayıcı değişimleri için kullanılır.
