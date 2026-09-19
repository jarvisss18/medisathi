# Architecture & Design Decisions Log — MediSathi

This document records key architectural, safety, and technical decisions made during the development of MediSathi MVP.

---

## Decision 1: Offline-First Pure Dart Confidence Gate
- **Context:** The safety gate must evaluate whether a scanned strip matches a known medication and reject ambiguous/shaky scans reliably.
- **Decision:** Implement the confidence gate in pure Dart (`mobile/lib/engine/gate/confidence_gate.dart`) with no UI or Flutter framework dependencies. Mirror the decision rules in Python for the FastAPI backend.
- **Rationale:** Ensures 100% unit-testability, instant sub-millisecond execution, and total offline independence. No LLM or cloud API call is used in the safety critical path.

## Decision 2: Multi-Frame Burst Capture with Motion Gating
- **Context:** Elderly users with hand tremors produce shaky images where individual frames are blurred or out of focus.
- **Decision:** Use `sensors_plus` gyroscope data to allow capture when phone stability passes threshold, and auto-capture a burst of 3–5 frames. OCR and quality metrics evaluate across all usable frames to vote on stable tokens.
- **Rationale:** Turns hand tremor from a fatal capture error into noise that multi-frame voting can filter out cleanly.

## Decision 3: "Don't Guess" Principle & UI Deviations
- **Context:** The problem statement explicitly requires avoiding false confirmations. Standard AI apps often display "92% match confidence" which elderly users interpret as 100% certainty.
- **Decision:** 
  1. Remove raw percentage confidence display in primary UI. Show "Medicine Verified" only when hard safety rules pass.
  2. Display explicit signals checklist (Name match, Strength match, Shade match, Sharp scan).
  3. Change "No interactions found" to "No stored interaction rule matched your current medicines. Ask your doctor or pharmacist."
- **Rationale:** Prevents dangerous shift from assistive triage to authoritative medical diagnosis. False rejection is preferred over false confirmation.

## Decision 4: Neutral Uncalibrated Shade Fallback
- **Context:** Palette color signature matching requires physical strip calibration under standard lighting.
- **Decision:** When `calibrated` is false in catalog color signatures, the shade metric contributes 0 score and causes 0 penalty.
- **Rationale:** Prevents false rejections on uncalibrated catalog items while allowing calibrated items (e.g., Amlodipine 5mg vs 10mg) to use packaging shade as a look-alike discriminator.
