// lib/screens/home_screen.dart

import 'dart:convert'; // ✅ 추가
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ✅ 추가
import 'package:shared_preferences/shared_preferences.dart'; // ✅ 추가
import '../app_data.dart';
import '../services/health_service.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';
import 'meal_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _stepCount = 0;
  int _lifestyleScore = 0; // ✅ 실제 생활 습관 점수 상태 변수 추가
  List<Workout> _workouts = [];
  final HealthService _healthService = HealthService();
  double _totalKcal = 0;
  double _carbRatio = 0;
  double _proteinRatio = 0;
  double _fatRatio = 0;

  @override
  void initState() {
    super.initState();
    print('🛠 HomeScreen initState() 실행됨');
    AppData.maybeResetDailyData();
    _fetchHealthData();
  }

  void _calculateMealStats() {
    double totalKcal = 0;
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    AppData.meals.values.expand((mealList) => mealList).forEach((food) {
      totalKcal += food['kcal'] ?? 0;
      totalCarb += food['carbohydrate'] ?? 0;
      totalProtein += food['protein'] ?? 0;
      totalFat += food['fat'] ?? 0;
    });

    final totalMacro = totalCarb + totalProtein + totalFat;

    setState(() {
      _totalKcal = totalKcal;
      _carbRatio = totalMacro > 0 ? (totalCarb / totalMacro) : 0;
      _proteinRatio = totalMacro > 0 ? (totalProtein / totalMacro) : 0;
      _fatRatio = totalMacro > 0 ? (totalFat / totalMacro) : 0;
    });
  }

  Future<void> _fetchHealthData() async {
    print('🌐 _fetchHealthData() 진입');

    final authorized = await _healthService.requestAuthorization();
    print('🛂 권한 요청 결과: $authorized');

    if (!authorized) {
      print('⛔️ 권한이 거부되어 데이터를 가져올 수 없습니다.');
      return;
    }

    try {
      print('🚀 fetchTodayWorkouts() 실행 전');
      final workouts = await _healthService.fetchTodayWorkouts();
      print('✅ fetchTodayWorkouts() 완료');

      print('🚶‍♂️ fetchTodaySteps() 실행 전');
      final steps = await _healthService.fetchTodaySteps();
      print('✅ fetchTodaySteps() 완료');

      // ✅ lifestyle 점수 API 호출
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final profileRes = await http.get(
        Uri.parse('http://localhost:8080/v1/members/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      int score = 0;
      if (profileRes.statusCode == 200) {
        final profileData = jsonDecode(utf8.decode(profileRes.bodyBytes));
        score = profileData['lifestyleScore'] ?? 0; // ✅ 실제 키에 따라 변경 가능
        print('📊 lifestyleScore: $score');
      } else {
        print('❌ 프로필 API 호출 실패: ${profileRes.statusCode}');
      }

      setState(() {
        _workouts = workouts;
        _stepCount = steps;
        _lifestyleScore = score; // ✅ 점수 상태에 반영
        print('🟢 setState 실행됨. steps = $steps → _stepCount = $_stepCount');
      });
    } catch (e, stack) {
      print('❌ 오류 발생: $e');
      print(stack);
    }
  }

        // ✅ 이 함수만 남기고
  void _editMeal(String meal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealFoodScreen(mealType: meal)),
    );
    setState(() {
      _calculateMealStats(); // 식사 수정 후 다시 계산
    });
  } 

  String formatWorkoutType(String rawType) {
    switch (rawType.toUpperCase()) {
      case 'RUNNING':
      case 'RUNNING_TREADMILL':
        return '러닝';
      case 'WALKING':
        return '걷기';
      case 'CYCLING':
      case 'CYCLING_OUTDOOR':
      case 'CYCLING_INDOOR':
        return '자전거';
      case 'SWIMMING':
      case 'SWIMMING_POOL':
      case 'SWIMMING_OPEN_WATER':
        return '수영';
      default:
        print('❗️ Unknown workout type: $rawType');
        return '기타';
    }
  }

  Widget buildWorkoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('합계 운동 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_workouts.isEmpty)
          const Text('운동 기록이 없습니다.', style: TextStyle(color: Colors.grey))
        else
          Column(
            children: _workouts.map((w) {
              final formattedStart = DateFormat.yMd().add_jm().format(w.start);
              final formattedEnd = DateFormat.yMd().add_jm().format(w.end);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('운동 종류: ${formatWorkoutType(w.exerciseType)}'),
                    Text('시작: $formattedStart'),
                    Text('종료: $formattedEnd'),
                    Text(w.calories >= 0
                        ? '칼로리: ${w.calories.toStringAsFixed(1)} kcal'
                        : '칼로리: 정보 없음'),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('📦 build() 실행됨. _stepCount = $_stepCount');
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '어제 당신의 생활 습관 점수는?',
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
                width: 320,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: _lifestyleScore / 100.0, // ✅ 점수 반영
                        strokeWidth: 30,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_lifestyleScore점', // ✅ 하드코딩 제거, 상태값 반영
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '습관 점수',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            _buildStatCard(
              title: '걸음수',
              value: _stepCount.round().toString(),
              unit: '걸음',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 32),
            const Text('식단',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Text('${_totalKcal.toStringAsFixed(0)} kcal',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('탄 ${(100 * _carbRatio).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.deepPurple)),
                      Text('단 ${(100 * _proteinRatio).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.blue)),
                      Text('지 ${(100 * _fatRatio).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.teal)),
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
                  case '아침':
                    emoji = '🍳';
                    break;
                  case '점심':
                    emoji = '☀️';
                    break;
                  case '저녁':
                    emoji = '🌙';
                    break;
                  case '간식':
                    emoji = '🍎';
                    break;
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
                        Text(meal,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        AppData.meals[meal]!.isEmpty
                            ? const Icon(Icons.add,
                                size: 20, color: Colors.grey)
                            : Text(
                                AppData.meals[meal]!
                                    .map((f) => f['foodName'])
                                    .join(', '),
                                style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            buildWorkoutSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/entry');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/savings');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/report');
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

  Widget _buildCountCard(
      {required String title,
      required int count,
      required String unit,
      required VoidCallback onIncrement}) {
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
            Text('$count $unit',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onIncrement),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required String title,
      required String value,
      required String unit,
      required IconData icon}) {
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
              Text('$value $unit',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
