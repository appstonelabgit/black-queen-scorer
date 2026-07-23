// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ScoreWise';

  @override
  String get tagline => 'Fast scoring for card nights';

  @override
  String get startNewSession => 'Start New Session';

  @override
  String get startSession => 'Start Session';

  @override
  String get resume => 'Resume';

  @override
  String get discardSession => 'Discard session';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get newRound => '+ New Round';

  @override
  String get finishSession => 'Finish Session';

  @override
  String get resultWon => 'Won';

  @override
  String get resultLost => 'Lost';

  @override
  String get finishConfirmTitle => 'Finish this session?';

  @override
  String get finishConfirmBody =>
      'You can still view it in History, but no more rounds can be added.';

  @override
  String get discardConfirmTitle => 'Discard this session?';

  @override
  String get discardConfirmBody => 'All rounds will be permanently lost.';

  @override
  String get valPickBidder => 'Pick a caller';

  @override
  String get valPickBid => 'Enter a target score';

  @override
  String get valPickResult => 'Pick Won or Lost';

  @override
  String get emptyHistory => 'No past sessions yet.';

  @override
  String get emptyRounds => 'No rounds yet — tap New Round to begin.';

  @override
  String get shareButton => 'Share';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get addNewPlayer => 'Add new player';

  @override
  String get alreadyAdded => 'Already added';

  @override
  String get tapToAdd => 'Tap to add to this session';

  @override
  String get enableBonus => 'Enable bonus';

  @override
  String get bonusAmount => 'Bonus amount';

  @override
  String get bonusHelper => 'Caller gets ±bonus on top of the target.';

  @override
  String get howScoringWorks => 'How scoring works';

  @override
  String get pickBidderFirst => 'Pick a caller first';

  @override
  String get teamLabel => 'Team';

  @override
  String get oppositionLabel => 'Opposition';

  @override
  String get sharedFooter => 'Shared from ScoreWise';
}
