import 'package:dorm_annotations/dorm_annotations.dart';

part 'features/entities/models.dart';
part 'models.g.dart';
part 'models.dorm.dart';

@Data()
abstract class _Entity {
  @Field(name: "id")
  int get id;

  @Field(name: "wiki_href")
  String get wikiHref;

  @Field(name: "name")
  String get name;
}

@Data()
abstract class _Episode {
  @Field(name: "id")
  int get id;

  @Field(name: "wiki_href")
  String get wikiHref;

  @Field(name: "name")
  String get name;

  @Field(name: "season_number")
  int get seasonNumber;

  @Field(name: "episode_number")
  int get episodeNumber;
}
