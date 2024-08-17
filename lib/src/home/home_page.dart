import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'weather_service.dart';
import 'location_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherService weatherService = WeatherService(
    apiKey: '1e7707a859e64a0d482be8303bce2c4d',
    baseUrl: 'https://api.openweathermap.org/data/2.5',
  );

  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? forecast;
  late District selectedDistrict;
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
      setState(() {
        currentWeather = weatherData;
        forecast = forecastData;
        isLoading = false;
      });
    } catch (e) {
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
        title: const Text('Thời tiết'),
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
                  onDistrictChanged: (District? newDistrict) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherForecastCard extends StatelessWidget {
  final Map<String, dynamic>? currentWeather;
  final Map<String, dynamic>? forecast;
  final District selectedDistrict;
  final Ward selectedWard;
  final bool isLoading;
  final List<District> districts;
  final Function(District?) onDistrictChanged;
  final Function(Ward?) onWardChanged;
  final VoidCallback onRetry;

  const WeatherForecastCard({
    Key? key,
    required this.currentWeather,
    required this.forecast,
    required this.selectedDistrict,
    required this.selectedWard,
    required this.isLoading,
    required this.districts,
    required this.onDistrictChanged,
    required this.onWardChanged,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DỰ BÁO THỜI TIẾT (THEO OPENWEATHERMAP)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<District>(
                    value: selectedDistrict,
                    items: districts.map((District district) {
                      return DropdownMenuItem<District>(
                        value: district,
                        child: Text(district.name, style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: onDistrictChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<Ward>(
                    value: selectedWard,
                    items: selectedDistrict.wards.map((Ward ward) {
                      return DropdownMenuItem<Ward>(
                        value: ward,
                        child: Text(ward.name, style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: onWardChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (currentWeather == null || forecast == null)
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Không thể tải dữ liệu thời tiết',
                      style: TextStyle(color: Colors.white),
                    ),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else
              _buildWeatherInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final temp = currentWeather!['main']['temp'];
    final humidity = currentWeather!['main']['humidity'];
    final windSpeed = currentWeather!['wind']['speed'];
    final description = currentWeather!['weather'][0]['description'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời tiết hiện tại',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          '${selectedWard.name}, ${selectedDistrict.name}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.cloud, color: Colors.white, size: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temp.toStringAsFixed(1)}°C',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Độ ẩm: $humidity%',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Gió: ${windSpeed.toStringAsFixed(1)} m/s',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildForecastDays(),
        ),
      ],
    );
  }

  List<Widget> _buildForecastDays() {
    final List<Widget> forecastWidgets = [];
    final List<dynamic> forecastList = forecast!['list'];

    for (int i = 0; i < 5; i++) {
      final dailyForecast = forecastList[i * 8]; // Get forecast for every 24 hours
      final temp = dailyForecast['main']['temp'];
      final date = DateTime.fromMillisecondsSinceEpoch(dailyForecast['dt'] * 1000);
      final dayName = DateFormat('E').format(date);

      forecastWidgets.add(
        Column(
          children: [
            Text(dayName, style: const TextStyle(color: Colors.white)),
            const Icon(Icons.cloud, color: Colors.white),
            Text('${temp.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return forecastWidgets;
  }
}

class DisasterWarningCard extends StatelessWidget {
  const DisasterWarningCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Colors.blue,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DỰ BÁO LÚC: 08:26 NGÀY 17/08',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            WarningRow(icon: Icons.warning, text: 'Số điểm nguy cơ sạt lở', value: '0'),
            WarningRow(icon: Icons.warning, text: 'Số công trình có nguy cơ bị thiệt hại', value: '0'),
            WarningRow(icon: Icons.warning, text: 'Số người có nguy cơ bị ảnh hưởng', value: '0'),
            WarningRow(icon: Icons.warning, text: 'Diện tích nông nghiệp bị thiệt hại', value: '0'),
          ],
        ),
      ),
    );
  }
}

class WarningRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String value;

  const WarningRow({Key? key, required this.icon, required this.text, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}