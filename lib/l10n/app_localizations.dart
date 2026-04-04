import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Sora de'**
  String get appTitle;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Gifting & photobooth — inventory, orders, and profit in one place.'**
  String get welcomeTagline;

  /// No description provided for @welcomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter app'**
  String get welcomeContinue;

  /// No description provided for @profitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profitLabel;

  /// No description provided for @profitNetGain.
  ///
  /// In en, this message translates to:
  /// **'Net gain'**
  String get profitNetGain;

  /// No description provided for @profitNetLoss.
  ///
  /// In en, this message translates to:
  /// **'Net loss'**
  String get profitNetLoss;

  /// No description provided for @profitSemantic.
  ///
  /// In en, this message translates to:
  /// **'{status}, {amount}'**
  String profitSemantic(String status, String amount);

  /// No description provided for @reportsShareCsv.
  ///
  /// In en, this message translates to:
  /// **'Share month as CSV'**
  String get reportsShareCsv;

  /// No description provided for @reportsShareCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'Sora de monthly report'**
  String get reportsShareCsvSubject;

  /// No description provided for @reportsTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get reportsTrendTitle;

  /// No description provided for @reportsTrendRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsTrendRevenue;

  /// No description provided for @reportsTrendExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsTrendExpenses;

  /// No description provided for @reportsCsvSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportsCsvSummary;

  /// No description provided for @reportsCsvBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get reportsCsvBreakdown;

  /// No description provided for @reportsCsvInventoryUsage.
  ///
  /// In en, this message translates to:
  /// **'Inventory usage'**
  String get reportsCsvInventoryUsage;

  /// No description provided for @reportsCsvFieldMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get reportsCsvFieldMetric;

  /// No description provided for @reportsCsvFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reportsCsvFieldAmount;

  /// No description provided for @reportsCsvFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get reportsCsvFieldLabel;

  /// No description provided for @reportsCsvFieldUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get reportsCsvFieldUnits;

  /// No description provided for @shareCsvError.
  ///
  /// In en, this message translates to:
  /// **'Could not share file'**
  String get shareCsvError;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Sora de'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booth-friendly overview'**
  String get dashboardSubtitle;

  /// No description provided for @metricTodaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get metricTodaysSales;

  /// No description provided for @metricMonthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly revenue'**
  String get metricMonthlyRevenue;

  /// No description provided for @metricMonthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly expenses'**
  String get metricMonthlyExpenses;

  /// No description provided for @metricNetProfitLoss.
  ///
  /// In en, this message translates to:
  /// **'Net profit / loss'**
  String get metricNetProfitLoss;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
