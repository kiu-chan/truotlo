import 'package:flutter/material.dart';

TableRow buildTableRow(List<dynamic> cells, {bool isHeader = false}) {
  return TableRow(
    children: cells
        .map((cell) => TableCell(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                // color: isHeader ? Colors.white : null,
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
      return const Icon(Icons.circle, color: Colors.grey, size: 16);
    case 'medium':
      return Image.asset('lib/assets/report/icon_nguy_co_trung_binh.jpg',
          width: 16, height: 16);
    case 'high':
      return Image.asset('lib/assets/report/icon_nguy_co_cao.png',
          width: 16, height: 16);
    case 'very_high':
      return Image.asset('lib/assets/report/icon_nguy_co_rat_cao.png',
          width: 16, height: 16);
    default:
      return const SizedBox.shrink();
  }
}

Widget buildColorDot(int riskLevel) {
  final Color color;
  switch (riskLevel) {
    case 0:
      color = Colors.grey;
      break;
    case 1:
      color = Colors.green;
      break;
    case 2:
      color = Colors.yellow;
      break;
    case 3:
      color = Colors.orange;
      break;
    case 4:
      color = Colors.red;
      break;
    case 5:
      color = Colors.purple;
      break;
    default:
      color = Colors.grey;
  }
  return Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
  );
}

Widget buildHourlyLegend(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Chú giải các cấp nguy cơ trượt lở:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildHourlyLegendItem(
          context, 'no_risk', 'Không có', 'Hiếm khi xảy ra trượt lở'),
      _buildHourlyLegendItem(context, 'medium', 'Trung bình',
          'Cảnh báo phát sinh trượt lở cục bộ, chủ yếu trượt lở có quy mô nhỏ. Chủ động cảnh giác đối với các khu vực nguy hiểm.'),
      _buildHourlyLegendItem(context, 'high', 'Cao',
          'Cảnh báo nguy cơ trượt lở trên diện rộng, có thể phát sinh trượt lở quy mô lớn. Theo dõi và sẵn sàng ứng phó ở các khu vực nguy hiểm.'),
      _buildHourlyLegendItem(context, 'very_high', 'Rất cao',
          'Trượt lở trên diện rộng, phát sinh trượt lở quy mô lớn. Di chuyển dân trong vùng nguy hiểm đến nơi an toàn'),
    ],
  );
}

Widget buildDailyLegend(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Chú giải các cấp nguy cơ trượt lở:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildDailyLegendItem(context, 0, 'Không có', 'Hiếm khi xảy ra trượt lở'),
      _buildDailyLegendItem(
          context, 1, 'Rất thấp', 'Chú ý nguy cơ phát sinh trượt lở'),
      _buildDailyLegendItem(context, 2, 'Thấp',
          'Chú ý trượt lở có thể phát sinh cục bộ, nhất là các vị trí đã có dấu hiệu nguy hiểm như khe nứt tách, khu vực đã có dấu hiệu dịch chuyển từ trước, khu vực đang khắc phục trượt lở (nếu có)....'),
      _buildDailyLegendItem(context, 3, 'Trung bình',
          'Cảnh báo phát sinh trượt lở cục bộ, chủ yếu trượt lở có quy mô nhỏ. Chủ động cảnh giác đối với các khu vực nguy hiểm.'),
      _buildDailyLegendItem(context, 4, 'Cao',
          'Cảnh báo nguy cơ trượt lở trên diện rộng, có thể phát sinh trượt lở quy mô lớn. Theo dõi và sẵn sàng ứng phó ở các khu vực nguy hiểm.'),
      _buildDailyLegendItem(context, 5, 'Rất cao',
          'Trượt lở trên diện rộng, phát sinh trượt lở quy mô lớn. Di chuyển dân trong vùng nguy hiểm đến nơi an toàn'),
    ],
  );
}

Widget _buildHourlyLegendItem(
    BuildContext context, String riskLevel, String level, String description) {
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

Widget _buildDailyLegendItem(
    BuildContext context, int riskLevel, String level, String description) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildColorDot(riskLevel),
        const SizedBox(width: 8),
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
