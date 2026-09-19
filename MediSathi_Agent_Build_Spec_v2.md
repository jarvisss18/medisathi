# MediSathi — Complete MVP Build Specification for the Coding Agent (v2)

**Event:** CODEX 2026 (MUSA) — Round 2 (online, **22 September**)
**Problem Statement:** CX0305 — *Medicine Roulette*
**Team:** Bug Buster's — Yaser Mukadam (Lead, ML & Backend), Pratham Lokare (Frontend/UI-UX), Kalpesh Patil (Computer Vision & ML), Nityam Patil (Research & PPT)

> **How to use this document:** This is the single source of truth. Read it fully before writing any code. Build the working Android MVP, create the GitHub repository, commit incrementally, push, and prepare everything needed for the Round 2 submission. Follow the priority tiers (P0/P1/P2) in Section 3. If something is ambiguous, choose the simplest option that keeps the demo reliable, and record the decision in `docs/decisions.md`.

---

## 0. Round 2 Submission Requirements (what this build must produce)

1. **Demo video (YouTube link):** must show what was actually built and how it works. The repo must contain a recording-ready demo flow (`docs/demo-script.md`) and a Demo Mode (Section 12) so the video can be recorded reliably.
2. **Live GitHub repository:** code and implementation must be reviewable, with meaningful commits.
3. **Updated PPT** (only if changes since Round 1): produce a short "Implementation Evidence" slide content file `docs/ppt-update.md` (real screenshots, what is implemented vs future).

**Time constraint:** the team has only a few days. Build the P0 path first and keep it demonstrable at every commit. Never leave the app in a non-building state.

---

## 1. Product Context

### 1.1 The problem (from the official problem statement)
An elderly patient on **six different medications** regularly confuses look-alike strips and misses doses. Family members only find out after a health scare. Required: a **voice-and-visual, vernacular-language app** that **scans a strip or bottle**, **sets dosage-timing reminders**, and **warns of dangerous drug interactions in plain language**.

**The twist (must be addressed explicitly):** look-alike strips often differ only in a **small printed batch code** or a **subtly different shade**. The recognition must work **reliably even when the elderly user's hands shake** while holding the phone.

### 1.2 Product name and principle
- **Name:** MediSathi — tagline: *"Right Medicine. Safe You."*
- **Core principle (must be visible in code, UI and docs):** ***"When MediSathi is not sure, it does not guess."***

### 1.3 Target users
- **Primary:** elderly patients (60+) — large text, few taps, voice, vernacular.
- **Secondary:** family members / caregivers — get alerts on missed doses and failed scans.
- **Tertiary:** doctors / pharmacists — plain-language warnings tell the patient to consult them.

### 1.4 Demo persona (used for seed data, demo mode and video)
**Mrs. Sunanda Patil, 72, Panvel.** Takes six medicines daily (see Section 9.3). Her son **Rahul** is her caregiver. She confuses Amlodipine 5 mg with Amlodipine 10 mg and Atorvastatin 10 mg with 20 mg because the strips look nearly identical. *All persona data is fictional; never use real personal data.*

### 1.5 Safety & honesty disclaimers (mandatory)
- This is a **hackathon prototype** for medication identification and adherence support. It is **NOT a medical device**, not a diagnosis tool, and not a substitute for a doctor or pharmacist.
- The app must **never** invent a medicine identity, dose, or interaction warning.
- Never show "Safe to take". Recognition ≠ safety. Use "Medicine Verified" (identity only) and show "No stored interaction rule matched" (not "No interactions").
- Do not claim clinical accuracy anywhere (UI, README, docs). The confidence score is a **prototype heuristic**, not a validated probability.
- A visible footer/disclaimer on Verification, Details and Settings/About: *"Prototype for medication identification and adherence support — not a substitute for medical advice."*

---

## 2. Design Principles

1. **Fail safe:** any uncertainty → rescan / ask caregiver. False rejection is acceptable; **false confirmation is not**.
2. **Deterministic & explainable:** the confidence gate is rule-based code with unit tests. No LLM anywhere in the safety path.
3. **Elderly-first UX:** min body font 18 sp (headings 24–32 sp), min touch target 56 dp, high contrast (WCAG AA), respect system font scaling up to 200%, one primary action per screen, icons + text labels, voice read-out on every result screen.
4. **Offline-first:** the entire P0 demo (scan → verify → interaction check → reminder → voice) must work with **no internet and no backend**. Backend is an enhancement layer.
5. **Honest scope:** README must list what is implemented vs future. Never claim unimplemented features.

---

## 3. Scope and Priority Tiers

### P0 — MUST work (demo-critical)
1. App shell, splash, home, bottom navigation (Home / My Medicines / Reminders / More).
2. Camera scan with **multi-frame burst capture**, **motion-gated capture**, per-frame **quality scoring** (blur, glare, brightness), best-frame selection.
3. **On-device OCR** (Google ML Kit) → extract name, strength, batch, expiry text.
4. **Catalog matching** against the curated local medicine catalog (Section 9).
5. **Look-alike discrimination** using strength + batch/variant marker + **shade (color signature)** — the PS twist.
6. **Deterministic Confidence Gate** with hard safety rules → VERIFIED / REVIEW / FAIL states and their UIs.
7. **Medicine Details**, add to **My Medicines**.
8. **Interaction check** against saved medicines using curated rules only.
9. **Reminders**: create, list, local notifications, mark taken, missed-dose detection.
10. **Voice output (TTS)** for key states in English (Hindi/Marathi strings included, see P1).
11. **Caregiver escalation (simulated)** after repeated low-confidence scans or missed dose.
12. **Demo Mode** with bundled sample images.
13. Automated tests for the gate; GitHub repo with commits, README, docs.

### P1 — Should work if time permits
- Full Hindi + Marathi localization with device TTS in `hi-IN` / `mr-IN`.
- Voice input ("Listening…" screen): simple command recognition (scan / my medicines / reminders / read aloud) using `speech_to_text`.
- FastAPI backend (`/verify`, `/interactions/check`, `/medicines`, `/reminders`, `/caregiver/escalate`) mirroring the on-device engine, with Docker + shared test vectors.
- Caregiver summary share via Android share sheet (user-entered contact only).
- Adherence summary (taken / missed this week).
- GitHub Actions CI; GitHub Release with debug APK.

### P2 — Nice to have (only after everything above is done and green)
- TFLite image classifier for package recognition; PostgreSQL via docker-compose; editable catalog; barcode/QR reading (ML Kit barcode) as an additional signal.

### Explicitly OUT of scope
- Any claim of medical-grade accuracy; 50,000+ medicine catalog; recommending to change/skip/double a dose; guessing a medicine from a blurry image; using batch/lot number alone as identity; hospital/EHR integration; real SMS/WhatsApp infrastructure or payments; LLM as source of drug interactions; scraping copyrighted or private data; storing camera images in Git.

---

## 4. Technology Stack

| Layer | Choice | Notes |
|---|---|---|
| Mobile | **Flutter (stable) + Dart**, Android target (minSdk 23, targetSdk latest supported by Flutter) | iOS not required |
| State management | **Riverpod** | keep simple, testable |
| Navigation | `go_router` | |
| Camera | `camera` plugin | burst via repeated `takePicture()` or image stream; fall back to `image_picker` for gallery |
| Motion gating | `sensors_plus` (gyro/accelerometer) | capture only when phone is steady (Section 7.2) |
| OCR | `google_mlkit_text_recognition` (Latin script) | on-device; extract text blocks with bounding boxes |
| Image analysis | `image` (Dart) run in an isolate (`compute`) | Laplacian variance (blur), glare ratio, brightness, color signature. Native OpenCV only if the Dart version is too slow |
| TTS | `flutter_tts` | locales `en-IN`, `hi-IN`, `mr-IN`; fall back gracefully if a voice is missing |
| Speech input (P1) | `speech_to_text` | |
| Local DB | `sqflite` (+ `path`) | user medicines, reminders, dose logs, verification logs |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` | exact alarms, survive reboot |
| Localization | Flutter `gen_l10n` with ARB files (`en`, `hi`, `mr`) | **no hardcoded user-facing strings** |
| Backend (P1) | **FastAPI (Python 3.11+)**, Pydantic, SQLAlchemy | SQLite by default; Postgres optional through docker-compose |
| Backend tests | `pytest` | |
| Mobile tests | `flutter_test` (unit + widget) | |
| CI (P1) | GitHub Actions | `flutter analyze`, `flutter test`, `pytest` |
| VCS | Git + GitHub via `gh` CLI | Section 16 |

**Dependency rule:** add packages with `flutter pub add <name>` / `pip install`, letting the tool resolve the current compatible version. Do not invent version numbers. Commit `pubspec.lock`. If a plugin fails to build (e.g., ML Kit / camera Gradle conflicts), fix it or choose the closest alternative and document it in `docs/decisions.md`.

---

## 5. System Architecture

```
Flutter Android App (offline-capable)
 ├─ UI screens (15)                         ← Section 6
 ├─ Capture module: camera + motion gate + burst
 ├─ Quality module: blur / glare / brightness / stability   ← Section 7
 ├─ OCR module: ML Kit → tokens, strength, batch, expiry
 ├─ Shade module: color signature of pack region             ← Section 7.5
 ├─ Matching + Confidence Gate (pure Dart, unit-tested)      ← Section 8
 ├─ Interaction engine (local rules JSON)                    ← Section 10
 ├─ Reminder + dose-log engine + notifications              ← Section 11
 ├─ TTS + localization (en/hi/mr)
 ├─ Caregiver escalation (simulated)
 └─ Local SQLite + bundled assets (catalog, rules)
            │  optional (P1)
            ▼
FastAPI backend: /health /medicines /verify /interactions/check /reminders /caregiver/escalate
   └─ same catalog + rules JSON; same gate logic; parity proven via shared test vectors
```

**Primary path is on-device.** The backend is optional; if unreachable, the app silently uses the local engine and shows nothing alarming. Never make the safety decision depend on network availability.

### 5.1 Repository layout (required)
```
MediSathi/
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/            (router, theme, providers)
│   │   ├── core/           (constants, config, utils, l10n)
│   │   ├── features/
│   │   │   ├── splash/ home/ scan/ verification/ medicine_details/
│   │   │   ├── interactions/ reminders/ my_medicines/ caregiver/
│   │   │   ├── voice/ settings/
│   │   ├── engine/
│   │   │   ├── quality/        (blur, glare, brightness, stability)
│   │   │   ├── ocr/            (ml kit wrapper, parsers)
│   │   │   ├── shade/          (color signature + compare)
│   │   │   ├── matching/       (normalize, fuzzy match, candidates)
│   │   │   ├── gate/           (confidence_gate.dart, config)
│   │   │   └── interactions/
│   │   ├── data/           (models, repositories, sqlite, seed loader)
│   │   └── l10n/           (app_en.arb, app_hi.arb, app_mr.arb)
│   ├── assets/
│   │   ├── data/           (medicines.json, interaction_rules.json, gate_config.json)
│   │   └── demo/           (sample strip images for Demo Mode)
│   ├── test/
│   ├── android/
│   └── pubspec.yaml
├── backend/
│   ├── app/ (main.py, routers/, engine/, models/, db.py)
│   ├── tests/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
├── data/
│   ├── medicines.json
│   ├── interaction_rules.json
│   ├── gate_config.json
│   ├── test_vectors/verify_cases.json     (shared by Dart + Python tests)
│   └── README.md                          (provenance, limitations)
├── tools/
│   ├── make_synthetic_strips.py           (generates labelled synthetic test images)
│   └── eval_false_confirmation.py         (false-confirmation-rate harness)
├── docs/
│   ├── architecture.md  safety.md  demo-script.md  decisions.md
│   ├── ppt-update.md    testing.md
├── screenshots/
├── .github/workflows/ci.yml
├── .gitignore  .env.example  README.md  LICENSE (MIT)
```
`assets/data/*` in `mobile/` should be copied from (or symlinked/synced by a script from) `/data` so there is one canonical dataset. Provide `tools/sync_data.sh`.

---

## 6. Screens (15) — Required UI Specification

The team's mockup defines the visual style: rounded cards, soft gradient backgrounds, blue primary (#1E6FE8-ish), green = success, amber = caution, red = danger, bottom nav with Home / My Medicines / Reminders / More. Reproduce this look using a central `ThemeData` (`app/theme.dart`). Colors must always be paired with an icon and text (never color alone).

### 6.0 Mandatory deviations from the mockup (safety wording)
| Mockup text | Use instead | Reason |
|---|---|---|
| "Medicine Identified!" + "Confidence 92%" | **"Medicine Verified"** + "Match strength: High" with signal checklist. Optionally show the number as small "Prototype score 0.92" | Gate passing = verified; score is not a probability |
| "No major interactions found with your current medicines" | **"No stored interaction rule matched your current medicines. This is not a guarantee of safety. Ask your doctor or pharmacist."** | Never imply safe |
| Interaction example "Paracetamol 500 + Amlodipine 5 → low blood pressure" | Use only rules in `interaction_rules.json` (Section 10). Do **not** ship that example | Not a curated/sourced rule |
| Batch / expiry shown as identity info | Show as **supporting evidence**; expired → red "Expired — do not use, ask pharmacist" | Batch alone never confirms identity |
| Caregiver alert implies real delivery | Label "Prototype: simulated alert — nothing was sent" | Out-of-scope infra |

### 6.1 Splash
Logo (heart+cross), "MediSathi", tagline "Right Medicine. Safe You.", elderly-couple illustration (use a simple vector/placeholder asset), footer "Your AI companion for safe and correct medicine usage." Load DB, seed data, TTS init, notification channel, timezone. ≤ 2 s, then go Home (or first-run language picker: English / हिंदी / मराठी, stored in prefs).

### 6.2 Home
Greeting "Namaste! How can we help you today?" (localized). Four large tiles: **Scan Medicine**, **My Medicines**, **Reminders**, **Caregiver**. Below: **"Today's doses"** card (next due dose, count taken/missed) and a small safety status line (e.g., "All scans this week verified" / "1 scan needs review"). A floating/inline **🔊 Read aloud** button and a **🎤 Voice** button (P1). Bottom nav.

### 6.3 Scan Medicine
Full-screen camera preview with green corner guide frame. Text: "Place the medicine strip or bottle within the frame. Keep it steady." (TTS on entry: `scan_hold_steady`). Large round capture button. Secondary: gallery picker ("Use a photo instead"), flash toggle, close (X). Live **steadiness indicator** (green ring when gyro below threshold). Tapping capture starts the guided burst (auto-captures when steady; see 7.2). Camera-permission denied → friendly full-screen explanation + "Open Settings" + gallery fallback (never crash).

### 6.4 Processing / Multi-frame Capture
"Scanning Medicine… Capturing multiple frames for better accuracy. Please hold steady." Show 3 thumbnails, each with ✓ (usable) or ⚠ (rejected: blurry/glare/dark, with reason), a progress bar "Processing images… 2/3". Then run OCR + shade + matching + gate. If no usable frame → go to 6.11 (RESCAN) with reason "Too shaky — hold steadier" (this is the **demoable shaky-hand safeguard**).

### 6.5 Verification Result — VERIFIED
Only when the Confidence Gate returns VERIFIED. Green check, **"Medicine Verified"**, card: medicine image/icon, name + strength, dosage form, detected batch & expiry (if read), and a **signals checklist** (✓ Name read from label, ✓ Strength matches, ✓ Shade matches pack, ✓ Sharp scan). Buttons: **View Details** (primary), **Scan Another**. TTS: `medicine_verified` + name + strength. Small disclaimer.

### 6.6 Verification Result — REVIEW / FAIL ("Don't Guess")  *(mockup screen 11)*
Amber/orange screen: warning icon, **"Unable to verify this medicine"**, plain reason(s) from the gate (e.g., "Strength on the strip does not match", "Image too blurry", "Two similar medicines — cannot tell which"). Blurred thumbnail. Buttons: **Rescan** (primary), **Ask Caregiver**. **Never show a "best guess" name as if it were the answer.** If a candidate is shown at all it must be labeled "Possible match — NOT verified" and only in the REVIEW state, with the Add button disabled. TTS: `medicine_uncertain` + `rescan_or_caregiver`. Increment consecutive-failure counter; at 2 failures show 6.14 escalation prompt automatically.

### 6.7 Medicine Details
Header: image/icon, name, strength, form. Rows: **Use for** (from catalog `instruction_text` — factual category e.g., "Blood pressure"), **Usual instruction** (**user-entered field** — placeholder "Enter as prescribed by your doctor"; never invent a prescription), **When** (Before / After food dropdown). **Interaction check card** (see 6.8 states). Buttons: **Add to My Medicines**, **Set Reminder**. Show batch/expiry evidence and the disclaimer.

### 6.8 Interaction Check states
- **Match found:** red/amber screen "Potential interaction detected", the two medicine names, plain-language text from the rule, **"Please consult your doctor or pharmacist before taking these medicines together."**, buttons **Got it** and **View details**. Log `rule_id` + source in dev logs and on the details view ("Rule INT-002 · reviewed 2026-09-xx").
- **No match:** neutral (not green) card with the wording from 6.0. Include a rule-set version.
- TTS: `interaction_warning` + `consult_professional`. Repeated visibly on My Medicines when two saved medicines have a rule.

### 6.9 Set Reminder
Fields: medicine (prefilled), **dose text** (e.g., "1 tablet"), **date**, **time picker**, **repeat** (Once / Daily / Custom weekdays), optional "with food" note. Buttons **Save Reminder**, **Cancel**. Validate; schedule exact local notification; if permission missing → request with an explanation.

### 6.10 Reminder Confirmation
"Reminder Set!" card: medicine, dose, next time, repeat. Buttons **View My Reminders**, **Done**. TTS `reminder_saved`.

### 6.11 My Medicines
List of verified saved medicines: name + strength, dose, next time, chevron → details. **+ Add Medicine** (goes to Scan; manual add is allowed only from the catalog with a "Not verified by scan" tag). Swipe/menu: edit, remove (confirm dialog). Never silently alter a dose. Show an interaction badge if any two saved medicines match a rule.

### 6.12 Reminders List
Tabs **Upcoming / Completed**. Each row: medicine, dose, time, "Today/Tomorrow", a large **"Taken"** check button. Tapping Taken writes a dose log entry. Overdue items (past due > grace period, default 30 min) turn amber "Missed?" and trigger the missed-dose flow (Section 11).

### 6.13 Voice Guidance (P1 for input; output is P0)
"Listening… Speak to get instructions in your preferred language." Language chips **English / हिंदी / मराठी**, Cancel. Supported commands (keyword based, per language): scan medicine, my medicines, reminders, read result. Unrecognized → say "Sorry, I did not understand" and offer buttons. Output-only TTS "Read aloud" buttons exist on all result screens regardless of P1 status.

### 6.14 Caregiver Alert / Escalation (simulated)
Triggers: **(a)** 2 consecutive failed/low-confidence scans, **(b)** missed dose beyond grace period, **(c)** user taps "Ask Caregiver". Shows a red card "Low Confidence Scan Alert / Missed Dose Alert" with blurred thumbnail (only if the user consented to include a photo; default OFF), time, medicine (if known) and **"Prototype: simulated alert — nothing was sent"**. Includes **consent language** ("Share this alert with Rahul? You can turn this off in Settings"). Stores a `caregiver_events` row. Optional P1: "Share via…" opens Android share sheet with prefilled plain text (contact entered at runtime, never committed). Caregiver profile (name/relationship/phone) is user-entered; seed with the fictional "Rahul (Son)".

### 6.15 Settings / Profile
Patient Profile (name, age — fictional defaults), **Language** (English/हिंदी/मराठी), **Voice preferences** (on/off, speed), **Notifications** toggle, **Caregiver** settings (name, consent toggles: share alerts, include photo), **Demo Mode** toggle, **About MediSathi** (version, disclaimer, dataset provenance, "not a medical device"), **Help & Support**. Text-size setting (Normal / Large / Extra Large).

### 6.16 Navigation map
Splash → Home ↔ {Scan → Processing → (Verified | Review/Fail) → Details → (Interaction) → Reminder → Confirmation}, Home → My Medicines / Reminders / Caregiver, More → Settings. Bottom nav persistent on Home/My Medicines/Reminders/More.

---

## 7. Image Quality, Shaky-Hand Robustness and Look-alike Signals (core technical story)

### 7.1 Overview
Goal: reject bad captures loudly, prefer sharp frames, and never let a weak frame decide identity. Implement in `mobile/lib/engine/quality/` and run in a background isolate.

### 7.2 Motion-gated burst capture
1. On the Scan screen subscribe to gyroscope (`sensors_plus`); compute angular speed magnitude with a short moving average.
2. When steady (`gyro_mag < motion_threshold` for ≥ 250 ms) allow capture; show green ring. If the user presses capture while shaking, wait up to 2 s for a steady window and show "Hold steady…".
3. Capture a **burst of up to N=5 frames** at ~250–400 ms spacing (configurable; minimum 3 frames attempted). Store each frame's gyro magnitude at capture time.
4. Keep all frames in memory/app cache only; delete after processing (privacy).

### 7.3 Per-frame quality metrics (all configurable in `gate_config.json`)
| Metric | Method | Default threshold |
|---|---|---|
| Sharpness | Variance of Laplacian on grayscale, downscaled to ~800 px on the long edge | reject < `blur_min` (tune on real images; start ~100) |
| Glare | Fraction of near-saturated pixels (V > 0.97 and S < 0.15) | reject > 6 % |
| Brightness | Mean luminance | reject < 40 or > 230 (0–255) |
| Motion at capture | Gyro magnitude | reject > `motion_reject` |
| Framing | OCR found ≥ 1 text block inside the guide area | warn if none |

`frame_quality = weighted(sharpness_norm, glare_ok, brightness_ok, steady_ok)` in 0–1. **Best frame** = highest quality among usable frames. If **no frame** passes → decision `RESCAN` with reason `TOO_SHAKY` / `TOO_DARK` / `GLARE`.

### 7.4 Multi-frame OCR agreement (shaky-hand safeguard)
Run OCR on up to the 3 best usable frames. For each frame extract candidate tokens: medicine name, strength (`\d+(\.\d+)?\s?(mg|mcg|g|ml)`), batch (see 7.6), expiry. **Vote across frames:** a value is "stable" if it appears in ≥ 2 usable frames (normalized). `agreement = stable_tokens / total_key_tokens`. Conflicting strengths across frames → immediate FAIL (see 8.3). This turns a shaky hand from a hazard into noise the gate can detect.

### 7.5 Shade (color) signature — addresses "subtly different shade"
1. From the best frame, take the pack/foil region (largest low-text-density area inside the guide frame; if unreliable use the guide-frame center 60 %).
2. **Normalize lighting** with a gray-world white balance, then convert to HSV/Lab.
3. Compute a compact signature: dominant hue/saturation/value (k-means k=3 or histogram peaks) and mean Lab of the dominant cluster.
4. Compare to the catalog `color_signature` (`hue`, `sat`, `val`, tolerances) with a distance `ΔE`-like metric → `shade_score` 0–1.
5. **Rules:** shade is a *supporting* signal only. It can raise or lower confidence and **discriminate between look-alike variants** (e.g., 5 mg vs 10 mg with a slightly different printed tint) — but it can never confirm identity alone. Document that shade is sensitive to lighting and that the app asks for good, even light.
6. The team must fill real `color_signature` values from their own strip photos (helper script `tools/measure_color_signature.py` prints signature from a photo). Until then use clearly-marked placeholder values flagged `"calibrated": false` and the gate treats uncalibrated shade as **neutral (0 score contribution, never a penalty, never a confirmation)**.

### 7.6 Batch code and expiry — used as a differentiator, never as identity
- Regex extract batch (`B\.?\s?No\.?|Batch|Lot` followed by alphanumerics) and expiry (`EXP|Exp\.?|Expiry` + `MM/YYYY`, `MM-YY`, `MMM YYYY`) from OCR text.
- Catalog may hold `known_batch_prefixes` per medicine variant (e.g., variant markers such as a printed suffix or code prefix). If a look-alike group member's discriminator (strength / printed variant marker / batch prefix) is read and **matches exactly one** member → tie broken with a bonus. If not read → tie stays unresolved → REVIEW.
- Expiry < today → show "Expired" state; verification of identity may still pass, but the details screen shows a red expired banner and the reminder flow warns.
- **A batch number alone can never produce VERIFIED** (hard rule).

### 7.7 Look-alike groups
Catalog field `lookalike_group_id` (e.g., `LA-AMLO`, `LA-ATOR`, `LA-PARA`, `LA-METF`) and `discriminators` (list of which fields separate members: `strength`, `batch_prefix`, `shade`). If the top candidate belongs to a group and the **required discriminator was not positively read** (e.g., strength not visible) → REVIEW even if OCR name matched strongly. This directly implements "look-alike strips differ only in subtle detail".

---

## 8. Matching and the Confidence Gate (defining safety feature)

Pure Dart in `engine/gate/`, no Flutter imports, 100 % unit-testable. Mirror in Python for the backend. Config in `data/gate_config.json` (weights, thresholds) so they can be tuned without code changes.

### 8.1 Text normalization
Lowercase; strip punctuation; collapse whitespace; map common OCR confusions (`0/o`, `1/l/i`, `5/s` **only within alphabetic name tokens, never within strength digits**); remove tablet-boilerplate words (`tablets`, `ip`, `bp`, `film coated`, ...). Fuzzy name match via normalized Levenshtein / token-set ratio against `canonical_name`, `brand_name`, `aliases[]`, `ocr_keywords[]`.

### 8.2 Scoring (deterministic; default weights in config)
| Signal | Weight | Definition |
|---|---|---|
| Name match | 0.35 | best fuzzy match ratio vs catalog, gated by min token overlap |
| Strength match | 0.20 | exact strength equal to candidate's → full; not visible → 0; conflict → hard FAIL |
| Visual/package match | 0.20 | combination of shade_score (if calibrated), manufacturer/keyword tokens present, dosage-form cue |
| Variant/batch discriminator | 0.10 | positive discriminator read and consistent with candidate |
| Quality & frame agreement | 0.15 | best `frame_quality` (0.5) + multi-frame `agreement` (0.5) |

`score = Σ weight × signal` ∈ [0,1]. **Thresholds (configurable):** `≥ 0.80` HIGH (eligible), `0.60–0.79` REVIEW, `< 0.60` LOW.

### 8.3 Hard safety rules (evaluated BEFORE scoring; any hit overrides the score)
1. No candidate above the minimum name match → **NO_CANDIDATE** ("Don't guess").
2. Strength read ≠ candidate strength, or strengths conflict across frames → **FAIL** (`STRENGTH_CONFLICT`).
3. OCR candidate ≠ visual/shade candidate materially (when shade is calibrated and strongly points elsewhere) → **FAIL** (`SIGNAL_CONFLICT`).
4. Best frame quality below minimum, or no usable frame → **RESCAN** (`LOW_QUALITY`).
5. Top-2 candidates within `ambiguity_margin` (default 0.08) → **REVIEW** (`AMBIGUOUS`).
6. Candidate is in a look-alike group and the required discriminator was not positively read → **REVIEW** (`DISCRIMINATOR_MISSING`).
7. Batch/lot alone, or only one signal present → **never** VERIFIED.
8. VERIFIED requires: ≥ 2 independent signal families positively agreeing (text + one of strength/visual/discriminator) **and** score ≥ HIGH threshold **and** no hard rule hit.

### 8.4 Output contract
```json
{
  "decision": "VERIFIED | REVIEW | FAIL | RESCAN | NO_CANDIDATE",
  "score": 0.91,
  "candidate": { "medicine_id": "MED-003", "name": "Amlodipine", "strength": "5 mg" } ,
  "signals": { "name": 0.98, "strength": 1.0, "visual": 0.7, "discriminator": 1.0, "quality": 0.86 },
  "reasons": ["STRENGTH_MATCH", "NAME_MATCH"],
  "next_action": "SHOW_DETAILS | RESCAN | ASK_CAREGIVER | RESCAN_OR_CAREGIVER"
}
```
`candidate` is `null` unless decision is `VERIFIED` (in `REVIEW` it may include `possible_candidate`, which the UI labels "NOT verified"). The UI layer **must not** be able to render VERIFIED without `decision == VERIFIED` (enforce with a sealed class / enum and a widget test that tries to bypass it).

### 8.5 Logging
Write `verification_logs` (timestamp, decision, score, reasons, quality metrics, candidate id) — **no images stored**. This powers the false-confirmation evaluation.

---

## 9. Data

### 9.1 Provenance rules
Only legitimate, self-created data: the team photographs their own strips; drug facts come from reputable public drug information (document the source name and date in `source_reference`). No scraping of copyrighted/private sources. `data/README.md` must state provenance, limitations and that the dataset is a **prototype demo catalog, not comprehensive**.

### 9.2 `medicines.json` schema
```
medicine_id, canonical_name, brand_name, aliases[], strength, dosage_form,
manufacturer, ocr_keywords[], lookalike_group_id, discriminators[],
color_signature{hue,sat,val,tol,calibrated}, known_batch_prefixes[],
category_use_text, instruction_text (generic, non-prescriptive),
sample_image_paths[], interaction_rule_ids[], source_reference, updated_at
```

### 9.3 Seed catalog (start with these 14; team fills brand/manufacturer/shade from their real strips; the agent must create the entries with `TODO_TEAM` markers rather than invent brand facts)
| ID | Generic | Strength | Look-alike group | Note |
|---|---|---|---|---|
| MED-001 | Paracetamol | 500 mg | LA-PARA | fever/pain |
| MED-002 | Paracetamol | 650 mg | LA-PARA | look-alike of 001 |
| MED-003 | Amlodipine | 5 mg | LA-AMLO | blood pressure — **patient's** |
| MED-004 | Amlodipine | 10 mg | LA-AMLO | look-alike of 003 |
| MED-005 | Metformin | 500 mg | LA-METF | diabetes — **patient's** |
| MED-006 | Metformin | 850 mg | LA-METF | look-alike of 005 |
| MED-007 | Atorvastatin | 10 mg | LA-ATOR | cholesterol — **patient's** |
| MED-008 | Atorvastatin | 20 mg | LA-ATOR | look-alike of 007 |
| MED-009 | Telmisartan | 40 mg | — | blood pressure — **patient's** |
| MED-010 | Aspirin (low-dose) | 75 mg | — | blood thinner — **patient's** |
| MED-011 | Pantoprazole | 40 mg | — | acidity — **patient's** |
| MED-012 | Ibuprofen | 400 mg | — | pain (used to demo interaction) |
| MED-013 | Simvastatin | 20 mg | — | cholesterol (used to demo interaction) |
| MED-014 | Cetirizine | 10 mg | — | allergy (filler) |

**Demo patient's six medicines:** MED-003, 005, 007, 009, 010, 011.

### 9.4 Synthetic test images
`tools/make_synthetic_strips.py` (Pillow) generates labelled **synthetic** strip-like images from the catalog (foil background tint + printed name/strength/batch/expiry text) plus degradations: Gaussian/motion blur, glare blobs, rotation/perspective, low light, color shift. Clearly label synthetic images as such in docs — they are for automated tests only, **not evidence of real-world accuracy**. Real-strip photos supplied by the team live in `mobile/assets/demo/real/` (team adds later; the agent creates the folder with a README explaining naming: `MED-003_clear_01.jpg`, `MED-003_shaky_01.jpg`, etc.).

---

## 10. Interaction Rules

### 10.1 Rules
Deterministic lookup: for a candidate medicine, check every saved medicine pair against `interaction_rules.json`. **No LLM, no invented rules.** Every warning shown must map to a stored `rule_id` with source and review date. Use *class-level* keys so brands/strengths map correctly (e.g., `NSAID`, `statin`).

### 10.2 Schema
```json
{ "rule_id": "INT-001", "a": "aspirin", "b": "ibuprofen", "severity": "review",
  "plain_language": {"en": "...", "hi": "...", "mr": "..."},
  "consult": true, "source": "<name of source>", "reviewed_at": "YYYY-MM-DD",
  "status": "candidate_needs_team_verification | verified" }
```

### 10.3 Starter rules to seed (well-known pairs; **the team (Nityam) must verify each against a reputable drug-information source and set `reviewed_at`/`status: verified` before the video; until then the app labels them "Prototype rule")**
| Rule | Pair | Plain-language gist (keep non-prescriptive) |
|---|---|---|
| INT-001 | Aspirin (low-dose) + Ibuprofen | Ibuprofen may reduce the protective effect of low-dose aspirin and increases stomach bleeding risk. Ask your doctor/pharmacist. |
| INT-002 | Amlodipine + Simvastatin | This combination can raise simvastatin levels and muscle-side-effect risk; simvastatin dose limits may apply. Ask your doctor/pharmacist. |
| INT-003 | Telmisartan + Ibuprofen (NSAIDs) | NSAIDs can weaken the blood-pressure medicine and may affect kidneys. Ask your doctor/pharmacist. |

Agent: seed INT-001..003 exactly as above with `status: candidate_needs_team_verification`, and add the disclaimer in the UI. Provide hi/mr translations marked `"reviewed": false`. Do **not** add further rules from memory.

**Demo interaction triggers:** scanning **Ibuprofen 400** while Aspirin 75 / Telmisartan 40 are saved → warning; scanning **Simvastatin 20** while Amlodipine 5 is saved → warning.

---

## 11. Reminders, Dose Log and Missed-Dose Flow

- Table `reminders(id, user_medicine_id, dose_text, time_of_day, days_of_week, enabled)`; `dose_log(id, reminder_id, scheduled_at, status TAKEN|MISSED|SKIPPED, acted_at)`.
- Notifications: channel "Medicine reminders", high importance, sound + vibration; full-screen text "Time for Amlodipine 5 mg — 1 tablet"; actions **Taken** / **Snooze 10 min**. Reschedule on app start and after device reboot. Request notification and exact-alarm permissions with plain explanations. Android 13+ `POST_NOTIFICATIONS`.
- Voice: when a reminder fires while the app is open, speak it via TTS in the selected language.
- **Missed dose:** if not marked Taken within `grace_minutes` (default 30) → mark MISSED, show amber on Home, trigger caregiver escalation (simulated) with the medicine name and time. **Never** suggest doubling a dose or taking a late dose; text is only "You missed your dose. Please contact your doctor or pharmacist if unsure."
- Adherence summary (P1): taken/missed counts for the last 7 days on Home.

---

## 12. Demo Mode (critical for a reliable video)
Settings → **Demo Mode** toggle. When ON:
- Scan screen shows a "Demo" chip and a sheet of bundled sample images (clear MED-003, clear MED-012, shaky MED-003, blurred MED-007, strength-conflict, unknown strip) — using **real team photos if present, else synthetic images**, labelled honestly.
- A "Simulate shaky hand" switch blurs/motion-shakes the live frame stream so the rejection behavior is visible on camera.
- Pre-loads the demo patient's six medicines and reminders; "Reset demo data" button.
- Live scanning with the real camera must **also** work with Demo Mode OFF. Demo Mode is a convenience, and the README must state when the sample images are used.

---

## 13. Voice & Vernacular

- All strings via ARB (`app_en.arb`, `app_hi.arb`, `app_mr.arb`) — no hardcoded text. Provide **full** en; provide hi and mr for the keys below (P1: complete for all screens); mark machine-translated strings with a `// needs native review` note in `docs/localization.md`.
- Required keys: `scan_hold_steady`, `scan_analyzing`, `too_shaky_rescan`, `medicine_verified`, `medicine_uncertain`, `rescan_or_caregiver`, `strength_conflict`, `interaction_warning`, `no_rule_matched_not_guarantee`, `consult_professional`, `reminder_saved`, `reminder_due`, `missed_dose`, `caregiver_alert_simulated`, `disclaimer_short`.
- TTS: `flutter_tts` with `en-IN`/`hi-IN`/`mr-IN`; sentences ≤ 12 words; if the language voice isn't installed, show a small hint and fall back to English **text still shown in the chosen language**.
- Devanagari font must render correctly (Noto Sans Devanagari bundled or system).

---

## 14. Backend API (P1) — FastAPI

```
GET  /health
GET  /medicines            GET /medicines/{id}
POST /verify               → same output contract as 8.4
POST /interactions/check   body: {candidate_id, saved_ids[]}
POST /reminders            GET /reminders
POST /caregiver/escalate   (simulated; logs event, returns 202)
```
`POST /verify` request: `{ "ocr_text": "...", "ocr_confidence": 0.92, "frame_quality": 0.88, "agreement": 0.9, "shade_score": 0.7, "strength_text": "5 mg", "batch_text": "...", "frames": 3 }`. Implementation must import the **same thresholds from `data/gate_config.json`** and pass **the shared test vectors** (`data/test_vectors/verify_cases.json`). CORS limited; secrets via env; `.env.example` provided; temp files deleted; HTTPS for any non-local deploy (document only). Dockerfile + `docker-compose.yml` (api + optional postgres). SQLite default so `uvicorn app.main:app` runs with zero setup.

Database (SQLAlchemy models): `medicines`, `interaction_rules`, `users` (anonymous local), `user_medicines`, `reminders`, `dose_log`, `verification_logs`, `caregiver_events`.

---

## 15. Privacy & Security
- Fictional data only; never commit real names, phone numbers, keys, tokens, or camera images of people/prescriptions.
- Process images on device; do not upload by default; delete frames after processing; store no images in DB.
- Caregiver photo-sharing OFF by default; consent text before any sharing.
- Secrets only via env vars; `.env` git-ignored; commit `.env.example`.
- Android permissions requested only when needed, with plain-language rationale. Release notes state "debug build, prototype".

---

## 16. GitHub Repository, Commits and Release

### 16.1 Preflight (do this first and report results)
Check availability: `flutter doctor -v`, `flutter --version`, `dart --version`, Android SDK (`adb version`), `java -version`, `python3 --version`, `git --version`, `gh --version`, `gh auth status`. Install/repair what is possible. **If `gh` is not authenticated:** stop before creating a remote, keep working locally with commits, and tell the user exactly: run `gh auth login` (GitHub.com → HTTPS/SSH → browser) and then say "continue". **Never** embed tokens in code, commands saved to files, or the remote URL.

### 16.2 Repository
Name: `medisathi-mvp` (public unless the user says private). `gh repo create medisathi-mvp --public --source=. --remote=origin` after local init. Default branch `main`. Work on `main` with small commits (or short-lived feature branches merged fast).

### 16.3 Commit plan (conventional commits; one commit per completed, building increment)
1. `chore: scaffold repo (mobile, backend, data, docs) with README, LICENSE, .gitignore, .env.example`
2. `feat(mobile): app shell, theme, localization, navigation, splash and home`
3. `feat(data): curated prototype catalog, interaction rules, gate config, provenance README`
4. `feat(scan): camera, motion-gated burst capture, gallery fallback`
5. `feat(quality): blur, glare, brightness metrics and frame selection with tests`
6. `feat(ocr): ML Kit OCR, strength/batch/expiry parsers, multi-frame voting with tests`
7. `feat(shade): color signature extraction and comparison with tests`
8. `feat(gate): deterministic confidence gate, hard safety rules, look-alike logic, test vectors`
9. `feat(ui): verification, don't-guess, details and interaction screens`
10. `feat(reminders): reminders, notifications, dose log, missed-dose flow`
11. `feat(voice): TTS and en/hi/mr strings (+ voice input if P1)`
12. `feat(caregiver): simulated escalation flow with consent`
13. `feat(demo): demo mode, sample images, synthetic image generator`
14. `feat(backend): FastAPI verify/interactions/reminders with shared test-vector parity`
15. `test: false-confirmation evaluation harness, widget tests, CI workflow`
16. `docs: README, architecture, safety, demo script, PPT update notes, screenshots`
17. `chore: prepare CODEX 2026 round 2 MVP demo` (final; tag `v0.1.0-round2`)

Every commit must leave `flutter analyze` clean and `flutter test` passing. After pushing: `gh release create v0.1.0-round2 mobile/build/app/outputs/flutter-apk/app-debug.apk --title "MediSathi Round 2 MVP (debug APK)" --notes "Prototype — not a medical device."` (only if authenticated; else give exact blocker). Commit `.gitignore` before any build output. Add screenshots (taken from the emulator/real flows — not mockups) into `screenshots/`.

---

## 17. Testing Requirements

### 17.1 Unit tests for the gate (must pass; shared vectors in `data/test_vectors/verify_cases.json`)
| Case | Expected |
|---|---|
| Clear Amlodipine 5 mg, sharp, name+strength+shade agree | VERIFIED |
| Clear label, name matches, strength missing, candidate in look-alike group | REVIEW (`DISCRIMINATOR_MISSING`) |
| Name = Amlodipine, strength read = 10 mg vs saved candidate 5 mg | FAIL/strength conflict → never VERIFIED as 5 mg |
| Strength differs across frames (5 vs 10) | FAIL (`STRENGTH_CONFLICT`) |
| Very blurry all frames | RESCAN |
| Unknown medicine name | NO_CANDIDATE |
| Only batch number readable | never VERIFIED |
| Two candidates within ambiguity margin | REVIEW (`AMBIGUOUS`) |
| Shade calibrated and points to a different medicine | FAIL (`SIGNAL_CONFLICT`) |
| Uncalibrated shade | contributes 0, does not confirm |
| Score exactly 0.80 vs 0.79 boundary | VERIFIED vs REVIEW (only if no hard rule) |
| Config threshold change alters decision predictably | pass |
Both Dart and Python suites must load the **same JSON** and assert the same outputs.

### 17.2 Other tests
Quality metrics on synthetic sharp vs blurred images (sharp > blurred); parsers (strength/batch/expiry) with messy OCR strings; interaction engine (rule triggers only for stored rules; symmetric pair lookup); reminder scheduling logic (next occurrence, snooze, missed after grace); widget test that VERIFIED UI cannot render unless decision == VERIFIED; permission-denied camera path; offline run.

### 17.3 False-confirmation evaluation (deck promise: "Test false-confirmation rate")
`tools/eval_false_confirmation.py` (or Dart test) runs the engine over: (a) synthetic images of every catalog medicine under degradations, and (b) **negatives**: wrong strength variant, unknown medicines, blurred/glare-only images. Report: false-confirmation rate (**target 0 on negatives**), false-rejection rate, decisions histogram. Save to `docs/testing.md` with the honest statement that synthetic results ≠ real-world accuracy. Update the numbers with real-strip photos when the team adds them.

### 17.4 Manual device checklist (record results in `docs/testing.md`)
Camera opens; permission denied handled; gallery fallback; clear label → Verified; deliberately shaking → rescan; wrong/unknown label → not confirmed; strength conflict → blocked; add to My Medicines; interaction fires only for stored rules; reminder fires and can be marked Taken; missed dose → caregiver simulated alert; TTS reads key states; Hindi/Marathi strings display; airplane mode full flow; no secrets in Git history (`git log -p | grep -i -E "token|secret|password"`).

---

## 18. Documentation Deliverables
- **README.md:** overview + CX0305 context; features split into *Implemented* vs *Future scope*; architecture diagram; stack; local setup (mobile + backend); Android build/install (`flutter build apk --debug`); dataset provenance & limitations; confidence-gate explanation; the shaky-hand & look-alike approach; demo flow; false-confirmation results; known limitations (shade lighting sensitivity, small catalog, prototype rules, machine-translated strings); team & roles; screenshots; license.
- **docs/architecture.md, safety.md** (hard rules, disclaimers, what the app will never do), **demo-script.md**, **decisions.md**, **testing.md**, **ppt-update.md**, **localization.md**.

### 18.1 3-minute demo script (`docs/demo-script.md` must expand this)
1. (0:00) Home — "Mrs. Patil takes six medicines and confuses look-alike strips." Show Today's doses.
2. (0:20) Scan → hold steady indicator → 3 frames processed → **Medicine Verified** (Amlodipine 5 mg) with signals; TTS speaks it.
3. (0:50) Details → interaction check: scan **Ibuprofen 400** → plain-language warning from stored rule → "Consult doctor/pharmacist".
4. (1:15) Set reminder → confirmation → appears on Home/Reminders.
5. (1:35) **Shaky-hand test:** deliberately shake the phone → frames rejected → "Too shaky — hold steadier".
6. (1:55) **Look-alike test:** scan Amlodipine strip where strength/variant is unclear → **"Don't Guess — Rescan or Ask Caregiver"**.
7. (2:15) Two failures → simulated caregiver alert with consent language; missed-dose alert.
8. (2:35) Switch language to Marathi/Hindi; voice read-out.
9. (2:50) Close: **"MediSathi does not guess when it is not sure."** Show GitHub repo + tests.

---

## 19. Agent Operating Instructions & Definition of Done

**Working method**
1. Run preflight (16.1); report tool status to the user in a short summary.
2. Build in the order of the commit plan. After each major step: `flutter analyze`, `flutter test`, and (when the emulator/device is available) `flutter build apk --debug`. Fix failures before moving on. Commit.
3. Get the P0 happy path running on an emulator/device *early* (by commit 9), then harden.
4. Implement the gate and its tests **before** polishing UI. Keep decisions deterministic.
5. Prefer the simplest reliable option; if a package fights you for > ~30 minutes, replace it or downgrade the feature and record it in `docs/decisions.md`.
6. Never fabricate results: do not claim accuracy numbers, device tests, or features that were not actually run. If something could not be tested (e.g., no physical phone), say so in the README and to the user.
7. Never invent brand names, manufacturers, colors or drug-interaction facts; use `TODO_TEAM` markers and list them in `docs/team-todo.md`.
8. If blocked (auth, missing SDK, no device), report the **exact** blocker and the exact command/action the user must take, then continue with whatever can proceed.

**Definition of Done (all must be true, or explicitly reported as not done)**
- [ ] Clean-checkout build works with documented commands; debug APK produced.
- [ ] All 15 screens exist and are navigable; wording deviations in 6.0 applied.
- [ ] A clear image passes OCR → gate → VERIFIED; an ambiguous/shaky/strength-conflict image reaches the safe-failure state.
- [ ] Multi-frame + motion-gated capture and blur rejection demonstrably work.
- [ ] Look-alike (group + discriminator) logic and shade signal implemented; uncalibrated shade handled neutrally.
- [ ] Gate deterministic, config-driven, covered by shared test vectors (Dart and Python if backend built).
- [ ] Interaction warnings appear only from stored rules; "no rule matched" never says safe.
- [ ] Reminders fire, can be marked Taken; missed dose creates a simulated caregiver alert.
- [ ] TTS works; en complete; hi/mr present for required keys.
- [ ] Demo Mode works offline; full P0 flow works in airplane mode.
- [ ] False-confirmation evaluation run and documented honestly.
- [ ] README, docs, screenshots (real), CI config present; no secrets/images/personal data in Git.
- [ ] Repo pushed to GitHub with the meaningful commit history in 16.3 (or exact auth blocker reported).
- [ ] Final report to the user: what works, what is partial, what needs the team (`team-todo.md`: real strip photos, brand/manufacturer/shade calibration, interaction-rule source verification, native-language review, recording the YouTube demo, updating the PPT).

---

## 20. Team Follow-ups After the Agent Finishes (human tasks)
1. Photograph your own real strips (clear + intentionally shaky) into `mobile/assets/demo/real/`; run `tools/measure_color_signature.py` and fill `color_signature`.
2. Verify the three seeded interaction rules against a reputable source; set `status: verified` and `reviewed_at`.
3. Have a native speaker review Hindi/Marathi strings.
4. Record the demo video following `docs/demo-script.md`, upload to YouTube, submit the link + repo URL + updated PPT (only if changed) via the official group, and pay the ₹400 Round 2 fee as instructed there.

*End of specification — MediSathi MVP Build Spec v2 • Bug Buster's • CX0305 • CODEX 2026*
