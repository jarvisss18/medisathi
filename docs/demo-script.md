# MediSathi — 3-Minute Demo Video Script (CODEX 2026 Round 2)

**Persona:** Mrs. Sunanda Patil, 72, Panvel. Takes 6 daily medications. Son Rahul is caregiver.

---

## Demo Script Timeline

### 1. Introduction & Context (0:00 - 0:20)
- **Visual:** Open MediSathi App Home Screen showing "Namaste Mrs. Sunanda Patil" and Today's Doses card.
- **Narrative:** "Mrs. Patil is 72 and takes six daily medications. Because many medicine strips look nearly identical in shape and color, she risks taking the wrong dose or confusing medicines. Here is how MediSathi helps her stay safe."

### 2. Scanning & Verification (0:20 - 0:50)
- **Visual:** Tap "Scan Medicine". Place Amlodipine 5mg strip in frame. Green steadiness ring turns solid green. Multi-frame burst captures 3 images.
- **Result:** Screen transitions to **"Medicine Verified"** (Green Check, Amlodipine 5mg, Signals Checklist: Name matched, Strength 5mg matched, Pack shade verified).
- **TTS Audio:** App speaks: *"Amlodipine 5 mg verified. Take 1 tablet daily after food."*

### 3. Interaction Warning Check (0:50 - 1:15)
- **Visual:** Scan an OTC painkiller (Ibuprofen 400mg) while Aspirin 75mg is saved in My Medicines.
- **Result:** Warning screen appears in Amber/Red: *"Potential Interaction Detected — Ibuprofen + Aspirin. Ibuprofen may reduce the protective effect of low-dose aspirin and increase stomach bleeding risk. Please consult your doctor or pharmacist."*

### 4. Setting Reminders & Home View (1:15 - 1:35)
- **Visual:** Tap "Set Reminder" for Amlodipine 5mg at 8:00 AM daily. Show notification scheduled alert.

### 5. Shaky-Hand Robustness Safeguard (1:35 - 1:55)
- **Visual:** Deliberately shake phone while attempting to scan a strip (or toggle Demo Mode: Simulate Shaky Hand).
- **Result:** Quality engine rejects blurry frames. Screen displays: *"Unable to verify — Too shaky. Please hold steadier or ask your caregiver."*

### 6. Look-Alike "Don't Guess" Protection (1:55 - 2:15)
- **Visual:** Scan Amlodipine 10mg strip where strength digit is obscured.
- **Result:** Gate detects look-alike group `LA-AMLO` missing strength discriminator. Screen displays: **"Don't Guess — Unable to verify medicine identity. Please rescan or ask caregiver."**

### 7. Simulated Caregiver Alert (2:15 - 2:35)
- **Visual:** After two consecutive failed scans, screen prompts: *"Simulated Caregiver Alert — Notify Rahul?"* Consent banner explicitly displays *"Prototype: simulated alert — no real SMS sent."*

### 8. Voice & Vernacular Support (2:35 - 2:50)
- **Visual:** Toggle Language selector to Marathi (मराठी) / Hindi (हिंदी).
- **Audio:** Tap "🔊 Read Aloud" — app reads result aloud in selected vernacular TTS voice.

### 9. Conclusion & Honest Scope (2:50 - 3:00)
- **Visual:** Show Settings / About MediSathi with disclaimer and link to GitHub repository and automated safety test suite.
- **Narrative:** *"MediSathi — Right Medicine. Safe You. When MediSathi is not sure, it does not guess."*
