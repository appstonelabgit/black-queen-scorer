import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Black Queen Scorer'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Fast scoring for card nights'**
  String get tagline;

  /// No description provided for @startNewSession.
  ///
  /// In en, this message translates to:
  /// **'Start New Session'**
  String get startNewSession;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @discardSession.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get discardSession;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @newRound.
  ///
  /// In en, this message translates to:
  /// **'+ New Round'**
  String get newRound;

  /// No description provided for @finishSession.
  ///
  /// In en, this message translates to:
  /// **'Finish Session'**
  String get finishSession;

  /// No description provided for @resultWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get resultWon;

  /// No description provided for @resultLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get resultLost;

  /// No description provided for @finishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish this session?'**
  String get finishConfirmTitle;

  /// No description provided for @finishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can still view it in History, but no more rounds can be added.'**
  String get finishConfirmBody;

  /// No description provided for @discardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this session?'**
  String get discardConfirmTitle;

  /// No description provided for @discardConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All rounds will be permanently lost.'**
  String get discardConfirmBody;

  /// No description provided for @valPickBidder.
  ///
  /// In en, this message translates to:
  /// **'Pick a caller'**
  String get valPickBidder;

  /// No description provided for @valPickBid.
  ///
  /// In en, this message translates to:
  /// **'Enter a target score'**
  String get valPickBid;

  /// No description provided for @valPickResult.
  ///
  /// In en, this message translates to:
  /// **'Pick Won or Lost'**
  String get valPickResult;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No past sessions yet.'**
  String get emptyHistory;

  /// No description provided for @emptyRounds.
  ///
  /// In en, this message translates to:
  /// **'No rounds yet — tap New Round to begin.'**
  String get emptyRounds;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @addNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add new player'**
  String get addNewPlayer;

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get alreadyAdded;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add to this session'**
  String get tapToAdd;

  /// No description provided for @enableBonus.
  ///
  /// In en, this message translates to:
  /// **'Enable bonus'**
  String get enableBonus;

  /// No description provided for @bonusAmount.
  ///
  /// In en, this message translates to:
  /// **'Bonus amount'**
  String get bonusAmount;

  /// No description provided for @bonusHelper.
  ///
  /// In en, this message translates to:
  /// **'Caller gets ±bonus on top of the target.'**
  String get bonusHelper;

  /// No description provided for @howScoringWorks.
  ///
  /// In en, this message translates to:
  /// **'How scoring works'**
  String get howScoringWorks;

  /// No description provided for @pickBidderFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a caller first'**
  String get pickBidderFirst;

  /// No description provided for @teamLabel.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get teamLabel;

  /// No description provided for @oppositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Opposition'**
  String get oppositionLabel;

  /// No description provided for @sharedFooter.
  ///
  /// In en, this message translates to:
  /// **'Shared from Black Queen Scorer'**
  String get sharedFooter;
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
      <String>['en', 'hi'].contains(locale.languageCode);

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
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
