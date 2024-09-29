import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:truotlo/src/database/landslide.dart';

class DisasterWarningCard extends StatefulWidget {
  const DisasterWarningCard({super.key});

  @override
  DisasterWarningCardState createState() => DisasterWarningCardState();
}

class DisasterWarningCardState extends State<DisasterWarningCard> {
  final LandslideDatabase _forecastService = LandslideDatabase();
  Map<String, int> _counts = {};
  bool _isLoading = true;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateCurrentTime();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm dd/MM').format(now);
  }

  Future<void> _loadData() async {
    try {
      final counts = await _forecastService.getForecastCounts();
      setState(() {
        _counts = counts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading forecast data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DỰ BÁO LÚC: $_currentTime',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else ...[
              WarningRow(
                icon: Icons.warning,
                text: 'Số điểm nguy trượt lở đất đá RẤT CAO',
                value: _counts['Rất cao']?.toString() ?? '0',
              ),
              WarningRow(
                icon: Icons.warning,
                text: 'Số điểm nguy trượt lở đất đá CAO',
                value: _counts['Cao']?.toString() ?? '0',
              ),
              WarningRow(
                icon: Icons.warning,
                text: 'Số điểm nguy trượt lở đất đá TRUNG BÌNH',
                value: _counts['Trung bình']?.toString() ?? '0',
              ),
              WarningRow(
                icon: Icons.warning,
                text: 'Số điểm nguy trượt lở đất đá THẤP',
                value: _counts['Thấp']?.toString() ?? '0',
              ),
              WarningRow(
                icon: Icons.warning,
                text: 'Số điểm nguy trượt lở đất đá RẤT THẤP',
                value: _counts['Rất thấp']?.toString() ?? '0',
              ),
            ],
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

  const WarningRow({
    Key? key,
    required this.icon,
    required this.text,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
