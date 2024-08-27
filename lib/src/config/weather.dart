class WeatherConfig {
  String apiKey = '1e7707a859e64a0d482be8303bce2c4d';
  String baseUrl = 'https://api.openweathermap.org/data/2.5';

  String getApiKey() {
    return apiKey;
  }

  String getBaseUrl() {
    return baseUrl;
  }
}