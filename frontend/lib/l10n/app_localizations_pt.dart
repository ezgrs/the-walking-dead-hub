// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get homepageMenu => 'Menu';

  @override
  String get homepageEntitiesButtonLabel => 'Personagens';

  @override
  String get homepageSeasonsButtonLabel => 'Temporadas';

  @override
  String get homepageEpisodesButtonLabel => 'Episódios';

  @override
  String get homepageIntroductionTitleText =>
      'Um guia dos personagens de The Walking Dead';

  @override
  String get homepageIntroductionBodyText =>
      'Este site reúne informações sobre os personagens de The Walking Dead, incluindo a primeira aparição, eventos importantes da sua história e, quando aplicável, como suas histórias terminam. Também é possível ver em quais episódios eles aparecem, incluindo flashbacks, e consultar dados básicos ao longo das temporadas. A ideia é servir como uma referência simples para revisar ou encontrar detalhes sobre os personagens da série.';

  @override
  String get homepageCreatedByLabel => 'Criado por';
}
