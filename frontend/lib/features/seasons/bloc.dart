import 'package:flutter_bloc/flutter_bloc.dart';
import 'repository.dart';

import 'bloc_event.dart';
import 'bloc_state.dart';

class SeasonsBloc extends Bloc<SeasonsEvent, SeasonsState> {
  SeasonsBloc({required SeasonsRepository repository})
    : super(const SeasonsIndicesLoadInProgress()) {
    on<SeasonsIndicesLoadRequested>((event, emit) {
      repository
          .readIndices()
          .then((data) => add(SeasonsIndicesLoadSucceeded(indices: data)))
          .catchError((e) => add(SeasonsIndicesLoadFailed(error: e)));
      return emit(const SeasonsIndicesLoadInProgress());
    });
    on<SeasonsIndicesLoadSucceeded>((event, emit) {
      return emit(SeasonsIndicesInitial(indices: event.indices));
    });
    on<SeasonsIndicesLoadFailed>((event, emit) {});
    on<SeasonEpisodesLoadRequested>((event, emit) {
      final SeasonsState state = this.state;
      switch (state) {
        case SeasonsIndicesLoadSuccessBase():
          repository
              .readEpisodes(seasonNumber: event.seasonNumber)
              .then((data) => add(SeasonEpisodesLoadSucceeded(episodes: data)))
              .catchError((e) => add(SeasonEpisodesLoadFailed(error: e)));
          return emit(
            SeasonEpisodesLoadInProgress(
              indices: state.indices,
              seasonNumber: event.seasonNumber,
            ),
          );
        case SeasonsIndicesLoadInProgress():
          return;
      }
    });
    on<SeasonEpisodesLoadSucceeded>((event, emit) {
      final SeasonsState state = this.state;
      switch (state) {
        case SeasonSelectedInitialBase():
          return emit(
            SeasonEpisodesInitial(
              indices: state.indices,
              seasonNumber: state.seasonNumber,
              episodes: event.episodes,
            ),
          );
        case SeasonsIndicesLoadInProgress():
          return;
        case SeasonsIndicesInitial():
          return;
      }
    });
    on<SeasonEpisodesLoadFailed>((event, emit) {});
    on<SeasonEpisodeLoadRequested>((event, emit) {
      final SeasonsState state = this.state;
      switch (state) {
        case SeasonEpisodesLoadSuccessBase():
          emit(
            SeasonEpisodeLoadInProgress(
              indices: state.indices,
              seasonNumber: state.seasonNumber,
              episodes: state.episodes,
              episodeNumber: event.episodeNumber,
            ),
          );
          repository
              .readEpisode(event.seasonNumber, event.episodeNumber)
              .then((data) => add(SeasonEpisodeLoadSucceeded(stats: data!)))
              .catchError((e) => add(SeasonEpisodeLoadFailed(error: e)));
          return;
        case SeasonsIndicesLoadInProgress():
        case SeasonsIndicesInitial():
        case SeasonEpisodesLoadInProgress():
          return;
      }
    });
    on<SeasonEpisodeLoadSucceeded>((event, emit) {
      final SeasonsState state = this.state;
      switch (state) {
        case SeasonEpisodesLoadSuccessBase():
          return emit(
            SeasonEpisodeSelectedInitial(
              indices: state.indices,
              seasonNumber: state.seasonNumber,
              episodes: state.episodes,
              stats: event.stats,
            ),
          );
        case SeasonsIndicesLoadInProgress():
        case SeasonsIndicesInitial():
        case SeasonEpisodesLoadInProgress():
          return;
      }
    });
    on<SeasonEpisodeLoadFailed>((event, emit) {});
  }
}
