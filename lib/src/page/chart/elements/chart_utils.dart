// lib/src/page/chart/elements/chart_utils.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:truotlo/src/data/chart/chart_data.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';
import 'package:truotlo/src/data/chart/rainfall_data.dart';

class ChartUtils {
  static void initLineVisibility(Map<int, bool> lineVisibility, int dataLength) {
    lineVisibility.clear();
    for (int i = 0; i < dataLength; i++) {
      lineVisibility[i] = true;
    }
    lineVisibility[-1] = true; // Cho đường giá trị mặc định
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static List<LandslideDataModel> filterDataByDateRange(
    List<LandslideDataModel> allData,
    DateTime? startDateTime,
    DateTime? endDateTime
  ) {
    if (startDateTime != null && endDateTime != null) {
      return allData.where((d) {
        final dataDate = DateTime.parse(d.createdAt);
        final adjustedStartDateTime = startDateTime.add(const Duration(hours: 7));
        final adjustedEndDateTime = endDateTime.add(const Duration(hours: 7));
        return dataDate.isAfter(adjustedStartDateTime) &&
               dataDate.isBefore(adjustedEndDateTime.add(const Duration(days: 1)));
      }).toList();
    } else {
      return List.from(allData);
    }
  }

  static String getDateRangeText(DateTime? startDateTime, DateTime? endDateTime) {
    if (startDateTime != null && endDateTime != null) {
      return 'từ ${DateFormat('dd/MM/yyyy HH:mm').format(startDateTime).toLowerCase()} đến ${DateFormat('dd/MM/yyyy HH:mm').format(endDateTime).toLowerCase()}';
    } else {
      return 'chọn khoảng thời gian';
    }
  }

  static List<RainfallData> filterRainfallDataByDateRange(
    List<RainfallData> allData,
    DateTime? startDateTime,
    DateTime? endDateTime
  ) {
    if (startDateTime != null && endDateTime != null) {
      return allData.where((d) {
        final adjustedStartDateTime = startDateTime.add(const Duration(hours: 7));
        final adjustedEndDateTime = endDateTime.add(const Duration(hours: 7));
        return d.measurementTime.isAfter(adjustedStartDateTime) &&
               d.measurementTime.isBefore(adjustedEndDateTime.add(const Duration(days: 1)));
      }).toList();
    } else {
      return List.from(allData);
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
      lineBarsData: _getLineBarsData(selectedChart, chartDataList, lineVisibility, isAdmin),
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

              ChartData selectedChartData = chartDataList.firstWhere((c) => c.name == selectedChart);
              String tooltipText;
              
              if (selectedChart == 'Lượng mưa tích lũy') {
                String date = DateFormat('dd/MM/yyyy HH:mm').format(selectedChartData.dates[flSpot.x.toInt()]).toLowerCase();
                tooltipText = '$date: ${flSpot.y.toStringAsFixed(1)} mm';
              } else if (selectedChart == 'Lượng mưa') {
                String date = DateFormat('dd/MM/yyyy HH:mm').format(selectedChartData.dates[flSpot.x.toInt()]).toLowerCase();
                tooltipText = '$date: ${flSpot.y.toStringAsFixed(2)} mm';
              } else if (selectedChart.startsWith('Đo nghiêng')) {
                int dateIndex = barSpot.barIndex;
                if (dateIndex >= 0 && dateIndex < selectedChartData.dates.length) {
                  String date = DateFormat('dd/MM/yyyy HH:mm').format(selectedChartData.dates[dateIndex]).toLowerCase();
                  tooltipText = '$date: ${flSpot.x.toStringAsFixed(3)}';
                } else {
                  tooltipText = 'giá trị: ${flSpot.x.toStringAsFixed(3)}';
                }
              } else {
                String date = DateFormat('dd/MM/yyyy HH:mm').format(selectedChartData.dates[flSpot.x.toInt()]).toLowerCase();
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
        handleBuiltInTouches: true,
      ),
    );
  }

  static List<LineChartBarData> _getLineBarsData(
    String selectedChart,
    List<ChartData> chartDataList,
    Map<int, bool> lineVisibility,
    bool isAdmin,
  ) {
    ChartData selectedChartData = chartDataList.firstWhere((c) => c.name == selectedChart);
    List<LineChartBarData> lineBars = [];

    if (selectedChart == 'Lượng mưa tích lũy') {
      if (lineVisibility[0] ?? false) {
        lineBars.add(
          LineChartBarData(
            spots: List.generate(selectedChartData.dataPoints[0].length, (index) {
              return FlSpot(index.toDouble(), selectedChartData.dataPoints[0][index]);
            }),
            isCurved: true,
            color: Colors.green,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        );
      }
    } else if (selectedChart == 'Lượng mưa') {
      if (lineVisibility[0] ?? false) {
        lineBars.add(
          LineChartBarData(
            spots: List.generate(selectedChartData.dataPoints[0].length, (index) {
              return FlSpot(index.toDouble(), selectedChartData.dataPoints[0][index]);
            }),
            isCurved: false,
            color: Colors.blue,
            barWidth: 5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        );
      }
    } else if (['Piezometer 1', 'Piezometer 2', 'Crackmeter 1', 'Crackmeter 2', 'Crackmeter 3'].contains(selectedChart)) {
      if (lineVisibility[0] ?? false) {
lineBars.add(
          LineChartBarData(
            spots: List.generate(selectedChartData.dataPoints[0].length, (index) {
              return FlSpot(index.toDouble(), selectedChartData.dataPoints[0][index]);
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
    String selectedChart,
    List<LandslideDataModel> filteredData,
    List<ChartData> chartDataList
  ) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            if (selectedChart == 'Lượng mưa tích lũy' || selectedChart == 'Lượng mưa') {
              ChartData selectedChartData = chartDataList.firstWhere((c) => c.name == selectedChart);
              int dataLength = selectedChartData.dates.length;
              List<int> indicesToShow = [0, dataLength ~/ 4, dataLength ~/ 2, (3 * dataLength) ~/ 4, dataLength - 1];
              
              int index = value.toInt();
              if (indicesToShow.contains(index)) {
                return Transform.rotate(
                  angle: -45 * 3.14 / 180,
                  child: Text(
                    DateFormat('dd/MM HH:mm').format(selectedChartData.dates[index]).toLowerCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
            } else if (selectedChart.startsWith('Đo nghiêng')) {
              List<double> fixedValues = [-0.5, -0.3, -0.1, 0, 0.1];
              int index = fixedValues.indexWhere((v) => (v - value).abs() < 0.001);
              if (index != -1) {
                return Transform.rotate(
                  angle: -45 * 3.14 / 180,
                  child: Text(
                    fixedValues[index].toStringAsFixed(1).toLowerCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
            } else {
              ChartData selectedChartData = chartDataList.firstWhere((c) => c.name == selectedChart);
              int dataLength = selectedChartData.dates.length;
              List<int> indicesToShow = [0, dataLength ~/ 4, dataLength ~/ 2, (3 * dataLength) ~/ 4, dataLength - 1];
              
              int index = value.toInt();
              if (indicesToShow.contains(index)) {
                return Transform.rotate(
                  angle: -45 * 3.14 / 180,
                  child: Text(
                    DateFormat('dd/MM HH:mm').format(selectedChartData.dates[index]).toLowerCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
            }
            return const Text('');
          },
          interval: 1,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            if (selectedChart == 'Lượng mưa tích lũy' || selectedChart == 'Lượng mưa') {
              if (value % 5 == 0) {
                return Text('${value.toInt()} mm');
              }
            } else if (selectedChart.startsWith('Đo nghiêng')) {
              List<double> depthValues = [-16, -11, -6];
              if (depthValues.contains(value)) {
                return Text(value.toStringAsFixed(0));
              }
            } else {
              ChartData selectedChartData = chartDataList.firstWhere((c) => c.name == selectedChart);
              double minY = selectedChartData.dataPoints[0].reduce((a, b) => a < b ? a : b);
              double maxY = selectedChartData.dataPoints[0].reduce((a, b) => a > b ? a : b);
              double range = maxY - minY;
              List<double> yValues = List.generate(5, (index) => minY + (range / 4) * index);
              
              if (yValues.any((y) => (y - value).abs() < 0.001)) {
                return Text(value.toStringAsFixed(2));
              }
            }
            return const Text('');
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
    if (selectedChart == 'Lượng mưa tích lũy') {
      return [
        _buildLegendItem(
          Colors.green,
          'lượng mưa tích lũy (mm)',
          0,
          lineVisibility,
          toggleLineVisibility,
        )
      ];
    } else if (selectedChart == 'Lượng mưa') {
      return [
        _buildLegendItem(
          Colors.blue,
          'lượng mưa (mm)',
          0,
          lineVisibility,
          toggleLineVisibility,
        )
      ];
    } else if (['Piezometer 1', 'Piezometer 2', 'Crackmeter 1', 'Crackmeter 2', 'Crackmeter 3'].contains(selectedChart)) {
      return [_buildLegendItem(Colors.blue, selectedChart.toLowerCase(), 0, lineVisibility, toggleLineVisibility)];
    } else {
      var legendItems = lineVisibility.entries.where((entry) => entry.key != -1).map((entry) {
        return _buildLegendItem(
          Colors.primaries[entry.key % Colors.primaries.length],
          DateFormat('dd/MM/yyyy HH:mm').format(chartDataList[0].dates[entry.key]).toLowerCase(),
          entry.key,
          lineVisibility,
          toggleLineVisibility,
        );
      }).toList();

      if (lineVisibility[-1] ?? false) {
        legendItems.add(
          _buildLegendItem(
            Colors.black,
            'bắt đầu(19/11/2023)',
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
              decoration: BoxDecoration(
                color: lineVisibility[index] ?? true ? color : Colors.grey,
                borderRadius: label.contains('lượng mưa') ? BorderRadius.circular(0) : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: lineVisibility[index] ?? true ? Colors.black : Colors.grey,
                decoration: lineVisibility[index] ?? true ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<LandslideDataModel> filterDataBasedOnUserRole(List<LandslideDataModel> allData, bool isAdmin) {
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

  static List<RainfallData> filterRainfallDataBasedOnUserRole(
    List<RainfallData> allData,
    bool isAdmin
  ) {
    if (isAdmin) {
      return List.from(allData);
    } else {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      return allData.where((item) => item.measurementTime.isAfter(twoDaysAgo)).toList();
    }
  }

  static (double, double) getRainfallYAxisRange(List<RainfallData> rainfallData) {
    if (rainfallData.isEmpty) return (0, 5);
    
    double maxValue = rainfallData
        .map((data) => data.rainfallAmount)
        .reduce((max, value) => max > value ? max : value);
    
    return (0, (maxValue + 1).ceilToDouble());
  }

  static (double, double) getCumulativeRainfallYAxisRange(List<RainfallData> rainfallData) {
    if (rainfallData.isEmpty) return (0, 10);
    
    double totalRainfall = rainfallData
        .map((data) => data.rainfallAmount)
        .reduce((sum, value) => sum + value);
    
    // Round up to the nearest 5 or 10 for better readability
    double maxValue = totalRainfall;
    if (maxValue <= 50) {
      maxValue = (maxValue / 5).ceil() * 5.0;
    } else {
      maxValue = (maxValue / 10).ceil() * 10.0;
    }
    
    return (0, maxValue);
  }
}