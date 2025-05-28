import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportWeekly extends StatefulWidget {
  final VoidCallback onBack;
  const ReportWeekly({super.key, required this.onBack});

  @override
  State<ReportWeekly> createState() => _ReportWeeklyState();
}

// 차트 데이터 모델
class ChartData {
  final String day;
  final double score;
  ChartData(this.day, this.score);
}

class _ReportWeeklyState extends State<ReportWeekly> {
  int weekOffset = 0;
  Map<String, double> scoreMap = {};
  bool isLoading = true;
  String dateRangeLabel = '';
  late DateTime startOfWeek;

  @override
  void initState() {
    super.initState();
    _loadWeeklyReport();
  }

  Future<void> _loadWeeklyReport() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = thisMonday.subtract(Duration(days: 7 * weekOffset));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (endOfWeek.isAfter(now)) endOfWeek = now;

    final formatter = DateFormat('yyyy-MM-dd');
    dateRangeLabel =
        '(${DateFormat('yyyy.MM.dd').format(startOfWeek)} ~ ${DateFormat('yyyy.MM.dd').format(endOfWeek)})';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final url = Uri.parse('http://localhost:8080/health/report/scores');
    final client = http.Client();
    final request =
        http.Request('GET', url)
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({
            "start": formatter.format(startOfWeek),
            "end": formatter.format(endOfWeek),
          });

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['scores'] as List<dynamic>;
      scoreMap = {
        for (var e in data)
          if (e['endDate'] is String && e['healthLifeScore'] is num)
            e['endDate']: (e['healthLifeScore'] as num).toDouble(),
      };
    } else {
      scoreMap = {};
    }

    setState(() => isLoading = false);
  }

  void _changeWeek(int offset) {
    setState(() => weekOffset = offset);
    _loadWeeklyReport();
  }

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    final chartData =
        List<ChartData>.generate(7, (i) {
          final d = startOfWeek.add(Duration(days: i));
          final key = DateFormat('yyyy-MM-dd').format(d);
          final score = scoreMap[key] ?? double.nan;
          return ChartData(days[i], score);
        }).where((d) => !d.score.isNaN).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("뒤로가기", style: TextStyle(color: Colors.deepPurple)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "주간 리포트",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              DropdownButton<int>(
                value: weekOffset,
                items: List.generate(4, (idx) {
                  final label =
                      idx == 0
                          ? '이번 주'
                          : idx == 1
                          ? '지난 주'
                          : '$idx주 전';
                  return DropdownMenuItem(value: idx, child: Text(label));
                }),
                onChanged: (v) {
                  if (v != null) _changeWeek(v);
                },
              ),
              const SizedBox(width: 8),
              Text(dateRangeLabel),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: 280,
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SfCartesianChart(
                        margin: const EdgeInsets.only(bottom: 50),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        primaryXAxis: CategoryAxis(
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: 100,
                          interval: 20,
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                        series: <LineSeries<ChartData, String>>[
                          LineSeries<ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (d, _) => d.day,
                            yValueMapper: (d, _) => d.score,
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                            ),
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                              offset: const Offset(0, -10),
                            ),
                            width: 3,
                            onCreateShader: (ShaderDetails details) {
                              return const LinearGradient(
                                colors: [
                                  Colors.deepPurpleAccent,
                                  Colors.deepPurple,
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ).createShader(details.rect);
                            },
                            animationDuration: 500,
                          ),
                        ],
                      ),
            ),
          ),
          if (!isLoading && chartData.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  '이번 주 데이터가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportWeekly extends StatefulWidget {
  final VoidCallback onBack;

  const ReportWeekly({super.key, required this.onBack});

  @override
  State<ReportWeekly> createState() => _ReportWeeklyState();
}

class _ReportWeeklyState extends State<ReportWeekly> {
  int weekOffset = 0;
  List<FlSpot> spots = [];
  bool isLoading = true;
  String weekLabel = '';
  String dateRangeLabel = '';

  @override
  void initState() {
    super.initState();
    _loadWeeklyReport();
  }

  void _loadWeeklyReport() async {
    setState(() {
      isLoading = true;
    });

    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = thisMonday.subtract(Duration(days: 7 * weekOffset));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (endOfWeek.isAfter(now)) {
      endOfWeek = now;
    }

    final formatter = DateFormat('yyyy-MM-dd');
    final startStr = formatter.format(startOfWeek);
    final endStr = formatter.format(endOfWeek);

    weekLabel = weekOffset == 0
        ? '이번 주'
        : weekOffset == 1
            ? '지난 주'
            : '$weekOffset주 전';
    dateRangeLabel =
        '(${DateFormat('yyyy.MM.dd').format(startOfWeek)} ~ ${DateFormat('yyyy.MM.dd').format(endOfWeek)})';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final url = Uri.parse('http://localhost:8080/health/report/scores');
    final client = http.Client();

    final request = http.Request('GET', url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        "start": startStr,
        "end": endStr,
      });

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['scores'];

      final Map<String, double> scoreMap = {};
      for (var e in data) {
        final date = e['endDate'];
        final score = e['healthLifeScore'];
        if (date is String && score is num) {
          scoreMap[date] = score.toDouble();
        }
      }

      final List<FlSpot> tempSpots = List.generate(7, (i) {
        final day = startOfWeek.add(Duration(days: i));
        final dayStr = DateFormat('yyyy-MM-dd').format(day);
        final score = scoreMap[dayStr];
        return score != null
            ? FlSpot(i.toDouble(), score)
            : FlSpot(i.toDouble(), double.nan); // 점/선 표시 안함
      });

      setState(() {
        spots = tempSpots;
        isLoading = false;
      });
    } else {
      setState(() {
        spots = [];
        isLoading = false;
      });
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      weekOffset = offset;
    });
    _loadWeeklyReport();
  }

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("뒤로가기", style: TextStyle(color: Colors.deepPurple)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("주간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              DropdownButton<int>(
                value: weekOffset,
                items: List.generate(
                  4,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      index == 0
                          ? '이번 주'
                          : index == 1
                              ? '지난 주'
                              : '$index주 전',
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    _changeWeek(value);
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(dateRangeLabel),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: 280,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        lineBarsData: spots.isEmpty
                            ? []
                            : [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  color: Colors.deepPurple,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  preventCurveOverShooting: true,
                                  dotData: FlDotData(
                                    show: true,
                                    checkToShowDot: (spot, _) => !spot.y.isNaN,
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                final i = value.toInt();
                                return Text(
                                  i >= 0 && i < 7 ? days[i] : '',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              getTitlesWidget: (value, _) => Text(
                                "${value.toInt()}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
            ),
          ),
          if (!isLoading && spots.every((e) => e.y.isNaN))
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  '이번 주 데이터가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
*/
