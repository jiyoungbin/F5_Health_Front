// Flutter 메인 리포트 화면 - 선택된 리포트만 올라오고 전환 시 기존 리포트는 내려감
import 'package:flutter/material.dart';
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSelectableReportBox("일간", Icons.today),
                _buildSelectableReportBox("주간", Icons.calendar_today),
                _buildSelectableReportBox("월간", Icons.calendar_month),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: selectedPage == "main"
                  ? const SizedBox()
                  : Container(
                      key: ValueKey(selectedPage),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          )
                        ],
                      ),
                      child: _buildPageContent(),
                    ),
            ),
          ),
        ],
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
      case "일간":
        return ReportDaily(
          selectedDate: selectedDate,
          onBack: () => setState(() => selectedPage = "main"),
        );
      case "주간":
        return ReportWeekly(
          onBack: () => setState(() => selectedPage = "main"),
        );
      case "월간":
        return ReportMonthly(
          onBack: () => setState(() => selectedPage = "main"),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSelectableReportBox(String title, IconData icon) {
    final isSelected = selectedPage == title;
    return GestureDetector(
      onTap: () {
        if (selectedPage != title) {
          setState(() => selectedPage = title);
        }
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
          border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.deepPurple : Colors.grey, size: 30),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.black,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
