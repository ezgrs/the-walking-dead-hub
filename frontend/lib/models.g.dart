// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Entity _$EntityFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'wiki_href', 'name'],
    disallowNullValues: const ['id', 'wiki_href', 'name'],
  );
  return Entity(
    id: (json['id'] as num).toInt(),
    wikiHref: json['wiki_href'] as String,
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$EntityToJson(Entity instance) => <String, dynamic>{
  'id': instance.id,
  'wiki_href': instance.wikiHref,
  'name': instance.name,
};

Episode _$EpisodeFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'wiki_href',
      'name',
      'season_number',
      'episode_number',
    ],
    disallowNullValues: const [
      'id',
      'wiki_href',
      'name',
      'season_number',
      'episode_number',
    ],
  );
  return Episode(
    id: (json['id'] as num).toInt(),
    wikiHref: json['wiki_href'] as String,
    name: json['name'] as String,
    seasonNumber: (json['season_number'] as num).toInt(),
    episodeNumber: json['episode_number'] as String,
  );
}

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
  'id': instance.id,
  'wiki_href': instance.wikiHref,
  'name': instance.name,
  'season_number': instance.seasonNumber,
  'episode_number': instance.episodeNumber,
};

IndexOut _$IndexOutFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['index', 'count'],
    disallowNullValues: const ['index', 'count'],
  );
  return IndexOut(
    index: json['index'] as String,
    count: (json['count'] as num).toInt(),
  );
}

Map<String, dynamic> _$IndexOutToJson(IndexOut instance) => <String, dynamic>{
  'index': instance.index,
  'count': instance.count,
};

EpisodeOut _$EpisodeOutFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['episode', 'appearance_type_label'],
    disallowNullValues: const ['episode', 'appearance_type_label'],
  );
  return EpisodeOut(
    entity: Episode.fromJson(json['episode'] as Map),
    appearanceTypeLabel: json['appearance_type_label'] as String,
    appearanceFormTypeLabel: json['appearance_form_type_label'] as String?,
  );
}

Map<String, dynamic> _$EpisodeOutToJson(EpisodeOut instance) =>
    <String, dynamic>{
      'episode': instance.entity.toJson(),
      'appearance_type_label': instance.appearanceTypeLabel,
      'appearance_form_type_label': instance.appearanceFormTypeLabel,
    };

EntityOut _$EntityOutFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['entity', 'episodes'],
    disallowNullValues: const ['entity', 'episodes'],
  );
  return EntityOut(
    entity: Entity.fromJson(json['entity'] as Map),
    episodes: (json['episodes'] as List<dynamic>)
        .map((e) => EpisodeOut.fromJson(e as Map))
        .toList(),
  );
}

Map<String, dynamic> _$EntityOutToJson(EntityOut instance) => <String, dynamic>{
  'entity': instance.entity.toJson(),
  'episodes': instance.episodes.map((e) => e.toJson()).toList(),
};
