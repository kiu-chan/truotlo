import 'package:flutter/material.dart';

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
      _buildLegendItem(
          context, 'low', 'THẤP', 'Hiếm khi xảy ra trượt lở'),
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
    BuildContext context, String riskLevel, String level, String description, {bool boldLevel = false}) {
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

Widget _buildDailyLegendItem(
    BuildContext context, int riskLevel, String level, String description) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                    text: '$riskLevel ',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text: '$level: ',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}