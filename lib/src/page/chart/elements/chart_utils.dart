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
    lineVisibility[-1] = true;
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static String getDateRangeText(DateTime? startDateTime, DateTime? endDateTime) {
    if (startDateTime != null && endDateTime != null) {
      return 'từ ${DateFormat('dd/MM/yyyy HH:mm').format(startDateTime).toLowerCase()} đến ${DateFormat('dd/MM/yyyy HH:mm').format(endDateTime).toLowerCase()}';
    } else {
      return 'chọn khoảng thời gian';
    }
  }

  static (double, List<double>) calculateRainfallYAxisRange(List<double> values) {
    if (values.isEmpty) return (5, [0, 1, 2, 3, 4, 5]);
    
    double maxValue = values.reduce((max, value) => max > value ? max : value);
    
    // Làm tròn maxValue lên 
    double roundedMax;
    if (maxValue <= 5) {
      roundedMax = 5;
    } else if (maxValue <= 10) {
      roundedMax = 10;
    } else {
      roundedMax = (maxValue / 5).ceil() * 5;
    }
    
    // Tạo 5 giá trị đều nhau
    List<double> intervals = List.generate(6, (index) => 
      (roundedMax / 5 * index).roundToDouble()
    );
    
    return (roundedMax, intervals);
  }

  static List<int> calculateXAxisLabels(int dataLength) {
    if (dataLength <= 5) {
      return List.generate(dataLength, (index) => index);
    }

    List<int> indices = [];
    double interval = (dataLength - 1) / 4;
    for (int i = 0; i < 5; i++) {
      indices.add((i * interval).round());
    }
    return indices;
  }

  static LineChartData getLineChartData(
    String selectedChart,
    List<ChartData> chartDataList,
    Map<int, bool> lineVisibility,
    List<LandslideDataModel> filteredData,
    bool isAdmin,
  ) {
    ChartData chartData = chartDataList.firstWhere((c) => c.name == selectedChart);
    bool isRainfallChart = selectedChart.contains('Lượng mưa');

    late double maxY;
    late List<double> yAxisValues;
    late List<int> xAxisIndices;

    if (isRainfallChart) {
      final result = calculateRainfallYAxisRange(chartData.dataPoints[0]);
      maxY = result.$1;
      yAxisValues = result.$2;
      xAxisIndices = calculateXAxisLabels(chartData.dates.length);
    }

    return LineChartData(
      lineBarsData: _getLineBarsData(selectedChart, chartDataList, lineVisibility, isAdmin),
      minY: isRainfallChart ? 0 : null,
      maxY: isRainfallChart ? maxY : null,
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (isRainfallChart) {
                if (xAxisIndices.contains(index)) {
                  return Transform.rotate(
                    angle: -45 * 3.14 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        DateFormat('dd/MM\nHH:mm').format(chartData.dates[index]),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
              } else if (selectedChart.startsWith('Đo nghiêng')) {
                List<double> fixedValues = [-0.5, -0.3, -0.1, 0, 0.1];
                int idx = fixedValues.indexWhere((v) => (v - value).abs() < 0.001);
                if (idx != -1) {
                  return Transform.rotate(
                    angle: -45 * 3.14 / 180,
                    child: Text(
                      fixedValues[idx].toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
              } else {
                if (index >= 0 && index < chartData.dates.length && index % (chartData.dates.length ~/ 4) == 0) {
                  return Transform.rotate(
                    angle: -45 * 3.14 / 180,
                    child: Text(
                      DateFormat('dd/MM\nHH:mm').format(chartData.dates[index]),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              if (isRainfallChart) {
                if (yAxisValues.contains(value)) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} mm',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              } else if (selectedChart.startsWith('Đo nghiêng')) {
                List<double> depthValues = [-16, -11, -6];
                if (depthValues.contains(value)) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              } else {
                double minY = chartData.dataPoints[0].reduce((min, value) => min < value ? min : value);
                double maxY = chartData.dataPoints[0].reduce((max, value) => max > value ? max : value);
                double range = maxY - minY;
                List<double> yValues = List.generate(5, (index) => minY + (range / 4) * index);
                
                if (yValues.any((y) => (y - value).abs() < 0.001)) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              }
              return const SizedBox();
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          if (isRainfallChart && !yAxisValues.contains(value)) {
            return const FlLine(color: Colors.transparent);
          }
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          int index = value.toInt();
          if (isRainfallChart) {
            if (xAxisIndices.contains(index)) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            }
            return const FlLine(color: Colors.transparent);
          }
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              if (barSpot.x < 0 || barSpot.y < 0) return null;

              String tooltipText;
              int index = barSpot.x.toInt();
              if (index >= 0 && index < chartData.dates.length) {
                String date = DateFormat('dd/MM/yyyy HH:mm').format(chartData.dates[index]);
                if (isRainfallChart) {
                  tooltipText = '$date\n${barSpot.y.toStringAsFixed(1)} mm';
                } else {
                  tooltipText = '$date\n${barSpot.y.toStringAsFixed(2)}';
                }
              } else {
                tooltipText = barSpot.y.toStringAsFixed(2);
              }

              return LineTooltipItem(
                tooltipText,
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
          // tooltipBgColor: Colors.black.withOpacity(0.8),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
        handleBuiltInTouches: true,
        touchSpotThreshold: 20,
      ),
    );
  }

  static List<LineChartBarData> _getLineBarsData(
    String selectedChart,
    List<ChartData> chartDataList,
    Map<int, bool> lineVisibility,
    bool isAdmin,
  ) {
    ChartData chartData = chartDataList.firstWhere((c) => c.name == selectedChart);
    List<LineChartBarData> lineBars = [];

    if (selectedChart.contains('Lượng mưa') && (lineVisibility[0] ?? false)) {
      bool isCumulative = selectedChart == 'Lượng mưa tích lũy';
      List<FlSpot> spots = List.generate(
        chartData.dataPoints[0].length,
        (index) => FlSpot(index.toDouble(), chartData.dataPoints[0][index]),
      );

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: isCumulative,
          color: isCumulative ? Colors.green : Colors.blue,
          barWidth: isCumulative ? 2 : 3,
          dotData: FlDotData(
            show: isCumulative,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: isCumulative ? Colors.green : Colors.blue,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: (isCumulative ? Colors.green : Colors.blue).withOpacity(0.15),
          ),
        ),
      );
    } else if (selectedChart.startsWith('Đo nghiêng')) {
      for (int i = 0; i < chartData.dataPoints.length; i++) {
        if (lineVisibility[i] ?? false) {
          lineBars.add(
            LineChartBarData(
              spots: [
                FlSpot(chartData.dataPoints[i][0], -6),
                FlSpot(chartData.dataPoints[i][1], -11),
                FlSpot(chartData.dataPoints[i][2], -16),
              ],
              isCurved: true,
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
              color: Colors.black,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
              dashArray: [5, 5],
            ),
          );
        }
      }
    } else if (lineVisibility[0] ?? false) {
      lineBars.add(
        LineChartBarData(
          spots: List.generate(
            chartData.dataPoints[0].length,
            (index) => FlSpot(index.toDouble(), chartData.dataPoints[0][index]),
          ),
isCurved: true,
          color: Colors.blue,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return lineBars;
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
  } else if (['Piezometer 1', 'Piezometer 2', 'Crackmeter 1', 'Crackmeter 2', 'Crackmeter 3']
      .contains(selectedChart)) {
    return [
      _buildLegendItem(
        Colors.blue,
        selectedChart.toLowerCase(),
        0,
        lineVisibility,
        toggleLineVisibility,
      )
    ];
  } else if (selectedChart.startsWith('Đo nghiêng')) {
    ChartData? tiltData;
    for (var chart in chartDataList) {
      if (chart.name == selectedChart) {
        tiltData = chart;
        break;
      }
    }

    if (tiltData == null || tiltData.dates.isEmpty) {
      return [];
    }

    var legendItems = <Widget>[];
    
    // Add items for valid indices
    for (var entry in lineVisibility.entries) {
      if (entry.key == -1) continue;
      
      final index = entry.key;
      if (index >= 0 && index < tiltData.dates.length) {
        legendItems.add(
          _buildLegendItem(
            Colors.primaries[index % Colors.primaries.length],
            DateFormat('dd/MM/yyyy HH:mm').format(tiltData.dates[index]),
            index,
            lineVisibility,
            toggleLineVisibility,
          )
        );
      }
    }

    // Add reference line if enabled
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

  return [];
}

  static Widget _buildLegendItem(
    Color color,
    String label,
    int index,
    Map<int, bool> lineVisibility,
    Function(int) toggleLineVisibility,
  ) {
    final bool isVisible = lineVisibility[index] ?? true;
    final bool isRainfallChart = label.contains('lượng mưa');

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
                color: isVisible ? color : Colors.grey.shade300,
                borderRadius: isRainfallChart 
                    ? BorderRadius.zero 
                    : BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isVisible ? Colors.black87 : Colors.grey,
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
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

  static List<RainfallData> filterRainfallDataBasedOnUserRole(
    List<RainfallData> allData,
    bool isAdmin,
  ) {
    if (isAdmin) {
      return List.from(allData);
    } else {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      return allData
          .where((item) => item.measurementTime.isAfter(twoDaysAgo))
          .toList();
    }
  }

  static List<RainfallData> filterRainfallDataByDateRange(
    List<RainfallData> allData,
    DateTime? startDateTime,
    DateTime? endDateTime,
  ) {
    if (startDateTime != null && endDateTime != null) {
      return allData
          .where((d) => d.measurementTime.isAfter(startDateTime) &&
              d.measurementTime.isBefore(endDateTime.add(const Duration(days: 1))))
          .toList();
    }
    return List.from(allData);
  }

  static double getRainfallBarWidth(int dataLength) {
    if (dataLength <= 24) {
      return 8.0;
    } else if (dataLength <= 48) {
      return 6.0;
    } else if (dataLength <= 72) {
      return 4.0;
    } else {
      return 3.0;
    }
  }

  static Color getRainfallBarColor(double amount) {
    if (amount == 0) return Colors.grey.shade300;
    
    if (amount < 2.5) {
      return Colors.blue.shade300;
    } else if (amount < 7.5) {
      return Colors.blue.shade500;
    } else {
      return Colors.blue.shade700;
    }
  }

  static FlGridData getRainfallGridData(List<double> yAxisValues, List<int> xAxisIndices) {
    return FlGridData(
      show: true,
      getDrawingHorizontalLine: (value) {
        if (!yAxisValues.contains(value)) {
          return const FlLine(color: Colors.transparent);
        }
        return FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        if (!xAxisIndices.contains(value.toInt())) {
          return const FlLine(color: Colors.transparent);
        }
        return FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        );
      },
    );
  }

  static FlBorderData getChartBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  static String formatRainfallAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(1);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static (DateTime, DateTime)? getDefaultDateRange() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    return (startOfToday, endOfToday);
  }

  static bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start) && 
           date.isBefore(end.add(const Duration(days: 1)));
  }
}