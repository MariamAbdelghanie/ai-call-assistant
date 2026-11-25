# Google ile giriş — kurulum

Uygulamadaki giriş ekranı **gerçek** Google oturum açma kullanır. Kod hazırdır;
çalışması için Firebase tarafında bir kerelik yapılandırma gerekir. Bu dosya
o adımları sırayla anlatır.

Yapılandırma tamamlanmadan giriş ekranı açılır ama düğme çalışmaz ve
"Google girişi henüz yapılandırılmadı" uyarısı gösterilir. Sahte/geçici
oturum açma bilerek eklenmemiştir.

---

## 1. SHA-1 parmak izini alın

Firebase, uygulamanızı imzanızdan tanır. PowerShell'de proje klasöründe:

```powershell
cd mobile\android
.\gradlew signingReport
```

Çıktıda `Variant: debug` bölümündeki **SHA1** satırını kopyalayın. Örnek:

```
SHA1: A1:B2:C3:D4:...
```

> Yayınlanacak sürüm için `Variant: release` altındaki SHA-1 de eklenmelidir.
> Şu an release derlemesi debug anahtarıyla imzalandığı için ikisi aynıdır;
> gerçek bir yayın anahtarı oluşturduğunuzda yenisini de eklemeniz gerekir.

## 2. Firebase Console'da Android uygulaması ekleyin

1. <https://console.firebase.google.com> → proje **ai-call-bot-f04ea**
2. Proje ayarları → **Uygulamalarınız** → **Uygulama ekle** → **Android**
3. **Android paket adı**: `com.example.ai_call_assistant`
   (Uygulama takma adı serbest, örn. `CALLORA`)
4. **Hata ayıklama imzalama sertifikası SHA-1**: 1. adımda kopyaladığınız değer
5. **Uygulamayı kaydet**

## 3. google-services.json dosyasını yerleştirin

Firebase'in indirttiği dosyayı şu yola koyun:

```
mobile/android/app/google-services.json
```

Dosya adı ve klasör birebir aynı olmalıdır.

## 4. Google sağlayıcısını açın

Firebase Console → **Authentication** → **Sign-in method** → **Google** →
**Etkinleştir** → proje destek e-postasını seçin → **Kaydet**.

## 5. Bağımlılıkları kurun ve çalıştırın

```powershell
cd mobile
flutter pub get
flutter run
```

İlk açılışta karşılama ekranından sonra giriş ekranı gelir; **Google ile
devam et** düğmesi hesap seçiciyi açar.

---

## Sorun giderme

| Belirti | Sebep ve çözüm |
|---|---|
| "Google girişi henüz yapılandırılmadı" | `google-services.json` yok veya yanlış klasörde. 3. adımı tekrar edin. |
| `ApiException: 10` | SHA-1 eksik ya da yanlış. 1. ve 2. adımları tekrar edin; parmak izini ekledikten sonra `flutter clean` çalıştırın. |
| `ApiException: 12501` | Kullanıcı hesap seçiciyi kapattı. Hata değildir. |
| Derleme `minSdk` hatası veriyor | `firebase_auth` en az API 23 ister; `android/app/build.gradle.kts` içinde `minSdk = maxOf(flutter.minSdkVersion, 23)` satırı bulunmalı. |

## Yayın öncesi notlar

- **Paket adı** şu an `com.example.ai_call_assistant`. Google Play
  `com.example.*` ile başlayan paketleri **kabul etmez**; yayından önce
  (örneğin `com.ndm.callora` olarak) değiştirilmeli ve Firebase'e yeni paket
  adıyla yeni bir Android uygulaması eklenmelidir.
- `google-services.json` depoya **eklenmez** (`.gitignore` içinde). Gizli bir
  anahtar sayılmaz ama projeye özeldir; her geliştirici kendi kopyasını
  Firebase Console'dan indirir.
- Release derlemesi için ayrı bir imzalama anahtarı oluşturulduğunda o
  anahtarın SHA-1'i de Firebase'e eklenmelidir.
