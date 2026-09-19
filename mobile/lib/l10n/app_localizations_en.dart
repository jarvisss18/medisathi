// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MediSathi';

  @override
  String get appTagline => 'Right Medicine. Safe You.';

  @override
  String get homeGreeting => 'Namaste! How can we help you today?';

  @override
  String get navHome => 'Home';

  @override
  String get navMyMedicines => 'My Medicines';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navMore => 'More';

  @override
  String get tileScanMedicine => 'Scan Medicine';

  @override
  String get tileMyMedicines => 'My Medicines';

  @override
  String get tileReminders => 'Reminders';

  @override
  String get tileCaregiver => 'Caregiver';

  @override
  String get todaysDoses => 'Today\'s Doses';

  @override
  String get scan_hold_steady =>
      'Place the medicine strip in frame. Keep it steady.';

  @override
  String get scan_analyzing => 'Scanning Medicine… Processing images...';

  @override
  String get too_shaky_rescan => 'Too shaky — hold steadier or use a photo.';

  @override
  String get medicine_verified => 'Medicine Verified';

  @override
  String get medicine_uncertain => 'Unable to verify this medicine';

  @override
  String get rescan_or_caregiver => 'Rescan or Ask Caregiver for help.';

  @override
  String get strength_conflict =>
      'Strength on strip does not match candidate medicine.';

  @override
  String get interaction_warning => 'Potential interaction detected!';

  @override
  String get no_rule_matched_not_guarantee =>
      'No stored interaction rule matched your current medicines. This is not a guarantee of safety. Ask your doctor or pharmacist.';

  @override
  String get consult_professional =>
      'Please consult your doctor or pharmacist before taking these medicines together.';

  @override
  String get reminder_saved => 'Reminder set successfully!';

  @override
  String get reminder_due => 'Time for your medicine!';

  @override
  String get missed_dose => 'Missed Dose Alert';

  @override
  String get caregiver_alert_simulated =>
      'Prototype: simulated alert — nothing was sent';

  @override
  String get disclaimer_short =>
      'Prototype for medication identification and adherence support — not a substitute for medical advice.';
}
