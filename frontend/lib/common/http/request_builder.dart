import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class HttpRequestBuilder {
  http.BaseRequest build(String methodName, Uri uri, Object? body);
}

class HttpDefaultRequestBuilder implements HttpRequestBuilder {
  final void Function(http.Request)? initializer;

  const HttpDefaultRequestBuilder({this.initializer});

  @override
  http.BaseRequest build(String methodName, Uri uri, Object? body) {
    final http.Request request = http.Request(methodName, uri);
    final void Function(http.Request)? initializer = this.initializer;
    if (initializer != null) {
      initializer(request);
    }
    if (body != null) {
      request.body = json.encode(body);
      request.headers['Content-Type'] = 'application/json';
    }
    return request;
  }
}

class HttpMultipartRequestBuilder implements HttpRequestBuilder {
  final void Function(http.MultipartRequest)? initializer;

  const HttpMultipartRequestBuilder({this.initializer});

  @override
  http.BaseRequest build(String methodName, Uri uri, Object? body) {
    final http.MultipartRequest request = http.MultipartRequest(
      methodName,
      uri,
    );
    final void Function(http.MultipartRequest)? initializer = this.initializer;
    if (initializer != null) {
      initializer(request);
    }
    if (body case Map()) {
      request.fields.addAll(body.map((key, value) => MapEntry(key, '$value')));
    }
    return request;
  }
}
