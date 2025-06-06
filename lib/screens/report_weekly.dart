import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

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

    final url = Uri.parse('${Config.baseUrl}/health/report/scores');
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
