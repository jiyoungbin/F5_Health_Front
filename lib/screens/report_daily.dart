import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportDaily extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onBack;

  const ReportDaily({
    super.key,
    required this.selectedDate,
    required this.onBack,
  });

  @override
  State<ReportDaily> createState() => _ReportDailyState();
}

class _ReportDailyState extends State<ReportDaily> {
  late DateTime selectedDate;
  Map<String, dynamic>? record;
  bool isLoading = true;
  bool hasData = true;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    setState(() {
      isLoading = true;
      hasData = true;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    print('📅 [API] 리포트 로딩 시도 - date: $dateStr');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final res = await http.get(
        Uri.parse('http://localhost:8080/health/report?date=$dateStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🌐 status: ${res.statusCode}');

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded != null &&
            decoded is Map<String, dynamic> &&
            decoded.isNotEmpty) {
          setState(() {
            record = decoded;
            hasData = true;
          });
          print('📦 응답 내용 전체: ${jsonEncode(record)}');
        } else {
          setState(() {
            record = null;
            hasData = false;
          });
        }
      } else {
        setState(() {
          record = null;
          hasData = false;
        });
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
      setState(() {
        hasData = false;
        record = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<DateTime> _generateMonthDays(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
  }

  int _calculateTotalKcal() {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    return meals.fold(0, (sum, meal) => sum + (meal['totalKcal'] ?? 0));
  }

  Widget _buildMealSummary() {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    if (meals.isEmpty) return const Text('식단 정보 없음');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: meals.map<Widget>((meal) {
        final label = meal['mealTypeLabel'] ?? '식사';
        final kcal = meal['totalKcal'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '[$label] $kcal kcal',
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 MM월 dd일').format(selectedDate);
    final days = _generateMonthDays(selectedDate);
    final score = record?['score'] ?? 0;
    final totalKcal = _calculateTotalKcal();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: widget.onBack,
        ),
        title: const Text('일일 리포트'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? const Center(
                  child: Text('해당 날짜에는 기록된 데이터가 없습니다.',
                      style: TextStyle(fontSize: 16)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: days.length,
                          itemBuilder: (_, i) {
                            final d = days[i];
                            final isSelected = DateFormat('yyyy-MM-dd')
                                    .format(d) ==
                                DateFormat('yyyy-MM-dd').format(selectedDate);
                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedDate = d);
                                _loadRecord();
                              },
                              child: Container(
                                width: 48,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepPurple
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text('${d.day}',
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('생활 습관 점수: $score점',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      const Text("이 날의 식단 🍽️",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.deepPurple.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildMealSummary(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("📊 건강 정보",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.deepPurple.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoRow("💧 물 섭취량",
                                  "${record!['waterIntake'] ?? 0} ml"),
                              _infoRow("🚬 흡연량",
                                  "${record!['smokeCigarettes'] ?? 0} 개비"),
                              _infoRow("🍺 음주량",
                                  "${record!['alcoholDrinks'] ?? 0} 잔"),
                              _infoRow("🔥 총 섭취 칼로리", "$totalKcal kcal"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("💡 AI 피드백",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.deepPurple.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            record!['healthFeedback'] ?? '오늘은 피드백이 없습니다.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 18, color: Colors.black87)),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
        ],
      ),
    );
  }
}
