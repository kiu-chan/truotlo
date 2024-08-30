import 'package:flutter/material.dart';
import 'package:truotlo/src/data/weather/weather_district.dart';
import 'package:truotlo/src/page/home/elements/warning.dart';
import 'package:truotlo/src/page/home/elements/weather/weather_forecast_card.dart';
import 'package:truotlo/src/page/home/elements/landslide/landslide_forecast_card.dart'; // New import
import 'elements/weather/weather_service.dart';
import '../../data/weather/location_data.dart';
import 'package:truotlo/src/config/weather.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final WeatherService weatherService = WeatherService(
    apiKey: WeatherConfig().apiKey,
    baseUrl: WeatherConfig().baseUrl,
  );

  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? forecast;
  late WeatherDistrict selectedDistrict;
  late Ward selectedWard;
  String? errorMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDistrict = districts.first;
    selectedWard = selectedDistrict.wards.first;
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    if (!mounted) return; // Kiểm tra xem widget còn mounted không

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final weatherData = await weatherService.getWeatherByCoordinates(
        selectedWard.latitude,
        selectedWard.longitude,
      );
      final forecastData = await weatherService.getForecastByCoordinates(
        selectedWard.latitude,
        selectedWard.longitude,
      );

      if (!mounted) {
        return; // Kiểm tra lại sau khi các hoạt động bất đồng bộ hoàn thành
      }

      setState(() {
        currentWeather = weatherData;
        forecast = forecastData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return; // Kiểm tra lại trước khi set state trong trường hợp lỗi
      }

      setState(() {
        errorMessage = 'Không thể tải dữ liệu thời tiết. Vui lòng thử lại sau.';
        isLoading = false;
      });
      print('Error fetching weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thời tiết',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWeatherData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                WeatherForecastCard(
                  currentWeather: currentWeather,
                  forecast: forecast,
                  selectedDistrict: selectedDistrict,
                  selectedWard: selectedWard,
                  isLoading: isLoading,
                  districts: districts,
                  onDistrictChanged: (WeatherDistrict? newDistrict) {
                    if (newDistrict != null) {
                      setState(() {
                        selectedDistrict = newDistrict;
                        selectedWard = newDistrict.wards.first;
                      });
                      _fetchWeatherData();
                    }
                  },
                  onWardChanged: (Ward? newWard) {
                    if (newWard != null) {
                      setState(() {
                        selectedWard = newWard;
                      });
                      _fetchWeatherData();
                    }
                  },
                  onRetry: _fetchWeatherData,
                ),
                const SizedBox(height: 16),
                const DisasterWarningCard(),
                const SizedBox(height: 16),
                const LandslideForecastCard(), // New widget for landslide forecast
              ],
            ),
          ),
        ),
      ),
    );
  }
}
