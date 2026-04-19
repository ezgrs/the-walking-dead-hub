// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'models.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class Entity implements _Entity {
  factory Entity.fromJson(Map json) => _$EntityFromJson(json);

  const Entity({required this.id, required this.wikiHref, required this.name});

  @override
  @JsonKey(name: 'id', required: true, disallowNullValue: true)
  final int id;

  @override
  @JsonKey(name: 'wiki_href', required: true, disallowNullValue: true)
  final String wikiHref;

  @override
  @JsonKey(name: 'name', required: true, disallowNullValue: true)
  final String name;

  Map<String, Object?> toJson() => _$EntityToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class Episode implements _Episode {
  factory Episode.fromJson(Map json) => _$EpisodeFromJson(json);

  const Episode({
    required this.id,
    required this.wikiHref,
    required this.name,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  @override
  @JsonKey(name: 'id', required: true, disallowNullValue: true)
  final int id;

  @override
  @JsonKey(name: 'wiki_href', required: true, disallowNullValue: true)
  final String wikiHref;

  @override
  @JsonKey(name: 'name', required: true, disallowNullValue: true)
  final String name;

  @override
  @JsonKey(name: 'season_number', required: true, disallowNullValue: true)
  final int seasonNumber;

  @override
  @JsonKey(name: 'episode_number', required: true, disallowNullValue: true)
  final String episodeNumber;

  Map<String, Object?> toJson() => _$EpisodeToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class IndexOut implements _IndexOut {
  factory IndexOut.fromJson(Map json) => _$IndexOutFromJson(json);

  const IndexOut({required this.index, required this.count});

  @override
  @JsonKey(name: 'index', required: true, disallowNullValue: true)
  final String index;

  @override
  @JsonKey(name: 'count', required: true, disallowNullValue: true)
  final int count;

  Map<String, Object?> toJson() => _$IndexOutToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class EpisodeOut implements _EpisodeOut {
  factory EpisodeOut.fromJson(Map json) => _$EpisodeOutFromJson(json);

  const EpisodeOut({
    required this.entity,
    required this.appearanceTypeLabel,
    required this.appearanceFormTypeLabel,
  });

  @override
  @JsonKey(name: 'episode', required: true, disallowNullValue: true)
  final Episode entity;

  @override
  @JsonKey(
    name: 'appearance_type_label',
    required: true,
    disallowNullValue: true,
  )
  final String appearanceTypeLabel;

  @override
  @JsonKey(name: 'appearance_form_type_label')
  final String? appearanceFormTypeLabel;

  Map<String, Object?> toJson() => _$EpisodeOutToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class EntityOut implements _EntityOut {
  factory EntityOut.fromJson(Map json) => _$EntityOutFromJson(json);

  const EntityOut({required this.entity, required this.episodes});

  @override
  @JsonKey(name: 'entity', required: true, disallowNullValue: true)
  final Entity entity;

  @override
  @JsonKey(name: 'episodes', required: true, disallowNullValue: true)
  final List<EpisodeOut> episodes;

  Map<String, Object?> toJson() => _$EntityOutToJson(this);
}
