import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/csv/csv_parser.dart';
import 'models.dart';

class MedicineRepository extends ChangeNotifier {
  List<Map<String, dynamic>> _catalog = [];
  List<InteractionRule> _interactionRules = [];
  final List<SavedMedicine> _savedMedicines = [];
  final List<ReminderItem> _reminders = [];
  final List<DoseLog> _doseLogs = [];
  final List<CaregiverEvent> _caregiverEvents = [];
  CaregiverContact _caregiverContact = CaregiverContact();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Primary catalog: Load offline CSV file
      final csvStr = await rootBundle.loadString('assets/data/medicines.csv');
      _catalog = CsvParser.parseMedicineCatalogCsv(csvStr);
    } catch (_) {
      try {
        // Fallback: Load JSON catalog if CSV is unavailable
        final catalogStr = await rootBundle.loadString('assets/data/medicines.json');
        _catalog = List<Map<String, dynamic>>.from(jsonDecode(catalogStr));
      } catch (_) {
        _catalog = [];
      }
    }

    try {
      final rulesStr = await rootBundle.loadString('assets/data/interaction_rules.json');
      final rulesJson = jsonDecode(rulesStr) as List;
      _interactionRules = rulesJson.map((r) => InteractionRule.fromJson(r)).toList();
    } catch (_) {}

    if (_catalog.isEmpty) {
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

    await _loadFromPrefs();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // v2 key: forces a clean re-seed on existing installs to clear stale/duplicated reminders.
      final hasInitialized = prefs.getBool('has_initialized_seed_data_v2') ?? false;

      if (!hasInitialized) {
        // Clear any old data from previous app versions.
        await prefs.remove('saved_medicines');
        await prefs.remove('reminders');
        _loadSeedData();
        await prefs.setBool('has_initialized_seed_data_v2', true);
        await _saveToPrefs();
        return;
      }

      final savedMedsJson = prefs.getString('saved_medicines');
      if (savedMedsJson != null) {
        final List list = jsonDecode(savedMedsJson);
        _savedMedicines.clear();
        _savedMedicines.addAll(list.map((m) => SavedMedicine.fromJson(m)));

        for (final med in _savedMedicines) {
          if (findCatalogEntry(med.medicineId) == null && findCatalogEntry(med.canonicalName) == null) {
            _catalog.add({
              "medicine_id": med.medicineId,
              "canonical_name": med.canonicalName,
              "brand_name": med.brandName.isNotEmpty ? med.brandName : 'Generic',
              "aliases": [med.canonicalName.toLowerCase(), med.brandName.toLowerCase()],
              "strength": med.strength,
              "dosage_form": med.dosageForm,
              "instruction_text": med.usageInstruction,
              "color_signature": {"calibrated": false},
            });
          }
        }
      }

      final remindersJson = prefs.getString('reminders');
      if (remindersJson != null) {
        final List list = jsonDecode(remindersJson);
        _reminders.clear();
        _reminders.addAll(list.map((r) => ReminderItem.fromJson(r)));
      }

      final logsJson = prefs.getString('dose_logs');
      if (logsJson != null) {
        final List list = jsonDecode(logsJson);
        _doseLogs.clear();
        _doseLogs.addAll(list.map((l) => DoseLog.fromJson(l)));
      }

      final cgJson = prefs.getString('caregiver_events');
      if (cgJson != null) {
        final List list = jsonDecode(cgJson);
        _caregiverEvents.clear();
        _caregiverEvents.addAll(list.map((e) => CaregiverEvent.fromJson(e)));
      }

      final contactJson = prefs.getString('caregiver_contact');
      if (contactJson != null) {
        _caregiverContact = CaregiverContact.fromJson(jsonDecode(contactJson));
      }
    } catch (_) {
      // Retain current state gracefully
    }
  }


  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medsJson = jsonEncode(_savedMedicines.map((m) => m.toJson()).toList());
      await prefs.setString('saved_medicines', medsJson);

      final remsJson = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await prefs.setString('reminders', remsJson);

      final logsJson = jsonEncode(_doseLogs.map((l) => l.toJson()).toList());
      await prefs.setString('dose_logs', logsJson);

      final cgJson = jsonEncode(_caregiverEvents.map((e) => e.toJson()).toList());
      await prefs.setString('caregiver_events', cgJson);

      final contactJson = jsonEncode(_caregiverContact.toJson());
      await prefs.setString('caregiver_contact', contactJson);
    } catch (_) {}
  }

  void _loadSeedData() {
    if (_savedMedicines.isNotEmpty) return;

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

      // Seed reminder uses standardized 24h HH:mm format.
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

  CaregiverContact get caregiverContact => _caregiverContact;

  void addSavedMedicine(SavedMedicine med) {
    _savedMedicines.removeWhere((m) => m.medicineId == med.medicineId || m.id == med.id);
    _savedMedicines.add(med);
    // NOTE: We do NOT auto-create a reminder here.
    // Reminders are only created when the user explicitly sets one via SetReminderScreen.
    _saveToPrefs();
    notifyListeners();
  }

  String addCustomMedicine({
    required String name,
    required String brand,
    required String strength,
    required String dosageForm,
    required String timing,
    required String usageInstruction,
    String? customId,
  }) {
    final newId = customId ?? 'CUSTOM-${DateTime.now().millisecondsSinceEpoch}';
    final customMed = SavedMedicine(
      id: newId,
      medicineId: newId,
      canonicalName: name,
      brandName: brand.isNotEmpty ? brand : 'Generic',
      strength: strength,
      dosageForm: dosageForm,
      usageInstruction: usageInstruction,
      timing: timing,
      addedAt: DateTime.now().toIso8601String(),
    );
    _savedMedicines.add(customMed);
    // NOTE: No auto-reminder here — prevents the double-reminder bug.
    // The caller (SetReminderScreen) explicitly adds the reminder with the
    // user-selected time after calling this method.

    // Register custom med into catalog so OCR and details screen can resolve it.
    _catalog.add({
      "medicine_id": newId,
      "canonical_name": name,
      "brand_name": brand.isNotEmpty ? brand : 'Generic',
      "aliases": [name.toLowerCase(), brand.toLowerCase()],
      "strength": strength,
      "dosage_form": dosageForm,
      "instruction_text": usageInstruction,
      "color_signature": {"calibrated": false},
    });

    _saveToPrefs();
    notifyListeners();
    return newId;
  }

  void removeSavedMedicine(String id) {
    final target = _savedMedicines.where((m) => m.id == id || m.medicineId == id).firstOrNull;
    _savedMedicines.removeWhere((m) => m.id == id || m.medicineId == id);

    if (target != null) {
      final targetName = target.canonicalName.toLowerCase();
      _reminders.removeWhere((r) =>
        r.medicineId == id ||
        r.medicineId == target.medicineId ||
        r.medicineName.toLowerCase().contains(targetName)
      );
    } else {
      _reminders.removeWhere((r) => r.medicineId == id);
    }

    _saveToPrefs();
    notifyListeners();
  }

  void addReminder(ReminderItem reminder) {
    _reminders.removeWhere((r) => r.id == reminder.id);
    _reminders.add(reminder);
    _saveToPrefs();
    notifyListeners();
  }

  void toggleReminder(String id, bool enabled) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(isEnabled: enabled);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _saveToPrefs();
    notifyListeners();
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
    _saveToPrefs();
    notifyListeners();
  }

  void addCaregiverEvent(CaregiverEvent event) {
    _caregiverEvents.add(event);
    _saveToPrefs();
    notifyListeners();
  }

  void updateCaregiverContact(CaregiverContact contact) {
    _caregiverContact = contact;
    _saveToPrefs();
    notifyListeners();
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

  /// Check interaction between any 2 arbitrary drugs directly
  List<InteractionRule> checkInteractionBetweenTwoDrugs(String drug1, String drug2) {
    final results = <InteractionRule>[];
    final norm1 = drug1.toLowerCase();
    final norm2 = drug2.toLowerCase();

    for (final rule in _interactionRules) {
      final rA = rule.drugA.toLowerCase();
      final rB = rule.drugB.toLowerCase();

      bool pairMatch1 = (norm1.contains(rA) || rA.contains(norm1)) && (norm2.contains(rB) || rB.contains(norm2));
      bool pairMatch2 = (norm1.contains(rB) || rB.contains(norm1)) && (norm2.contains(rA) || rA.contains(norm2));

      if (pairMatch1 || pairMatch2) {
        results.add(rule);
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

