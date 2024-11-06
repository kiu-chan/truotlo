import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DisasterWarningCard extends StatefulWidget {
  const DisasterWarningCard({super.key});

  @override
  DisasterWarningCardState createState() => DisasterWarningCardState();
}

class DisasterWarningCardState extends State<DisasterWarningCard> {
  bool _isLoading = true;
  bool _hasData = false;
  Map<String, int> _riskLevelCounts = {
    '5': 0, // Rất cao (>=5)
    '4': 0, // Cao (>=4)
    '3': 0, // Trung bình (>=3)
    '2': 0, // Thấp (>=2)
    '1': 0, // Rất thấp (<2)
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupPeriodicUpdate();
  }

  void _setupPeriodicUpdate() {
    // Cập nhật mỗi phút
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  String _getCurrentTime() {
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  }

Future<void> _loadData() async {
  if (!mounted) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse('http://truotlobinhdinh.girc.edu.vn/api/forecast-points')
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final Map<String, dynamic> data = jsonResponse['data'];
        if (data.isEmpty) {
          setState(() {
            _hasData = false;
            _isLoading = false;
          });
          return;
        }

        final String currentHourKey = data.keys.first;
        final List<dynamic> hourlyPoints = data[currentHourKey] ?? [];
        
        if (hourlyPoints.isEmpty) {
          setState(() {
            _hasData = false;
            _isLoading = false;
          });
          return;
        }
        
        Map<String, int> counts = {
          '5': 0,
          '4': 0,
          '3': 0,
          '2': 0,
          '1': 0,
        };

        bool hasNonZeroRisk = false;  // Thêm biến để kiểm tra có điểm nào có nguy cơ > 0

        for (var point in hourlyPoints) {
          final nguyCoTruotNong = double.tryParse(point['nguy_co_truot_nong']?.toString() ?? '0') ?? 0;
          
          if (nguyCoTruotNong > 0) {
            hasNonZeroRisk = true;  // Đánh dấu có ít nhất 1 điểm có nguy cơ > 0
            
            if (nguyCoTruotNong >= 5) {
              counts['5'] = (counts['5'] ?? 0) + 1;
            } else if (nguyCoTruotNong >= 4) {
              counts['4'] = (counts['4'] ?? 0) + 1;
            } else if (nguyCoTruotNong >= 3) {
              counts['3'] = (counts['3'] ?? 0) + 1;
            } else if (nguyCoTruotNong >= 2) {
              counts['2'] = (counts['2'] ?? 0) + 1;
            } else {
              counts['1'] = (counts['1'] ?? 0) + 1;
            }
          }
        }

        if (mounted) {
          setState(() {
            _riskLevelCounts = counts;
            // Chỉ set _hasData = true nếu có ít nhất 1 điểm có nguy cơ > 0
            _hasData = hasNonZeroRisk;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasData = false;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _hasData = false;
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error loading forecast data: $e');
    if (mounted) {
      setState(() {
        _hasData = false;
        _isLoading = false;
      });
    }
  }
}

  Widget _buildRiskLevelRow(String level, int count) {
    String riskText;
    Color riskColor;
    String description;

    switch (level) {
      case '5':
        riskText = 'RẤT CAO';
        riskColor = Colors.red;
        description = 'Trượt lở trên diện rộng, phát sinh trượt lở quy mô lớn';
        break;
      case '4':
        riskText = 'CAO';
        riskColor = Colors.orange;
        description = 'Có thể phát sinh trượt lở quy mô lớn';
        break;
      case '3':
        riskText = 'TRUNG BÌNH';
        riskColor = Colors.yellow.shade700;
        description = 'Chủ yếu trượt lở có quy mô nhỏ';
        break;
      case '2':
        riskText = 'THẤP';
        riskColor = Colors.blue;
        description = 'Trượt lở có thể phát sinh cục bộ';
        break;
      default:
        riskText = 'RẤT THẤP';
        riskColor = Colors.green;
        description = 'Ít có khả năng xảy ra trượt lở';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: riskColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
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
            color: Colors.red,
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Cảnh báo trượt nông',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                      Expanded(
                        child: Text(
                          'DỰ BÁO LÚC: ${_getCurrentTime()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (!_hasData)
                  const Center(
                    child: Text(
                      'Không có nguy cơ trượt nông',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ..._riskLevelCounts.entries
                      .where((e) => e.value > 0)
                      .map((e) => _buildRiskLevelRow(e.key, e.value))
                      .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}