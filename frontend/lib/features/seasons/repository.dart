import 'package:twd_hub/common/http/client.dart';
import 'package:twd_hub/common/http/response_transformer.dart';
import 'package:twd_hub/models.dart';

class SeasonsRepository extends HttpClient {
  const SeasonsRepository({required super.vault, required super.authenticator});

  Future<List<SeasonIndexDto>> readIndices() {
    return makeRequest(
      'GET',
      ['seasons', 'indices'],
      transformer: HttpModelListResponseTransformer(
        by: SeasonIndexDto.fromJson,
      ),
    );
  }

  Future<List<Episode>> readEpisodes({int? seasonNumber}) {
    return makeRequest(
      'GET',
      ['seasons'],
      query: {if (seasonNumber != null) "index": "$seasonNumber"},
      transformer: HttpModelListResponseTransformer(by: Episode.fromJson),
    );
  }

  Future<SeasonEpisodeDto?> readEpisode(int seasonNumber, int episodeNumber) {
    return makeRequest(
      'GET',
      ['seasons', "$seasonNumber", "$episodeNumber"],
      transformer: HttpModelResponseTransformer(by: SeasonEpisodeDto.fromJson),
    );
  }
}
