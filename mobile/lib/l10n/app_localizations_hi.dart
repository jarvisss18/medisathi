// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'मेडीसाथी';

  @override
  String get appTagline => 'सही दवा। सुरक्षित आप।';

  @override
  String get homeGreeting => 'नमस्ते! आज हम आपकी क्या मदद कर सकते हैं?';

  @override
  String get navHome => 'होम';

  @override
  String get navMyMedicines => 'मेरी दवाएं';

  @override
  String get navReminders => 'रिमाइंडर';

  @override
  String get navMore => 'अधिक';

  @override
  String get tileScanMedicine => 'दवा स्कैन करें';

  @override
  String get tileMyMedicines => 'मेरी दवाएं';

  @override
  String get tileReminders => 'रिमाइंडर';

  @override
  String get tileCaregiver => 'देखभालकर्ता';

  @override
  String get todaysDoses => 'आज की खुराक';

  @override
  String get scan_hold_steady => 'दवा की स्ट्रिप फ्रेम में रखें। स्थिर रखें।';

  @override
  String get scan_analyzing =>
      'दवा स्कैन हो रही है… चित्रों का विश्लेषण हो रहा है...';

  @override
  String get too_shaky_rescan =>
      'हाथ हिल रहा है — कृपया स्थिर रखें या फोटो चुनें।';

  @override
  String get medicine_verified => 'दवा सत्यापित हुई';

  @override
  String get medicine_uncertain => 'इस दवा की पुष्टि नहीं हो सकी';

  @override
  String get rescan_or_caregiver =>
      'दोबारा स्कैन करें या देखभालकर्ता से मदद लें।';

  @override
  String get strength_conflict =>
      'स्ट्रिप पर लिखी मात्रा चुनी गई दवा से मेल नहीं खाती।';

  @override
  String get interaction_warning => 'संभावित दवा रिएक्शन की चेतावनी!';

  @override
  String get no_rule_matched_not_guarantee =>
      'आपकी मौजूदा दवाओं के लिए कोई इंटरैक्शन नियम नहीं मिला। यह सुरक्षा की गारंटी नहीं है। डॉक्टर या फार्मासिस्ट से सलाह लें।';

  @override
  String get consult_professional =>
      'इन दवाओं को एक साथ लेने से पहले कृपया अपने डॉक्टर या फार्मासिस्ट से सलाह लें।';

  @override
  String get reminder_saved => 'रिमाइंडर सफलतापूर्वक सेट हो गया!';

  @override
  String get reminder_due => 'आपकी दवा का समय हो गया है!';

  @override
  String get missed_dose => 'छूटी हुई खुराक की चेतावनी';

  @override
  String get caregiver_alert_simulated =>
      'प्रोटोटाइप: सिमुलेटेड अलर्ट — कोई वास्तविक संदेश नहीं भेजा गया';

  @override
  String get disclaimer_short =>
      'दवा पहचान और सहायता के लिए प्रोटोटाइप — चिकित्सीय सलाह का विकल्प नहीं।';
}
