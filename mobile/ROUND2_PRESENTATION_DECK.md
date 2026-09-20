# 📊 MediSathi — Round 2 Hackathon Presentation Deck Outline

Use these slide contents to update your PPT presentation for **Round 2 Submission**.

---

## 🖼️ Slide 1: Title & Team Overview
- **Title**: **MediSathi (स्मार्ट औषध साथी)**
- **Subtitle**: *Offline-First Smart Medication Verification & Native Adherence System for Elderly Care*
- **Event**: CODEX Hackathon 2026 — Round 2 Finalist
- **Team Name**: Team BugBusters
- **Tagline**: *"Ensuring zero pill confusion and 100% adherence for elderly care."*

---

## 🖼️ Slide 2: Problem Statement & Real-World Impact
- **The Elderly Medication Crisis in India**:
  1. **68%+ of elderly patients** manage 3 to 6 daily prescriptions independently.
  2. **Lookalike Packaging Hazard**: Strips with similar foil shapes/colors (*Paracetamol 500mg* vs *Amlodipine 5mg*) lead to accidental overdoses.
  3. **Missed Doses on Sleeping Phones**: Standard app push notifications fail during Android sleep mode or Doze state.
  4. **Rural Connectivity Void**: Cloud-only AI vision tools fail in sub-urban/rural areas without high-speed internet.

---

## 🖼️ Slide 3: The MediSathi Solution Architecture
- **Dual-Engine Innovation**:
  1. **Offline Computer Vision Engine**: 4-gate verification algorithm (Quality, OCR, Shade, & Confidence Gate) running 100% on-device via Google ML Kit.
  2. **Native Android Alarm Engine**: Custom Java/Android `AlarmActivity` using `AlarmManager.setAlarmClock()` to wake device CPU/screen and trigger full-screen lockscreen alarms.
- **Key Differentiator**: Operates completely offline without internet or backend server dependency.

---

## 🖼️ Slide 4: Key Technical Features & Innovation
- **🔍 1. Offline Pill Strip Scanner**: OCR active ingredient parsing + lookalike group identification.
- **⚠️ 2. Drug-Drug Interaction Checker**: Cross-checks candidate medicine against active prescriptions for severe clinical risks.
- **⏰ 3. Native Lock-Screen Alarm**: Hardware screen wake (`PowerManager.FULL_WAKE_LOCK`) + lockscreen keyguard bypass.
- **📅 4. Today's Adherence Timeline**: Timestamped TAKEN vs MISSED dose logs saved in persistent storage.
- **📞 5. Caregiver Escalation**: Automated SMS alerts and emergency calling for missed doses.
- **🌐 6. Inclusive Accessibility**: 30pt+ typography, HSL green contrast theme, full English/Hindi/Marathi l10n.

---

## 🖼️ Slide 5: Technical Deep-Dive — Native Alarm vs Standard Notifications

| Aspect | Standard App Notifications | MediSathi Native Alarm System |
|---|---|---|
| **OS Priority** | Standard Push / Local Notification | System Alarm Priority (`setAlarmClock`) |
| **Doze Mode Behavior** | Often delayed or silenced | Immediate CPU wake via `FULL_WAKE_LOCK` |
| **Lock-Screen Action** | Card in notification drawer | Wakes hardware screen & displays full-screen green dialog |
| **Ringtone** | Single alert chime | Looping system alarm ringtone + haptic vibration |
| **Flutter Dependency** | Requires active Flutter engine | Native Java/Android activity (bypasses Dart thread) |

---

## 🖼️ Slide 6: Live MVP Verification Results & Demo Highlights
- **Tested on Physical Device**: Samsung Galaxy S22 Ultra (Android 14 / One UI 6.0).
- **Test Scenarios Verified**:
  - ✅ Cold-start OCR scanning of Indian brand medicine packs (*Crocin*, *Amlokind*, *Glycomet*, *Telma*).
  - ✅ Direct alarm trigger from phone sleep mode / locked screen.
  - ✅ Adherence logging and Caregiver SMS escalation.
- **Video Demo Link**: [YouTube Link]

---

## 🖼️ Slide 7: Roadmap & Future Expansion
- **Phase 1 (Achieved)**: Offline OCR scanner, native lockscreen alarm, adherence timeline, caregiver SMS.
- **Phase 2 (Post-Hackathon)**: Bluetooth smart pillbox hardware sync, regional voice assistance (text-to-speech for regional dialects), WhatsApp Webhook caregiver alerts.
- **Phase 3**: Integration with ABHA (Ayushman Bharat Health Account) digital health records.

---

## 🖼️ Slide 8: Thank You & Q&A
- **Repository**: `https://github.com/<your-username>/medisathi`
- **Video Demo**: `[Insert YouTube Link]`
- **Team Contact**: Team BugBusters (CODEX 2026)
