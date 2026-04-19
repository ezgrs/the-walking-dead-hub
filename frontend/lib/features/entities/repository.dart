import 'package:twd_hub/common/http/client.dart';
import 'package:twd_hub/common/http/response_transformer.dart';
import 'package:twd_hub/models.dart';

class EntitiesRepository extends HttpClient {
  const EntitiesRepository({
    required super.vault,
    required super.authenticator,
  });

  Future<List<IndexOut>> readIndices() {
    return makeRequest('GET', [
      'entities',
      'indices',
    ], transformer: HttpModelListResponseTransformer(by: IndexOut.fromJson));
  }

  Future<List<Entity>> readEntities({String? index}) {
    return makeRequest(
      'GET',
      ['entities'],
      query: {if (index != null) "index": index},
      transformer: HttpModelListResponseTransformer(by: Entity.fromJson),
    );
  }

  Future<EntityOut?> readEntity(int id) {
    return makeRequest('GET', [
      'entities',
      "$id",
    ], transformer: HttpModelResponseTransformer(by: EntityOut.fromJson));
  }
}
