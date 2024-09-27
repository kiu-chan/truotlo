import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:truotlo/src/data/weather/weather_district.dart';

class WeatherForecastCard extends StatelessWidget {
  final Map<String, dynamic>? currentWeather;
  final Map<String, dynamic>? forecast;
  final WeatherDistrict selectedDistrict;
  final Ward selectedWard;
  final bool isLoading;
  final List<WeatherDistrict> districts;
  final Function(WeatherDistrict?) onDistrictChanged;
  final Function(Ward?) onWardChanged;
  final VoidCallback onRetry;

  const WeatherForecastCard({
    super.key,
    required this.currentWeather,
    required this.forecast,
    required this.selectedDistrict,
    required this.selectedWard,
    required this.isLoading,
    required this.districts,
    required this.onDistrictChanged,
    required this.onWardChanged,
    required this.onRetry,
  });

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
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButton<WeatherDistrict>(
              value: selectedDistrict,
              isExpanded: true,
              items: districts.map((WeatherDistrict district) {
                return DropdownMenuItem<WeatherDistrict>(
                  value: district,
                  child: Text(district.name,
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onDistrictChanged,
            ),
            const SizedBox(height: 8),
            DropdownButton<Ward>(
              value: selectedWard,
              isExpanded: true,
              items: selectedDistrict.wards.map((Ward ward) {
                return DropdownMenuItem<Ward>(
                  value: ward,
                  child: Text(ward.name,
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onWardChanged,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white))
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
    final iconPath = currentWeather!['iconPath'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời tiết hiện tại',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          '${selectedWard.name}, ${selectedDistrict.name}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Image.asset(iconPath, width: 48, height: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temp.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
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
      final dailyForecast = forecastList[i * 8];
      final temp = dailyForecast['main']['temp'];
      final date =
          DateTime.fromMillisecondsSinceEpoch(dailyForecast['dt'] * 1000);
      final dayName = DateFormat('E').format(date);
      final iconCode = dailyForecast['weather'][0]['icon'];
      final iconPath = 'lib/assets/clouds/$iconCode.png';

      forecastWidgets.add(
        Column(
          children: [
            Text(dayName, style: const TextStyle(color: Colors.white)),
            Image.asset(iconPath, width: 32, height: 32),
            Text('${temp.toStringAsFixed(1)}°',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return forecastWidgets;
  }
}
