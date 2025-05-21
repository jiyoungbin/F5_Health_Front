// ✅ 수정된 report_screen.dart — ReportDaily가 selectedDate만 받도록 변경 + named parameter 오류 제거
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/report_daily.dart';
import '../screens/report_weekly.dart';
import '../screens/report_monthly.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedPage = "main";
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("리포트")),
      body: _buildPageContent(),
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
      case "일간":
        return ReportDaily(
          selectedDate: selectedDate,
          onBack: () => setState(() => selectedPage = "main"),
        );
      case "주간":
        return ReportWeekly(
            onBack: () => setState(() => selectedPage = "main"));
      case "월간":
        return ReportMonthly(
            onBack: () => setState(() => selectedPage = "main"));
      default:
        return _buildMainReport();
    }
  }

  Widget _buildMainReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectableReportBox("일간", Icons.today),
            _buildSelectableReportBox("주간", Icons.calendar_today),
            _buildSelectableReportBox("월간", Icons.calendar_month),
          ],
        ),
        const SizedBox(height: 24),
        const Center(child: Text("리포트를 선택하세요")),
      ],
    );
  }

  Widget _buildSelectableReportBox(String title, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => selectedPage = title),
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
}
