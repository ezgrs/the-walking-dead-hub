import '../../models.dart';

sealed class EntitiesState {
  const EntitiesState();
}

class IndicesLoadInProgress extends EntitiesState {
  const IndicesLoadInProgress();
}

sealed class IndicesLoadSuccessBase extends EntitiesState {
  final List<IndexOut> indices;

  const IndicesLoadSuccessBase({required this.indices});
}

class IndicesInitial extends IndicesLoadSuccessBase {
  const IndicesInitial({required super.indices});
}

sealed class IndexSelectedInitialBase extends IndicesLoadSuccessBase {
  final String index;

  const IndexSelectedInitialBase({required super.indices, required this.index});
}

class EntitiesLoadInProgress extends IndexSelectedInitialBase {
  const EntitiesLoadInProgress({required super.indices, required super.index});
}

sealed class EntitiesLoadSuccessBase extends IndexSelectedInitialBase {
  final List<Entity> entities;

  const EntitiesLoadSuccessBase({
    required super.indices,
    required super.index,
    required this.entities,
  });
}

class EntitiesInitial extends EntitiesLoadSuccessBase {
  const EntitiesInitial({
    required super.indices,
    required super.index,
    required super.entities,
  });
}

class EpisodesLoadInProgress extends EntitiesLoadSuccessBase {
  final int selectedEntityId;

  const EpisodesLoadInProgress({
    required super.indices,
    required super.index,
    required super.entities,
    required this.selectedEntityId,
  });
}

class EntitySelectedInitial extends EntitiesLoadSuccessBase {
  final EntityOut stats;

  const EntitySelectedInitial({
    required super.indices,
    required super.index,
    required super.entities,
    required this.stats,
  });
}
