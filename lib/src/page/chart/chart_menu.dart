import 'package:flutter/material.dart';

class ChartMenu extends StatelessWidget {
  final List<String> chartNames;
  final String selectedChart;
  final bool showLegend;
  final Function(String) onChartTypeChanged;
  final Function(bool) onShowLegendChanged;

  const ChartMenu({
    super.key,
    required this.chartNames,
    required this.selectedChart,
    required this.showLegend,
    required this.onChartTypeChanged,
    required this.onShowLegendChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
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
            subtitle: Text('Biểu đồ hiện tại: $selectedChart'),
            children: chartNames.map((chartName) {
              return RadioListTile<String>(
                title: Text(chartName),
                value: chartName,
                groupValue: selectedChart,
                onChanged: (value) {
                  onChartTypeChanged(value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          SwitchListTile(
            title: const Text('Hiển thị chú thích'),
            value: showLegend,
            onChanged: (bool value) {
              onShowLegendChanged(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}