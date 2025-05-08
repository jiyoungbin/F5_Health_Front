// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../app_data.dart'; // ← 전역 변수 클래스 임포트


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _stepCount = 0; // 걸음 수 (추후 API 연동 예정)

  @override
  void initState() {
    super.initState();
    AppData.maybeResetDailyData(); // 날짜 변경 시 초기화 로직
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 생활 습관 점수
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '당신의 생활 습관 점수는?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/report'),
                  child: const Text('더보기'),
                ),
              ],
            ),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 16,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                    ),
                    const Text('75%', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 음수량 · 흡연량
            Row(
              children: [
                _buildCountCard(
                  title: '음수량',
                  count: AppData.waterCount,
                  unit: '잔',
                  onIncrement: () => setState(() => AppData.waterCount++),
                ),
                const SizedBox(width: 12),
                _buildCountCard(
                  title: '흡연량',
                  count: AppData.smokeCount,
                  unit: '개비',
                  onIncrement: () => setState(() => AppData.smokeCount++),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 걸음 수
            _buildStatCard(
              title: '걸음수',
              value: _stepCount.toString(),
              unit: '걸음',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 32),

            
            // 식단 입력
            const Text('식단', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('0 kcal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('탄 0%', style: TextStyle(color: Colors.deepPurple)),
                      Text('단 0%', style: TextStyle(color: Colors.blue)),
                      Text('지 0%', style: TextStyle(color: Colors.teal)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppData.meals.keys.map((meal) {
                String emoji = '';
                switch (meal) {
                  case '아침': emoji = '🍳'; break;
                  case '점심': emoji = '☀️'; break;
                  case '저녁': emoji = '🌙'; break;
                  case '간식': emoji = '🍎'; break;
                }

                return GestureDetector(
                  onTap: () => _editMeal(meal),
                  child: Container(
                    width: MediaQuery.of(context).size.width / 4 - 24,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(meal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        AppData.meals[meal]!.isEmpty
                            ? const Icon(Icons.add, size: 20, color: Colors.grey)
                            : Text(AppData.meals[meal]!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
         onTap: (i) {
          if (i == 2) return ;
          switch (i) {
            case 0: Navigator.pushReplacementNamed(context, '/entry'); break;
            case 1: Navigator.pushReplacementNamed(context, '/savings'); break;
            case 3: Navigator.pushReplacementNamed(context, '/report'); break;
            case 4: Navigator.pushReplacementNamed(context, '/badge'); break;
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

  Widget _buildCountCard({
    required String title,
    required int count,
    required String unit,
    required VoidCallback onIncrement,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('$count $unit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onIncrement),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text('$value $unit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _editMeal(String meal) {
    final controller = TextEditingController(text: AppData.meals[meal]);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$meal 입력'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '내용을 입력하세요')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() => AppData.meals[meal] = controller.text);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}



