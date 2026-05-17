sealed class Vault {
  Uri get backendUrl;
}

class HardcodedVault implements Vault {
  const HardcodedVault();

  @override
  Uri get backendUrl => Uri.http("localhost:5000");
}

class DecodedVault implements Vault {
  final Map<String, String> data;

  const DecodedVault({required this.data});

  @override
  Uri get backendUrl => Uri.parse(data["BACKEND_URL"]!);
}
