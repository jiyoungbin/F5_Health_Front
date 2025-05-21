import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReportMonthly extends StatefulWidget {
  final VoidCallback onBack;

  const ReportMonthly({super.key, required this.onBack});

  @override
  State<ReportMonthly> createState() => _ReportMonthlyState();
}

class _ReportMonthlyState extends State<ReportMonthly> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  List<FlSpot> spots = [];
  bool isLoading = true;
  String dateRangeLabel = '';

  @override
  void initState() {
    super.initState();
    _loadMonthlyReport();
  }

  Future<void> _loadMonthlyReport() async {
    setState(() {
      isLoading = true;
    });

    final startOfMonth = DateTime(selectedYear, selectedMonth, 1);
    DateTime endOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);
    final today = DateTime.now();

    if (endOfMonth.isAfter(today)) {
      endOfMonth = today;
    }

    final formatter = DateFormat('yyyy-MM-dd');
    final startStr = formatter.format(startOfMonth);
    final endStr = formatter.format(endOfMonth);

    dateRangeLabel =
        '${DateFormat('yyyy.MM.dd').format(startOfMonth)} ~ ${DateFormat('yyyy.MM.dd').format(endOfMonth)}';

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

      final now = DateTime.now();
      final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;

      final List<FlSpot> tempSpots = List.generate(lastDay, (i) {
        final dayIndex = i + 1;
        final date = DateTime(selectedYear, selectedMonth, dayIndex);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        if (date.isAfter(now)) {
          return FlSpot(dayIndex.toDouble(), double.nan); // 미래는 표시 안함
        }

        final score = scoreMap[dateStr];
        return score != null
            ? FlSpot(dayIndex.toDouble(), score)
            : FlSpot(dayIndex.toDouble(), double.nan); // 점/선 없음
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
      print('❌ 월간 데이터 불러오기 실패');
    }
  }

  void _changeMonth(int month) {
    setState(() {
      selectedMonth = month;
    });
    _loadMonthlyReport();
  }

  void _changeYear(int year) {
    setState(() {
      selectedYear = year;
    });
    _loadMonthlyReport();
  }

  @override
  Widget build(BuildContext context) {
    final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;

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
          const Text("월간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(
                    value: DateTime.now().year - i,
                    child: Text('${DateTime.now().year - i}년'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    _changeYear(value);
                  }
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: selectedMonth,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}월'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    _changeMonth(value);
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
                  : spots.isEmpty
                      ? const Center(child: Text('데이터가 없습니다.'))
                      : LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: false,
                                color: Colors.indigo,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, _) =>
                                      !spot.y.isNaN, // NaN인 날은 점 없음
                                ),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  getTitlesWidget: (value, _) => Text(
                                    '${value.toInt()}일',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  getTitlesWidget: (value, _) => Text(
                                    '${value.toInt()}점',
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
        ],
      ),
    );
  }
}
