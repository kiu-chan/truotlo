import 'package:flutter/material.dart';
import 'package:truotlo/src/data/home/weather/weather_district.dart';
import 'package:truotlo/src/page/home/elements/reference_detail_page.dart';
import 'package:truotlo/src/page/home/elements/warning.dart';
import 'package:truotlo/src/page/home/elements/weather/weather_forecast_card.dart';
import 'package:truotlo/src/page/home/elements/landslide/landslide_forecast_card.dart';
import 'package:truotlo/src/page/home/elements/weather/weather_service.dart';
import 'package:truotlo/src/data/home/weather/location_data.dart';
import 'package:truotlo/src/config/weather.dart';
import 'package:truotlo/src/database/home.dart';
import 'package:truotlo/src/config/api.dart';

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
  final HomeDatabase homeDatabase = HomeDatabase();
  final ApiConfig apiConfig = ApiConfig();

  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? forecast;
  late WeatherDistrict selectedDistrict;
  late Ward selectedWard;
  String? errorMessage;
  bool isLoading = false;
  List<dynamic> references = [];

  @override
  void initState() {
    super.initState();
    selectedDistrict = districts.first;
    selectedWard = selectedDistrict.wards.first;
    _fetchWeatherData();
    _fetchReferences();
  }

  Future<void> _fetchWeatherData() async {
    if (!mounted) return;

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

      if (!mounted) return;

      setState(() {
        currentWeather = weatherData;
        forecast = forecastData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Không thể tải dữ liệu thời tiết. Vui lòng thử lại sau.';
        isLoading = false;
      });
      print('Error fetching weather data: $e');
    }
  }

  Future<void> _fetchReferences() async {
    try {
      final fetchedReferences = await homeDatabase.fetchReferences();
      if (mounted) {
        setState(() {
          references = fetchedReferences;
        });
      }
    } catch (e) {
      print('Error fetching references: $e');
    }
  }

  Future<void> _onReferenceClicked(int id) async {
    try {
      await homeDatabase.incrementViews(id);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReferenceDetailPage(id: id),
        ),
      );
      // Cập nhật lại danh sách tài liệu tham khảo sau khi quay lại từ trang chi tiết
      await _fetchReferences();
    } catch (e) {
      print('Error handling reference click: $e');
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
        onRefresh: () async {
          await _fetchWeatherData();
          await _fetchReferences();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const LandslideForecastCard(),
                const SizedBox(height: 16),
                const Text(
                  'Tài liệu tham khảo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: references.length,
                  itemBuilder: (context, index) {
                    final reference = references[index];
                    final imageUrl = '${apiConfig.getImgUrl()}/${reference['file_path']}';
                    return Card(
                      child: ListTile(
                        leading: Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $imageUrl');
                            return const Icon(Icons.error);
                          },
                        ),
                        title: Text(reference['title']),
                        subtitle: Text(
                          'Ngày đăng: ${reference['published_at']}\n'
                          'Số người xem: ${reference['views']}',
                        ),
                        onTap: () => _onReferenceClicked(reference['id']),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}