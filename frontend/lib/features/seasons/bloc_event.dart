import '../../models.dart';

sealed class SeasonsEvent {}

class SeasonsIndicesLoadRequested implements SeasonsEvent {
  const SeasonsIndicesLoadRequested();
}

class SeasonsIndicesLoadSucceeded implements SeasonsEvent {
  final List<SeasonIndexDto> indices;

  const SeasonsIndicesLoadSucceeded({required this.indices});
}

class SeasonsIndicesLoadFailed implements SeasonsEvent {
  final Object error;

  const SeasonsIndicesLoadFailed({required this.error});
}

class SeasonEpisodesLoadRequested implements SeasonsEvent {
  final int seasonNumber;

  const SeasonEpisodesLoadRequested({required this.seasonNumber});
}

class SeasonEpisodesLoadSucceeded implements SeasonsEvent {
  final List<Episode> episodes;

  const SeasonEpisodesLoadSucceeded({required this.episodes});
}

class SeasonEpisodesLoadFailed implements SeasonsEvent {
  final Object error;

  const SeasonEpisodesLoadFailed({required this.error});
}

class SeasonEpisodeLoadRequested implements SeasonsEvent {
  final int seasonNumber;
  final int episodeNumber;

  const SeasonEpisodeLoadRequested({
    required this.seasonNumber,
    required this.episodeNumber,
  });
}

class SeasonEpisodeLoadSucceeded implements SeasonsEvent {
  final SeasonEpisodeDto stats;

  const SeasonEpisodeLoadSucceeded({required this.stats});
}

class SeasonEpisodeLoadFailed implements SeasonsEvent {
  final Object error;

  const SeasonEpisodeLoadFailed({required this.error});
}
