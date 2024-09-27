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
    bool isAdmin,
  ) {
    return LineChartData(
      lineBarsData: _getLineBarsData(
          selectedChart, chartDataList, lineVisibility, isAdmin),
      titlesData: _getTitlesData(selectedChart, filteredData, chartDataList),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              if (flSpot.x == -1 || flSpot.y == -1) {
                return null;
              }

              ChartData selectedChartData =
                  chartDataList.firstWhere((c) => c.name == selectedChart);
              String tooltipText;
              if (selectedChart.startsWith('Đo nghiêng')) {
                tooltipText =
                    'Độ sâu: ${flSpot.y.toStringAsFixed(0)}, Giá trị: ${flSpot.x.toStringAsFixed(3)}';
              } else {
                String date = DateFormat('dd/MM/yyyy HH:mm')
                    .format(selectedChartData.dates[flSpot.x.toInt()]);
                tooltipText = '$date: ${flSpot.y.toStringAsFixed(2)}';
              }

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
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              const FlLine(color: Colors.white, strokeWidth: 2),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
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
    bool isAdmin,
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
    } else if (selectedChart.startsWith('Đo nghiêng')) {
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

      // Thêm đường giá trị mặc định chỉ cho admin
      if ((lineVisibility[-1] ?? false) && isAdmin) {
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

  static FlTitlesData _getTitlesData(String selectedChart,
      List<LandslideDataModel> filteredData, List<ChartData> chartDataList) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            if ([
              'Piezometer 1',
              'Piezometer 2',
              'Crackmeter 1',
              'Crackmeter 2',
              'Crackmeter 3'
            ].contains(selectedChart)) {
              ChartData selectedChartData =
                  chartDataList.firstWhere((c) => c.name == selectedChart);
              int index = value.toInt();
              if (index >= 0 &&
                  index < selectedChartData.dates.length &&
                  index % (selectedChartData.dates.length ~/ 5) == 0) {
                return Transform.rotate(
                  angle: -45 * 3.14 / 180,
                  child: Text(
                    DateFormat('dd/MM HH:mm')
                        .format(selectedChartData.dates[index]),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            } else if (selectedChart.startsWith('Đo nghiêng')) {
              // Hiển thị giá trị đo nghiêng trên trục x
              return Text(
                value.toStringAsFixed(3),
                style: const TextStyle(fontSize: 10),
              );
            }
            return Text(value.truncateToDouble() == value
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(2));
          },
          interval: selectedChart.startsWith('Đo nghiêng') ? 0.1 : null,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            if (selectedChart.startsWith('Đo nghiêng')) {
              List<double> depthValues = [-16, -11, -6];
              if (depthValues.contains(value)) {
                return Text(value.toStringAsFixed(0));
              }
              return const Text('');
            } else {
              return Text(value.truncateToDouble() == value
                  ? value.toStringAsFixed(0)
                  : value.toStringAsFixed(2));
            }
          },
          interval: 1,
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
    bool isAdmin,
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
      var legendItems =
          lineVisibility.entries.where((entry) => entry.key != -1).map((entry) {
        return _buildLegendItem(
          Colors.primaries[entry.key % Colors.primaries.length],
          DateFormat('dd/MM/yyyy HH:mm')
              .format(chartDataList[0].dates[entry.key]),
          entry.key,
          lineVisibility,
          toggleLineVisibility,
        );
      }).toList();

      // Thêm mục chú thích giá trị mặc định chỉ cho admin
      if (isAdmin && (lineVisibility[-1] ?? false)) {
        legendItems.add(
          _buildLegendItem(
            Colors.black,
            'Giá trị mặc định',
            -1,
            lineVisibility,
            toggleLineVisibility,
          ),
        );
      }

      return legendItems;
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

  static List<LandslideDataModel> filterDataBasedOnUserRole(
    List<LandslideDataModel> allData,
    bool isAdmin,
  ) {
    if (isAdmin) {
      return List.from(allData);
    } else {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      return allData.where((item) {
        final itemDate = DateTime.parse(item.createdAt);
        return itemDate.isAfter(twoDaysAgo);
      }).toList();
    }
  }
}
