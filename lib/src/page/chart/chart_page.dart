import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:truotlo/src/data/chart/chart_data.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';
import 'package:truotlo/src/database/landslide.dart';
import 'package:truotlo/src/page/chart/elements/chart_menu.dart';
import 'package:truotlo/src/user/auth_service.dart';
import 'package:truotlo/src/page/chart/elements/chart_data_processor.dart';
import 'package:truotlo/src/page/chart/elements/chart_utils.dart';
import 'package:intl/intl.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({Key? key}) : super(key: key);

  @override
  ChartPageState createState() => ChartPageState();
}

class ChartPageState extends State<ChartPage> {
  final LandslideDatabase _dataService = LandslideDatabase();
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
  String? _userRole;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndData();
  }

  Future<void> _fetchUserRoleAndData() async {
    try {
      final role = await UserPreferences.getUserRole();
      final isLoggedIn = await UserPreferences.isLoggedIn();
      setState(() {
        _userRole = role;
        _isAdmin = isLoggedIn && role == 'admin';
      });
      await _fetchData();
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi lấy dữ liệu người dùng: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await _dataService.fetchLandslideData(
        startDate: _startDateTime,
        endDate: _endDateTime,
      );
      if (data.isEmpty) {
        setState(() {
          _error = 'Không có dữ liệu trong khoảng thời gian đã chọn';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _allData = data;
        _filterDataBasedOnUserRole();
        _processData();
        ChartUtils.initLineVisibility(_lineVisibility, _filteredData.length);
        _selectedChart = _chartDataList.isNotEmpty ? _chartDataList[0].name : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _filterDataBasedOnUserRole() {
    _filteredData = ChartUtils.filterDataBasedOnUserRole(_allData, _isAdmin);
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
            _startDateTime = ChartUtils.combineDateAndTime(dateRange.start, startTime);
            _endDateTime = ChartUtils.combineDateAndTime(dateRange.end, endTime);
          });
          await _fetchData(); // Tải lại dữ liệu sau khi chọn khoảng thời gian
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      endDrawer: ChartMenu(
        chartNames: [..._chartDataList.map((c) => c.name), 'Đo nghiêng'],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedChart,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_isAdmin)
                    Center(
                      child: ElevatedButton(
                        onPressed: _selectDateTimeRange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          ChartUtils.getDateRangeText(_startDateTime, _endDateTime),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (!_isAdmin)
                    Center(
                      child: Text(
                        'Dữ liệu của 2 ngày gần nhất',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
            _buildChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    if (_chartDataList.isEmpty) {
      return const Center(child: Text('Không có dữ liệu để hiển thị'));
    }
    if (_selectedChart == 'Đo nghiêng') {
      return Column(
        children: [
          _buildSingleChart('Đo nghiêng, hướng Tây - Đông'),
          const SizedBox(height: 20),
          _buildSingleChart('Đo nghiêng, hướng Bắc - Nam'),
        ],
      );
    } else {
      return _buildSingleChart(_selectedChart);
    }
  }

  Widget _buildSingleChart(String chartName) {
    ChartData chartData = _chartDataList.firstWhere((chart) => chart.name == chartName);
    return Column(
      children: [
        Text(chartName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            ChartUtils.getLineChartData(
              chartName,
              _chartDataList,
              _lineVisibility,
              _filteredData,
              _isAdmin,
            ),
          ),
        ),
        if (_showLegend) ...[
          const SizedBox(height: 20),
          const Text('Chú thích:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ChartUtils.buildLegendItems(
                  chartName,
                  _lineVisibility,
                  _chartDataList,
                  _toggleLineVisibility,
                  _isAdmin,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _toggleLineVisibility(int index) {
    setState(() {
      _lineVisibility[index] = !(_lineVisibility[index] ?? true);
    });
  }
}