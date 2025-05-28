import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_service.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';
import 'meal_food_screen.dart';
import 'meal_detail_screen.dart';
import 'package:hive/hive.dart';
import '../models/eaten_food.dart'; // 식단 하이브
import '../models/daily_record.dart'; // 음수량, 흡연량 하이브

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _stepCount = 0; // 추가
  int _lifestyleScore = 0; // 추가
  List<Workout> _workouts = [];
  final HealthService _healthService = HealthService();
  double _totalKcal = 0;
  double _carbRatio = 0;
  double _proteinRatio = 0;
  double _fatRatio = 0;
  final Map<String, double> foodCountMap = {};

  int _waterCount = 0;
  int _smokeCount = 0;

  @override
  void initState() {
    super.initState();
    print('🛠 HomeScreen initState() 실행됨');
    _loadDailyCounts(); // 추가
    _fetchHealthData();
    _calculateMealStats();
  }

  /// 오늘 날짜 키 계산
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Hive에서 오늘의 water/smoke 카운트 불러오기
  Future<void> _loadDailyCounts() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);

    setState(() {
      _waterCount = record.waterCount;
      _smokeCount = record.smokeCount;
    });
  }

  /// 물 섭취량 1 증가 후 Hive에 저장
  Future<void> _incrementWater() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);

    record.waterCount++;
    await box.put(_todayKey, record);

    setState(() {
      _waterCount = record.waterCount;
    });
  }

  // 1) 물 줄이기(_incrementWater 바로 아래)
  Future<void> _decrementWater() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    if (record.waterCount > 0) {
      record.waterCount--;
      await box.put(_todayKey, record);
    }
    setState(() {
      _waterCount = record.waterCount;
    });
  }

  /// 흡연량 1 증가 후 Hive에 저장
  Future<void> _incrementSmoke() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);

    record.smokeCount++;
    await box.put(_todayKey, record);

    setState(() {
      _smokeCount = record.smokeCount;
    });
  }

  // 2) 흡연량 줄이기(_incrementSmoke 바로 아래)
  Future<void> _decrementSmoke() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    if (record.smokeCount > 0) {
      record.smokeCount--;
      await box.put(_todayKey, record);
    }
    setState(() {
      _smokeCount = record.smokeCount;
    });
  }

  Future<void> _calculateMealStats() async {
    setState(() {
      _totalKcal = 0;
      _carbRatio = 0;
      _proteinRatio = 0;
      _fatRatio = 0;
    });

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final box = Hive.box<List<EatenFood>>('mealFoodsBox');
    final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'DESSERT'];

    double totalKcal = 0;
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final type in mealTypes) {
      final key = '$today|$type';
      final storedList = box.get(key, defaultValue: <EatenFood>[])!;

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

      final request =
          http.Request('GET', url)
            ..headers.addAll({
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode({'start': dateStr, 'end': dateStr});

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
    final box = Hive.box<List<EatenFood>>('mealFoodsBox');

    final mealTypes = {
      '아침': 'BREAKFAST',
      '점심': 'LUNCH',
      '저녁': 'DINNER',
      '간식': 'DESSERT',
    };

    Map<String, List<EatenFood>> result = {};

    for (final entry in mealTypes.entries) {
      final key = '$today|${entry.value}';
      final list = box.get(key, defaultValue: <EatenFood>[])!;
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
        const Text(
          '운동 기록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_workouts.isEmpty)
          const Text('운동 기록이 없습니다.', style: TextStyle(color: Colors.grey))
        else
          Column(
            children:
                _workouts.map((w) {
                  final formattedStart = DateFormat.yMd().add_jm().format(
                    w.start,
                  );
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
                        Text(
                          w.calories >= 0
                              ? '칼로리: ${w.calories.toStringAsFixed(1)} kcal'
                              : '칼로리: 정보 없음',
                        ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
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
                  count: _waterCount,
                  unit: '잔',
                  onIncrement: _incrementWater,
                  onDecrement: _decrementWater,
                ),
                const SizedBox(width: 12),
                _buildCountCard(
                  title: '흡연량',
                  count: _smokeCount,
                  unit: '개비',
                  onIncrement: _incrementSmoke,
                  onDecrement: _decrementSmoke,
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
            const Text(
              '식단',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                  Text(
                    '${_totalKcal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '탄 ${(100 * _carbRatio).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                      Text(
                        '단 ${(100 * _proteinRatio).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      Text(
                        '지 ${(100 * _fatRatio).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.teal),
                      ),
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

                final mealOrder = ['아침', '점심', '저녁', '간식'];
                final mealIcons = {
                  '아침': '🍳',
                  '점심': '☀️',
                  '저녁': '🌙',
                  '간식': '🍎',
                };

                return Column(
                  children:
                      mealOrder.map((meal) {
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
                                  Text(
                                    mealIcons[meal]!,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    meal,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => MealDetailScreen(
                                                  mealType: meal,
                                                ),
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
    required VoidCallback onDecrement,
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
            Text(
              '$count $unit',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: onDecrement, // ← 추가
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: onIncrement,
                ),
              ],
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
              Text(
                '$value $unit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
