import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

class MedicineRepository {
  List<Map<String, dynamic>> _catalog = [];
  List<InteractionRule> _interactionRules = [];
  final List<SavedMedicine> _savedMedicines = [];
  final List<ReminderItem> _reminders = [];
  final List<DoseLog> _doseLogs = [];
  final List<CaregiverEvent> _caregiverEvents = [];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final catalogStr = await rootBundle.loadString('assets/data/medicines.json');
      _catalog = List<Map<String, dynamic>>.from(jsonDecode(catalogStr));

      final rulesStr = await rootBundle.loadString('assets/data/interaction_rules.json');
      final rulesJson = jsonDecode(rulesStr) as List;
      _interactionRules = rulesJson.map((r) => InteractionRule.fromJson(r)).toList();
    } catch (_) {
      // Fallback mock catalog if assets fail in headless environment
      _catalog = [
        {
          "medicine_id": "MED-001",
          "canonical_name": "Paracetamol",
          "brand_name": "Crocin",
          "aliases": ["paracetamol", "acetaminophen"],
          "strength": "500 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Fever and mild to moderate pain relief.",
          "lookalike_group_id": "LA-PARA",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-003",
          "canonical_name": "Amlodipine",
          "brand_name": "Amlokind",
          "aliases": ["amlodipine"],
          "strength": "5 mg",
          "dosage_form": "Tablet",
          "instruction_text": "High blood pressure (hypertension) & angina.",
          "lookalike_group_id": "LA-AMLO",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-005",
          "canonical_name": "Metformin",
          "brand_name": "Glycomet",
          "aliases": ["metformin"],
          "strength": "500 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Type 2 Diabetes management.",
          "lookalike_group_id": "LA-METF",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-007",
          "canonical_name": "Atorvastatin",
          "brand_name": "Atorva",
          "aliases": ["atorvastatin"],
          "strength": "10 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Cholesterol reduction & cardiovascular prevention.",
          "lookalike_group_id": "LA-ATOR",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-009",
          "canonical_name": "Telmisartan",
          "brand_name": "Telma",
          "aliases": ["telmisartan"],
          "strength": "40 mg",
          "dosage_form": "Tablet",
          "instruction_text": "High blood pressure management.",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-010",
          "canonical_name": "Aspirin (low-dose)",
          "brand_name": "Ecosprin",
          "aliases": ["aspirin", "ecosprin"],
          "strength": "75 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Blood thinner to prevent blood clots.",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-011",
          "canonical_name": "Pantoprazole",
          "brand_name": "Pan 40",
          "aliases": ["pantoprazole"],
          "strength": "40 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Acidity, GERD & stomach ulcers.",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-012",
          "canonical_name": "Ibuprofen",
          "brand_name": "Brufen",
          "aliases": ["ibuprofen"],
          "strength": "400 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Pain relief & anti-inflammatory.",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-013",
          "canonical_name": "Simvastatin",
          "brand_name": "Zocor",
          "aliases": ["simvastatin"],
          "strength": "20 mg",
          "dosage_form": "Tablet",
          "instruction_text": "Cholesterol reduction.",
          "color_signature": {"calibrated": false},
        },
      ];
    }

    _loadSeedData();
    _isInitialized = true;
  }

  void _loadSeedData() {
    if (_savedMedicines.isNotEmpty) return;

    // Seed Mrs. Sunanda Patil's 6 daily medicines
    final seeds = [
      {'id': 'MED-003', 'name': 'Amlodipine', 'brand': 'Amlokind', 'str': '5 mg', 'time': '08:00', 'timing': 'After food'},
      {'id': 'MED-005', 'name': 'Metformin', 'brand': 'Glycomet', 'str': '500 mg', 'time': '09:00', 'timing': 'After food'},
      {'id': 'MED-007', 'name': 'Atorvastatin', 'brand': 'Atorva', 'str': '10 mg', 'time': '21:00', 'timing': 'After food'},
      {'id': 'MED-009', 'name': 'Telmisartan', 'brand': 'Telma', 'str': '40 mg', 'time': '08:30', 'timing': 'Before food'},
      {'id': 'MED-010', 'name': 'Aspirin (low-dose)', 'brand': 'Ecosprin', 'str': '75 mg', 'time': '13:00', 'timing': 'After food'},
      {'id': 'MED-011', 'name': 'Pantoprazole', 'brand': 'Pan 40', 'str': '40 mg', 'time': '07:30', 'timing': 'Before food'},
    ];

    for (int i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final savedId = 'SAVED-${i + 1}';
      _savedMedicines.add(SavedMedicine(
        id: savedId,
        medicineId: s['id']!,
        canonicalName: s['name']!,
        brandName: s['brand']!,
        strength: s['str']!,
        dosageForm: 'Tablet',
        usageInstruction: 'As prescribed by doctor',
        timing: s['timing']!,
        addedAt: DateTime.now().toIso8601String(),
      ));

      _reminders.add(ReminderItem(
        id: 'REM-${i + 1}',
        medicineId: s['id']!,
        medicineName: '${s['name']} ${s['str']}',
        doseText: '1 Tablet',
        timeOfDay: s['time']!,
        repeatOption: 'Daily',
        isEnabled: true,
      ));
    }
  }

  List<Map<String, dynamic>> get catalog => _catalog;

  List<SavedMedicine> get savedMedicines => List.unmodifiable(_savedMedicines);

  List<ReminderItem> get reminders => List.unmodifiable(_reminders);

  List<DoseLog> get doseLogs => List.unmodifiable(_doseLogs);

  List<CaregiverEvent> get caregiverEvents => List.unmodifiable(_caregiverEvents);

  void addSavedMedicine(SavedMedicine med) {
    _savedMedicines.removeWhere((m) => m.medicineId == med.medicineId);
    _savedMedicines.add(med);
  }

  void removeSavedMedicine(String id) {
    _savedMedicines.removeWhere((m) => m.id == id || m.medicineId == id);
  }

  void addReminder(ReminderItem reminder) {
    _reminders.removeWhere((r) => r.id == reminder.id);
    _reminders.add(reminder);
  }

  void toggleReminder(String id, bool enabled) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(isEnabled: enabled);
    }
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
  }

  void markDoseStatus(String reminderId, String medicineName, DoseStatus status) {
    _doseLogs.add(DoseLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      reminderId: reminderId,
      medicineName: medicineName,
      scheduledAt: DateTime.now().toIso8601String(),
      status: status,
      actedAt: DateTime.now().toIso8601String(),
    ));

    if (status == DoseStatus.missed) {
      addCaregiverEvent(CaregiverEvent(
        id: 'EVT-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        eventType: 'MISSED_DOSE',
        medicineName: medicineName,
        note: 'Missed scheduled dose beyond 30-minute grace window.',
      ));
    }
  }

  void addCaregiverEvent(CaregiverEvent event) {
    _caregiverEvents.add(event);
  }

  /// Checks if candidate medicine interacts with any currently saved medicines
  List<InteractionRule> checkInteractionsForCandidate(String candidateName) {
    final results = <InteractionRule>[];
    final normCandidate = candidateName.toLowerCase();

    for (final rule in _interactionRules) {
      final drugA = rule.drugA.toLowerCase();
      final drugB = rule.drugB.toLowerCase();

      bool candidateMatchesA = normCandidate.contains(drugA) || drugA.contains(normCandidate);
      bool candidateMatchesB = normCandidate.contains(drugB) || drugB.contains(normCandidate);

      if (candidateMatchesA || candidateMatchesB) {
        final otherDrug = candidateMatchesA ? drugB : drugA;
        
        // Check if other drug is in saved medicines
        final isOtherSaved = _savedMedicines.any(
          (m) => m.canonicalName.toLowerCase().contains(otherDrug) || m.brandName.toLowerCase().contains(otherDrug),
        );

        if (isOtherSaved) {
          results.add(rule);
        }
      }
    }
    return results;
  }

  Map<String, dynamic>? findCatalogEntry(String idOrName) {
    for (final item in _catalog) {
      if (item['medicine_id'] == idOrName) return item;
      if ((item['canonical_name'] as String).toLowerCase() == idOrName.toLowerCase()) return item;
    }
    return null;
  }
}
