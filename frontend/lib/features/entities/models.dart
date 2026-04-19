part of '../../models.dart';

@Data()
abstract class _IndexOut {
  @Field(name: "index")
  String get index;

  @Field(name: "count")
  int get count;
}

@Data()
abstract class _EpisodeOut {
  @ModelField(name: "episode", referTo: _Episode)
  get entity;

  @Field(name: "appearance_type_label")
  String get appearanceTypeLabel;

  @Field(name: "appearance_form_type_label")
  String? get appearanceFormTypeLabel;
}

@Data()
abstract class _EntityOut {
  @ModelField(name: "entity", referTo: _Entity)
  get entity;

  @ModelField(
    name: "episodes",
    referTo: _EpisodeOut,
    template: ModelFieldTemplate<List<ModelFieldType>>(),
  )
  get episodes;
}
