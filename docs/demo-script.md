# MediSathi Mobile MVP — CODEX 2026 Hackathon Demo Script

**Persona:** Mrs. Sunanda Patil (68 years old, Pune, Maharashtra)  
**Caregiver:** Rahul Patil (Son, living in Mumbai)  
**Duration:** 3 Minutes  
**Core Motto:** *"When MediSathi is not sure, it does not guess."*

---

## Act 1: The Problem & Persona (0:00 - 0:30)

* **Presenter:** "Namaste Judges! Meet Mrs. Sunanda Patil, 68, from Pune. She takes 6 daily medicines for blood pressure, diabetes, and cholesterol. With age-related presbyopia and small Marathi/English foil text, reading 5 mg versus 10 mg is dangerous."
* **Presenter:** "Existing AI apps often guess or hallucinate when text is blurry. In healthcare, a false guess can be fatal. MediSathi is built on a strict, deterministic, offline-first safety rule: **If confidence or quality falls below safety thresholds, MediSathi NEVER guesses.**"

---

## Act 2: High-Confidence Scan & Multilingual TTS (0:30 - 1:30)

* **Action:** Open MediSathi App. Tap **Scan Medicine**.
* **Presenter:** "Watch the live feedback box. The motion gate checks camera stability. We select **TEST-001 (Clear Paracetamol 500 mg)**."
* **Screen:** Flashes Green — **"Medicine Verified"**.
* **Voice Output (TTS):** *"दवा सत्यापित: पैरासिटामोल 500 मिलीग्राम। डॉक्टर की सलाह के अनुसार खाना खाने के बाद लें।"*
* **Presenter:** "Notice the signals checklist: Name matched, strength matched, shade verified, image sharp. With one tap, Sunanda adds it to her daily medicines and sets an 8:00 AM reminder."

---

## Act 3: Don't-Guess Engine & Caregiver Escalation (1:30 - 2:30)

* **Action:** Tap **Scan Medicine** again. Select **TEST-002 (Blurry Strip)**.
* **Screen:** Amber Review Card — **"Unable to verify this medicine"**. Reason: *Photo is blurry or poorly lit.*
* **Presenter:** "Notice MediSathi refused to guess! Now let's try **TEST-003 (Amlodipine without mg)**."
* **Screen:** Amber Card — Reason: *Similar medicine detected, but strength (mg) is unclear.*
* **Screen Trigger:** Pop-up dialog: *"2 consecutive unverified scans. Alert caregiver Rahul?"*
* **Action:** Tap **Alert Caregiver**.
* **Screen:** Opens Caregiver Escalation Screen. Shows privacy consent toggles (photo sharing OFF by default) and simulated event log. Banner reads: *Prototype: simulated alert — nothing was sent.*

---

## Act 4: Multi-Drug Interaction Guard (2:30 - 3:00)

* **Action:** Navigate to **My Medicines** / **Interaction Warnings**.
* **Screen:** Red Warning Banner — **Potential Drug Interaction Detected: Amlodipine + Simvastatin**.
* **Presenter:** "MediSathi automatically cross-checks saved medicines against verified clinical interaction rules. It provides plain-language warnings in English, Hindi, and Marathi, advising Sunanda to consult her doctor."
* **Closing:** "MediSathi: Offline, deterministic, elderly-friendly medication verification. Thank you!"
