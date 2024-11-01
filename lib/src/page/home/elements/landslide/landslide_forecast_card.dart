import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandslideForecastCard extends StatefulWidget {
  const LandslideForecastCard({super.key});

  @override
  LandslideForecastCardState createState() => LandslideForecastCardState();
}

class LandslideForecastCardState extends State<LandslideForecastCard> {
  bool _showHourlyForecast = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _forecastPoints = [];
  late String _currentTimestamp;
  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    _updateTimestamp();
    _loadForecastData();
  }

  void _updateTimestamp() {
    _currentDateTime = DateTime.now();
    _currentTimestamp = DateFormat('HH:mm dd/MM/yyyy').format(_currentDateTime);
  }

  Future<void> _loadForecastData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://truotlobinhdinh.girc.edu.vn/api/forecast-points')
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _forecastPoints = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Không thể tải dữ liệu dự báo');
      }
    } catch (e) {
      print('Lỗi khi tải dữ liệu dự báo: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getCurrentHourForecasts() {
    final currentHour = DateFormat('yyyy-MM-dd HH').format(_currentDateTime);
    return _forecastPoints.where((point) {
      final createdAt = DateTime.tryParse(point['created_at'] ?? '');
      if (createdAt == null) return false;
      
      final forecastHour = DateFormat('yyyy-MM-dd HH').format(createdAt);
      return forecastHour == currentHour;
    }).toList();
  }

  String _getRiskLevel(String value) {
    try {
      final double risk = double.parse(value);
      if (risk >= 5.0) return 'very_high';
      if (risk >= 4.0) return 'high';
      if (risk >= 3.0) return 'medium';
      if (risk >= 2.0) return 'low';
      return 'very_low';
    } catch (e) {
      print('Lỗi khi chuyển đổi giá trị nguy cơ: $e');
      return 'no_risk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showHourlyForecast
                  ? 'THÔNG TIN DỰ BÁO TRƯỢT LỞ THEO GIỜ'
                  : 'THÔNG TIN DỰ BÁO TRƯỢT LỞ THEO NGÀY',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Cập nhật lúc: $_currentTimestamp'),
            const Text(
                '(Thông tin dự báo chi tiết theo giờ đến cấp xã, liên hệ e-mail: quynhdtgeo@gmail.com hoặc contact@igevn.com)'),
            const SizedBox(height: 16),
            _buildToggleButtons(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_forecastPoints.isEmpty)
              const Center(child: Text('Không có dữ liệu dự báo'))
            else
              _showHourlyForecast
                  ? _buildHourlyForecastTable()
                  : _buildDailyForecastTable(),
            const SizedBox(height: 16),
            buildLegend(context),
            const SizedBox(height: 8),
            const Text(
                'Các huyện không có trong danh sách không có nguy cơ trượt lở',
                style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecastTable() {
    final currentHourForecasts = _getCurrentHourForecasts();

    if (currentHourForecasts.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu dự báo cho giờ hiện tại'),
      );
    }

    // Nhóm dữ liệu theo huyện
    Map<String, List<Map<String, dynamic>>> groupedByDistrict = {};
    for (var point in currentHourForecasts) {
      String district = point['huyen'] ?? 'Không xác định';
      if (!groupedByDistrict.containsKey(district)) {
        groupedByDistrict[district] = [];
      }
      groupedByDistrict[district]!.add(point);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Table(
          border: TableBorder.all(),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            buildTableRow(
              ['Huyện', 'Vị trí', 'Lũ quét', 'Trượt nông', 'Trượt lớn'],
              isHeader: true,
            ),
            ...groupedByDistrict.entries.expand((district) {
              return district.value.map((point) {
                return buildTableRow([
                  point['huyen'] ?? '',
                  point['vi_tri'] ?? '',
                  buildRiskIcon(_getRiskLevel(point['nguy_co_lu_quet']?.toString() ?? '0')),
                  buildRiskIcon(_getRiskLevel(point['nguy_co_truot_nong']?.toString() ?? '0')),
                  buildRiskIcon(_getRiskLevel(point['nguy_co_truot_lon']?.toString() ?? '0')),
                ]);
              }).toList();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ToggleButtons(
        isSelected: [_showHourlyForecast, !_showHourlyForecast],
        onPressed: (int index) {
          setState(() {
            _showHourlyForecast = index == 0;
            _updateTimestamp();
            _loadForecastData();
          });
        },
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Theo giờ', style: TextStyle(color: Colors.blue)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Theo ngày', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecastTable() {
    final dateFormat = DateFormat('dd/MM');
    final today = DateTime.now();
    final dateHeaders = List.generate(
        5, (index) => dateFormat.format(today.add(Duration(days: index))));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Table(
          border: TableBorder.all(),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            buildTableRow(['Huyện', ...dateHeaders], isHeader: true),
            ...groupedDailyForecast(dateHeaders.length),
          ],
        ),
      ),
    );
  }

  List<TableRow> groupedDailyForecast(int days) {
    Map<String, List<Map<String, dynamic>>> groupedByDistrict = {};
    for (var point in _forecastPoints) {
      String district = point['huyen'] ?? 'Không xác định';
      if (!groupedByDistrict.containsKey(district)) {
        groupedByDistrict[district] = [];
      }
      groupedByDistrict[district]!.add(point);
    }

    return groupedByDistrict.entries.map((entry) {
      List<dynamic> rowData = [entry.key];
      // Add placeholder risk icons for each day
      for (int i = 0; i < days; i++) {
        rowData.add(buildRiskIcon('no_risk'));
      }
      return buildTableRow(rowData);
    }).toList();
  }
}

TableRow buildTableRow(List<dynamic> cells, {bool isHeader = false}) {
  return TableRow(
    decoration: BoxDecoration(
      color: isHeader ? Colors.grey[200] : null,
    ),
    children: cells
        .map((cell) => TableCell(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: cell is Widget
                    ? Center(child: cell)
                    : Text(
                        cell.toString(),
                        style: TextStyle(
                          fontWeight:
                              isHeader ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ))
        .toList(),
  );
}

Widget buildRiskIcon(String riskLevel) {
  switch (riskLevel) {
    case 'no_risk':
      return Image.asset('lib/assets/map/landslide_0.png',
          width: 16, height: 16);
    case 'very_low':
      return Image.asset('lib/assets/map/landslide_1.png',
          width: 16, height: 16);
    case 'low':
      return Image.asset('lib/assets/map/landslide_2.png',
          width: 16, height: 16);
    case 'medium':
      return Image.asset('lib/assets/map/landslide_3.png',
          width: 16, height: 16);
    case 'high':
      return Image.asset('lib/assets/map/landslide_4.png',
          width: 16, height: 16);
    case 'very_high':
      return Image.asset('lib/assets/map/landslide_5.png',
          width: 16, height: 16);
    default:
      return const SizedBox.shrink();
  }
}

Widget buildLegend(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Chú giải các cấp nguy cơ trượt lở:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildLegendItem(
          context, 'no_risk', 'KHÔNG CÓ', 'Không có nguy cơ trượt lở'),
      _buildLegendItem(
          context, 'very_low', 'RẤT THẤP', 'Nguy cơ < 2'),
      _buildLegendItem(
          context, 'low', 'THẤP', 'Nguy cơ từ 2 đến < 3'),
      _buildLegendItem(context, 'medium', 'TRUNG BÌNH',
          'Nguy cơ từ 3 đến < 4. Cảnh báo phát sinh trượt lở cục bộ, chủ yếu trượt lở có quy mô nhỏ.'),
      _buildLegendItem(context, 'high', 'CAO',
          'Nguy cơ từ 4 đến < 5. Cảnh báo nguy cơ trượt lở trên diện rộng.',
          boldLevel: true),
      _buildLegendItem(context, 'very_high', 'RẤT CAO',
          'Nguy cơ >= 5. Trượt lở trên diện rộng, phát sinh trượt lở quy mô lớn.',
          boldLevel: true),
    ],
  );
}

Widget _buildLegendItem(
    BuildContext context, String riskLevel, String level, String description,
    {bool boldLevel = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRiskIcon(riskLevel),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                    text: '$level: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: boldLevel ? Colors.red : null,
                    )),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}