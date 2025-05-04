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
            const Text('식단 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...AppData.meals.keys.map((meal) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal),
                  subtitle: Text(
                    AppData.meals[meal]!.isEmpty
                        ? '입력된 내용이 없습니다.'
                        : AppData.meals[meal]!,
                  ),
                  onTap: () => _editMeal(meal),
                )),
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




/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 비교용

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1) 날짜별 초기화 로직을 위해 마지막 초기화 날짜 저장
  DateTime _lastReset = DateTime.now();

  // 2) 카운트 변수
  int _waterCount = 0;
  int _smokeCount = 0;
  int _stepCount = 0; // TODO: 실제론 HealthKit API 호출

  // 3) 식단 텍스트 저장
  final Map<String, String> _meals = {
    '아침': '',
    '점심': '',
    '저녁': '',
    '간식': '',
  };

  // 날짜가 바뀌면 카운트를 0으로 초기화
  void _maybeResetCounts() {
    final today = DateTime.now();
    if (!isSameDate(today, _lastReset)) {
      _lastReset = today;
      _waterCount = 0;
      _smokeCount = 0;
    }
  }

  bool isSameDate(DateTime a, DateTime b) {
    return DateFormat('yyyy-MM-dd').format(a) ==
           DateFormat('yyyy-MM-dd').format(b);
  }

  @override
  Widget build(BuildContext context) {
    _maybeResetCounts();

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
            // TODO: 실 차트로 교체 가능
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.75, // 75% 예시
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

            // 음수량 · 흡연량 박스
            Row(
              children: [
                _buildCountCard(
                  title: '음수량',
                  count: _waterCount,
                  unit: '잔',
                  onIncrement: () => setState(() => _waterCount++),
                ),
                const SizedBox(width: 12),
                _buildCountCard(
                  title: '흡연량',
                  count: _smokeCount,
                  unit: '개비',
                  onIncrement: () => setState(() => _smokeCount++),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 걸음 수 박스
            _buildStatCard(
              title: '걸음수',
              value: _stepCount.toString(),
              unit: '걸음',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 32),

            // 식단 입력
            const Text('식단 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._meals.keys.map((meal) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal),
                  subtitle: Text(_meals[meal]!.isEmpty ? '입력된 내용이 없습니다.' : _meals[meal]!),
                  onTap: () => _editMeal(meal),
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),

      // bottom nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // 홈이 0번
        onTap: (i) {
          switch (i) {
            case 0: Navigator.pushReplacementNamed(context, '/entry'); break; 
            case 1: Navigator.pushReplacementNamed(context, '/savings'); break;
            case 2: break; // 이미 홈
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

  // + 버튼 있는 카운트 카드
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

  // 아이콘과 값만 보여주는 통계 카드
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

  // 식단 입력 다이얼로그
  void _editMeal(String meal) {
    final controller = TextEditingController(text: _meals[meal]);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$meal 입력'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: '내용을 입력하세요')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() {
                _meals[meal] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
*/