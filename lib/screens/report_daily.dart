// ReportDaily 화면 - 날짜 선택과 생활 습관 점수 UI 추가 + 탄단지 비율 바 색상 및 퍼센트 표시 추가
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_meal_report.dart';

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
        Uri.parse('http://localhost:8080/health/report?date=$dateStr'),
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
            0.0, (sum, meal) => sum + (meal['totalCarbohydrate'] ?? 0.0));
      case 'protein':
        return meals.fold(
            0.0, (sum, meal) => sum + (meal['totalProtein'] ?? 0.0));
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
          final isSelected = DateFormat('yyyy-MM-dd').format(d) ==
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
                child: Text('${d.day}',
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
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
                            const Text("생활 습관 점수",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("$score점",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor)),
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
                            const Text("Calories",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.search,
                                  color: Colors.deepPurple),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MealDetailScreenServer(
                                        date: selectedDate),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("$totalKcal kcal",
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildBar("단백질", proteinRatio, Colors.purple.shade200),
                        const SizedBox(height: 8),
                        _buildBar("탄수화물", carbRatio, Colors.lightBlue.shade100),
                        const SizedBox(height: 8),
                        _buildBar("지방", fatRatio, Colors.green.shade100),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      _miniCard("💧", "음수량", "${record?['waterIntake']} ml"),
                      const SizedBox(width: 12),
                      _miniCard(
                          "🚬", "흡연량", "${record?['smokeCigarettes']} 개비"),
                      const SizedBox(width: 12),
                      _miniCard("🍺", "음주량", "${record?['alcoholDrinks']} 잔"),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: const [
                      Icon(Icons.smart_toy, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text("AI Feedback",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EDFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(record?['healthFeedback'] ?? '오늘은 피드백이 없습니다.',
                        style: const TextStyle(fontSize: 16)),
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



/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_meal_report.dart';

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

  Widget _buildDateSelector() {
    final days = _generateMonthDays(selectedDate);
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected = DateFormat('yyyy-MM-dd').format(d) ==
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
                child: Text('${d.day}',
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ 수정된 부분: 서버 응답 키와 매핑
  double _calculateTotal(String key) {
    final meals = record?['mealsResponse']?['mealResponseList'] ?? [];
    switch (key) {
      case 'carbohydrate':
        return meals.fold(
            0.0, (sum, meal) => sum + (meal['totalCarbohydrate'] ?? 0.0));
      case 'protein':
        return meals.fold(
            0.0, (sum, meal) => sum + (meal['totalProtein'] ?? 0.0));
      case 'fat':
        return meals.fold(0.0, (sum, meal) => sum + (meal['totalFat'] ?? 0.0));
      default:
        return 0.0;
    }
  }

  Widget _buildReportContents(int score, int totalKcal) {
    // ✅ 수정된 부분: 정확한 영양 키로부터 합산
    final double totalCarb = _calculateTotal('carbohydrate');
    final double totalProtein = _calculateTotal('protein');
    final double totalFat = _calculateTotal('fat');
    final double total = totalCarb + totalProtein + totalFat;
    final double carbRatio = total > 0 ? totalCarb / total : 0;
    final double proteinRatio = total > 0 ? totalProtein / total : 0;
    final double fatRatio = total > 0 ? totalFat / total : 0;

    final int recommendedKcal =
        record?['mealsResponse']?['recommendedCalories'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('생활 습관 점수: $score점',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        const Text("이 날의 식단 🍽️",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple)),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey.shade100,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ [수정된 부분] 총 섭취 칼로리 / 권장 칼로리 표시
                    Text('$totalKcal / $recommendedKcal kcal',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('탄 ${(carbRatio * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.deepPurple)),
                        const SizedBox(width: 8),
                        Text('단 ${(proteinRatio * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.blue)),
                        const SizedBox(width: 8),
                        Text('지 ${(fatRatio * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.teal)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MealDetailScreenServer(date: selectedDate),
                      ),
                    );
                  },
                ),
              ],
            ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow("💧 물 섭취량", "${record!['waterIntake'] ?? 0} ml"),
                _infoRow("🚬 흡연량", "${record!['smokeCigarettes'] ?? 0} 개비"),
                _infoRow("🍺 음주량", "${record!['alcoholDrinks'] ?? 0} 잔"),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 MM월 dd일').format(selectedDate);
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  if (!hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Text('해당 날짜에는 기록된 데이터가 없습니다.',
                            style: TextStyle(fontSize: 16)),
                      ),
                    )
                  else
                    _buildReportContents(score, totalKcal),
                ],
              ),
            ),
    );
  }
}
*/