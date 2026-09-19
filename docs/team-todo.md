# MediSathi — Team Action Items (`team-todo.md`)

This document lists action items for team members to complete prior to final Round 2 submission.

---

## 1. Physical Strip Calibration (Kalpesh Patil & Pratham Lokare)
- [ ] Photograph real medicine strips (clear and shaky captures) for the demo patient's 6 medicines into `mobile/assets/demo/real/`.
- [ ] Run `python tools/measure_color_signature.py` on real strip photos and update `color_signature` (`hue`, `sat`, `val`, `calibrated: true`) in `data/medicines.json`.

## 2. Interaction Rule Source Verification (Nityam Patil)
- [ ] Review seeded interaction rules (INT-001, INT-002, INT-003) against a clinical source (e.g. CDSCO / PubChem / DrugBank).
- [ ] Update `status: verified` and fill `reviewed_at` date in `data/interaction_rules.json`.

## 3. Localization Native Review (Yaser Mukadam & Team)
- [ ] Review Hindi (`app_hi.arb`) and Marathi (`app_mr.arb`) strings for natural phrasing suitable for elderly users.

## 4. Final Submission Artifacts (Yaser Mukadam & Team)
- [ ] Record the 3-minute demo video using `docs/demo-script.md`.
- [ ] Upload video to YouTube and verify playback.
- [ ] Include real app screenshots in `screenshots/` and update `docs/ppt-update.md`.
- [ ] Submit YouTube link, GitHub repo link, and PPT update.
