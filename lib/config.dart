/// lib/config.dart

class Config {
  /// 기본값은 로컬호스트, 필요하면 --dart-define 으로 덮어씁니다.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
