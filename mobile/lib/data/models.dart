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

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineId': medicineId,
        'medicineName': medicineName,
        'doseText': doseText,
        'timeOfDay': timeOfDay,
        'repeatOption': repeatOption,
        'isEnabled': isEnabled,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'],
        medicineId: json['medicineId'],
        medicineName: json['medicineName'],
        doseText: json['doseText'] ?? '1 Tablet',
        timeOfDay: json['timeOfDay'] ?? '08:00',
        repeatOption: json['repeatOption'] ?? 'Daily',
        isEnabled: json['isEnabled'] ?? true,
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminderId': reminderId,
        'medicineName': medicineName,
        'scheduledAt': scheduledAt,
        'status': status.name,
        'actedAt': actedAt,
      };

  factory DoseLog.fromJson(Map<String, dynamic> json) => DoseLog(
        id: json['id'],
        reminderId: json['reminderId'],
        medicineName: json['medicineName'],
        scheduledAt: json['scheduledAt'],
        status: DoseStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DoseStatus.taken,
        ),
        actedAt: json['actedAt'],
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'medicineName': medicineName,
        'note': note,
        'isSimulated': isSimulated,
      };

  factory CaregiverEvent.fromJson(Map<String, dynamic> json) => CaregiverEvent(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        eventType: json['eventType'],
        medicineName: json['medicineName'],
        note: json['note'],
        isSimulated: json['isSimulated'] ?? true,
      );
}

class CaregiverContact {
  final String name;
  final String phone;
  final String relationship;
  final bool alertOnScanFailures;
  final bool alertOnMissedDoses;
  final bool attachPhoto;

  CaregiverContact({
    this.name = 'Rahul Patil',
    this.phone = '+919820012345',
    this.relationship = 'Son',
    this.alertOnScanFailures = true,
    this.alertOnMissedDoses = true,
    this.attachPhoto = false,
  });

  CaregiverContact copyWith({
    String? name,
    String? phone,
    String? relationship,
    bool? alertOnScanFailures,
    bool? alertOnMissedDoses,
    bool? attachPhoto,
  }) {
    return CaregiverContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      alertOnScanFailures: alertOnScanFailures ?? this.alertOnScanFailures,
      alertOnMissedDoses: alertOnMissedDoses ?? this.alertOnMissedDoses,
      attachPhoto: attachPhoto ?? this.attachPhoto,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'alertOnScanFailures': alertOnScanFailures,
        'alertOnMissedDoses': alertOnMissedDoses,
        'attachPhoto': attachPhoto,
      };

  factory CaregiverContact.fromJson(Map<String, dynamic> json) => CaregiverContact(
        name: json['name'] ?? 'Rahul Patil',
        phone: json['phone'] ?? '+919820012345',
        relationship: json['relationship'] ?? 'Son',
        alertOnScanFailures: json['alertOnScanFailures'] ?? true,
        alertOnMissedDoses: json['alertOnMissedDoses'] ?? true,
        attachPhoto: json['attachPhoto'] ?? false,
      );
}

class AuthUser {
  final String id;
  final String name;
  final String phone;
  final String pin;
  final String role; // "Patient" | "Caregiver"
  final bool isAuthenticated;
  final bool isGuest;
  final String createdAt;

  AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.pin = '1234',
    this.role = 'Patient',
    this.isAuthenticated = true,
    this.isGuest = false,
    required this.createdAt,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? pin,
    String? role,
    bool? isAuthenticated,
    bool? isGuest,
    String? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'pin': pin,
        'role': role,
        'isAuthenticated': isAuthenticated,
        'isGuest': isGuest,
        'createdAt': createdAt,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] ?? 'USR-001',
        name: json['name'] ?? 'Mrs. Sunanda Patil',
        phone: json['phone'] ?? '+919820098765',
        pin: json['pin'] ?? '1234',
        role: json['role'] ?? 'Patient',
        isAuthenticated: json['isAuthenticated'] ?? true,
        isGuest: json['isGuest'] ?? false,
        createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      );

  factory AuthUser.defaultDemoUser() => AuthUser(
        id: 'USR-DEFAULT',
        name: 'Mrs. Sunanda Patil',
        phone: '+919820098765',
        pin: '1234',
        role: 'Patient',
        isAuthenticated: true,
        isGuest: false,
        createdAt: DateTime.now().toIso8601String(),
      );

  factory AuthUser.guestUser() => AuthUser(
        id: 'GUEST-001',
        name: 'Guest User',
        phone: '',
        pin: '',
        role: 'Guest',
        isAuthenticated: true,
        isGuest: true,
        createdAt: DateTime.now().toIso8601String(),
      );
}


