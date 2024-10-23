// lib/src/page/chart/elements/chart_data_processor.dart

import 'package:truotlo/src/data/chart/chart_data.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';
import 'package:truotlo/src/data/chart/rainfall_data.dart';

class ChartDataProcessor {
  List<ChartData> processData(List<LandslideDataModel> filteredData, List<RainfallData>? rainfallData) {
    // Sort the filtered data by date in ascending order
    filteredData.sort((a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));

    List<List<double>> eastWestData = [];
    List<List<double>> northSouthData = [];
    List<double> pz1Data = [];
    List<double> pz2Data = [];
    List<double> cr1Data = [];
    List<double> cr2Data = [];
    List<double> cr3Data = [];
    List<DateTime> dates = [];

    for (var item in filteredData) {
      eastWestData.add([
        item.calculatedTiltAOr1,
        item.calculatedTiltAOr2,
        item.calculatedTiltAOr3,
      ]);
      northSouthData.add([
        item.calculatedTiltBOr1,
        item.calculatedTiltBOr2,
        item.calculatedTiltBOr3,
      ]);
      pz1Data.add(item.calculatedPZ1Digit);
      pz2Data.add(item.calculatedPZ2Digit);
      cr1Data.add(item.calculatedCR1Digit);
      cr2Data.add(item.calculatedCR2Digit);
      cr3Data.add(item.calculatedCR3Digit);
      dates.add(DateTime.parse(item.createdAt));
    }

    List<ChartData> chartDataList = [
      ChartData(
        name: 'Đo nghiêng, hướng Tây - Đông',
        dataPoints: eastWestData,
        dates: dates,
      ),
      ChartData(
        name: 'Đo nghiêng, hướng Bắc - Nam',
        dataPoints: northSouthData,
        dates: dates,
      ),
      ChartData(
        name: 'Piezometer 1',
        dataPoints: [pz1Data],
        dates: dates,
      ),
      ChartData(
        name: 'Piezometer 2',
        dataPoints: [pz2Data],
        dates: dates,
      ),
      ChartData(
        name: 'Crackmeter 1',
        dataPoints: [cr1Data],
        dates: dates,
      ),
      ChartData(
        name: 'Crackmeter 2',
        dataPoints: [cr2Data],
        dates: dates,
      ),
      ChartData(
        name: 'Crackmeter 3',
        dataPoints: [cr3Data],
        dates: dates,
      ),
    ];

    // Add rainfall data if available
    if (rainfallData != null && rainfallData.isNotEmpty) {
      List<double> rainfallAmounts = [];
      List<double> cumulativeRainfall = [];
      List<DateTime> rainfallDates = [];
      
      double cumulative = 0.0;
      for (var item in rainfallData) {
        rainfallAmounts.add(item.rainfallAmount);
        cumulative += item.rainfallAmount;
        cumulativeRainfall.add(cumulative);
        rainfallDates.add(item.measurementTime);
      }

      chartDataList.addAll([
        ChartData(
          name: 'Lượng mưa',
          dataPoints: [rainfallAmounts],
          dates: rainfallDates,
        ),
        ChartData(
          name: 'Lượng mưa tích lũy',
          dataPoints: [cumulativeRainfall],
          dates: rainfallDates,
        ),
      ]);
    }

    return chartDataList;
  }
}