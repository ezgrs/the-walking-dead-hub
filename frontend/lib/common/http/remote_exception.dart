sealed class HttpRemoteException implements Exception {
  int get statusCode;

  String? get contents;

  String describe();
}

class HttpKnownRemoteException implements HttpRemoteException {
  @override
  final int statusCode;
  @override
  final String? contents;
  final Object? data;

  const HttpKnownRemoteException({
    required this.statusCode,
    required this.data,
    required this.contents,
  });

  @override
  String describe() => switch (data) {
    Map data => data['detail'] ?? '',
    _ => '',
  };
}

class HttpUnknownRemoteException implements HttpRemoteException {
  @override
  final int statusCode;
  final String type;
  final List<String> args;
  @override
  final String? contents;

  const HttpUnknownRemoteException({
    required this.statusCode,
    required this.type,
    required this.args,
    required this.contents,
  });

  @override
  String describe() => '$type: ${args.join(', ')}';
}
