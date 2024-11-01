class WeatherDistrict {
  final String name;
  final List<Ward> wards;

  WeatherDistrict(this.name, this.wards);
}

class Ward {
  final String name;
  final double latitude;
  final double longitude;

  Ward(this.name, this.latitude, this.longitude);
}