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
  // 알코올 및 금액
  int _beerCount = 0;
  int _sojuCount = 0;
  int _alcoholSpentMoney = 0;

  // 오늘 이미 제출했는지 여부
  bool _isSubmittedToday = false;
  late final String _submitPrefKey;

  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();
  final _alcoholMoneyController = TextEditingController();
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
    _alcoholMoneyController.dispose();
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
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('생활습관 점수 계산 중…', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
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

      final totalAlcoholMl = _beerCount * 250 + _sojuCount * 50;
      final alcoholCount = totalAlcoholMl ~/ 100;

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
            'consumedAlcoholDrinks': alcoholCount,
            'alcoholCost': _alcoholSpentMoney,
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
                  current: currentWater,
                  total: totalWater,
                  controller: _waterController,
                  onConfirm: (v) => setState(() => _extraWater += v),
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  title: '흡연량',
                  current: currentSmoke,
                  total: totalSmoke,
                  controller: _smokeController,
                  onConfirm: (v) => setState(() => _extraSmoke += v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 음주량 기록
            const Text('음주량 기록', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 8),
            const Text(
              '음주에 사용한 금액 입력 (원)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _alcoholMoneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '예: 10000',
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (val) => setState(
                    () => _alcoholSpentMoney = int.tryParse(val) ?? 0,
                  ),
            ),
            const SizedBox(height: 16),

            // 식단 입력
            const Text('식단 입력', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...['아침', '점심', '저녁', '간식'].map(
              (meal) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(meal),
                trailing: const Icon(Icons.arrow_forward_ios),
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
            const SizedBox(height: 24),

            // 기록 완료 버튼
            Center(
              child: ElevatedButton(
                onPressed: _isSubmittedToday ? null : _onSave,
                child: Text(_isSubmittedToday ? '오늘 기록 완료됨' : '기록 완료하기'),
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

  Widget _buildCounterCard({
    required String title,
    required int current,
    required int total,
    required TextEditingController controller,
    required ValueSetter<int> onConfirm,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: EdgeInsets.only(
          right: title == '음수량' ? 12 : 0,
          left: title == '흡연량' ? 12 : 0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title 기록',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('오늘 $title: $current'),
            Text('총 $title: $total'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed:
                  () => _showAddDialog(
                    title: title,
                    ctrl: controller,
                    onConfirm: onConfirm,
                  ),
              child: const Text('추가 입력'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcoholButton(String type, ValueSetter<int> onCountSelected) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final current = (type == '맥주') ? _beerCount : _sojuCount;

          final result = await Navigator.push<int>(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DrinkEntryScreen(
                    drinkType: type,
                    initialCount: current, // ← 기존에 누적된 값 넘겨주기
                  ),
            ),
          );

          if (result != null) {
            setState(() {
              if (type == '맥주')
                _beerCount = result;
              else
                _sojuCount = result;
            });
          }
        },
        child: Text(type),
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
  // 알코올 및 금액
  int _beerCount = 0;
  int _sojuCount = 0;
  int _alcoholSpentMoney = 0;

  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();
  final _alcoholMoneyController = TextEditingController();
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    print('[ENTRY] ⚙️ initState 호출, _loadDailyCounts 실행');
    _loadDailyCounts();
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
    print(
        '[ENTRY] 💾 _loadDailyCounts 완료: water=$_initialWater, smoke=$_initialSmoke');
  }

  @override
  void dispose() {
    _waterController.dispose();
    _smokeController.dispose();
    _alcoholMoneyController.dispose();
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
      builder: (_) => AlertDialog(
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
              print('[ENTRY] 🔢 $title 추가 입력 값: $v');
              onConfirm(v);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 저장: Hive 업데이트 및 서버 전송
  Future<void> _onSave() async {
    print('[ENTRY] 🚀 _onSave() 호출됨');
    final totalWater = _initialWater + _extraWater;
    final totalSmoke = _initialSmoke + _extraSmoke;

    // 1) Hive에 오늘 최종 값 저장
    print('[ENTRY] 💾 Hive 저장 시작: water=$totalWater, smoke=$totalSmoke');
    final box = Hive.box<DailyRecord>('dailyData');
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = DailyRecord(waterCount: totalWater, smokeCount: totalSmoke);
    await box.put(todayKey, record);
    print('[ENTRY] 💾 Hive 저장 완료');

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
        'mealFoodRequestList': storedList
            .map((e) => {'foodCode': e.foodCode, 'count': e.count})
            .toList(),
      });
    }

    final totalAlcoholMl = _beerCount * 250 + _sojuCount * 50;
    final alcoholCount = totalAlcoholMl ~/ 100;

    final payload = {
      'healthKit': {
        'period': {
          'startDateTime': DateTime.now()
              .subtract(const Duration(hours: 24))
              .toIso8601String(),
          'endDateTime': DateTime.now().toIso8601String(),
        },
        'customHealthKit': {
          'waterIntake': totalWater * 250,
          'smokedCigarettes': totalSmoke,
          'consumedAlcoholDrinks': alcoholCount,
          'alcoholCost': _alcoholSpentMoney,
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
            'workoutTypes': healthData['exercise']
                .map((e) => e['exerciseType'])
                .toSet()
                .toList(),
          },
        },
      },
      'mealsRequest': {
        'mealRequestList': mealRequestList,
        // 'mealCount': mealRequestList.length,
      },
    };

    print('[ENTRY] 📡 POST payload: ${jsonEncode(payload)}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    if (token.isEmpty) {
      print('[ENTRY] ❌ 토큰이 없습니다. _onSave 중단');
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('http://${Config.baseUrl}/health/report/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(payload),
      );
      print('[ENTRY] 🌐 HTTP 응답 코드: ${res.statusCode}');
    } catch (e, st) {
      print('[ENTRY] ⚠️ HTTP 예외 발생: $e\n$st');
    }

    if (mounted) {
      print('[ENTRY] ✅ 홈화면으로 이동');
      Navigator.pushReplacementNamed(context, '/home');
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
            Row(
              children: [
                _buildCounterCard(
                  title: '음수량',
                  current: currentWater,
                  total: totalWater,
                  controller: _waterController,
                  onConfirm: (v) => setState(() => _extraWater += v),
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  title: '흡연량',
                  current: currentSmoke,
                  total: totalSmoke,
                  controller: _smokeController,
                  onConfirm: (v) => setState(() => _extraSmoke += v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('음주량 기록', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              _buildAlcoholButton(
                  '맥주', (count) => setState(() => _beerCount = count)),
              const SizedBox(width: 8),
              _buildAlcoholButton(
                  '소주', (count) => setState(() => _sojuCount = count)),
            ]),
            const SizedBox(height: 8),
            const Text('음주에 사용한 금액 입력 (원)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _alcoholMoneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: '예: 10000', border: OutlineInputBorder()),
              onChanged: (val) =>
                  setState(() => _alcoholSpentMoney = int.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 16),
            const Text('식단 입력', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...['아침', '점심', '저녁', '간식'].map((meal) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MealFoodScreen(mealType: meal)));
                    setState(() {});
                  },
                )),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  print('[ENTRY] 🎯 기록 완료하기 버튼 눌림');
                  _onSave();
                },
                child: const Text('기록 완료하기'),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildCounterCard({
    required String title,
    required int current,
    required int total,
    required TextEditingController controller,
    required ValueSetter<int> onConfirm,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: EdgeInsets.only(
            right: title == '음수량' ? 12 : 0, left: title == '흡연량' ? 12 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title 기록',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('오늘 $title: $current'),
            Text('총 $title: $total'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _showAddDialog(
                  title: title, ctrl: controller, onConfirm: onConfirm),
              child: const Text('추가 입력'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcoholButton(String type, ValueSetter<int> onCountSelected) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DrinkEntryScreen(drinkType: type)),
          );
          if (result is int) {
            print('[ENTRY] 🍻 $type 선택: $result');
            onCountSelected(result);
          }
        },
        child: Text(type),
      ),
    );
  }
}
*/
