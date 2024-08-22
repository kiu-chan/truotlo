import 'package:truotlo/src/data/chart/chart_data.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';

class ChartDataProcessor {
  List<ChartData> processData(List<LandslideDataModel> filteredData) {
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

    return [
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
  }
}