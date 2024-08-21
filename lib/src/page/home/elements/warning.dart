import 'package:flutter/material.dart';

class DisasterWarningCard extends StatelessWidget {
  const DisasterWarningCard({super.key});

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

  const WarningRow({super.key, required this.icon, required this.text, required this.value});

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