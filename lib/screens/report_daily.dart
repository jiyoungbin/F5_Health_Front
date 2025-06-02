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

  // ─── 날짜 리스트 제어용 ScrollController ─────────────────
  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    // 초기 리포트 로드
    _loadRecord().then((_) {
      // 로드가 끝난 뒤 한 번만 중앙 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToDate(selectedDate);
      });
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  /// 서버에서 해당 날짜 리포트를 가져와 record에 저장
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

  // 일자 선택 리스트 생성 (해당 월의 1일 ~ 말일)
  List<DateTime> _generateMonthDays(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
  }

  /// (도우미) 주어진 date가 리스트에서 몇 번째 인덱스인지 반환
  int _indexOfDate(DateTime date, List<DateTime> monthDays) {
    for (int i = 0; i < monthDays.length; i++) {
      if (monthDays[i].day == date.day) {
        return i;
      }
    }
    return 0;
  }

  /// (도우미) 화면 중앙으로 날짜(i번째) 스크롤
  void _scrollToIndex(int index, int totalDays) {
    // 1) 하나의 아이템이 차지하는 전체 폭: width 48 + 좌우 margin 4+4 = 56
    const double itemExtent = 56.0;

    // 2) 화면 가로 전체 너비
    final double screenWidth = MediaQuery.of(context).size.width;

    // 3) 목표 스크롤 오프셋 계산:
    //    itemExtent * index → 해당 아이템의 시작 위치
    //    (screenWidth/2 − itemExtent/2) → 중앙 정렬 보정값
    double targetOffset =
        itemExtent * index - (screenWidth / 2 - itemExtent / 2);

    // 4) 음수거나 범위를 벗어나면 clamp
    final double maxScroll = itemExtent * totalDays - screenWidth;
    if (targetOffset < 0) targetOffset = 0;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    // 5) 애니메이션 스크롤
    _dateScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// (도우미) 현재 selectedDate에 해당하는 인덱스로 스크롤
  void _scrollToDate(DateTime date) {
    final days = _generateMonthDays(selectedDate);
    final idx = _indexOfDate(date, days);
    _scrollToIndex(idx, days.length);
  }

  // ─── 연도·월 선택용 위젯 ─────────────────
  Widget _buildYearMonthSelector() {
    // 현재 화면에 표시된 연도·월
    final currentYear = selectedDate.year;
    final currentMonth = selectedDate.month;

    // '현재 연도' 기준으로 3년 전부터 이번 년도까지 리스트 생성
    final int nowYear = DateTime.now().year;
    final List<int> yearList = List.generate(
      4,
      (i) => nowYear - i,
    ); // [2025, 2024, 2023, 2022]

    return Row(
      children: [
        // ① 연도 드롭다운
        DropdownButton<int>(
          value: currentYear,
          underline: const SizedBox(),
          items:
              yearList.map((yearValue) {
                return DropdownMenuItem(
                  value: yearValue,
                  child: Text(
                    '$yearValue년',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          yearValue == currentYear
                              ? Colors.deepPurple
                              : Colors.black87,
                      fontWeight:
                          yearValue == currentYear
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (newYear) {
            if (newYear == null) return;
            final int currentDay = selectedDate.day;
            final int newMonth = currentMonth;
            // 해당 연도·월의 마지막 날 계산
            final int lastDayOfNewMonth =
                DateTime(newYear, newMonth + 1, 0).day;
            final int adjustedDay =
                (currentDay <= lastDayOfNewMonth)
                    ? currentDay
                    : lastDayOfNewMonth;

            setState(() {
              selectedDate = DateTime(newYear, newMonth, adjustedDay);
            });
            // 리포트 다시 로드 후 스크롤 중앙 정렬
            _loadRecord().then((_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToDate(selectedDate);
              });
            });
          },
        ),

        const SizedBox(width: 12),

        // ② 월 드롭다운
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
            final int currentDay = selectedDate.day;
            final int currentYearLocal = selectedDate.year;
            // 선택된 연도·새 월의 마지막 날 계산
            final int lastDayOfNewMonth =
                DateTime(currentYearLocal, newMonth + 1, 0).day;
            final int adjustedDay =
                (currentDay <= lastDayOfNewMonth)
                    ? currentDay
                    : lastDayOfNewMonth;

            setState(() {
              selectedDate = DateTime(currentYearLocal, newMonth, adjustedDay);
            });
            // 리포트 다시 로드 후 스크롤 중앙 정렬
            _loadRecord().then((_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToDate(selectedDate);
              });
            });
          },
        ),
      ],
    );
  }

  // 일자 선택 리스트 위젯
  Widget _buildDateSelector() {
    final days = _generateMonthDays(selectedDate);
    return SizedBox(
      height: 60,
      child: ListView.builder(
        controller: _dateScrollController, // ScrollController 연결
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected =
              DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);

          return GestureDetector(
            onTap: () {
              // (1) selectedDate 업데이트
              setState(() => selectedDate = d);

              // (2) 리포트를 다시 불러온 뒤에, 스크롤을 중앙으로 옮겨야 함
              _loadRecord().then((_) {
                // 로딩이 완료된 후에 한 번만 중앙 정렬
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToDate(selectedDate);
                });
              });
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
                    // ① 연도·월 드롭다운 + 선택된 일자 표시
                    Row(
                      children: [
                        _buildYearMonthSelector(),
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

                    // ② 일자 목록 (ScrollController 연결하여 중앙 정렬)
                    _buildDateSelector(),
                    const SizedBox(height: 12),

                    // ③ 생활 습관 점수 카드
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

                    // ④ 전체 칼로리 카드
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

                    // ⑤ 미니 카드 (음수량/흡연량/음주량)
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

                    // ⑥ AI Feedback
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

  // ──────────────────────────────────────────────────────────────────

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
