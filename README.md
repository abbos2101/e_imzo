# E-Imzo Flutter Package

[![pub package](https://img.shields.io/pub/v/prompt_generator.svg)](https://pub.dev/packages/e_imzo)

O'zbekiston E-Imzo (elektron raqamli imzo) bilan ishlash uchun sof Dart tilida yozilgan Flutter package.

## Xususiyatlari

- ✅ Tashqi packagelarga bog'liq emas
- ✅ QR code orqali autentifikatsiya
- ✅ Deeplink orqali autentifikatsiya
- ✅ Android va iOS qo'llab-quvvatlash
- ⏳ Fayl imzolash (kelajakda qo'shiladi)

## O'rnatish
```yaml
dependencies:
  e_imzo: ^version
  url_launcher: ^version
```

## Sozlash

### 1. Backend tayyorlash

Backend ishlab chiquvchi quyidagi API larni tayyorlab berishi kerak:

**1.1. Autentifikatsiya sessiyasi yaratish**
```json
POST /api/eimzo/create-session

Response:
{
  "status": 1,
  "siteId": "0000",
  "documentId": "2944F1F2",
  "challange": "F8D2181DC6C02EA819B88FF3EF49BE0C"
}
```

**1.2. Imzolash statusini tekshirish**
```json
GET /api/eimzo/check-status/{documentId}

Response:
{
  "status": 1, // 1 - imzolandi, 2 - kutilmoqda yoki boshqacha bo'lishi mumkin
}
```

**1.3. Foydalanuvchi ma'lumotlarini olish**
```json
GET /api/eimzo/user-info/{documentId}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "pinfl": "12345678901234",
    "fullName": "Aliyev Ali Alijonovich",
    ...
  }
}
```

### 2. Soliq bilan shartnoma

E-Imzo xizmatini ishlatish uchun O'zbekiston Soliq Qo'mitasi bilan shartnoma tuzish talab etiladi (pullik xizmat).

### 3. Mobil ilovalar

Foydalanuvchilar qurilmalariga E-Imzo ilovasini o'rnatishi kerak:
- **Android**: [Google Play](https://play.google.com/store/apps/details?id=uz.yt.idcard.eimzo&hl=ru)
- **iOS**: [App Store](https://apps.apple.com/uz/app/e-imzo-id/id1563416406)

### 4. url_launcher sozlash

`url_launcher` package uchun platform konfiguratsiyalari:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="eimzo" />
  </intent>
</queries>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>eimzo</string>
</array>
```

## Ishlatish

### QR Code orqali autentifikatsiya
```dart
import 'package:e_imzo/e_imzo.dart';
import 'package:qr_flutter/qr_flutter.dart';

// 1. Backenddan session yaratish
final response = await createSession(); // sizning API chaqiruvingiz

// 2. QR code uchun text generatsiya qilish
final qrText = EImzo.qrcodeAuth(
  challenge: response['challange'],
  siteId: response['siteId'],
  documentId: response['documentId'],
);

// 3. QR code ko'rsatish
QrImageView(
  data: qrText,
  version: QrVersions.auto,
  size: 200.0,
)

// 4. Status tekshirish (polling)
Timer.periodic(Duration(seconds: 2), (timer) async {
  final status = await checkStatus(response['documentId']);
  if (status['status']==1) {
    timer.cancel();
    final userInfo = await getUserInfo(response['documentId']);
    // Foydalanuvchi tizimga kirdi
  }
});
```

### Deeplink orqali autentifikatsiya
```dart
import 'package:e_imzo/e_imzo.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. Backenddan session yaratish
final response = await createSession();

// 2. Deeplink generatsiya qilish
final deeplink = EImzo.deeplinkAuth(
  challenge: response['challange'],
  siteId: response['siteId'],
  documentId: response['documentId'],
);

// 3. E-Imzo ilovasini ochish
if (await canLaunchUrl(Uri.parse(deeplink))) {
  await launchUrl(
    Uri.parse(deeplink),
    mode: LaunchMode.externalApplication,
  );
} else {
  // E-Imzo ilovasi o'rnatilmagan
  showDialog(...);
}

// 4. Ilovaga qaytgandan keyin status tekshirish
// (AppLifecycleState.resumed da)
final status = await checkStatus(response['documentId']);
if (status['status']==1) {
  final userInfo = await getUserInfo(response['documentId']);
  // Foydalanuvchi tizimga kirdi
}
```

## Foydali havolalar

- [E-Imzo Android](https://play.google.com/store/apps/details?id=uz.yt.idcard.eimzo)
- [E-Imzo iOS](https://apps.apple.com/uz/app/e-imzo-id/id1563416406)
- [E-Imzo hujjatlari](https://github.com/qo0p/e-imzo-doc)
- [Integratsiya namunasi](https://github.com/jafar260698/E-IMZO-INTEGRATION)

---

**Eslatma**: Fayl imzolash funksiyasi hozirda ishlab chiqilmoqda va keyingi versiyalarda qo'shiladi.