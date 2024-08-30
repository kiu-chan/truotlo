import 'package:flutter/material.dart';
import 'landslide_forecast_utils.dart';

class LandslideForecastCard extends StatefulWidget {
  const LandslideForecastCard({super.key});

  @override
  LandslideForecastCardState createState() => LandslideForecastCardState();
}

class LandslideForecastCardState extends State<LandslideForecastCard> {
  bool _showHourlyForecast = true;

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
            const Text('Cập nhật lúc: 15:00 30/08/2024'),
            const Text('(Thông tin dự báo chi tiết theo giờ đến cấp xã, liên hệ e-mail: quynhdtgeo@gmail.com hoặc contact@igevn.com)'),
            const SizedBox(height: 16),
            _buildToggleButtons(),
            const SizedBox(height: 16),
            _showHourlyForecast ? _buildHourlyForecastTable() : _buildDailyForecastTable(),
            const SizedBox(height: 16),
            _showHourlyForecast ? buildHourlyLegend(context) : buildDailyLegend(context),
            const SizedBox(height: 8),
            const Text('Các huyện không có trong danh sách không có nguy cơ trượt lở', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return ToggleButtons(
      isSelected: [_showHourlyForecast, !_showHourlyForecast],
      onPressed: (int index) {
        setState(() {
          _showHourlyForecast = index == 0;
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
    );
  }

  Widget _buildHourlyForecastTable() {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
        6: FlexColumnWidth(1),
      },
      children: [
        buildTableRow(['STT', 'Tỉnh', 'Huyện', 'Vị trí', 'Lũ quét', 'Trượt nông', 'Trượt lớn'], isHeader: true),
        buildTableRow(['1', 'Bình Định', 'An Lão', 'Đá Cạnh', buildRiskIcon('no_risk'), buildRiskIcon('no_risk'), buildRiskIcon('very_high')]),
        buildTableRow(['2', 'Bình Định8', 'An Lão8', 'Đá Cạnh8', buildRiskIcon('no_risk'), buildRiskIcon('no_risk'), buildRiskIcon('very_high')]),
        buildTableRow(['3', 'Bình Định9', 'An Lão9', 'Cống Chào9', buildRiskIcon('no_risk'), buildRiskIcon('no_risk'), buildRiskIcon('very_high')]),
        buildTableRow(['4', 'Bình Định30', 'An Lão30', 'Đá Cạnh30', buildRiskIcon('no_risk'), buildRiskIcon('no_risk'), buildRiskIcon('very_high')]),
        buildTableRow(['5', 'Bình Định31', 'An Lão31', 'Đá Cạnh31', buildRiskIcon('no_risk'), buildRiskIcon('no_risk'), buildRiskIcon('very_high')]),
        buildTableRow(['6', 'Bình Định32', 'An Lão32', 'Đá Cạnh32', buildRiskIcon('no_risk'), buildRiskIcon('no_risk'), buildRiskIcon('very_high')]),
      ],
    );
  }

  Widget _buildDailyForecastTable() {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
        6: FlexColumnWidth(1),
      },
      children: [
        buildTableRow(['TT', 'Huyện', '26/08', '27/08', '28/08', '29/08', '30/08'], isHeader: true),
        buildTableRow(['1', 'An Lão', buildColorDot(0), buildColorDot(0), buildColorDot(0), buildColorDot(0), buildColorDot(0)]),
        buildTableRow(['2', 'An Lão1', buildColorDot(0), buildColorDot(0), buildColorDot(0), buildColorDot(0), buildColorDot(0)]),
        buildTableRow(['3', 'An Lão12', buildColorDot(0), buildColorDot(0), buildColorDot(0), buildColorDot(0), buildColorDot(0)]),
      ],
    );
  }
}