// lib/src/page/chart/chart_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:truotlo/src/data/chart/chart_data.dart';
import 'package:truotlo/src/data/chart/landslide_data.dart';
import 'package:truotlo/src/data/chart/rainfall_data.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Data states
  List<LandslideDataModel> _allData = [];
  List<LandslideDataModel> _filteredData = [];
  List<RainfallData> _rainfallData = [];
  List<ChartData> _chartDataList = [];
  
  // UI states
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _error = '';
  String _selectedChart = '';
  bool _showLegend = true;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  final Map<int, bool> _lineVisibility = {};
  
  // User states
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
      if (mounted) {
        setState(() {
          _userRole = role;
          _isAdmin = isLoggedIn && role == 'admin';
        });
        await _fetchData(showLoadingIndicator: true);
      }
    } catch (e) {
      _handleError('Lỗi khi lấy dữ liệu người dùng: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
        _isRefreshing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _fetchData({bool showLoadingIndicator = false}) async {
    if (!mounted) return;

    setState(() {
      if (showLoadingIndicator) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
      _error = '';
      
      // Clear existing data
      _allData = [];
      _rainfallData = [];
      _filteredData = [];
      _chartDataList = [];
    });

    try {
      // Fetch both landslide and rainfall data
      final landslideFuture = _dataService.fetchLandslideData(
        startDate: _startDateTime,
        endDate: _endDateTime,
      );
      
      final rainfallFuture = RainfallDataService.fetchRainfallData(
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
      );

      print('Fetching data for range: ${_startDateTime?.toString()} - ${_endDateTime?.toString()}');

      final results = await Future.wait([landslideFuture, rainfallFuture]);
      
      final landslideData = results[0] as List<LandslideDataModel>;
      final rainfallData = results[1] as List<RainfallData>;

      print('Received ${landslideData.length} landslide records');
      print('Received ${rainfallData.length} rainfall records');

      if (!mounted) return;

      if (landslideData.isEmpty && rainfallData.isEmpty) {
        _handleError('Không có dữ liệu trong khoảng thời gian đã chọn');
        return;
      }

      setState(() {
        _allData = landslideData;
        _rainfallData = rainfallData;
        _filterDataBasedOnUserRole();
        _processData();
        
        // Initialize line visibility if needed
        if (_lineVisibility.isEmpty) {
          ChartUtils.initLineVisibility(_lineVisibility, _filteredData.length);
        }
        
        // Select first chart if none selected
        if (_selectedChart.isEmpty || !_chartDataList.any((chart) => chart.name == _selectedChart)) {
          _selectedChart = _chartDataList.isNotEmpty ? _chartDataList[0].name : '';
        }
        
        _isLoading = false;
        _isRefreshing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật dữ liệu: ${rainfallData.length} bản ghi lượng mưa',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error fetching data: $e');
      _handleError('Lỗi khi tải dữ liệu: $e');
    }
  }

  void _filterDataBasedOnUserRole() {
    _filteredData = ChartUtils.filterDataBasedOnUserRole(_allData, _isAdmin);
    if (!_isAdmin && _startDateTime == null && _endDateTime == null) {
      _rainfallData = ChartUtils.filterRainfallDataBasedOnUserRole(_rainfallData, _isAdmin);
    }
  }

  void _processData() {
    _chartDataList = _dataProcessor.processData(_filteredData, _rainfallData);
  }

  Future<void> _selectDateTimeRange() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDateTime != null && _endDateTime != null
          ? DateTimeRange(start: _startDateTime!, end: _endDateTime!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null && mounted) {
      // Set start time to 00:00:00
      final startDateTime = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
      );

      // Set end time to 23:59:59
      final endDateTime = DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
        23,
        59,
        59,
      );

      setState(() {
        _startDateTime = startDateTime;
        _endDateTime = endDateTime;
      });

      await _fetchData(showLoadingIndicator: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      endDrawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Biểu đồ', style: TextStyle(color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: Colors.blue,
      elevation: 2,
      actions: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : () => _fetchData(),
          tooltip: 'Làm mới dữ liệu',
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          tooltip: 'Menu biểu đồ',
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return ChartMenu(
      chartNames: [..._chartDataList.map((c) => c.name)],
      selectedChart: _selectedChart,
      showLegend: _showLegend,
      onChartTypeChanged: (value) {
        setState(() {
          _selectedChart = value;
        });
        Navigator.pop(context);
      },
      onShowLegendChanged: (value) {
        setState(() {
          _showLegend = value;
        });
      },
      isAdmin: _isAdmin,
      onDateRangeSelect: _selectDateTimeRange,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _fetchData(showLoadingIndicator: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_chartDataList.isEmpty)
              _buildNoDataWidget()
            else
              _buildChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedChart,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isAdmin || _selectedChart.contains('Lượng mưa'))
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _selectDateTimeRange,
                  tooltip: 'Chọn khoảng thời gian',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getDateRangeDisplayText(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeDisplayText() {
    if (_startDateTime != null && _endDateTime != null) {
      final startStr = DateFormat('dd/MM/yyyy HH:mm').format(_startDateTime!);
      final endStr = DateFormat('dd/MM/yyyy HH:mm').format(_endDateTime!);
      return 'Từ $startStr đến $endStr';
    } else if (!_isAdmin) {
      return 'Dữ liệu của 2 ngày gần nhất';
    }
    return 'Tất cả dữ liệu';
  }

  Widget _buildChartContent() {
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
    final ChartData chartData = _chartDataList.firstWhere((chart) => chart.name == chartName);
    final bool isRainfallChart = chartName.contains('Lượng mưa');
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            chartName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: chartName.contains('Lượng mưa') ? 2.0 : 1.5,
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
        if (isRainfallChart) ...[
          const SizedBox(height: 10),
          _buildRainfallSummaryCard(chartData),
        ],
        if (_showLegend) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chú thích:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRainfallSummaryCard(ChartData chartData) {
    if (!chartData.name.contains('Lượng mưa')) return const SizedBox.shrink();

    final bool isCumulative = chartData.name == 'Lượng mưa tích lũy';
    final Color cardColor = isCumulative ? Colors.green.shade50 : Colors.blue.shade50;
    final Color textColor = isCumulative ? Colors.green : Colors.blue;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'Thống kê lượng mưa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getRainfallSummary(chartData),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            if (isCumulative) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text(
                'Thời gian bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(chartData.dates.first)}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Thời gian kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(chartData.dates.last)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRainfallSummary(ChartData chartData) {
    if (chartData.name == 'Lượng mưa tích lũy') {
      final totalRainfall = chartData.dataPoints[0].last;
      final duration = chartData.dates.last.difference(chartData.dates.first);
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      
      String durationText = '';
      if (days > 0) {
        durationText += '$days ngày ';
      }
      if (hours > 0 || days == 0) {
        durationText += '$hours giờ';
      }
      
      return 'Tổng lượng mưa: ${totalRainfall.toStringAsFixed(1)} mm trong $durationText';
    } else if (chartData.name == 'Lượng mưa') {
      final maxRainfall = chartData.dataPoints[0].reduce((max, value) => max > value ? max : value);
      final maxRainfallTime = chartData.dates[
        chartData.dataPoints[0].indexOf(maxRainfall)
      ];
      
      return 'Lượng mưa cao nhất: ${maxRainfall.toStringAsFixed(1)} mm (${DateFormat('dd/MM/yyyy HH:mm').format(maxRainfallTime)})';
    }
    return '';
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _fetchData(showLoadingIndicator: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.blue[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có dữ liệu trong khoảng thời gian đã chọn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (_startDateTime != null && _endDateTime != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectDateTimeRange,
                icon: const Icon(Icons.date_range),
                label: const Text('Chọn khoảng thời gian khác'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleLineVisibility(int index) {
    setState(() {
      _lineVisibility[index] = !(_lineVisibility[index] ?? true);
    });
  }

  @override
  void dispose() {
    _scaffoldKey.currentState?.dispose();
    super.dispose();
  }
}