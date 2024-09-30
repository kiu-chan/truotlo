import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LandslideForecastCard extends StatefulWidget {
  const LandslideForecastCard({super.key});

  @override
  LandslideForecastCardState createState() => LandslideForecastCardState();
}

class LandslideForecastCardState extends State<LandslideForecastCard> {
  bool _showHourlyForecast = true;
  late String _currentTimestamp;

  @override
  void initState() {
    super.initState();
    _updateTimestamp();
  }

  void _updateTimestamp() {
    final now = DateTime.now();
    _currentTimestamp = DateFormat('HH:mm dd/MM/yyyy').format(now);
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

  Widget _buildToggleButtons() {
    return ToggleButtons(
      isSelected: [_showHourlyForecast, !_showHourlyForecast],
      onPressed: (int index) {
        setState(() {
          _showHourlyForecast = index == 0;
          _updateTimestamp();
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
        buildTableRow(
            ['STT', 'Huyện', 'Vị trí', 'Lũ quét', 'Trượt nông', 'Trượt lớn'],
            isHeader: true),
        buildTableRow([
          '1',
          'An Lão',
          'Đá Cạnh',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('very_high')
        ]),
        buildTableRow([
          '2',
          'An Lão8',
          'Đá Cạnh8',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('high')
        ]),
        buildTableRow([
          '3',
          'An Lão9',
          'Cống Chào9',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('medium')
        ]),
        buildTableRow([
          '4',
          'An Lão30',
          'Đá Cạnh30',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('high')
        ]),
        buildTableRow([
          '5',
          'An Lão31',
          'Đá Cạnh31',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('high')
        ]),
        buildTableRow([
          '6',
          'An Lão32',
          'Đá Cạnh32',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('high')
        ]),
      ],
    );
  }

  Widget _buildDailyForecastTable() {
    final dateFormat = DateFormat('dd/MM');
    final today = DateTime.now();
    final dateHeaders = List.generate(
        5, (index) => dateFormat.format(today.add(Duration(days: index))));

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
        buildTableRow(['TT', 'Huyện', ...dateHeaders], isHeader: true),
        buildTableRow([
          '1',
          'An Lão',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
        ]),
        buildTableRow([
          '2',
          'An Lão1',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
        ]),
        buildTableRow([
          '3',
          'An Lão12',
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
          buildRiskIcon('no_risk'),
        ]),
      ],
    );
  }
}

// Helper functions

TableRow buildTableRow(List<dynamic> cells, {bool isHeader = false}) {
  return TableRow(
    children: cells
        .map((cell) => TableCell(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: cell is Widget
                    ? cell
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
          context, 'no_risk', 'KHÔNG CÓ', 'Hiếm khi xảy ra trượt lở'),
      _buildLegendItem(
          context, 'very_low', 'RẤT THẤP', 'Hiếm khi xảy ra trượt lở'),
      _buildLegendItem(context, 'low', 'THẤP', 'Hiếm khi xảy ra trượt lở'),
      _buildLegendItem(context, 'medium', 'TRUNG BÌNH',
          'Cảnh báo phát sinh trượt lở cục bộ, chủ yếu trượt lở có quy mô nhỏ. Chủ động cảnh giác đối với các khu vực nguy hiểm.'),
      _buildLegendItem(context, 'high', 'CAO',
          'Cảnh báo nguy cơ trượt lở trên diện rộng, có thể phát sinh trượt lở quy mô lớn. Theo dõi và sẵn sàng ứng phó ở các khu vực nguy hiểm.',
          boldLevel: true),
      _buildLegendItem(context, 'very_high', 'RẤT CAO',
          'Trượt lở trên diện rộng, phát sinh trượt lở quy mô lớn. Di chuyển dân trong vùng nguy hiểm đến nơi an toàn',
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
