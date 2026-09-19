# MediSathi — Safety Rules & Non-Medical Disclaimer Framework

## 1. Safety Principles & Hard Rules

MediSathi adheres strictly to the core principle:
> **"When MediSathi is not sure, it does not guess."**

### Hard Safety Constraints
1. **Zero False Confirmation:** False rejection is acceptable; false confirmation is NOT.
2. **Deterministic Confidence Gate:** Hard safety rules override scoring. No LLM or probabilistic guess is ever used to confirm a medication identity or drug interaction.
3. **Strength Conflict Override:** If extracted OCR strength does not match candidate strength, or strengths conflict across multi-frame captures, verification fails immediately.
4. **Discriminator Gating:** If a candidate belongs to a `lookalike_group` (e.g. Amlodipine 5mg vs 10mg) and the required discriminator (strength number, batch prefix, or color shade) is not positively read, the gate forces the `REVIEW` ("Don't Guess") state.
5. **Batch Alone Never Confirms:** A batch code read in isolation without a matching brand/generic name cannot produce a `VERIFIED` state.

---

## 2. Mandatory Disclaimers in UI

All major app screens (Verification Result, Details, Interaction Warnings, Reminders, and Settings/About) contain the standard prototype footer:

> *"Prototype for medication identification and adherence support — not a substitute for medical advice."*

### UI Wording Guarantees
- Never show *"Safe to take"*. Recognition ≠ safety. Use **"Medicine Verified"**.
- Never show *"No interactions"*. Use **"No stored interaction rule matched your current medicines. Ask your doctor or pharmacist."**
- Never suggest doubling a dose or skipping doses after a missed reminder.
