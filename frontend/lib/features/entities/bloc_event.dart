import '../../models.dart';

sealed class EntitiesEvent {}

class IndicesLoadRequested implements EntitiesEvent {
  const IndicesLoadRequested();
}

class IndicesLoadSucceeded implements EntitiesEvent {
  final List<IndexOut> indices;

  const IndicesLoadSucceeded({required this.indices});
}

class IndicesLoadFailed implements EntitiesEvent {
  final Object error;

  const IndicesLoadFailed({required this.error});
}

class IndexLoadRequested implements EntitiesEvent {
  final String index;

  const IndexLoadRequested({required this.index});
}

class IndexLoadSucceeded implements EntitiesEvent {
  final List<Entity> entities;

  const IndexLoadSucceeded({required this.entities});
}

class IndexLoadFailed implements EntitiesEvent {
  final Object error;

  const IndexLoadFailed({required this.error});
}

class EpisodesLoadRequested implements EntitiesEvent {
  final int entityId;

  const EpisodesLoadRequested({required this.entityId});
}

class EpisodesLoadSucceeded implements EntitiesEvent {
  final EntityOut stats;

  const EpisodesLoadSucceeded({required this.stats});
}

class EpisodesLoadFailed implements EntitiesEvent {
  final Object error;

  const EpisodesLoadFailed({required this.error});
}
