import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../services/health_service.dart';
import '../models/eaten_food.dart';
import '../models/daily_record.dart';
import 'meal_food_screen.dart';
import 'drink_entry_screen.dart';

import '../config.dart';
import '../screens/report_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  // Hive에서 가져온 오늘 물/흡연 카운트
  int _initialWater = 0;
  int _initialSmoke = 0;

  // 알코올 개수 (맥주, 소주)
  int _beerCount = 0;
  int _sojuCount = 0;

  // 오늘 이미 제출했는지 여부
  bool _isSubmittedToday = false;
  late final String _submitPrefKey;

  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    // 오늘 날짜 기반으로 SharedPreferences 키 생성
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _submitPrefKey = 'submitted_$todayKey';

    // Hive에서 오늘 카운트 불러오기
    _loadDailyCounts();

    // SharedPreferences에서 오늘 제출 여부 확인
    _checkIfSubmitted();
  }

  /// 오늘 날짜 키 (yyyy-MM-dd)
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Hive에서 오늘 물/흡연 카운트를 읽어 초기화
  Future<void> _loadDailyCounts() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    setState(() {
      _initialWater = record.waterCount;
      _initialSmoke = record.smokeCount;
    });
  }

  /// 오늘 제출 여부를 SharedPreferences에서 읽어온다
  Future<void> _checkIfSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final submitted = prefs.getBool(_submitPrefKey) ?? false;
    setState(() => _isSubmittedToday = submitted);
  }

  /// 물 섭취량 1 증가 후 Hive에 저장
  Future<void> _incrementWater() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    record.waterCount++;
    await box.put(_todayKey, record);
    setState(() {
      _initialWater = record.waterCount;
    });
  }

  /// 물 섭취량 1 감소 후 Hive에 저장
  Future<void> _decrementWater() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    if (record.waterCount > 0) {
      record.waterCount--;
      await box.put(_todayKey, record);
    }
    setState(() {
      _initialWater = record.waterCount;
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
      _initialSmoke = record.smokeCount;
    });
  }

  /// 흡연량 1 감소 후 Hive에 저장
  Future<void> _decrementSmoke() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    if (record.smokeCount > 0) {
      record.smokeCount--;
      await box.put(_todayKey, record);
    }
    setState(() {
      _initialSmoke = record.smokeCount;
    });
  }

  /// 로딩용 다이얼로그 위젯
  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('생활습관 점수 계산 중…', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// 저장 버튼 클릭 시 호출되는 메서드
  Future<void> _onSave() async {
    // ➊ 로딩 다이얼로그 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      // 1) Hive에서 오늘 최종 물/흡연 값 불러오기
      final box = Hive.box<DailyRecord>('dailyData');
      final record =
          box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
      final totalWater = record.waterCount;
      final totalSmoke = record.smokeCount;

      // 2) HealthKit, 식단 데이터 수집
      final healthData = await _healthService.getTodayHealthData();
      final mealBox = Hive.box<List<EatenFood>>('mealFoodsBox');
      final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'DESSERT'];
      List<Map<String, dynamic>> mealRequestList = [];
      for (final type in mealTypes) {
        final key = '$_todayKey|$type';
        final storedList = mealBox.get(key, defaultValue: <EatenFood>[])!;
        if (storedList.isEmpty) continue;
        mealRequestList.add({
          'mealType': type,
          'mealTime': DateTime.now().toIso8601String(),
          'mealFoodRequestList':
              storedList
                  .map((e) => {'foodCode': e.foodCode, 'count': e.count})
                  .toList(),
        });
      }

      // 3) 음주량 계산 (맥주 한 잔 = 250ml, 소주 한 잔 = 50ml)
      final beerMl = _beerCount * 250;
      final sojuMl = _sojuCount * 50;
      List<Map<String, dynamic>> alcoholList = [];
      if (beerMl > 0) {
        alcoholList.add({
          'alcoholType': 'BEER',
          'consumedAlcoholDrinks': beerMl,
        });
      }
      if (sojuMl > 0) {
        alcoholList.add({
          'alcoholType': 'SOJU',
          'consumedAlcoholDrinks': sojuMl,
        });
      }

      // 4) alcoholList가 비어 있으면 null, 아니면 {'result': alcoholList} 생성
      final dynamic alcoholField =
          alcoholList.isEmpty ? null : {'result': alcoholList};

      // 5) 서버로 보낼 페이로드 작성
      final payload = {
        'healthKit': {
          'period': {
            'startDateTime':
                DateTime.now()
                    .subtract(const Duration(hours: 24))
                    .toIso8601String(),
            'endDateTime': DateTime.now().toIso8601String(),
          },
          'customHealthKit': {
            'waterIntake': totalWater * 250,
            'smokedCigarettes': totalSmoke,
            'alcoholConsumptionResult': alcoholField,
          },
          'appleHealthKit': {
            'activity': {
              'stepCount': (healthData['stepCount'] ?? 0).round(),
              'distanceWalkingRunning':
                  (healthData['activity']['distanceWalkingRunning'] ?? 0.0)
                      .round(),
              'activeEnergyBurned':
                  (healthData['activity']['activeEnergyBurned'] ?? 0.0).round(),
              'appleExerciseTime':
                  (healthData['activity']['appleExerciseTime'] ?? 0).round(),
            },
            'sleepAnalysis': healthData['sleep'],
            'vitalSigns': {
              'heartRate': (healthData['vital']['heartRate'] ?? 0).round(),
              'oxygenSaturation':
                  (healthData['vital']['oxygenSaturation'] ?? 0).round(),
              'bodyTemperature':
                  (healthData['vital']['bodyTemperature'] ?? 0.0).toDouble(),
            },
            'workouts': {
              'workoutTypes':
                  healthData['exercise']
                      .map((e) => e['exerciseType'])
                      .toSet()
                      .toList(),
            },
          },
        },
        'mealsRequest': {'mealRequestList': mealRequestList},
      };

      // 6) 서버 전송
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      if (token.isEmpty) {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('토큰이 없습니다. 로그인 후 다시 시도해주세요.')),
        );
        return;
      }

      final res = await http.post(
        Uri.parse('${Config.baseUrl}/health/report/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        // 제출 성공
        await prefs.setBool(_submitPrefKey, true);
        if (mounted) setState(() => _isSubmittedToday = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '일일 기록에 성공하였습니다.\n오늘은 더 이상 기록이 불가능해요.',
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          ),
        );

        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => ReportScreen(
                  initialPage: "일간",
                  initialDate: DateTime.now(),
                ),
          ),
        );
      } else {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘 이미 기록했거나, 저장에 실패했습니다.')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWater = _initialWater;
    final currentSmoke = _initialSmoke;

    return Scaffold(
      appBar: AppBar(title: const Text('오늘 하루 건강 기록 정리하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1) 물 / 흡연 카드 ───────────────────────
            Row(
              children: [
                _buildCountCard(
                  iconData: Icons.water_drop,
                  title: '음수량',
                  count: currentWater,
                  unit: '잔',
                  bgColor: Colors.lightBlue.shade100,
                  onIncrement: _incrementWater,
                  onDecrement: _decrementWater,
                ),
                const SizedBox(width: 12),
                _buildCountCard(
                  iconData: Icons.smoking_rooms,
                  title: '흡연량',
                  count: currentSmoke,
                  unit: '개비',
                  bgColor: const Color(0xFFF5D7DF),
                  onIncrement: _incrementSmoke,
                  onDecrement: _decrementSmoke,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 2) 음주량 기록 ───────────────────────
            const Text(
              '음주량 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAlcoholButton(
                  '맥주',
                  (count) => setState(() => _beerCount = count),
                ),
                const SizedBox(width: 8),
                _buildAlcoholButton(
                  '소주',
                  (count) => setState(() => _sojuCount = count),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 3) 식단 입력 ───────────────────────
            const Text(
              '식단 입력',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...['아침', '점심', '저녁', '간식'].map(
              (meal) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  meal == '아침'
                      ? Icons.free_breakfast
                      : meal == '점심'
                      ? Icons.sunny
                      : meal == '저녁'
                      ? Icons.nightlight_round
                      : Icons.apple,
                  color: Colors.deepPurple,
                ),
                title: Text(meal, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealFoodScreen(mealType: meal),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 32),

            // ─── 4) 기록 완료 버튼 ───────────────────────
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittedToday ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isSubmittedToday ? '오늘 기록 완료됨' : '기록 완료하기'),
                ),
              ),
            ),
          ],
        ),
      ),

      // ─── 하단 네비게이션 ───────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) return;
          switch (i) {
            case 1:
              Navigator.pushReplacementNamed(context, '/savings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
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

  /// 물/흡연량 조절 카드 위젯
  Widget _buildCountCard({
    required IconData iconData,
    required String title,
    required int count,
    required String unit,
    required Color bgColor,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 28,
                    color: Colors.green,
                  ),
                  onPressed: onIncrement,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$count $unit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 28,
                    color: Colors.red,
                  ),
                  onPressed: onDecrement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 음주량 기록 버튼 위젯
  Widget _buildAlcoholButton(String type, ValueSetter<int> onCountSelected) {
    final isBeer = type == '맥주';
    final current = isBeer ? _beerCount : _sojuCount;
    final iconData = isBeer ? Icons.local_drink : Icons.liquor;
    final bgColor = isBeer ? Colors.orange.shade100 : Colors.green.shade100;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(iconData, color: Colors.black54),
                const SizedBox(width: 6),
                Text('$type: $current', style: const TextStyle(fontSize: 16)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () async {
                final result = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DrinkEntryScreen(
                          drinkType: type,
                          initialCount: current,
                        ),
                  ),
                );
                if (result != null) {
                  onCountSelected(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../services/health_service.dart';
import '../models/eaten_food.dart';
import '../models/daily_record.dart';
import 'meal_food_screen.dart';
import 'drink_entry_screen.dart';

import '../config.dart';
import '../screens/report_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  // Hive에서 가져온 오늘 물/흡연 카운트
  int _initialWater = 0;
  int _initialSmoke = 0;

  // 알코올 개수 (맥주, 소주)
  int _beerCount = 0;
  int _sojuCount = 0;

  // 오늘 이미 제출했는지 여부
  bool _isSubmittedToday = false;
  late final String _submitPrefKey;

  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    // 오늘 날짜 기반으로 SharedPreferences 키 생성
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _submitPrefKey = 'submitted_$todayKey';

    // Hive에서 오늘 카운트 불러오기
    _loadDailyCounts();

    // SharedPreferences에서 오늘 제출 여부 확인
    _checkIfSubmitted();
  }

  /// 오늘 날짜 키 (yyyy-MM-dd)
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Hive에서 오늘 물/흡연 카운트를 읽어 초기화
  Future<void> _loadDailyCounts() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    setState(() {
      _initialWater = record.waterCount;
      _initialSmoke = record.smokeCount;
    });
  }

  /// 오늘 제출 여부를 SharedPreferences에서 읽어온다
  Future<void> _checkIfSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final submitted = prefs.getBool(_submitPrefKey) ?? false;
    setState(() => _isSubmittedToday = submitted);
  }

  /// 물 섭취량 1 증가 후 Hive에 저장
  Future<void> _incrementWater() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    record.waterCount++;
    await box.put(_todayKey, record);
    setState(() {
      _initialWater = record.waterCount;
    });
  }

  /// 물 섭취량 1 감소 후 Hive에 저장
  Future<void> _decrementWater() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    if (record.waterCount > 0) {
      record.waterCount--;
      await box.put(_todayKey, record);
    }
    setState(() {
      _initialWater = record.waterCount;
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
      _initialSmoke = record.smokeCount;
    });
  }

  /// 흡연량 1 감소 후 Hive에 저장
  Future<void> _decrementSmoke() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final record =
        box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    if (record.smokeCount > 0) {
      record.smokeCount--;
      await box.put(_todayKey, record);
    }
    setState(() {
      _initialSmoke = record.smokeCount;
    });
  }

  /// 로딩용 다이얼로그 위젯
  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('생활습관 점수 계산 중…', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// 저장 버튼 클릭 시 호출되는 메서드
  Future<void> _onSave() async {
    // ➊ 로딩 다이얼로그 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      // 1) Hive에서 오늘 최종 물/흡연 값 불러오기
      final box = Hive.box<DailyRecord>('dailyData');
      final record =
          box.get(_todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
      final totalWater = record.waterCount;
      final totalSmoke = record.smokeCount;

      // 2) HealthKit, 식단 데이터 수집
      final healthData = await _healthService.getTodayHealthData();
      final mealBox = Hive.box<List<EatenFood>>('mealFoodsBox');
      final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'DESSERT'];
      List<Map<String, dynamic>> mealRequestList = [];
      for (final type in mealTypes) {
        final key = '$_todayKey|$type';
        final storedList = mealBox.get(key, defaultValue: <EatenFood>[])!;
        if (storedList.isEmpty) continue;
        mealRequestList.add({
          'mealType': type,
          'mealTime': DateTime.now().toIso8601String(),
          'mealFoodRequestList':
              storedList
                  .map((e) => {'foodCode': e.foodCode, 'count': e.count})
                  .toList(),
        });
      }

      // 3) 음주량 계산 (맥주 한 잔 = 250ml, 소주 한 잔 = 50ml)
      final beerMl = _beerCount * 250;
      final sojuMl = _sojuCount * 50;
      List<Map<String, dynamic>> alcoholList = [];
      if (beerMl > 0) {
        alcoholList.add({
          'alcoholType': 'BEER',
          'consumedAlcoholDrinks': beerMl,
        });
      }
      if (sojuMl > 0) {
        alcoholList.add({
          'alcoholType': 'SOJU',
          'consumedAlcoholDrinks': sojuMl,
        });
      }

      // 4) 서버로 보낼 페이로드 작성
      final payload = {
        'healthKit': {
          'period': {
            'startDateTime':
                DateTime.now()
                    .subtract(const Duration(hours: 24))
                    .toIso8601String(),
            'endDateTime': DateTime.now().toIso8601String(),
          },
          'customHealthKit': {
            'waterIntake': totalWater * 250,
            'smokedCigarettes': totalSmoke,
            'alcoholConsumptionResult': {'result': alcoholList},
          },
          'appleHealthKit': {
            'activity': {
              'stepCount': (healthData['stepCount'] ?? 0).round(),
              'distanceWalkingRunning':
                  (healthData['activity']['distanceWalkingRunning'] ?? 0.0)
                      .round(),
              'activeEnergyBurned':
                  (healthData['activity']['activeEnergyBurned'] ?? 0.0).round(),
              'appleExerciseTime':
                  (healthData['activity']['appleExerciseTime'] ?? 0).round(),
            },
            'sleepAnalysis': healthData['sleep'],
            'vitalSigns': {
              'heartRate': (healthData['vital']['heartRate'] ?? 0).round(),
              'oxygenSaturation':
                  (healthData['vital']['oxygenSaturation'] ?? 0).round(),
              'bodyTemperature':
                  (healthData['vital']['bodyTemperature'] ?? 0.0).toDouble(),
            },
            'workouts': {
              'workoutTypes':
                  healthData['exercise']
                      .map((e) => e['exerciseType'])
                      .toSet()
                      .toList(),
            },
          },
        },
        'mealsRequest': {'mealRequestList': mealRequestList},
      };

      // 5) 서버 전송
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      if (token.isEmpty) {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('토큰이 없습니다. 로그인 후 다시 시도해주세요.')),
        );
        return;
      }

      final res = await http.post(
        Uri.parse('${Config.baseUrl}/health/report/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        // 제출 성공
        await prefs.setBool(_submitPrefKey, true);
        if (mounted) setState(() => _isSubmittedToday = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '일일 기록에 성공하였습니다.\n오늘은 더 이상 기록이 불가능해요.',
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          ),
        );

        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => ReportScreen(
                  initialPage: "일간",
                  initialDate: DateTime.now(),
                ),
          ),
        );
      } else {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘 이미 기록했거나, 저장에 실패했습니다.')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWater = _initialWater;
    final currentSmoke = _initialSmoke;

    return Scaffold(
      appBar: AppBar(title: const Text('오늘 하루 건강 기록 정리하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1) 물 / 흡연 카드 ───────────────────────
            Row(
              children: [
                _buildCountCard(
                  iconData: Icons.water_drop,
                  title: '음수량',
                  count: currentWater,
                  unit: '잔',
                  bgColor: Colors.lightBlue.shade100,
                  onIncrement: _incrementWater,
                  onDecrement: _decrementWater,
                ),
                const SizedBox(width: 12),
                _buildCountCard(
                  iconData: Icons.smoking_rooms,
                  title: '흡연량',
                  count: currentSmoke,
                  unit: '개비',
                  bgColor: const Color(0xFFF5D7DF),
                  onIncrement: _incrementSmoke,
                  onDecrement: _decrementSmoke,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 2) 음주량 기록 ───────────────────────
            const Text(
              '음주량 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAlcoholButton(
                  '맥주',
                  (count) => setState(() => _beerCount = count),
                ),
                const SizedBox(width: 8),
                _buildAlcoholButton(
                  '소주',
                  (count) => setState(() => _sojuCount = count),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 3) 식단 입력 ───────────────────────
            const Text(
              '식단 입력',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...['아침', '점심', '저녁', '간식'].map(
              (meal) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  meal == '아침'
                      ? Icons.free_breakfast
                      : meal == '점심'
                      ? Icons.sunny
                      : meal == '저녁'
                      ? Icons.nightlight_round
                      : Icons.apple,
                  color: Colors.deepPurple,
                ),
                title: Text(meal, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealFoodScreen(mealType: meal),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 32),

            // ─── 4) 기록 완료 버튼 ───────────────────────
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittedToday ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isSubmittedToday ? '오늘 기록 완료됨' : '기록 완료하기'),
                ),
              ),
            ),
          ],
        ),
      ),

      // ─── 하단 네비게이션 ───────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) return;
          switch (i) {
            case 1:
              Navigator.pushReplacementNamed(context, '/savings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
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

  /// 물/흡연량 조절 카드 위젯
  Widget _buildCountCard({
    required IconData iconData,
    required String title,
    required int count,
    required String unit,
    required Color bgColor,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 28,
                    color: Colors.green,
                  ),
                  onPressed: onIncrement,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$count $unit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 28,
                    color: Colors.red,
                  ),
                  onPressed: onDecrement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 음주량 기록 버튼 위젯
  Widget _buildAlcoholButton(String type, ValueSetter<int> onCountSelected) {
    final isBeer = type == '맥주';
    final current = isBeer ? _beerCount : _sojuCount;
    final iconData = isBeer ? Icons.local_drink : Icons.liquor;
    final bgColor = isBeer ? Colors.orange.shade100 : Colors.green.shade100;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(iconData, color: Colors.black54),
                const SizedBox(width: 6),
                Text('$type: $current', style: const TextStyle(fontSize: 16)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () async {
                final result = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DrinkEntryScreen(
                          drinkType: type,
                          initialCount: current,
                        ),
                  ),
                );
                if (result != null) {
                  onCountSelected(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../services/health_service.dart';
import '../models/eaten_food.dart';
import '../models/daily_record.dart';
import 'meal_food_screen.dart';
import 'drink_entry_screen.dart';

import '../config.dart';
import '../screens/report_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  // Hive에서 가져온 오늘 카운트
  int _initialWater = 0;
  int _initialSmoke = 0;
  // 추가 입력으로 더해질 값
  int _extraWater = 0;
  int _extraSmoke = 0;
  // 알코올 개수
  int _beerCount = 0;
  int _sojuCount = 0;

  // 오늘 이미 제출했는지 여부
  bool _isSubmittedToday = false;
  late final String _submitPrefKey;

  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();

    // 오늘 날짜 기반으로 SharedPreferences 키 생성
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _submitPrefKey = 'submitted_$todayKey';

    // Hive에서 오늘 카운트 불러오기
    _loadDailyCounts();

    // SharedPreferences에서 오늘 제출 여부 확인
    _checkIfSubmitted();
  }

  /// Hive에서 오늘 물/흡연 카운트를 읽어 초기화
  Future<void> _loadDailyCounts() async {
    final box = Hive.box<DailyRecord>('dailyData');
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record =
        box.get(todayKey) ?? DailyRecord(waterCount: 0, smokeCount: 0);
    setState(() {
      _initialWater = record.waterCount;
      _initialSmoke = record.smokeCount;
    });
  }

  /// 오늘 제출 여부를 SharedPreferences에서 읽어온다
  Future<void> _checkIfSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final submitted = prefs.getBool(_submitPrefKey) ?? false;
    setState(() => _isSubmittedToday = submitted);
  }

  @override
  void dispose() {
    _waterController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  /// 수/흡연 추가 입력 다이얼로그
  Future<void> _showAddDialog({
    required String title,
    required TextEditingController ctrl,
    required ValueSetter<int> onConfirm,
  }) async {
    ctrl.clear();
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('$title 추가 입력'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '숫자를 입력하세요'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  final v = int.tryParse(ctrl.text) ?? 0;
                  onConfirm(v);
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('생활습관 점수 계산 중…', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    // ➊ 로딩 다이얼로그 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      // 1) Hive에 오늘 최종 값 저장
      final totalWater = _initialWater + _extraWater;
      final totalSmoke = _initialSmoke + _extraSmoke;
      final box = Hive.box<DailyRecord>('dailyData');
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final record = DailyRecord(
        waterCount: totalWater,
        smokeCount: totalSmoke,
      );
      await box.put(todayKey, record);

      // 2) HealthKit, 식단 데이터 수집
      final healthData = await _healthService.getTodayHealthData();
      final mealBox = Hive.box<List<EatenFood>>('mealFoodsBox');
      final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'DESSERT'];
      List<Map<String, dynamic>> mealRequestList = [];
      for (final type in mealTypes) {
        final key = '$todayKey|$type';
        final storedList = mealBox.get(key, defaultValue: <EatenFood>[])!;
        if (storedList.isEmpty) continue;
        mealRequestList.add({
          'mealType': type,
          'mealTime': DateTime.now().toIso8601String(),
          'mealFoodRequestList':
              storedList
                  .map((e) => {'foodCode': e.foodCode, 'count': e.count})
                  .toList(),
        });
      }

      final beerMl = _beerCount * 250; // 맥주 한 잔 = 250ml
      final sojuMl = _sojuCount * 50; // 소주 한 잔 = 50ml

      //  STEP B: alcoholConsumptionResult 리스트 생성
      List<Map<String, dynamic>> alcoholList = [];
      if (beerMl > 0) {
        alcoholList.add({
          'alcoholType': 'BEER',
          'consumedAlcoholDrinks': beerMl,
        });
      }
      if (sojuMl > 0) {
        alcoholList.add({
          'alcoholType': 'SOJU',
          'consumedAlcoholDrinks': sojuMl,
        });
      }

      //  STEP C: payload 작성
      final payload = {
        'healthKit': {
          'period': {
            'startDateTime':
                DateTime.now()
                    .subtract(const Duration(hours: 24))
                    .toIso8601String(),
            'endDateTime': DateTime.now().toIso8601String(),
          },
          'customHealthKit': {
            'waterIntake': totalWater * 250,
            'smokedCigarettes': totalSmoke,
            'alcoholConsumptionResult': {'result': alcoholList},
          },
          'appleHealthKit': {
            'activity': {
              'stepCount': (healthData['stepCount'] ?? 0).round(),
              'distanceWalkingRunning':
                  (healthData['activity']['distanceWalkingRunning'] ?? 0.0)
                      .round(),
              'activeEnergyBurned':
                  (healthData['activity']['activeEnergyBurned'] ?? 0.0).round(),
              'appleExerciseTime':
                  (healthData['activity']['appleExerciseTime'] ?? 0).round(),
            },
            'sleepAnalysis': healthData['sleep'],
            'vitalSigns': {
              'heartRate': (healthData['vital']['heartRate'] ?? 0).round(),
              'oxygenSaturation':
                  (healthData['vital']['oxygenSaturation'] ?? 0).round(),
              'bodyTemperature':
                  (healthData['vital']['bodyTemperature'] ?? 0.0).toDouble(),
            },
            'workouts': {
              'workoutTypes':
                  healthData['exercise']
                      .map((e) => e['exerciseType'])
                      .toSet()
                      .toList(),
            },
          },
        },
        'mealsRequest': {'mealRequestList': mealRequestList},
      };

      // 3) 서버 전송
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      if (token.isEmpty) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('토큰이 없습니다. 로그인 후 다시 시도해주세요.')),
        );
        return;
      }

      final res = await http.post(
        Uri.parse('${Config.baseUrl}/health/report/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        // 제출 성공
        await prefs.setBool(_submitPrefKey, true);
        if (mounted) setState(() => _isSubmittedToday = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '일일 기록에 성공하였습니다.\n오늘은 더 이상 기록이 불가능해요.',
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          ),
        );

        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => ReportScreen(
                  initialPage: "일간",
                  initialDate: DateTime.now(),
                ),
          ),
        );
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘 이미 기록했거나, 저장에 실패했습니다.')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWater = _initialWater;
    final totalWater = _initialWater + _extraWater;
    final currentSmoke = _initialSmoke;
    final totalSmoke = _initialSmoke + _extraSmoke;

    return Scaffold(
      appBar: AppBar(title: const Text('오늘 하루 건강 기록 정리하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수/흡연 카운터
            Row(
              children: [
                _buildCounterCard(
                  title: '음수량',
                  iconData: Icons.water_drop,
                  backgroundColor: Colors.lightBlue.shade100,
                  countText: '오늘 $currentWater → 총 $totalWater 잔',
                  onTap:
                      () => _showAddDialog(
                        title: '음수량',
                        ctrl: _waterController,
                        onConfirm: (v) => setState(() => _extraWater += v),
                      ),
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  title: '흡연량',
                  iconData: Icons.smoke_free_outlined,
                  backgroundColor: Colors.pink.shade100,
                  countText: '오늘 $currentSmoke → 총 $totalSmoke 개비',
                  onTap:
                      () => _showAddDialog(
                        title: '흡연량',
                        ctrl: _smokeController,
                        onConfirm: (v) => setState(() => _extraSmoke += v),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 음주량 기록
            const Text(
              '음주량 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAlcoholButton(
                  '맥주',
                  (count) => setState(() => _beerCount = count),
                ),
                const SizedBox(width: 8),
                _buildAlcoholButton(
                  '소주',
                  (count) => setState(() => _sojuCount = count),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 식단 입력
            const Text(
              '식단 입력',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...['아침', '점심', '저녁', '간식'].map(
              (meal) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  meal == '아침'
                      ? Icons.free_breakfast 
                      : meal == '점심'
                      ? Icons.sunny
                      : meal == '저녁'
                      ? Icons.nightlight_round
                      : Icons.apple,
                  color: Colors.deepPurple,
                ),
                title: Text(meal, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealFoodScreen(mealType: meal),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 32),

            // 기록 완료 버튼
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittedToday ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isSubmittedToday ? '오늘 기록 완료됨' : '기록 완료하기'),
                ),
              ),
            ),
          ],
        ),
      ),

      // 하단 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) return;
          switch (i) {
            case 1:
              Navigator.pushReplacementNamed(context, '/savings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
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

  /// 물/흡연 카드 컴포넌트
  Widget _buildCounterCard({
    required String title,
    required IconData iconData,
    required Color backgroundColor,
    required String countText,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconData, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                top: 36,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    countText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 음주 기록 버튼
  Widget _buildAlcoholButton(String type, ValueSetter<int> onCountSelected) {
    final isBeer = type == '맥주';
    final current = isBeer ? _beerCount : _sojuCount;
    final iconData = isBeer ? Icons.local_drink : Icons.liquor;
    final bgColor = isBeer ? Colors.orange.shade100 : Colors.green.shade100;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(iconData, color: Colors.black54),
                const SizedBox(width: 6),
                Text('$type: $current', style: const TextStyle(fontSize: 16)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () async {
                final result = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DrinkEntryScreen(
                          drinkType: type,
                          initialCount: current,
                        ),
                  ),
                );
                if (result != null) {
                  onCountSelected(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
*/
