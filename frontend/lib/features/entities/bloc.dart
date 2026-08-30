import 'package:flutter_bloc/flutter_bloc.dart';
import 'repository.dart';

import 'bloc_event.dart';
import 'bloc_state.dart';

class EntitiesBloc extends Bloc<EntitiesEvent, EntitiesState> {
  EntitiesBloc({required EntitiesRepository repository})
    : super(const IndicesLoadInProgress()) {
    on<IndicesLoadRequested>((event, emit) {
      repository
          .readIndices()
          .then((data) => add(IndicesLoadSucceeded(indices: data)))
          .catchError((e) => add(IndicesLoadFailed(error: e)));
      return emit(const IndicesLoadInProgress());
    });
    on<IndicesLoadSucceeded>((event, emit) {
      return emit(IndicesInitial(indices: event.indices));
    });
    on<IndicesLoadFailed>((event, emit) {});
    on<IndexLoadRequested>((event, emit) {
      final EntitiesState state = this.state;
      switch (state) {
        case IndicesLoadSuccessBase():
          repository
              .readEntities(index: event.index)
              .then((data) => add(IndexLoadSucceeded(entities: data)))
              .catchError((e) => add(IndexLoadFailed(error: e)));
          return emit(
            EntitiesLoadInProgress(indices: state.indices, index: event.index),
          );
        case IndicesLoadInProgress():
          return;
      }
    });
    on<IndexLoadSucceeded>((event, emit) {
      final EntitiesState state = this.state;
      switch (state) {
        case IndexSelectedInitialBase():
          return emit(
            EntitiesInitial(
              indices: state.indices,
              index: state.index,
              entities: event.entities,
            ),
          );
        case IndicesLoadInProgress():
          return;
        case IndicesInitial():
          return;
      }
    });
    on<IndexLoadFailed>((event, emit) {});
    on<EpisodesLoadRequested>((event, emit) {
      final EntitiesState state = this.state;
      switch (state) {
        case EntitiesLoadSuccessBase():
          emit(
            EpisodesLoadInProgress(
              indices: state.indices,
              index: state.index,
              entities: state.entities,
              selectedEntityId: event.entityId,
            ),
          );
          repository
              .readEntity(event.entityId)
              .then((data) => add(EpisodesLoadSucceeded(stats: data!)))
              .catchError((e) => add(EpisodesLoadFailed(error: e)));
          return;
        case IndicesLoadInProgress():
        case IndicesInitial():
        case EntitiesLoadInProgress():
          return;
      }
    });
    on<EpisodesLoadSucceeded>((event, emit) {
      final EntitiesState state = this.state;
      switch (state) {
        case EntitiesLoadSuccessBase():
          return emit(
            EntitySelectedInitial(
              indices: state.indices,
              index: state.index,
              entities: state.entities,
              stats: event.stats,
            ),
          );
        case IndicesLoadInProgress():
        case IndicesInitial():
        case EntitiesLoadInProgress():
          return;
      }
    });
    on<EpisodesLoadFailed>((event, emit) {});
  }
}
