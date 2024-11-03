import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DailyForecastPoint {
  final String maDiem;
  final String viTri;
  final Map<String, dynamic> toaDo;
  final Map<String, dynamic> diaGioi;
  final List<Map<String, dynamic>> duBao;

  DailyForecastPoint({
    required this.maDiem,
    required this.viTri,
    required this.toaDo,
    required this.diaGioi,
    required this.duBao,
  });

  factory DailyForecastPoint.fromJson(Map<String, dynamic> json) {
    return DailyForecastPoint(
      maDiem: json['ma_diem'] ?? '',
      viTri: json['vi_tri'] ?? '',
      toaDo: json['toa_do'] ?? {},
      diaGioi: json['dia_gioi'] ?? {},
      duBao: List<Map<String, dynamic>>.from(json['du_bao'] ?? []),
    );
  }
}

class LandslideForecastCard extends StatefulWidget {
  const LandslideForecastCard({super.key});

  @override
  LandslideForecastCardState createState() => LandslideForecastCardState();
}

class LandslideForecastCardState extends State<LandslideForecastCard> {
  bool _showHourlyForecast = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _hourlyForecastPoints = [];
  List<DailyForecastPoint> _dailyForecastPoints = [];
  String _lastUpdateTime = '';
  Map<int, int> _riskLevelCounts = {
    5: 0, // Rất cao
    4: 0, // Cao
    3: 0, // Trung bình
    2: 0, // Thấp
    1: 0, // Rất thấp
  };

  static const String _dailyApiUrl = 'http://truotlobinhdinh.girc.edu.vn/api/forecasts/current';
  static const String _hourlyApiUrl = 'http://truotlobinhdinh.girc.edu.vn/api/forecast-points';

  @override
  void initState() {
    super.initState();
    _loadForecastData();
  }

  Future<void> _loadForecastData() async {
    setState(() => _isLoading = true);
    try {
      if (_showHourlyForecast) {
        await _loadHourlyForecast();
      } else {
        await _loadDailyForecast();
      }
    } catch (e) {
      print('Lỗi khi tải dữ liệu dự báo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  Future<void> _loadHourlyForecast() async {
    final response = await http.get(Uri.parse(_hourlyApiUrl));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == true && responseData['data'] != null) {
        setState(() {
          _hourlyForecastPoints = List<Map<String, dynamic>>.from(responseData['data']);
          _lastUpdateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        });
      }
    } else {
      throw Exception('Không thể tải dữ liệu dự báo theo giờ');
    }
  }

  Future<void> _loadDailyForecast() async {
    final response = await http.get(Uri.parse(_dailyApiUrl));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['thanh_cong'] == true && responseData['du_lieu'] != null) {
        setState(() {
          _dailyForecastPoints = List<DailyForecastPoint>.from(
            responseData['du_lieu'].map((x) => DailyForecastPoint.fromJson(x))
          );
          _lastUpdateTime = responseData['thoi_gian_cap_nhat'];
        });
        _updateRiskLevelCounts(_dailyForecastPoints);
      }
    } else {
      throw Exception('Không thể tải dữ liệu dự báo theo ngày');
    }
  }

  void _updateRiskLevelCounts(List<DailyForecastPoint> points) {
    Map<int, int> counts = {
      5: 0, // Rất cao
      4: 0, // Cao
      3: 0, // Trung bình
      2: 0, // Thấp
      1: 0, // Rất thấp
    };

    for (var point in points) {
      for (var forecast in point.duBao) {
        double risk = double.tryParse(forecast['nguy_co'].toString()) ?? 0;
        if (risk >= 5.0) counts[5] = (counts[5] ?? 0) + 1;
        else if (risk >= 4.0) counts[4] = (counts[4] ?? 0) + 1;
        else if (risk >= 3.0) counts[3] = (counts[3] ?? 0) + 1;
        else if (risk >= 2.0) counts[2] = (counts[2] ?? 0) + 1;
        else counts[1] = (counts[1] ?? 0) + 1;
      }
    }

    setState(() {
      _riskLevelCounts = counts;
    });
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
      return 'no_risk';
    }
  }

  List<String> _getForecastDates() {
    if (_dailyForecastPoints.isEmpty) return [];
    
    final forecastDates = <String>[];
    final dateFormat = DateFormat('dd/MM');
    
    // Lấy tháng hiện tại từ thời gian cập nhật
    final currentMonth = DateTime.parse(_lastUpdateTime);
    
    // Tìm ngày nhỏ nhất và lớn nhất trong dự báo
    int minDay = 999;
    int maxDay = 0;
    for (var point in _dailyForecastPoints) {
      for (var forecast in point.duBao) {
        final day = forecast['ngay'] as int;
        if (day < minDay) minDay = day;
        if (day > maxDay) maxDay = day;
      }
    }

    // Tạo danh sách ngày từ min đến max
    for (int i = minDay; i <= maxDay; i++) {
      final date = DateTime(currentMonth.year, currentMonth.month, i);
      forecastDates.add(dateFormat.format(date));
    }

    return forecastDates;
  }

  Widget _buildHourlyForecastTable() {
    if (_hourlyForecastPoints.isEmpty) {
      return const Center(child: Text('Không có dữ liệu dự báo theo giờ'));
    }

    // Lọc dữ liệu của giờ hiện tại
    final currentHour = DateTime.now().hour;
    final currentForecasts = _hourlyForecastPoints.where((point) {
      final createdAt = DateTime.tryParse(point['created_at'] ?? '');
      return createdAt?.hour == currentHour;
    }).toList();

    // Nhóm theo huyện
    Map<String, List<Map<String, dynamic>>> groupedByDistrict = {};
    for (var point in currentForecasts) {
      final district = point['huyen'] ?? 'Không xác định';
      if (!groupedByDistrict.containsKey(district)) {
        groupedByDistrict[district] = [];
      }
      groupedByDistrict[district]!.add(point);
    }

    if (groupedByDistrict.isEmpty) {
      return const Center(child: Text('Không có dữ liệu dự báo cho giờ hiện tại'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Table(
          border: TableBorder.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            buildTableRow(
              ['Huyện', 'Vị trí', 'Lũ quét', 'Trượt nông', 'Trượt lớn'],
              isHeader: true,
            ),
            ...groupedByDistrict.entries.expand((district) {
              return district.value.map((point) {
                return buildTableRow([
                  district.key,
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

  Widget _buildDailyForecastTable() {
    if (_dailyForecastPoints.isEmpty) {
      return const Center(child: Text('Không có dữ liệu dự báo theo ngày'));
    }

    final forecastDates = _getForecastDates();

    // Nhóm theo huyện
    Map<String, List<DailyForecastPoint>> groupedByDistrict = {};
    for (var point in _dailyForecastPoints) {
      String district = point.diaGioi['huyen'] ?? 'Không xác định';
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
          border: TableBorder.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            buildTableRow(
              ['Huyện', 'Vị trí', ...forecastDates],
              isHeader: true,
            ),
            ...groupedByDistrict.entries.expand((district) {
              return district.value.map((point) {
                final riskIcons = List<Widget>.filled(forecastDates.length, buildRiskIcon('no_risk'));
                
                for (var forecast in point.duBao) {
                  final day = forecast['ngay'] as int;
                  final currentMonth = DateTime.parse(_lastUpdateTime);
                  final startDay = currentMonth.day;
                  final index = day - startDay;
                  if (index >= 0 && index < riskIcons.length) {
                    riskIcons[index] = buildRiskIcon(
                      _getRiskLevel(forecast['nguy_co']?.toString() ?? '0')
                    );
                  }
                }

                return buildTableRow([
                  district.key,
                  point.viTri,
                  ...riskIcons,
                ]);
              }).toList();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        isSelected: [_showHourlyForecast, !_showHourlyForecast],
        selectedColor: Colors.white,
        fillColor: Colors.blue,
        onPressed: (int index) {
          setState(() {
_showHourlyForecast = index == 0;
            _loadForecastData();
          });
        },
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Theo giờ'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Theo ngày'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue,
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Thời tiết',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'DỰ BÁO LÚC: ${_formatDateTime(_lastUpdateTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: _buildToggleButtons()),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_showHourlyForecast)
                  _buildHourlyForecastTable()
                else
                  _buildDailyForecastTable(),
                const SizedBox(height: 16),
                buildLegend(context),
                const SizedBox(height: 8),
                const Text(
                  '(Thông tin dự báo chi tiết theo giờ đến cấp xã, liên hệ e-mail: quynhdtgeo@gmail.com hoặc contact@igevn.com)',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TableRow buildTableRow(List<dynamic> cells, {bool isHeader = false}) {
  return TableRow(
    decoration: BoxDecoration(
      color: isHeader ? Colors.grey[200] : null,
    ),
    children: cells.map((cell) => TableCell(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: cell is Widget
            ? Center(child: cell)
            : Text(
                cell.toString(),
                style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    )).toList(),
  );
}

Widget buildRiskIcon(String riskLevel) {
  switch (riskLevel) {
    case 'no_risk':
      return Image.asset('lib/assets/map/landslide_0.png',
          width: 18, height: 18);
    case 'very_low':
      return Image.asset('lib/assets/map/landslide_1.png',
          width: 18, height: 18);
    case 'low':
      return Image.asset('lib/assets/map/landslide_2.png',
          width: 18, height: 18);
    case 'medium':
      return Image.asset('lib/assets/map/landslide_3.png',
          width: 18, height: 18);
    case 'high':
      return Image.asset('lib/assets/map/landslide_4.png',
          width: 18, height: 18);
    case 'very_high':
      return Image.asset('lib/assets/map/landslide_5.png',
          width: 18, height: 18);
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
      _buildLegendItem(
          context, 'medium', 'TRUNG BÌNH', 'Nguy cơ từ 3 đến < 4'),
      _buildLegendItem(
          context, 'high', 'CAO', 'Nguy cơ từ 4 đến < 5',
          boldLevel: true),
      _buildLegendItem(
          context, 'very_high', 'RẤT CAO', 'Nguy cơ >= 5',
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
                    fontSize: 13,
                    color: boldLevel ? Colors.red : null,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}