import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:twd_hub/common/http/remote_exception.dart';
import 'package:twd_hub/common/http/response_output.dart';
import 'package:twd_hub/common/http/response_transformer.dart';
import 'package:universal_io/io.dart';

import '../authenticator.dart';
import 'request_builder.dart';
import '../vault.dart';

abstract class HttpClient {
  final Vault vault;
  final Authenticator authenticator;

  const HttpClient({required this.vault, required this.authenticator});

  Future<T> makeRequest<T>(
    String methodName,
    List<String> path, {
    Map<String, Object>? query,
    Object? body,
    Set<int> validStatusCodes = const {},
    HttpRequestBuilder builder = const HttpDefaultRequestBuilder(),
    required HttpResponseTransformer<T> transformer,
  }) async {
    if (validStatusCodes.isEmpty) {
      validStatusCodes = {
        ...validStatusCodes,
        switch (methodName) {
          'POST' => HttpStatus.created,
          _ => HttpStatus.ok,
        },
      };
    }

    final Uri uri = vault.backendUrl.replace(
      pathSegments: [...vault.backendUrl.pathSegments, ...path],
      queryParameters: query,
    );
    final http.BaseRequest request = builder.build(methodName, uri, body);
    if (authenticator.currentToken case String token) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final http.StreamedResponse response = await request.send();
    final int statusCode = response.statusCode;

    String? contents;
    if (validStatusCodes.contains(statusCode)) {
      final HttpResponseOutput<T> output = await transformer.evaluate(response);
      switch (output) {
        case HttpValidResponseOutput<T>():
          return output.value;
        case HttpInvalidResponseOutput<T>():
          contents = output.contents;
      }
    } else {
      contents = null;
    }
    if (statusCode == HttpStatus.unauthorized) {
      await authenticator.onTokenExpired();
    }
    final Map<String, Object?> errorData;
    contents ??= await response.stream.bytesToString();
    try {
      errorData = json.decode(contents);
    } on FormatException {
      throw HttpUnknownRemoteException(
        statusCode: statusCode,
        type: 'exception',
        args: [contents],
        contents: contents,
      );
    }
    throw HttpKnownRemoteException(
      statusCode: statusCode,
      data: errorData,
      contents: contents,
    );
  }
}
