# 🎥 MediSathi — Round 2 MVP Video Recording Guide & Script

Use this exact video script and recording plan to shoot your **2 to 3 minute YouTube Demo Video** for Round 2 submission.

---

## 📋 Pre-Recording Checklist
1. **Device**: Connected Android Smartphone (Samsung Galaxy S22 Ultra / physical device).
2. **Setup**:
   - Install latest app build: `flutter run --debug` (or use `app-debug.apk`).
   - Have 1 or 2 physical medicine blister packs ready (e.g. *Crocin*, *Amlokind*, *Glycomet*, or *Telma*).
   - Ensure phone volume is TURNED UP (so alarm ringtone is audible).
3. **Recording Software**: Screen Recorder + Phone Camera (or a secondary phone recording the physical phone in hand to show lockscreen waking up!).

---

## 🎬 Scene-by-Scene Video Script

### 📍 Scene 1: Introduction & Problem Statement (0:00 - 0:30)
- **Visual**:
  - Show the physical phone displaying the **MediSathi Home Dashboard**.
  - Show quick close-up of medicine strips on the table.
- **Voiceover / Narration**:
  > *"Hello Judges! Welcome to Team BugBusters' demonstration of **MediSathi** — an offline-first, elderly-friendly medication verification and native alarm system built for the CODEX 2026 Hackathon."*
  > *"In India, elderly patients taking multiple daily medicines face two huge risks: accidental consumption of lookalike pill strips, and missing critical doses because standard app notifications are silenced when the phone is sleeping. Here is how MediSathi solves both."*

---

### 📍 Scene 2: Offline Pill Strip Scan & Drug Verification (0:30 - 1:15)
- **Visual**:
  - On MediSathi home screen, tap **"Scan Medicine Strip"**.
  - Point camera preview at the medicine strip (*Amlokind 5mg* or *Crocin*).
  - Show real-time frame scan → Quality Gate → OCR Engine → Results Screen.
  - Show medicine details: Canonical Name, Dosage instruction, and Interaction status.
- **Voiceover / Narration**:
  > *"First, let me scan this medicine strip. MediSathi runs a 4-gate verification algorithm entirely offline on the device using Google ML Kit OCR. Notice how it instantly extracts the brand name, active ingredients, dosage form, and checks for severe drug-drug interactions with active prescriptions — 100% offline without needing internet connection!"*

---

### 📍 Scene 3: Setting Smart Reminder & Native Alarm Integration (1:15 - 1:45)
- **Visual**:
  - Tap **"Set Reminder"** (or `+`).
  - Select *Amlokind 5mg*, set time for **1 minute from now**, select frequency *Daily*, and tap **Save Reminder**.
  - Point out the clean reminder card appearing in the Reminders list.
- **Voiceover / Narration**:
  > *"Now, let's schedule a dose reminder for 1 minute from now. When saved, MediSathi doesn't rely on standard push notifications. Instead, it registers an exact system alarm natively with Android's AlarmManager."*

---

### 📍 Scene 4: The Core Innovation — Lock-Screen Hardware Alarm (1:45 - 2:30)
- **Visual** *(Crucial Scene)*:
  - **Close the MediSathi app completely** (swipe away from Recent Apps).
  - **Lock the phone screen** (screen turns completely black / off).
  - Place the phone on table and wait for the minute to turn.
  - **Watch the phone screen automatically turn ON, bypass lockscreen, ring system alarm, and display full-screen green 'Medicine Time!' dialog!**
  - Show the buttons: **✔ Mark as Taken**, **⏰ 15 min**, **⏱️ Snooze 5**.
- **Voiceover / Narration**:
  > *"Now, observe closely. I am closing the app process completely and locking the phone screen into deep sleep mode."*
  > *"The moment the reminder time hits... boom! The phone hardware screen turns ON automatically, bypasses the lockscreen keyguard, loops the system alarm, and displays this full-screen green 'Medicine Time!' interface. This works 100% natively at the Android OS layer!"*

---

### 📍 Scene 5: Adherence Logging & Caregiver Escalation (2:30 - 3:00)
- **Visual**:
  - Tap **"✔ Mark as Taken"** on the alarm popup (alarm stops, screen closes).
  - Open MediSathi -> Navigate to **Reminders -> Dose History Tab** (shows green `TAKEN` badge with timestamp).
  - Demonstrate tapping **"MISSED"** -> Navigate to **Caregiver Contact & Alerts** (shows `MISSED_DOSE` alert and **Call Caregiver** / **Send SMS** buttons).
- **Voiceover / Narration**:
  > *"Tapping 'Mark as Taken' stops the alarm and records a timestamped adherence log saved in persistent local storage."*
  > *"If a dose is missed, MediSathi logs a Caregiver Event and allows one-tap emergency calling and automated SMS alerts to family caregivers."*
  > *"MediSathi provides complete safety, offline reliability, and peace of mind for seniors and their families. Thank you!"*

---

## 📌 Submission Checklist Before Uploading
1. Record video in 1080p HD with clear audio.
2. Upload video to **YouTube** as **Public** or **Unlisted**.
3. Copy the YouTube link.
4. Submit:
   - 🎥 **YouTube Video Link**
   - 📊 **PPT Deck** (`ROUND2_PRESENTATION_DECK.md`)
   - 💻 **GitHub Repository Link** (`https://github.com/<your-username>/medisathi`)
