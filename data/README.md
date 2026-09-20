# MediSathi Canonical Datasets & Calibration Guide

This directory contains the single source of truth datasets for MediSathi:

- `medicines.csv` — Offline CSV drug catalog (parsed directly by mobile app for zero-dependency offline load)
- `medicines.json` — JSON drug catalog (14+ items across look-alike groups)
- `interaction_rules.json` — Deterministic drug-drug interaction safety rules
- `gate_config.json` — Quality, OCR, and Confidence Gate threshold parameters
- `test_vectors/verify_cases.json` — End-to-end verification test vectors

---

## 1. Dataset Provenance & Maintenance

All drug entries are grounded in standard generic pharmacology classifications. Fields marked with `"TODO_TEAM"` require physical strip inspection and verification by the hackathon human team (Kalpesh, Pratham, Nityam).

| Dataset File | Primary Purpose | Synchronized Target |
| :--- | :--- | :--- |
| `medicines.csv` | Primary offline CSV catalog of verifiable medications | `mobile/assets/data/medicines.csv` |
| `medicines.json` | Catalog of verifiable medications & look-alike groups | `mobile/assets/data/medicines.json`, SQLite DB, Python API |
| `interaction_rules.json` | High-risk interaction lookup table | `mobile/assets/data/interaction_rules.json`, Python API |
| `gate_config.json` | Deterministic verification gate thresholds | `mobile/assets/data/gate_config.json`, Python Safety Gate |
| `test_vectors/verify_cases.json` | Cross-platform verification test suite | `mobile/test/`, `backend/tests/` |

---

## 2. Color Signature Calibration Workflow (Team Guide)

The color signature feature is **disabled by default** (`"enabled": false` in `gate_config.json`) until physical strip calibration is completed.

### Step-by-Step Physical Strip Calibration:
1. Place physical medicine strip under standard white LED lighting (~4000K-5000K).
2. Take 3 test photos using the MediSathi Scan Screen test tool or Python script in `tools/`.
3. Crop the foil accent / brand banner section of the strip.
4. Run HSV extraction script:
   ```bash
   python tools/calibrate_color.py --image path/to/strip_crop.jpg
   ```
5. Note down `hue` (0-179), `sat` (0-255), and `val` (0-255).
6. Update `medicines.json` entry with extracted HSV values and set `"calibrated": true`.
7. Once 5+ key medicines are calibrated, enable color gate in `gate_config.json` (`"enabled": true`).

---

## 3. Parity Guarantee

**CRITICAL:** Any modifications made to JSON files in `data/` MUST be copied to `mobile/assets/data/` to maintain 100% offline mobile-backend parity.
