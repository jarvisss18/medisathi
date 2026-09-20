# 🌿 MediSathi (स्मार्ट औषध साथी)
### *Offline-First Smart Medication Verification & Native Adherence System for Elderly Care*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)](https.flutter.dev)
[![Android](https://img.shields.io/badge/Android-Native_Engine-3DDC84?style=for-the-badge&logo=android)](https://developer.android.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![ML Kit](https://img.shields.io/badge/Google_ML_Kit-Offline_OCR-4285F4?style=for-the-badge&logo=google)](https://developers.google.com/ml-kit)
[![Hackathon](https://img.shields.io/badge/CODEX_Hackathon-2026_Finalist-059669?style=for-the-badge)]()

---

## 📌 Problem Statement & Solution

In India, **over 68% of elderly individuals take multiple daily prescription medications**, facing two critical risks:
1. **Accidental Consumption of Lookalike Medicines**: Strips with similar foil colors, shapes, and font layouts (e.g. *Paracetamol* vs *Amlodipine*) lead to hazardous accidental overdoses or wrong pill ingestion.
2. **Missed Doses Due to Sleeping Phones**: Standard app push notifications are silenced or suppressed by Android battery optimizations during device sleep mode.

### 💡 The MediSathi Solution
**MediSathi** is an offline-first mobile application that acts as a intelligent guardian for elderly medicine adherence:
- **Offline Pill Strip Verification Engine**: Uses Google ML Kit OCR & a deterministic 4-gate verification algorithm (Quality, OCR, Lookalike Shade, and Confidence Gate) to identify medicine packaging instantly without internet connectivity.
- **Native Lock-Screen Alarm System**: Bypasses Flutter UI threads using a custom Java/Android `AlarmActivity` + `AlarmManager.setAlarmClock()` to wake hardware screens and fire high-priority full-screen alarms over lock screens.
- **Elderly-Friendly UI**: 30pt+ high-contrast typography, HSL emerald palette, large tap targets, and full English/Hindi/Marathi localization.
- **Caregiver Escalation**: Automatically logs missed doses and provides one-tap SOS calling and pre-formatted SMS alerts to designated family caregivers.

---

## ✨ Key Features

| Feature | Description | Technical Implementation |
|---|---|---|
| **🔍 Offline Strip Scanner** | Scans blister packs & extracts APIs, strengths, and dosage instructions without internet. | Google ML Kit OCR + Custom Confidence Gate Engine |
| **🚨 Drug Interaction Warning** | Checks candidate scanned medicines against current active prescriptions for severe interactions. | Multi-drug rule matrix cross-referencing |
| **⏰ Native Lock-Screen Alarm** | Wakes device screen from deep sleep; displays full-screen green alarm dialog over lockscreen. | Android `AlarmActivity` + `PowerManager.FULL_WAKE_LOCK` |
| **📅 Adherence Timeline** | Tracks daily TAKEN vs MISSED dose history with exact ISO timestamps. | Persistent `SharedPreferences` v2 JSON logging |
| **📞 Caregiver Telephony** | Instant phone calling and pre-populated SMS alerts for missed doses. | Native `tel:` & `sms:` Android Intent schemes |
| **🌐 Multi-Language Support** | Complete localization in English, Hindi (हिंदी), and Marathi (मराठी). | Flutter `flutter_localizations` & ARB translations |

---

## 🏗️ System Architecture

```
                       ┌────────────────────────────────────────┐
                       │          MediSathi Mobile Shell        │
                       │           (Flutter 3.x / Dart 3)       │
                       └───────────────────┬────────────────────┘
                                           │
          ┌────────────────────────────────┼────────────────────────────────┐
          ▼                                ▼                                ▼
┌──────────────────┐           ┌──────────────────────┐         ┌──────────────────────┐
│  Presentation &  │           │ Offline Computer     │         │ Native Android Bridge│
│  State Layer     │           │ Vision Engine        │         │ (MethodChannel)      │
├──────────────────┤           ├──────────────────────┤         ├──────────────────────┤
│ • Material 3 UI  │           │ • Camera Preview Stream│       │ • com.bugbusters.    │
│ • Riverpod State │           │ • ML Kit Text Parsing│         │   medisathi/alarm    │
│ • GoRouter       │           │ • Quality & Blur Gate│         └──────────┬───────────┘
│ • ARB Localizer  │           │ • Lookalike Group Match│                    │
└──────────────────┘           └──────────────────────┘                    │
                                                                           ▼
                                                               ┌──────────────────────┐
                                                               │ Native Android OS    │
                                                               │ Layer (Java/Kotlin)  │
                                                               ├──────────────────────┤
                                                               │ • AlarmManager       │
                                                               │   (setAlarmClock)    │
                                                               │ • AlarmActivity      │
                                                               │   (Lockscreen Window)│
                                                               │ • AlarmReceiver      │
                                                               │   (FULL_WAKE_LOCK)   │
                                                               └──────────────────────┘
```

---

## 🛠️ Technology Stack

- **Frontend Shell**: Flutter 3.x, Dart 3, Material 3 Design
- **State Management & Routing**: Flutter Riverpod, GoRouter
- **Native Android Layer**: Java, Kotlin, Android SDK (API 24-34)
- **Computer Vision**: Google ML Kit Text Recognition, Camera API
- **Persistence & Storage**: `SharedPreferences` v2, Offline CSV/JSON Catalog Engine
- **Telephony & Hardware**: Android Intent (`tel:`, `sms:`), RingtoneManager, VibratorManager

---

## 🚀 Installation & Setup Guide

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.19.0`)
- Android Studio / VS Code with Flutter extension
- Android Device running Android 7.0+ (API 24+) with USB Debugging enabled

### Steps to Run
```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/medisathi.git
cd medisathi/mobile

# 2. Install dependencies
flutter pub get

# 3. Check connected devices
flutter devices

# 4. Build and run debug APK on your connected Android device
flutter run --debug
```

### Pre-built Debug APK
If you want to test the compiled app directly on Android:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🎥 Round 2 Submission Deliverables

- **Demo Video (YouTube)**: [Insert YouTube Link Here]
- **Presentation Deck**: See `ROUND2_PRESENTATION_DECK.md`
- **Technical Architecture PDF**: See `MediSathi_Architecture_MVP_Guide.pdf`

---

## 🛡️ License & Team

Built with ❤️ by **Team BugBusters** for the CODEX Hackathon 2026.
