import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:f5_health/app_data.dart';
import 'package:f5_health/models/health_record.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedPage = "main";
  DateTime? selectedDate;
  HealthDailyRecord? selectedRecord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('리포트')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildPageContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/entry');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/savings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/badge');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '일괄 입력'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: '절약 금액'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '배지'),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildPageContent() {
    switch (selectedPage) {
      case "주간":
        return _buildWeeklyReport();
      case "월간":
        return _buildMonthlyReport();
      case "일간":
        return _buildDailyReport();
      default:
        return _buildMainReport();
    }
  }

  Widget _buildMainReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectableReportBox("일간", Icons.today),
              _buildSelectableReportBox("주간", Icons.calendar_today),
              _buildSelectableReportBox("월간", Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildWeeklyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("주간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("생활 습관 점수",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (_) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 70),
                            FlSpot(1, 80),
                            FlSpot(2, 75),
                            FlSpot(3, 90),
                            FlSpot(4, 85),
                            FlSpot(5, 88),
                            FlSpot(6, 82),
                          ],
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.deepPurple,
                                strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, _) {
                              const days = ['월', '화', '수', '목', '금', '토', '일'];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Text(days[value.toInt()],
                                    style: const TextStyle(fontSize: 12));
                              } else {
                                return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 20,
                            getTitlesWidget: (value, _) => Text(
                                "${value.toInt()}점",
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("월간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("생활 습관 점수",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (_) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 72),
                            FlSpot(5, 74),
                            FlSpot(10, 76),
                            FlSpot(15, 79),
                            FlSpot(20, 77),
                            FlSpot(25, 80),
                            FlSpot(30, 82),
                          ],
                          isCurved: true,
                          color: Colors.indigo,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.indigo,
                                strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 5,
                            getTitlesWidget: (value, _) {
                              return Text("${value.toInt()}일",
                                  style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 20,
                            getTitlesWidget: (value, _) => Text(
                                "${value.toInt()}점",
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("일간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: const Text("날짜 선택"),
          ),
          const SizedBox(height: 20),
          if (selectedDate != null)
            Text(
              "${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일 리포트",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 20),
          if (selectedDate != null && selectedRecord != null) ...[
            Text("🥤 총 음수량: ${selectedRecord!.waterIntake ~/ 250}잔"),
            const SizedBox(height: 8),
            Text("🚬 총 흡연량: ${selectedRecord!.smokingAmount}개비"),
            const SizedBox(height: 8),
            Text("🍺 음주량: ${selectedRecord!.alcoholAmount}잔"),
            const SizedBox(height: 8),
            Text("💸 음주 비용: ${selectedRecord!.alcoholSpentMoney}원"),
            const SizedBox(height: 8),
            Text("👟 걸음 수: ${selectedRecord!.stepCount}보"),
            const SizedBox(height: 8),
            Text("🛌 수면 시간: ${selectedRecord!.sleepHours}시간"),
            const SizedBox(height: 8),
            Text("🍽 식단 정보:"),
            const SizedBox(height: 4),
            ...selectedRecord!.meals.map((m) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                      "- ${m.mealType}: ${m.foods.map((f) => "${f.foodCode} x${f.count}").join(', ')}"),
                )),
          ] else if (selectedDate != null) ...[
            const Text("📭 해당 날짜의 데이터가 없습니다."),
          ],
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023, 1),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final key = picked.toIso8601String().split('T')[0];
      final record = AppData.healthBox?.get(key) as HealthDailyRecord?;
      setState(() {
        selectedDate = picked;
        selectedRecord = record;
      });
    }
  }

  Widget _buildAIFeedbackSection() {
    String overallFeedback =
        "어제 운동 시간과 칼로리 소모가 매우 우수하며, 걸음 수도 충분해 활동량이 높습니다. 흡연은 줄인 편이고, 소주 2잔 정도의 음주는 주기와 양을 고려할 때 무난합니다. 수면과 수분 섭취는 다소 부족하므로 개선이 필요합니다. 식단은 균형 잡혔으나 탄수화물이 약간 많습니다.";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AI 피드백",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple[50],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            overallFeedback,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableReportBox(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPage = title;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 36),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPage = "main";
          });
        },
        child: const Row(
          children: [
            Icon(Icons.arrow_back, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text("뒤로가기", style: TextStyle(color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedPage = "main"; // main, 주간, 월간, 일간
  DateTime? selectedDate; // 날짜 선택 저장

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리포트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildPageContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/entry');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/savings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/badge');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '일괄 입력'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: '절약 금액'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '배지'),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildPageContent() {
    switch (selectedPage) {
      case "주간":
        return _buildWeeklyReport();
      case "월간":
        return _buildMonthlyReport();
      case "일간":
        return _buildDailyReport();
      default:
        return _buildMainReport();
    }
  }

  Widget _buildMainReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectableReportBox("일간", Icons.today),
              _buildSelectableReportBox("주간", Icons.calendar_today),
              _buildSelectableReportBox("월간", Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

Widget _buildWeeklyReport() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const Text("주간 리포트",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // 📈 그래프 카드
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("생활 습관 점수",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 70),
                          FlSpot(1, 80),
                          FlSpot(2, 75),
                          FlSpot(3, 90),
                          FlSpot(4, 85),
                          FlSpot(5, 88),
                          FlSpot(6, 82),
                        ],
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.deepPurple,
                            strokeWidth: 0,
                           );
                          },
                        ),

                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, _) {
                            const days = ['월', '화', '수', '목', '금', '토', '일'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              );
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 20,
                          getTitlesWidget: (value, _) =>
                              Text("${value.toInt()}점",
                                  style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}


 Widget _buildMonthlyReport() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const Text("월간 리포트",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // 📈 그래프 카드
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("생활 습관 점수",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 72),
                          FlSpot(5, 74),
                          FlSpot(10, 76),
                          FlSpot(15, 79),
                          FlSpot(20, 77),
                          FlSpot(25, 80),
                          FlSpot(30, 82),
                        ],
                        isCurved: true,
                        color: Colors.indigo,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.indigo,
                              strokeWidth: 0,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 5,
                          getTitlesWidget: (value, _) {
                            return Text(
                              "${value.toInt()}일",
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 20,
                          getTitlesWidget: (value, _) => Text(
                            "${value.toInt()}점",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}



  Widget _buildDailyReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("일간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: const Text("날짜 선택"),
          ),
          const SizedBox(height: 20),
          if (selectedDate != null)
            Text(
              "${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일 리포트",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          if (selectedDate != null) const SizedBox(height: 20),
          if (selectedDate != null) ...[
            const Text("📊 오늘의 생활점수: 75점"),
            const SizedBox(height: 8),
            const Text("🥤 총 음수량: 5잔"),
            const SizedBox(height: 8),
            const Text("🚬 총 흡연량: 3개비"),
            const SizedBox(height: 8),
            const Text("🍺 음주량: 맥주 2잔, 소주 1잔"),
            const SizedBox(height: 8),
            const Text("🍽 식단 정보: 아침 - 계란, 점심 - 샐러드, 저녁 - 치킨"),
          ],
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023, 1),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildAIFeedbackSection() {
  String overallFeedback =
      "어제 운동 시간과 칼로리 소모가 매우 우수하며, 걸음 수도 충분해 활동량이 높습니다. 흡연은 줄인 편이고, 소주 2잔 정도의 음주는 주기와 양을 고려할 때 무난합니다. 수면과 수분 섭취는 다소 부족하므로 개선이 필요합니다. 식단은 균형 잡혔으나 탄수화물이 약간 많습니다.";
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("AI 피드백",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          overallFeedback,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}


  Widget _buildAIFeedbackCard(String emoji, String message) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Flexible(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableReportBox(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPage = title;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 36),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPage = "main";
          });
        },
        child: const Row(
          children: [
            Icon(Icons.arrow_back, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text("뒤로가기", style: TextStyle(color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
}

*/