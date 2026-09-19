import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MediSathi'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Right Medicine. Safe You.'**
  String get appTagline;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Namaste! How can we help you today?'**
  String get homeGreeting;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyMedicines.
  ///
  /// In en, this message translates to:
  /// **'My Medicines'**
  String get navMyMedicines;

  /// No description provided for @navReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @tileScanMedicine.
  ///
  /// In en, this message translates to:
  /// **'Scan Medicine'**
  String get tileScanMedicine;

  /// No description provided for @tileMyMedicines.
  ///
  /// In en, this message translates to:
  /// **'My Medicines'**
  String get tileMyMedicines;

  /// No description provided for @tileReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get tileReminders;

  /// No description provided for @tileCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get tileCaregiver;

  /// No description provided for @todaysDoses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Doses'**
  String get todaysDoses;

  /// No description provided for @scan_hold_steady.
  ///
  /// In en, this message translates to:
  /// **'Place the medicine strip in frame. Keep it steady.'**
  String get scan_hold_steady;

  /// No description provided for @scan_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Scanning Medicine… Processing images...'**
  String get scan_analyzing;

  /// No description provided for @too_shaky_rescan.
  ///
  /// In en, this message translates to:
  /// **'Too shaky — hold steadier or use a photo.'**
  String get too_shaky_rescan;

  /// No description provided for @medicine_verified.
  ///
  /// In en, this message translates to:
  /// **'Medicine Verified'**
  String get medicine_verified;

  /// No description provided for @medicine_uncertain.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify this medicine'**
  String get medicine_uncertain;

  /// No description provided for @rescan_or_caregiver.
  ///
  /// In en, this message translates to:
  /// **'Rescan or Ask Caregiver for help.'**
  String get rescan_or_caregiver;

  /// No description provided for @strength_conflict.
  ///
  /// In en, this message translates to:
  /// **'Strength on strip does not match candidate medicine.'**
  String get strength_conflict;

  /// No description provided for @interaction_warning.
  ///
  /// In en, this message translates to:
  /// **'Potential interaction detected!'**
  String get interaction_warning;

  /// No description provided for @no_rule_matched_not_guarantee.
  ///
  /// In en, this message translates to:
  /// **'No stored interaction rule matched your current medicines. This is not a guarantee of safety. Ask your doctor or pharmacist.'**
  String get no_rule_matched_not_guarantee;

  /// No description provided for @consult_professional.
  ///
  /// In en, this message translates to:
  /// **'Please consult your doctor or pharmacist before taking these medicines together.'**
  String get consult_professional;

  /// No description provided for @reminder_saved.
  ///
  /// In en, this message translates to:
  /// **'Reminder set successfully!'**
  String get reminder_saved;

  /// No description provided for @reminder_due.
  ///
  /// In en, this message translates to:
  /// **'Time for your medicine!'**
  String get reminder_due;

  /// No description provided for @missed_dose.
  ///
  /// In en, this message translates to:
  /// **'Missed Dose Alert'**
  String get missed_dose;

  /// No description provided for @caregiver_alert_simulated.
  ///
  /// In en, this message translates to:
  /// **'Prototype: simulated alert — nothing was sent'**
  String get caregiver_alert_simulated;

  /// No description provided for @disclaimer_short.
  ///
  /// In en, this message translates to:
  /// **'Prototype for medication identification and adherence support — not a substitute for medical advice.'**
  String get disclaimer_short;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
