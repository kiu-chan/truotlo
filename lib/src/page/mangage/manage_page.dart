import 'package:flutter/material.dart';
import 'package:truotlo/src/data/manage/forecast.dart';
import 'package:truotlo/src/data/manage/hourly_warning.dart';
import 'package:truotlo/src/data/manage/landslide_point.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  ManagePageState createState() => ManagePageState();
}

class ManagePageState extends State<ManagePage> {
  List<Forecast> forecasts = [
    Forecast(
      id: '1',
      name: 'Phiên dự báo 2024 - 6',
      location: 'Đà Nẵng',
      province: 'Đà Nẵng',
      district: 'Hải Châu',
      commune: 'Thanh Bình',
      days: [
        DayForecast(day: 1, riskLevel: 'Cao'),
        DayForecast(day: 2, riskLevel: 'Trung bình'),
        DayForecast(day: 3, riskLevel: 'Thấp'),
        DayForecast(day: 4, riskLevel: 'Thấp'),
        DayForecast(day: 5, riskLevel: 'Trung bình'),
      ],
    ),
    Forecast(
      id: '2',
      name: 'Phiên dự báo 2024 - 12',
      location: 'Hà Nội',
      province: 'Hà Nội',
      district: 'Ba Đình',
      commune: 'Kim Mã',
      days: [
        DayForecast(day: 1, riskLevel: 'Thấp'),
        DayForecast(day: 2, riskLevel: 'Thấp'),
        DayForecast(day: 3, riskLevel: 'Trung bình'),
        DayForecast(day: 4, riskLevel: 'Cao'),
        DayForecast(day: 5, riskLevel: 'Cao'),
      ],
    ),
  ];

  List<HourlyWarning> hourlyWarnings = [
    HourlyWarning(
      id: '1',
      hour: 2,
      day: 2,
      month: 2,
      year: 2032,
      location: 'Hà Nội',
      warningLevel: 'Nguy hiểm',
      description: 'Mưa lớn kèm gió giật mạnh',
    ),
    HourlyWarning(
      id: '2',
      hour: 15,
      day: 8,
      month: 3,
      year: 2024,
      location: 'Hồ Chí Minh',
      warningLevel: 'Cảnh báo',
      description: 'Nắng nóng gay gắt',
    ),
  ];

  List<LandslidePoint> landslidePoints = [
    LandslidePoint(
      id: '1',
      name: 'Núi Cấm (Cát Thành)',
      code: '7360',
      latitude: 13.7897,
      longitude: 109.1234,
    ),
    LandslidePoint(
      id: '2',
      name: 'Núi Gành (Cát Minh)',
      code: '7359',
      latitude: 13.8012,
      longitude: 109.2345,
    ),
    LandslidePoint(
      id: '3',
      name: 'Đèo Vĩnh Hội (Cát Hải)',
      code: '7362',
      latitude: 13.8123,
      longitude: 109.3456,
    ),
    LandslidePoint(
      id: '4',
      name: 'Đèo An Khê',
      code: '7358',
      latitude: 13.8234,
      longitude: 109.4567,
    ),
    LandslidePoint(
      id: '5',
      name: 'Đèo Chánh Oai (Cát Hải)',
      code: '7361',
      latitude: 13.8345,
      longitude: 109.5678,
    ),
  ];

  bool showForecasts = true;
  bool showHourlyWarnings = false;
  bool showLandslidePoints = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang cập nhật dữ liệu...')),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: buildDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng thêm mới đang được phát triển')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getAppBarTitle() {
    if (showForecasts) return 'Dự báo 5 ngày';
    if (showHourlyWarnings) return 'Cảnh báo theo giờ';
    if (showLandslidePoints) return 'Danh sách các điểm trượt lở';
    return 'Quản lý';
  }

  Widget _buildBody() {
    if (showForecasts) return buildForecastList();
    if (showHourlyWarnings) return buildHourlyWarningList();
    if (showLandslidePoints) return buildLandslidePointList();
    return const Center(child: Text('Chọn một danh mục để xem'));
  }

  Widget buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu Quản lý',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Dự báo 5 ngày'),
            onTap: () => _changeView(forecasts: true),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Cảnh báo theo giờ'),
            onTap: () => _changeView(hourlyWarnings: true),
          ),
          ListTile(
            leading: const Icon(Icons.landscape),
            title: const Text('Điểm trượt lở'),
            onTap: () => _changeView(landslidePoints: true),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _changeView({bool forecasts = false, bool hourlyWarnings = false, bool landslidePoints = false}) {
    setState(() {
      showForecasts = forecasts;
      showHourlyWarnings = hourlyWarnings;
      showLandslidePoints = landslidePoints;
    });
    Navigator.pop(context);
  }

  Widget buildForecastList() {
    return ListView.builder(
      itemCount: forecasts.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(forecasts[index].name),
            subtitle: Text(forecasts[index].location),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () => showForecastDetails(forecasts[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteForecast(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildHourlyWarningList() {
    return ListView.builder(
      itemCount: hourlyWarnings.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(hourlyWarnings[index].formattedDate),
            subtitle: Text(hourlyWarnings[index].location),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () => showHourlyWarningDetails(hourlyWarnings[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteHourlyWarning(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildLandslidePointList() {
    return ListView.builder(
      itemCount: landslidePoints.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(landslidePoints[index].name),
            subtitle: Text('Mã: ${landslidePoints[index].code}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () => showLandslidePointDetails(landslidePoints[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteLandslidePoint(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showForecastDetails(Forecast forecast) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(forecast.name),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vị trí: ${forecast.location}'),
                Text('Tỉnh: ${forecast.province}'),
                Text('Huyện: ${forecast.district}'),
                Text('Xã: ${forecast.commune}'),
                const SizedBox(height: 10),
                const Text('Dự báo 5 ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...forecast.days.map((day) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text('Ngày ${day.day}: ${day.riskLevel}'),
                )),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showHourlyWarningDetails(HourlyWarning warning) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cảnh báo ${warning.formattedDate}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vị trí: ${warning.location}'),
                Text('Mức độ cảnh báo: ${warning.warningLevel}'),
                Text('Mô tả: ${warning.description}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showLandslidePointDetails(LandslidePoint point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(point.name),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Mã: ${point.code}'),
                Text('Vĩ độ: ${point.latitude}'),
                Text('Kinh độ: ${point.longitude}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void deleteForecast(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa dự báo này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa'),
              onPressed: () {
                setState(() {
                  forecasts.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa dự báo')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void deleteHourlyWarning(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa cảnh báo này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa'),
              onPressed: () {
                setState(() {
                  hourlyWarnings.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa cảnh báo')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void deleteLandslidePoint(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa điểm trượt lở này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Xóa'),
              onPressed: () {
                setState(() {
                  landslidePoints.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa điểm trượt lở')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}