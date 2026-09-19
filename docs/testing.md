# MediSathi Mobile MVP — Verification & Safety Testing Report

**Date:** September 19, 2026  
**Target:** CODEX 2026 Hackathon Submission  
**Engine Architecture:** Pure Dart, Offline-First, Deterministic Zero-Guess Confidence Gate  

---

## 1. Safety & Deterministic Verification Test Matrix

| Test ID | Scenario Description | Synthetic / Image Payload | Quality Status | Gate Decision | Reason Code | Expected Outcome | Result |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TEST-001** | Sharp strip, Paracetamol 500 mg | `strip_paracetamol_500mg.jpg` | Laplacian: 190.0 (PASS) | `MATCH` | `MATCH_CONFIDENT` | Medicine Verified card shown with High strength match & voice guidance | **PASS** |
| **TEST-002** | Blurry strip (low Laplacian variance) | `strip_paracetamol_blurry.jpg` | Laplacian: 45.0 (FAIL) | `REVIEW` | `QUALITY_BLUR_FAILED` | Amber review card shown; "Photo is blurry or poorly lit" | **PASS** |
| **TEST-003** | Look-alike strip without strength (Amlodipine) | `strip_amlodipine_no_mg.jpg` | Laplacian: 160.0 (PASS) | `REVIEW` | `LOOKALIKE_STRENGTH_MISSING` | Safety rule enforced; "Similar medicine detected, but strength (mg) is unclear" | **PASS** |
| **TEST-004** | Non-medicine text / Unknown compound | `strip_unknown.jpg` | Laplacian: 200.0 (PASS) | `REJECT` | `NO_MEDICINE_FOUND` | Red reject card shown; "No matching medicine found in safety catalog" | **PASS** |

---

## 2. Automated Unit Testing Suite Results

**Command Run:** `flutter test`  
**Passed:** 25 / 25 Unit Tests (100% Success Rate)  
**Execution Time:** ~8.5 seconds  

### Test Categories Covered:
1. **Confidence Gate Evaluation Rules:**
   - Sharp scan matching catalog item (`MATCH` state, score > 0.85).
   - Low Laplacian variance blur failure (`REVIEW` state with `QUALITY_BLUR_FAILED`).
   - Glare ratio exceeding 0.15 threshold (`REVIEW` state with `QUALITY_GLARE_FAILED`).
   - Low brightness < 50.0 (`REVIEW` state with `QUALITY_BRIGHTNESS_LOW`).
   - Strength conflict (e.g. Paracetamol 650 mg vs candidate 500 mg) (`REVIEW` state with `STRENGTH_MISMATCH`).
   - Look-alike group handling when strength is ambiguous (`REVIEW` state with `LOOKALIKE_STRENGTH_MISSING`).
   - Look-alike group handling when strength matches (`MATCH` state with `LOOKALIKE_RESOLVED`).
   - Unknown text / non-medicine input (`REJECT` state with `NO_MEDICINE_FOUND`).

2. **Quality Assurance & Performance:**
   - Laplacian variance calculation (< 5ms).
   - Glare ratio computation (< 8ms).
   - Processing offline catalog matching (< 2ms).

---

## 3. Performance & Offline SLA

- **On-Device Evaluation Time:** < 50 ms total gate decision latency.
- **Offline Independence:** 100% operational without internet connectivity or external APIs.
- **Memory Footprint:** < 45 MB peak RAM usage.
