import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_data.dart';
import '../services/health_service.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';
import 'meal_food_screen.dart';
import 'meal_detail_screen.dart';
import 'package:hive/hive.dart';
import '../models/eaten_food.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _stepCount = 0;
  int _lifestyleScore = 0;
  List<Workout> _workouts = [];
  final HealthService _healthService = HealthService();
  double _totalKcal = 0;
  double _carbRatio = 0;
  double _proteinRatio = 0;
  double _fatRatio = 0;
  final Map<String, double> foodCountMap = {};

  @override
  void initState() {
    super.initState();
    print('🛠 HomeScreen initState() 실행됨');
    AppData.maybeResetDailyData();
    _fetchHealthData();
    _calculateMealStats();
  }

  Future<void> _calculateMealStats() async {
    setState(() {
      _totalKcal = 0;
      _carbRatio = 0;
      _proteinRatio = 0;
      _fatRatio = 0;
    });

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final box = await Hive.openBox<List>('eatenFoods');
    final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'DESSERT'];

    double totalKcal = 0;
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final type in mealTypes) {
      final key = '$today|$type';
      final storedList =
          box.get(key, defaultValue: [])?.cast<EatenFood>() ?? [];

      for (final item in storedList) {
        totalKcal += item.kcal * item.count;
        totalCarb += item.carbohydrate * item.count;
        totalProtein += item.protein * item.count;
        totalFat += item.fat * item.count;
      }
    }

    final totalMacro = totalCarb + totalProtein + totalFat;

    setState(() {
      _totalKcal = totalKcal;
      _carbRatio = totalMacro > 0 ? totalCarb / totalMacro : 0;
      _proteinRatio = totalMacro > 0 ? totalProtein / totalMacro : 0;
      _fatRatio = totalMacro > 0 ? totalFat / totalMacro : 0;
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      print('🔑 액세스 토큰: $token');

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = DateFormat('yyyy-MM-dd').format(yesterday);
      print('📅 어제 날짜: $dateStr');

      final url = Uri.parse('http://localhost:8080/health/report/scores');
      final client = http.Client();

      final request = http.Request('GET', url)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'start': dateStr,
          'end': dateStr,
        });

      print('🚀 점수 API 요청 전 (GET + body)');
      print('📦 URL: $url');
      print('📦 Headers: ${request.headers}');
      print('📦 Body: ${request.body}');

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 점수 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 본문: ${utf8.decode(response.bodyBytes)}');

      int score = 0;
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
        final scores = responseJson['scores'] as List<dynamic>;
        if (scores.isNotEmpty && scores[0]['healthLifeScore'] != null) {
          score = scores[0]['healthLifeScore'];
          print('✅ 점수 추출 성공: $score');
        } else {
          print('⚠️ 점수 항목 없음 또는 비어있음');
        }
      } else {
        print('❌ 점수 API 호출 실패');
      }

      final workouts = await _healthService.fetchTodayWorkouts();
      final steps = await _healthService.fetchTodaySteps();

      setState(() {
        _workouts = workouts;
        _stepCount = steps;
        _lifestyleScore = score;
        print('🟢 setState 실행됨. steps = $steps, score = $_lifestyleScore');
      });
    } catch (e, stack) {
      print('❌ 예외 발생: $e');
      print(stack);
    }
  }

  void _editMeal(String meal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealFoodScreen(mealType: meal)),
    );
    setState(() {
      _calculateMealStats();
    });
  }

  Future<Map<String, List<EatenFood>>> _loadMealsFromHive() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final box = await Hive.openBox<List>('eatenFoods');

    final mealTypes = {
      '아침': 'BREAKFAST',
      '점심': 'LUNCH',
      '저녁': 'DINNER',
      '간식': 'DESSERT',
    };

    Map<String, List<EatenFood>> result = {};

    for (final entry in mealTypes.entries) {
      final key = '$today|${entry.value}';
      final rawList = box.get(key, defaultValue: []);
      final list = rawList?.whereType<EatenFood>().toList() ?? [];
      result[entry.key] = list;
    }

    return result;
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
        const Text('운동 기록',
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
                        value: _lifestyleScore / 100.0,
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
                          '$_lifestyleScore점',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
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
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
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
            FutureBuilder<Map<String, List<EatenFood>>>(
              future: _loadMealsFromHive(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final mealMap = snapshot.data!;
                final mealOrder = ['아침', '점심', '저녁', '간식'];
                final mealIcons = {
                  '아침': '🍳',
                  '점심': '☀️',
                  '저녁': '🌙',
                  '간식': '🍎'
                };

                return Column(
                  children: mealOrder.map((meal) {
                    final foods = mealMap[meal] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(mealIcons[meal]!,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Text(meal,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MealDetailScreen(mealType: meal),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _editMeal(meal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
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
            Text('$count $unit',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
            ),
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
