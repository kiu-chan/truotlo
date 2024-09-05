import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:truotlo/src/data/chart/chart_data.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';

class ChartUtils {
  static void initLineVisibility(
      Map<int, bool> lineVisibility, int dataLength) {
    lineVisibility.clear();
    for (int i = 0; i < dataLength; i++) {
      lineVisibility[i] = true;
    }
    lineVisibility[-1] = true; // Cho đường giá trị mặc định
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static List<LandslideDataModel> filterDataByDateRange(
      List<LandslideDataModel> allData,
      DateTime? startDateTime,
      DateTime? endDateTime) {
    if (startDateTime != null && endDateTime != null) {
      return allData.where((d) {
        final dataDate = DateTime.parse(d.createdAt);
        final adjustedStartDateTime =
            startDateTime.add(const Duration(hours: 7));
        final adjustedEndDateTime = endDateTime.add(const Duration(hours: 7));
        return dataDate.isAfter(adjustedStartDateTime) &&
            dataDate.isBefore(adjustedEndDateTime.add(const Duration(days: 1)));
      }).toList();
    } else {
      return List.from(allData);
    }
  }

  static String getDateRangeText(
      DateTime? startDateTime, DateTime? endDateTime) {
    if (startDateTime != null && endDateTime != null) {
      return 'Từ ${DateFormat('dd/MM/yyyy HH:mm').format(startDateTime)} đến ${DateFormat('dd/MM/yyyy HH:mm').format(endDateTime)}';
    } else {
      return 'Chọn khoảng thời gian';
    }
  }

  static LineChartData getLineChartData(
    String selectedChart,
    List<ChartData> chartDataList,
    Map<int, bool> lineVisibility,
    List<LandslideDataModel> filteredData,
  ) {
    return LineChartData(
      lineBarsData:
          _getLineBarsData(selectedChart, chartDataList, lineVisibility),
      titlesData: _getTitlesData(selectedChart, filteredData),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              if (flSpot.x == -1 || flSpot.y == -1) {
                return null;
              }
              
              // Get the corresponding date for the x-value
              // DateTime date = chartDataList[0].dates[flSpot.x.toInt()];
              // String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
              
              // Format the tooltip text
              String tooltipText = '(${flSpot.x}, ${flSpot.y})';
              
              return LineTooltipItem(
                tooltipText,
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList();
          },
          tooltipPadding: const EdgeInsets.all(8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          // Custom touch callback if needed
        },
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              const FlLine(color: Colors.white, strokeWidth: 2),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    // strokeColor: barData.color,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  static List<LineChartBarData> _getLineBarsData(
    String selectedChart,
    List<ChartData> chartDataList,
    Map<int, bool> lineVisibility,
  ) {
    ChartData selectedChartData =
        chartDataList.firstWhere((c) => c.name == selectedChart);
    List<LineChartBarData> lineBars = [];

    if ([
      'Piezometer 1',
      'Piezometer 2',
      'Crackmeter 1',
      'Crackmeter 2',
      'Crackmeter 3'
    ].contains(selectedChart)) {
      if (lineVisibility[0] ?? false) {
        lineBars.add(
          LineChartBarData(
            spots:
                List.generate(selectedChartData.dataPoints[0].length, (index) {
              return FlSpot(
                  index.toDouble(), selectedChartData.dataPoints[0][index]);
            }),
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.blue,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    } else {
      for (int i = 0; i < selectedChartData.dataPoints.length; i++) {
        if (lineVisibility[i] ?? false) {
          lineBars.add(
            LineChartBarData(
              spots: [
                FlSpot(selectedChartData.dataPoints[i][0], -6),
                FlSpot(selectedChartData.dataPoints[i][1], -11),
                FlSpot(selectedChartData.dataPoints[i][2], -16),
              ],
              isCurved: true,
              curveSmoothness: 0.35,
              color: Colors.primaries[i % Colors.primaries.length],
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }
      }

      // Thêm đường giá trị mặc định
      if (lineVisibility[-1] ?? false) {
        if (selectedChart == 'Đo nghiêng, hướng Tây - Đông') {
          lineBars.add(
            LineChartBarData(
              spots: const [
                FlSpot(-0.001565, -6),
                FlSpot(0.009616, -11),
                FlSpot(0.000935, -16),
              ],
              isCurved: true,
              curveSmoothness: 0.35,
              color: Colors.black,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
              dashArray: [5, 5],
            ),
          );
        } else if (selectedChart == 'Đo nghiêng, hướng Bắc - Nam') {
          lineBars.add(
            LineChartBarData(
              spots: const [
                FlSpot(-0.03261, -6),
                FlSpot(-0.053559, -11),
                FlSpot(-0.032529, -16),
              ],
              isCurved: true,
              curveSmoothness: 0.35,
              color: Colors.black,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
              dashArray: [5, 5],
            ),
          );
        }
      }
    }

    return lineBars;
  }

  static FlTitlesData _getTitlesData(
      String selectedChart, List<LandslideDataModel> filteredData) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            if ([
              'Piezometer 1',
              'Piezometer 2',
              'Crackmeter 1',
              'Crackmeter 2',
              'Crackmeter 3'
            ].contains(selectedChart)) {
              int index = value.toInt();
              if (index >= 0 &&
                  index < filteredData.length &&
                  index % (filteredData.length ~/ 5) == 0) {
                return Text(
                  DateFormat('dd/MM')
                      .format(DateTime.parse(filteredData[index].createdAt)),
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            }
            // Chỉ làm tròn khi có số thập phân
            return Text(value.truncateToDouble() == value
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(2));
          },
          interval: [
            'Piezometer 1',
            'Piezometer 2',
            'Crackmeter 1',
            'Crackmeter 2',
            'Crackmeter 3'
          ].contains(selectedChart)
              ? null
              : 0.02, // Tăng khoảng cách giữa các nhãn
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            // Chỉ làm tròn khi có số thập phân
            return Text(value.truncateToDouble() == value
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(2));
          },
          interval: 2,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  static List<Widget> buildLegendItems(
    String selectedChart,
    Map<int, bool> lineVisibility,
    List<ChartData> chartDataList,
    Function(int) toggleLineVisibility,
  ) {
    if ([
      'Piezometer 1',
      'Piezometer 2',
      'Crackmeter 1',
      'Crackmeter 2',
      'Crackmeter 3'
    ].contains(selectedChart)) {
      return [
        _buildLegendItem(
            Colors.blue, selectedChart, 0, lineVisibility, toggleLineVisibility)
      ];
    } else {
      return lineVisibility.entries.map((entry) {
        return _buildLegendItem(
          entry.key == -1
              ? Colors.black
              : Colors.primaries[entry.key % Colors.primaries.length],
          entry.key == -1
              ? 'Giá trị mặc định'
              : DateFormat('dd/MM/yyyy HH:mm')
                  .format(chartDataList[0].dates[entry.key]),
          entry.key,
          lineVisibility,
          toggleLineVisibility,
        );
      }).toList();
    }
  }

  static Widget _buildLegendItem(
    Color color,
    String label,
    int index,
    Map<int, bool> lineVisibility,
    Function(int) toggleLineVisibility,
  ) {
    return GestureDetector(
      onTap: () => toggleLineVisibility(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              color: lineVisibility[index] ?? true ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    lineVisibility[index] ?? true ? Colors.black : Colors.grey,
                decoration: lineVisibility[index] ?? true
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }

}