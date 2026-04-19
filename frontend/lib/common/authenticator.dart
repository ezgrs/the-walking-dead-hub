abstract class Authenticator {
  String? get currentToken;

  Future<void> onTokenExpired();
}

class PublicAuthenticator implements Authenticator {
  @override
  final String? currentToken = null;

  @override
  Future<void> onTokenExpired() async {}
}
