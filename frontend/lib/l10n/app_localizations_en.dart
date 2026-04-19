// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homepageMenu => 'Menu';

  @override
  String get homepageEntitiesButtonLabel => 'Characters';

  @override
  String get homepageSeasonsButtonLabel => 'Seasons';

  @override
  String get homepageEpisodesButtonLabel => 'Episodes';

  @override
  String get homepageIntroductionTitleText =>
      'A guide to The Walking Dead characters';

  @override
  String get homepageIntroductionBodyText =>
      'This site collects information about characters from The Walking Dead, including their first appearance, key events in their story, and where applicable, how their story ends. You can also check appearances across episodes, including flashbacks, and browse basic statistics across seasons. It\'s meant as a simple reference to help you revisit or find details about characters from the series.';

  @override
  String get homepageCreatedByLabel => 'Created by';
}
