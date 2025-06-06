class Config {
  /// 기본값은 로컬호스트, 필요하면 --dart-define 으로 덮어씁니다.
  /// trim() 을 써서 앞뒤 공백을 제거합니다.
  static final String baseUrl =
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://f9e7-117-17-163-40.ngrok-free.app',
      ).trim();
}
