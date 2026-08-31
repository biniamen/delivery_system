final class AppConfig {
  const AppConfig({required this.apiOrigin});

  factory AppConfig.fromEnvironment() {
    const configuredOrigin = String.fromEnvironment(
      'API_ORIGIN',
      defaultValue: 'http://10.0.2.2:5080',
    );
    return AppConfig(apiOrigin: Uri.parse(configuredOrigin));
  }

  final Uri apiOrigin;

  Uri get apiBaseUri => apiOrigin.resolve('/api/v1/');
}
