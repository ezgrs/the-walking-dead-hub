sealed class Vault {
  Uri get backendUrl;
}

class HardcodedVault implements Vault {
  const HardcodedVault();

  @override
  Uri get backendUrl => Uri.base.resolve("/api");
}
