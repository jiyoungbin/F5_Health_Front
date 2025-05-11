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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("주간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
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
                    isCurved: false,
                    color: Colors.deepPurple,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const days = ['월', '화', '수', '목', '금', '토', '일'];
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("월간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
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
                    isCurved: false,
                    color: Colors.indigo,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, _) => Text("${value.toInt()}일"),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
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
    int waterIntake = 3;
    int steps = 2000;

    String waterFeedback = waterIntake < 5 ? "물을 더 마셔주세요" : "수분 섭취가 충분합니다!";
    String stepsFeedback = steps < 5000 ? "조금 더 걸어보세요" : "활동량이 충분합니다!";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AI 피드백",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAIFeedbackCard("💧", waterFeedback),
            const SizedBox(width: 12),
            _buildAIFeedbackCard("🚶", stepsFeedback),
          ],
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


/*
import 'package:flutter/material.dart';

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

  // 메인 리포트 화면
  Widget _buildMainReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectableReportBox("일간", Icons.today), // 일간 버튼을 가장 앞으로
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

  // 주간 리포트
  Widget _buildWeeklyReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("주간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("여기에 주간 리포트 데이터 표시"),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  // 월간 리포트
  Widget _buildMonthlyReport() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Text("월간 리포트",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("여기에 월간 리포트 데이터 표시"),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  // 일간 리포트 (달력만)
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
          if (selectedDate != null) const Text("여기에 선택한 날짜 리포트 데이터 표시"),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(),
        ],
      ),
    );
  }

  // 날짜 선택기
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

  // AI 피드백 섹션
  Widget _buildAIFeedbackSection() {
    int waterIntake = 3;
    int steps = 2000;

    String waterFeedback = waterIntake < 5 ? "물을 더 마셔주세요" : "수분 섭취가 충분합니다!";
    String stepsFeedback = steps < 5000 ? "조금 더 걸어보세요" : "활동량이 충분합니다!";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AI 피드백",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAIFeedbackCard("💧", waterFeedback),
            const SizedBox(width: 12),
            _buildAIFeedbackCard("🚶", stepsFeedback),
          ],
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

  // 주간/월간/일간 선택 박스
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

