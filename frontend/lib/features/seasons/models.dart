part of '../../models.dart';

@Data()
abstract class _SeasonIndexDto {
  @Field(name: "index")
  int get index;

  @Field(name: "count")
  int get count;
}

@Data()
abstract class _SeasonEpisodeAppearanceDto {
  @ModelField(name: "entity", referTo: _Entity)
  get entity;

  @Field(name: "appearance_type_label")
  String get appearanceTypeLabel;

  @Field(name: "appearance_form_type_label")
  String? get appearanceFormTypeLabel;
}

@Data()
abstract class _SeasonEpisodeDto {
  @ModelField(name: "episode", referTo: _Episode)
  get episode;

  @ModelField(
    name: "appearances",
    referTo: _SeasonEpisodeAppearanceDto,
    template: ModelFieldTemplate<List<ModelFieldType>>(),
  )
  get appearances;
}
