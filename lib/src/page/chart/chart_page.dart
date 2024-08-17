import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:truotlo/src/data/landslide_data.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  ChartPageState createState() => ChartPageState();
}

class ChartPageState extends State<ChartPage> {
  final LandslideDataService _dataService = LandslideDataService();
  List<LandslideDataModel> _data = [];
  bool _isLoading = true;
  String _error = '';
  int selected = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await _dataService.fetchLandslideData();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  List<LineChartBarData> _getLineBarsData() {
    List<LineChartBarData> lineBars = _data.map((d) {
      return LineChartBarData(
        spots: [
          FlSpot(d.calculatedTiltAOr1, -6),
          FlSpot(d.calculatedTiltAOr2, -11),
          FlSpot(d.calculatedTiltAOr3, -16),
        ],
        isCurved: true,
        curveSmoothness: 0.35,
        color: Colors.primaries[_data.indexOf(d) % Colors.primaries.length],
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    // Thêm đường mặc định với các giá trị chính xác
    lineBars.add(
      LineChartBarData(
        spots: [
          const FlSpot(-0.001565, -6),
          const FlSpot(0.009616, -11),
          const FlSpot(0.000935, -16),
        ],
        isCurved: true,
        curveSmoothness: 0.35,
        color: Colors.black,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        dashArray: [5, 5], // Tạo đường đứt khúc
      ),
    );

    return lineBars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đo nghiêng, hướng Tây - Đông'),
      ),
      endDrawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: <Widget>[
          SizedBox(
            height: 120,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Tùy chỉnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.api),
            title: const Text('Biểu đồ'),
            subtitle: const Text('Biểu đồ mặc định'),
            children: <Widget>[
              RadioListTile<int>(
                title: const Text('Đo nghiêng, hướng Tây - Đông'),
                value: 0,
                groupValue: selected,
                onChanged: (value) {
                  setState(() {
                    selected = value!;
                    // widget.onClick(value);
                  });
                },
              ),
            ],
          ),
        ]),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đo nghiêng, hướng Tây - Đông',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AspectRatio(
                            aspectRatio: 1.5,
                            child: LineChart(
                              LineChartData(
                                lineBarsData: _getLineBarsData(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        return Text(value.toStringAsFixed(4));
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        return Text(value.toStringAsFixed(0));
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: true),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Chú thích:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ..._data.asMap().entries.map((entry) {
                            int index = entry.key;
                            Color color = Colors
                                .primaries[index % Colors.primaries.length];
                            return _buildLegendItem(color, 'Mẫu ${index + 1}');
                          }).toList(),
                          _buildLegendItem(Colors.black, 'Giá trị mặc định'),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
