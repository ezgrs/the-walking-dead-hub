import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'response_output.dart';

abstract class HttpResponseTransformer<T> {
  FutureOr<HttpResponseOutput<T>> evaluate(http.StreamedResponse response);
}

class HttpAnyResponseTransformer implements HttpResponseTransformer<bool> {
  const HttpAnyResponseTransformer();

  @override
  HttpResponseOutput<bool> evaluate(http.StreamedResponse response) {
    return const HttpValidResponseOutput(true);
  }
}

abstract class HttpJsonResponseTransformer<T>
    implements HttpResponseTransformer<T> {
  const HttpJsonResponseTransformer();

  @override
  @nonVirtual
  Future<HttpResponseOutput<T>> evaluate(http.StreamedResponse response) async {
    final String contents = await response.stream.bytesToString();
    if (contents.isEmpty) {
      if (null is T) return HttpValidResponseOutput(null as T);
      return HttpInvalidResponseOutput(contents: contents);
    }
    final Object? data = json.decode(contents);
    final HttpResponseOutput<T> output = await evaluateJson(data);
    return switch (output) {
      HttpValidResponseOutput() => output,
      HttpInvalidResponseOutput() => HttpInvalidResponseOutput(
        contents: contents,
      ),
    };
  }

  FutureOr<HttpResponseOutput<T>> evaluateJson(Object? data);
}

class HttpRawResponseTransformer<T> implements HttpResponseTransformer<T> {
  final T? Function(http.BaseResponse data) parser;

  const HttpRawResponseTransformer({required this.parser});

  @override
  HttpResponseOutput<T> evaluate(http.StreamedResponse response) {
    final T? value = parser(response);
    if (value is T) return HttpValidResponseOutput(value);
    return const HttpInvalidResponseOutput();
  }
}

class HttpValueResponseTransformer<T> extends HttpJsonResponseTransformer<T> {
  final T? Function(Object? data) parser;

  const HttpValueResponseTransformer({required this.parser});

  @override
  FutureOr<HttpResponseOutput<T>> evaluateJson(Object? data) {
    final T? value = parser(data);
    if (value is T) return HttpValidResponseOutput(value);
    return const HttpInvalidResponseOutput();
  }
}

class HttpModelResponseTransformer<T> extends HttpJsonResponseTransformer<T> {
  final T? Function(Map<dynamic, dynamic> data) by;

  const HttpModelResponseTransformer({required this.by});

  @override
  HttpResponseOutput<T> evaluateJson(Object? data) {
    final T? value = switch (data) {
      null => null,
      String source => by(json.decode(source)),
      _ => by(data as Map<String, Object?>),
    };
    if (value is T) return HttpValidResponseOutput(value);
    return const HttpInvalidResponseOutput();
  }
}

class HttpModelListResponseTransformer<T>
    extends HttpJsonResponseTransformer<List<T>> {
  final T Function(Map<dynamic, dynamic> data) by;

  const HttpModelListResponseTransformer({required this.by});

  @override
  HttpResponseOutput<List<T>> evaluateJson(Object? data) {
    if (data is List) {
      return HttpValidResponseOutput(data.cast<Map>().map(by).toList());
    }
    return const HttpInvalidResponseOutput();
  }
}

class HttpFileResponseTransformer
    implements HttpResponseTransformer<Uint8List> {
  const HttpFileResponseTransformer();

  @override
  Future<HttpResponseOutput<Uint8List>> evaluate(
    http.StreamedResponse response,
  ) async {
    return HttpValidResponseOutput(await response.stream.toBytes());
  }
}
