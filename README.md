# MediSathi — Right Medicine. Safe You. 🩺💊

[![Event](https://img.shields.io/badge/Event-CODEX%202026%20(MUSA)-blue)](https://github.com/)
[![Problem Statement](https://img.shields.io/badge/Problem-CX0305--Medicine%20Roulette-orange)](https://github.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> **Core Philosophy:** *"When MediSathi is not sure, it does not guess."*

---

## Executive Overview
MediSathi is an offline-first, voice and visual medication verification app specifically designed for elderly patients who take multiple daily medications and risk confusing look-alike strips or bottles.

Built for **CODEX 2026 (MUSA) Round 2**, MediSathi addresses the critical challenge where look-alike medication strips differ only by small printed strength digits, batch suffixes, or subtle packaging shades, complicated by hand tremors during phone capture.

---

## Key Features

- **Multi-Frame Motion-Gated Burst Capture:** Subscribes to device gyroscope data to auto-capture frames only when steady, filtering out blur and hand-tremor artifacts.
- **On-Device OCR & Information Extraction:** Uses Google ML Kit Text Recognition to parse medicine names, strength values, batch codes, and expiry dates locally.
- **Multi-Frame Token Voting:** Combines OCR results across 3–5 captured frames to eliminate capture noise.
- **Shade (Color Signature) Analysis:** Compares packaging Lab/HSV color signatures to differentiate visually similar packaging variants.
- **Deterministic Confidence Gate:** Pure Dart decision matrix with hard safety overrides. **No LLM in safety path.**
- **Interaction Engine:** Local rule-based pair lookup with plain-language safety warnings.
- **Elderly-First Accessibility:** 18sp+ body typography, 56dp touch targets, high contrast, and full voice output (`flutter_tts`) in English, Hindi (हिंदी), and Marathi (मराठी).
- **Simulated Caregiver Escalation:** Triggers simulated alerts to caregivers upon consecutive scan failures or missed dose windows.
- **Demo Mode:** Offline demonstration suite with sample images and simulated shaky-hand effects.

---

## Technical Stack

| Layer | Technology |
|---|---|
| **Mobile Frontend** | Flutter 3.44+ (Dart), `go_router`, Riverpod |
| **OCR & Vision** | `google_mlkit_text_recognition`, Dart `image` package isolate processing |
| **Sensors & Sensors** | `sensors_plus` (gyroscope motion gating), `camera` burst controller |
| **Voice & Localization** | `flutter_tts`, Flutter `gen_l10n` (`en`, `hi`, `mr`) |
| **Local Storage** | `sqflite` (User medicines, Reminders, Dose logs) |
| **Notifications** | `flutter_local_notifications` + `timezone` |
| **Backend (Optional P1)** | FastAPI (Python 3.13), Pydantic, SQLAlchemy, Docker |

---

## Safety & Non-Medical Disclaimer

> **Prototype Disclaimer:** MediSathi is a hackathon prototype developed for medication identification and adherence support. It is **NOT** a medical device, diagnosis tool, or substitute for professional medical advice from a doctor or pharmacist.
