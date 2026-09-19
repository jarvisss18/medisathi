// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'मेडीसाथी';

  @override
  String get appTagline => 'योग्य औषध. सुरक्षित तुम्ही.';

  @override
  String get homeGreeting => 'नमस्ते! आज आम्ही तुम्हाला कशी मदत करू शकतो?';

  @override
  String get navHome => 'होम';

  @override
  String get navMyMedicines => 'माझी औषधे';

  @override
  String get navReminders => 'स्मरणपत्रे';

  @override
  String get navMore => 'अधिक';

  @override
  String get tileScanMedicine => 'औषध स्कॅन करा';

  @override
  String get tileMyMedicines => 'माझी औषधे';

  @override
  String get tileReminders => 'स्मरणपत्रे';

  @override
  String get tileCaregiver => 'काळजीवाहू';

  @override
  String get todaysDoses => 'आजचे डोस';

  @override
  String get scan_hold_steady => 'औषधाची पट्टी फ्रेममध्ये ठेवा. स्थिर ठेवा.';

  @override
  String get scan_analyzing =>
      'औषध स्कॅन होत आहे… प्रतिमांचे विश्लेषण होत आहे...';

  @override
  String get too_shaky_rescan =>
      'हात हलत आहे — कृपया स्थिर ठेवा किंवा फोटो निवडा.';

  @override
  String get medicine_verified => 'औषध सत्यापित झाले';

  @override
  String get medicine_uncertain => 'या औषधाची पडताळणी होऊ शकली नाही';

  @override
  String get rescan_or_caregiver =>
      'पुन्हा स्कॅन करा किंवा काळजीवाहूची मदत घ्या.';

  @override
  String get strength_conflict =>
      'पट्टीवरील प्रमाण निवडलेल्या औषधाशी जुळत नाही.';

  @override
  String get interaction_warning => 'संभाव्य औषध दुष्परिणामांची चेतावणी!';

  @override
  String get no_rule_matched_not_guarantee =>
      'तुमच्या सध्याच्या औषधांसाठी कोणताही दुष्परिणाम नियम आढळला नाही. ही सुरक्षिततेची हमी नाही. डॉक्टर किंवा औषधविक्रेत्यांचा सल्ला घ्या.';

  @override
  String get consult_professional =>
      'ही औषधे एकत्र घेण्यापूर्वी कृपया तुमच्या डॉक्टर किंवा औषधविक्रेत्यांचा सल्ला घ्या.';

  @override
  String get reminder_saved => 'स्मरणपत्र यशस्वीरित्या सेट झाले!';

  @override
  String get reminder_due => 'तुमच्या औषधाची वेळ झाली आहे!';

  @override
  String get missed_dose => 'रद्द झालेला डोस अलर्ट';

  @override
  String get caregiver_alert_simulated =>
      'प्रोटोटाइप: सिम्युलेटेड अलर्ट — कोणताही संदेश पाठवला नाही';

  @override
  String get disclaimer_short =>
      'औधषध ओळख आणि सुसंगततेसाठी प्रोटोटाइप — वैद्यकीय सल्ल्याचा पर्याय नाही.';
}
