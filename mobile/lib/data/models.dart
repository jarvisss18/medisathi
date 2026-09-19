class SavedMedicine {
  final String id;
  final String medicineId;
  final String canonicalName;
  final String brandName;
  final String strength;
  final String dosageForm;
  final String usageInstruction;
  final String timing; // Before food / After food / With food
  final String addedAt;

  SavedMedicine({
    required this.id,
    required this.medicineId,
    required this.canonicalName,
    required this.brandName,
    required this.strength,
    required this.dosageForm,
    required this.usageInstruction,
    required this.timing,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineId': medicineId,
        'canonicalName': canonicalName,
        'brandName': brandName,
        'strength': strength,
        'dosageForm': dosageForm,
        'usageInstruction': usageInstruction,
        'timing': timing,
        'addedAt': addedAt,
      };

  factory SavedMedicine.fromJson(Map<String, dynamic> json) => SavedMedicine(
        id: json['id'],
        medicineId: json['medicineId'],
        canonicalName: json['canonicalName'],
        brandName: json['brandName'],
        strength: json['strength'],
        dosageForm: json['dosageForm'],
        usageInstruction: json['usageInstruction'] ?? 'As prescribed by doctor',
        timing: json['timing'] ?? 'After food',
        addedAt: json['addedAt'] ?? DateTime.now().toIso8601String(),
      );
}

class ReminderItem {
  final String id;
  final String medicineId;
  final String medicineName;
  final String doseText;
  final String timeOfDay; // HH:mm format e.g. "08:00"
  final String repeatOption; // Daily / Once / Custom
  final bool isEnabled;

  ReminderItem({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.doseText,
    required this.timeOfDay,
    this.repeatOption = 'Daily',
    this.isEnabled = true,
  });

  ReminderItem copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? doseText,
    String? timeOfDay,
    String? repeatOption,
    bool? isEnabled,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      doseText: doseText ?? this.doseText,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      repeatOption: repeatOption ?? this.repeatOption,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

enum DoseStatus { taken, missed, skipped }

class DoseLog {
  final String id;
  final String reminderId;
  final String medicineName;
  final String scheduledAt;
  final DoseStatus status;
  final String actedAt;

  DoseLog({
    required this.id,
    required this.reminderId,
    required this.medicineName,
    required this.scheduledAt,
    required this.status,
    required this.actedAt,
  });
}

class InteractionRule {
  final String ruleId;
  final String drugA;
  final String drugB;
  final String severity;
  final String riskDescriptionEn;
  final String riskDescriptionHi;
  final String riskDescriptionMr;
  final String clinicalGuidance;
  final String source;

  InteractionRule({
    required this.ruleId,
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.riskDescriptionEn,
    required this.riskDescriptionHi,
    required this.riskDescriptionMr,
    required this.clinicalGuidance,
    required this.source,
  });

  factory InteractionRule.fromJson(Map<String, dynamic> json) => InteractionRule(
        ruleId: json['rule_id'],
        drugA: json['drug_a'],
        drugB: json['drug_b'],
        severity: json['severity'],
        riskDescriptionEn: json['risk_description_en'],
        riskDescriptionHi: json['risk_description_hi'],
        riskDescriptionMr: json['risk_description_mr'],
        clinicalGuidance: json['clinical_guidance'] ?? '',
        source: json['source'] ?? 'Verified Drug Database',
      );
}

class CaregiverEvent {
  final String id;
  final DateTime timestamp;
  final String eventType; // CONSECUTIVE_FAILURES | MISSED_DOSE
  final String medicineName;
  final String note;
  final bool isSimulated;

  CaregiverEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.medicineName,
    required this.note,
    this.isSimulated = true,
  });
}
