import 'package:flutter/material.dart';

class LandslideForecastCard extends StatefulWidget {
  const LandslideForecastCard({Key? key}) : super(key: key);

  @override
  _LandslideForecastCardState createState() => _LandslideForecastCardState();
}

class _LandslideForecastCardState extends State<LandslideForecastCard> {
  bool _showHourlyForecast = true; // Mặc định hiển thị dự báo theo giờ

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
            Text('Cập nhật lúc: 10:00 27/08/2024'),
            const SizedBox(height: 16),
            _buildToggleButtons(),
            const SizedBox(height: 16),
            _showHourlyForecast ? _buildHourlyForecastTable() : _buildDailyForecastTable(),
            const SizedBox(height: 16),
            _buildLegend(context),
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
      },
      children: [
        _buildTableRow(['STT', 'Tỉnh', 'Huyện', 'Vị trí', 'Lũ quét', 'Trượt nông', 'Trượt lớn'], isHeader: true),
        _buildTableRow(['1', 'Bình Định', 'An Lão', 'Đá Cạnh', '•', '•', '▲']),
        _buildTableRow(['2', 'Bình Định8', 'An Lão8', 'Đá Cạnh8', '•', '•', '▲']),
        _buildTableRow(['3', 'Bình Định9', 'An Lão9', 'Cống Chào9', '•', '•', '▲']),
        _buildTableRow(['4', 'Bình Định30', 'An Lão30', 'Đá Cạnh30', '•', '•', '▲']),
        _buildTableRow(['5', 'Bình Định31', 'An Lão31', 'Đá Cạnh31', '•', '•', '▲']),
        _buildTableRow(['6', 'Bình Định32', 'An Lão32', 'Đá Cạnh32', '•', '•', '▲']),
      ],
    );
  }

  Widget _buildDailyForecastTable() {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
      },
      children: [
        _buildTableRow(['Khu vực', '23/08', '24/08', '25/08', '26/08', '27/08'], isHeader: true),
        _buildTableRow(['An Lão', '•', '•', '•', '•', '•']),
        _buildTableRow(['An Lão1', '•', '•', '•', '•', '•']),
        _buildTableRow(['An Lão12', '•', '•', '•', '•', '•']),
      ],
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells.map((cell) => TableCell(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chú giải các cấp nguy cơ trượt lở:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildLegendItem(context, '•', 'Không có', 'Hiếm khi xảy ra trượt lở'),
        _buildLegendItem(context, '▲', 'Trung bình', 'Cảnh báo phát sinh trượt lở cục bộ, chủ yếu trượt lở có quy mô nhỏ. Chủ động cảnh giác đối với các khu vực nguy hiểm.'),
        _buildLegendItem(context, '▲', 'Cao', 'Cảnh báo nguy cơ trượt lở trên diện rộng, có thể phát sinh trượt lở quy mô lớn. Theo dõi và sẵn sàng ứng phó ở các khu vực nguy hiểm.'),
        _buildLegendItem(context, '▲', 'Rất cao', 'Trượt lở trên diện rộng, phát sinh trượt lở quy mô lớn. Di chuyển dân trong vùng nguy hiểm đến nơi an toàn'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String symbol, String level, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(text: '$level: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}