import '../../models.dart';

sealed class SeasonsState {
  const SeasonsState();
}

class SeasonsIndicesLoadInProgress extends SeasonsState {
  const SeasonsIndicesLoadInProgress();
}

sealed class SeasonsIndicesLoadSuccessBase extends SeasonsState {
  final List<SeasonIndexDto> indices;

  const SeasonsIndicesLoadSuccessBase({required this.indices});
}

class SeasonsIndicesInitial extends SeasonsIndicesLoadSuccessBase {
  const SeasonsIndicesInitial({required super.indices});
}

sealed class SeasonSelectedInitialBase extends SeasonsIndicesLoadSuccessBase {
  final int seasonNumber;

  const SeasonSelectedInitialBase({
    required super.indices,
    required this.seasonNumber,
  });
}

class SeasonEpisodesLoadInProgress extends SeasonSelectedInitialBase {
  const SeasonEpisodesLoadInProgress({
    required super.indices,
    required super.seasonNumber,
  });
}

sealed class SeasonEpisodesLoadSuccessBase extends SeasonSelectedInitialBase {
  final List<Episode> episodes;

  const SeasonEpisodesLoadSuccessBase({
    required super.indices,
    required super.seasonNumber,
    required this.episodes,
  });
}

class SeasonEpisodesInitial extends SeasonEpisodesLoadSuccessBase {
  const SeasonEpisodesInitial({
    required super.indices,
    required super.seasonNumber,
    required super.episodes,
  });
}

class SeasonEpisodeLoadInProgress extends SeasonEpisodesLoadSuccessBase {
  final int episodeNumber;

  const SeasonEpisodeLoadInProgress({
    required super.indices,
    required super.seasonNumber,
    required super.episodes,
    required this.episodeNumber,
  });
}

class SeasonEpisodeSelectedInitial extends SeasonEpisodesLoadSuccessBase {
  final SeasonEpisodeDto stats;

  const SeasonEpisodeSelectedInitial({
    required super.indices,
    required super.seasonNumber,
    required super.episodes,
    required this.stats,
  });
}
