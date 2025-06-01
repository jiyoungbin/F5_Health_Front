import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_meal_report.dart';
import '../config.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final res = await http.get(
        Uri.parse('${Config.baseUrl}/health/report?date=$dateStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
          setState(() {
            record = decoded;
            hasData = true;
          });
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
      setState(() {
        hasData = false;
        record = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 날짜 리스트(일) 생성
  List<DateTime> _generateMonthDays(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
  }

  // 일자 선택 리스트
  Widget _buildDateSelector() {
    final days = _generateMonthDays(selectedDate);
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected =
              DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() => selectedDate = d);
              _loadRecord();
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${d.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ① 월 선택용 드롭다운
  Widget _buildMonthSelector() {
    final currentYear = selectedDate.year;
    final currentMonth = selectedDate.month;

    return Row(
      children: [
        // 연도 텍스트
        Text(
          '$currentYear년 ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        // 월 드롭다운
        DropdownButton<int>(
          value: currentMonth,
          underline: const SizedBox(),
          items: List.generate(12, (i) {
            final monthValue = i + 1;
            return DropdownMenuItem(
              value: monthValue,
              child: Text(
                '$monthValue월',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      monthValue == currentMonth
                          ? Colors.deepPurple
                          : Colors.black87,
                  fontWeight:
                      monthValue == currentMonth
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            );
          }),
          onChanged: (newMonth) {
            if (newMonth == null) return;
            setState(() {
              final day = selectedDate.day;
              final lastDayOfNewMonth =
                  DateTime(currentYear, newMonth + 1, 0).day;
              final newDay = day <= lastDayOfNewMonth ? day : lastDayOfNewMonth;
              selectedDate = DateTime(currentYear, newMonth, newDay);
            });
            _loadRecord();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = record?['score'] ?? 0;
    final totalKcal = _calculateTotalKcal();
    final double totalCarb = _calculateTotal('carbohydrate');
    final double totalProtein = _calculateTotal('protein');
    final double totalFat = _calculateTotal('fat');
    final double total = totalCarb + totalProtein + totalFat;
    final double carbRatio = total > 0 ? totalCarb / total : 0;
    final double proteinRatio = total > 0 ? totalProtein / total : 0;
    final double fatRatio = total > 0 ? totalFat / total : 0;
    final scoreRatio = (score.clamp(0, 100)) / 100;
    final scoreColor = Color.lerp(Colors.red, Colors.green, scoreRatio)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("일일 리포트", style: TextStyle(color: Colors.deepPurple)),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ① 월 드롭다운 + 선택된 일자 표시
                    Row(
                      children: [
                        _buildMonthSelector(),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}일',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ② 일자 목록 (기존)
                    _buildDateSelector(),
                    const SizedBox(height: 12),

                    // ③ 생활 습관 점수, 칼로리 카드, 미니 카드, AI Feedback 등 나머지 UI
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "생활 습관 점수",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$score점",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: scoreRatio,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(scoreColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EDFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "🍽️ 전체 칼로리",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => MealDetailScreenServer(
                                            date: selectedDate,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$totalKcal kcal",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBar(
                            "단백질",
                            proteinRatio,
                            Colors.purple.shade200,
                          ),
                          const SizedBox(height: 8),
                          _buildBar(
                            "탄수화물",
                            carbRatio,
                            Colors.lightBlue.shade100,
                          ),
                          const SizedBox(height: 8),
                          _buildBar("지방", fatRatio, Colors.green.shade100),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        _miniCard(
                          "💧",
                          "음수량",
                          "${record?['waterIntake'] ?? 0} ml",
                        ),
                        const SizedBox(width: 12),
                        _miniCard(
                          "🚬",
                          "흡연량",
                          "${record?['smokeCigarettes'] ?? 0} 개비",
                        ),
                        const SizedBox(width: 12),
                        _miniCard(
                          "🍺",
                          "음주량",
                          "${record?['alcoholDrinks'] ?? 0} ml",
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Icon(Icons.smart_toy, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          "AI Feedback",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EDFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        record?['healthFeedback'] ?? '오늘은 피드백이 없습니다.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // (기존 메서드 그대로 유지)
  int _calculateTotalKcal() {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    return meals.fold(0, (sum, meal) => sum + (meal['totalKcal'] ?? 0));
  }

  double _calculateTotal(String key) {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    switch (key) {
      case 'carbohydrate':
        return meals.fold(
          0.0,
          (sum, meal) => sum + (meal['totalCarbohydrate'] ?? 0.0),
        );
      case 'protein':
        return meals.fold(
          0.0,
          (sum, meal) => sum + (meal['totalProtein'] ?? 0.0),
        );
      case 'fat':
        return meals.fold(0.0, (sum, meal) => sum + (meal['totalFat'] ?? 0.0));
      default:
        return 0.0;
    }
  }

  Widget _buildBar(String label, double ratio, Color color) {
    final percent = (ratio * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text("$percent%", style: TextStyle(color: Colors.deepPurple)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  Widget _miniCard(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EDFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}


/*
// ReportDaily 화면 - 날짜 선택과 생활 습관 점수 UI 추가 + 탄단지 비율 바 색상 및 퍼센트 표시 추가
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_meal_report.dart';
import '../config.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final res = await http.get(
        Uri.parse('${Config.baseUrl}/health/report?date=$dateStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
          setState(() {
            record = decoded;
            hasData = true;
          });
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
      setState(() {
        hasData = false;
        record = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  int _calculateTotalKcal() {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    return meals.fold(0, (sum, meal) => sum + (meal['totalKcal'] ?? 0));
  }

  double _calculateTotal(String key) {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    switch (key) {
      case 'carbohydrate':
        return meals.fold(
          0.0,
          (sum, meal) => sum + (meal['totalCarbohydrate'] ?? 0.0),
        );
      case 'protein':
        return meals.fold(
          0.0,
          (sum, meal) => sum + (meal['totalProtein'] ?? 0.0),
        );
      case 'fat':
        return meals.fold(0.0, (sum, meal) => sum + (meal['totalFat'] ?? 0.0));
      default:
        return 0.0;
    }
  }

  List<DateTime> _generateMonthDays(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
  }

  Widget _buildDateSelector() {
    final days = _generateMonthDays(selectedDate);
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected =
              DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() => selectedDate = d);
              _loadRecord();
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${d.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 MM월 dd일').format(selectedDate);
    final score = record?['score'] ?? 0;
    final totalKcal = _calculateTotalKcal();
    final double totalCarb = _calculateTotal('carbohydrate');
    final double totalProtein = _calculateTotal('protein');
    final double totalFat = _calculateTotal('fat');
    final double total = totalCarb + totalProtein + totalFat;
    final double carbRatio = total > 0 ? totalCarb / total : 0;
    final double proteinRatio = total > 0 ? totalProtein / total : 0;
    final double fatRatio = total > 0 ? totalFat / total : 0;
    // ✅ 수정: 생활 습관 점수 색상 바 생성
    final scoreRatio = (score.clamp(0, 100)) / 100;
    final scoreColor = Color.lerp(Colors.red, Colors.green, scoreRatio)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("일일 리포트", style: TextStyle(color: Colors.deepPurple)),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDateSelector(),
                    const SizedBox(height: 12),
                    // ✅ 수정: 생활 습관 점수 박스 + 프로그레스바
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "생활 습관 점수",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$score점",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: scoreRatio,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(scoreColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 칼로리 카드
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EDFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "🍽️ 전체 칼로리",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => MealDetailScreenServer(
                                            date: selectedDate,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$totalKcal kcal",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBar(
                            "단백질",
                            proteinRatio,
                            Colors.purple.shade200,
                          ),
                          const SizedBox(height: 8),
                          _buildBar(
                            "탄수화물",
                            carbRatio,
                            Colors.lightBlue.shade100,
                          ),
                          const SizedBox(height: 8),
                          _buildBar("지방", fatRatio, Colors.green.shade100),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        _miniCard(
                          "💧",
                          "음수량",
                          "${record?['waterIntake'] ?? 0} ml",
                        ),
                        const SizedBox(width: 12),
                        _miniCard(
                          "🚬",
                          "흡연량",
                          "${record?['smokeCigarettes'] ?? 0} 개비",
                        ),
                        const SizedBox(width: 12),
                        _miniCard(
                          "🍺",
                          "음주량",
                          "${record?['alcoholDrinks'] ?? 0} ml",
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Icon(Icons.smart_toy, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          "AI Feedback",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EDFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        record?['healthFeedback'] ?? '오늘은 피드백이 없습니다.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildBar(String label, double ratio, Color color) {
    final percent = (ratio * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text("$percent%", style: TextStyle(color: Colors.deepPurple)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  Widget _miniCard(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EDFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}
*/