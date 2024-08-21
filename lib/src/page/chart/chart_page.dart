import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:truotlo/src/data/chart_data.dart';
import 'package:truotlo/src/data/landslide_data.dart';
import 'package:truotlo/src/page/chart/chart_menu.dart';
import 'chart_data_processor.dart';
import 'chart_utils.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  ChartPageState createState() => ChartPageState();
}

class ChartPageState extends State<ChartPage> {
  final LandslideDataService _dataService = LandslideDataService();
  final ChartDataProcessor _dataProcessor = ChartDataProcessor();
  List<LandslideDataModel> _allData = [];
  List<LandslideDataModel> _filteredData = [];
  List<ChartData> _chartDataList = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedChart = '';
  bool _showLegend = true;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  final Map<int, bool> _lineVisibility = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await _dataService.fetchLandslideData();
      setState(() {
        _allData = data;
        _filteredData = List.from(_allData);
        _processData();
        ChartUtils.initLineVisibility(_lineVisibility, _filteredData.length);
        _selectedChart =
            _chartDataList.isNotEmpty ? _chartDataList[0].name : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _processData() {
    _chartDataList = _dataProcessor.processData(_filteredData);
  }

  Future<void> _selectDateTimeRange() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDateTime != null && _endDateTime != null
          ? DateTimeRange(start: _startDateTime!, end: _endDateTime!)
          : null,
    );

    if (dateRange != null) {
      final TimeOfDay? startTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDateTime ?? DateTime.now()),
      );

      if (startTime != null) {
        final TimeOfDay? endTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_endDateTime ?? DateTime.now()),
        );

        if (endTime != null) {
          setState(() {
            _startDateTime =
                ChartUtils.combineDateAndTime(dateRange.start, startTime);
            _endDateTime =
                ChartUtils.combineDateAndTime(dateRange.end, endTime);
            _filterDataByDateRange();
          });
        }
      }
    }
  }

  void _filterDataByDateRange() {
    _filteredData = ChartUtils.filterDataByDateRange(
        _allData, _startDateTime, _endDateTime);
    _processData();
    ChartUtils.initLineVisibility(_lineVisibility, _filteredData.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ'),
      ),
      endDrawer: ChartMenu(
        chartNames: _chartDataList.map((c) => c.name).toList(),
        selectedChart: _selectedChart,
        showLegend: _showLegend,
        onChartTypeChanged: (value) {
          setState(() {
            _selectedChart = value;
          });
        },
        onShowLegendChanged: (value) {
          setState(() {
            _showLegend = value;
          });
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedChart,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _selectDateTimeRange,
                  child: Text(ChartUtils.getDateRangeText(
                      _startDateTime, _endDateTime)),
                ),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.5,
                child: LineChart(
                  ChartUtils.getLineChartData(
                    _selectedChart,
                    _chartDataList,
                    _lineVisibility,
                    _filteredData,
                  ),
                ),
              ),
              if (_showLegend) ...[
                const SizedBox(height: 20),
                const Text(
                  'Chú thích:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...ChartUtils.buildLegendItems(
                  _selectedChart,
                  _lineVisibility,
                  _chartDataList,
                  _toggleLineVisibility,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLineVisibility(int index) {
    setState(() {
      _lineVisibility[index] = !(_lineVisibility[index] ?? true);
    });
  }
}
