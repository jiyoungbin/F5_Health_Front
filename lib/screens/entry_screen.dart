import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../app_data.dart';
import 'meal_food_screen.dart';
import 'drink_entry_screen.dart';
import '../services/health_service.dart';
import '../models/health_record.dart'; // ✅ Hive 모델 import

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  int _initialWater = AppData.waterCount;
  int _initialSmoke = AppData.smokeCount;
  int _extraWater = 0;
  int _extraSmoke = 0;
  int _alcoholCount = 0;
  int _alcoholSpentMoney = 0;

  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();
  final _alcoholMoneyController = TextEditingController();
  final HealthService _healthService = HealthService();

  @override
  void dispose() {
    _waterController.dispose();
    _smokeController.dispose();
    _alcoholMoneyController.dispose();
    super.dispose();
  }

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
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
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

  Future<void> _onSave() async {
    AppData.waterCount = _initialWater + _extraWater;
    AppData.smokeCount = _initialSmoke + _extraSmoke;

    final healthData = await _healthService.getTodayHealthData();
    final mealRequestList = AppData.toMealRequestList();

    final payload = {
      'healthKit': {
        'period': {
          'startDateTime': DateTime.now()
              .subtract(const Duration(hours: 24))
              .toIso8601String(),
          'endDateTime': DateTime.now().toIso8601String(),
        },
        'customHealthKit': {
          'waterIntake': AppData.waterCount * 250,
          'smokedCigarettes': AppData.smokeCount,
          'consumedAlcoholDrinks': _alcoholCount,
          'alcoholSpentMoney': _alcoholSpentMoney,
        },
        'appleHealthKit': {
          'activity': {
            'stepCount': healthData['stepCount'],
            'distanceWalkingRunning': healthData['activity']
                ['distanceWalkingRunning'],
            'activeEnergyBurned': healthData['activity']['activeEnergyBurned'],
            'appleExerciseTime': healthData['activity']['appleExerciseTime'],
          },
          'sleepAnalysis': healthData['sleep'],
          'vitalSigns': healthData['vital'],
          'workouts': {
            'workoutTypes': healthData['exercise']
                .map((e) => e['exerciseType'])
                .toSet()
                .toList(),
          },
        }
      },
      'mealsRequest': {
        'mealRequestList': mealRequestList,
        'mealCount': mealRequestList.length,
      }
    };

    print('📤 전송할 JSON:');
    print(const JsonEncoder.withIndent('  ').convert(payload));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    print('📛 accessToken: $token');
    if (token.isEmpty) {
      print('❌ 저장된 액세스 토큰이 없거나 비어 있음');
      return;
    }

    final res = await http.post(
      Uri.parse('http://localhost:8080/health/report/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      print('✅ 전송 성공');
    } else {
      print('❌ 전송 실패: ${res.statusCode}');
    }

    // ✅ Hive 저장
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final record = HealthDailyRecord(
      waterIntake: AppData.waterCount * 250,
      alcoholAmount: _alcoholCount,
      alcoholSpentMoney: _alcoholSpentMoney,
      smokingAmount: AppData.smokeCount,
      stepCount: healthData['stepCount'] ?? 0,
      distanceWalkingRunning:
          healthData['activity']['distanceWalkingRunning'] ?? 0.0,
      activeEnergyBurned: healthData['activity']['activeEnergyBurned'] ?? 0,
      appleExerciseTime: healthData['activity']['appleExerciseTime'] ?? 0,
      heartRate: healthData['vital']['heartRate'] ?? 0,
      totalCaloriesBurned: healthData['activity']['activeEnergyBurned'] ?? 0,
      sleepHours: healthData['sleep']['duration'] ?? 0,
      workoutTypes: healthData['exercise']
          .map<String>((e) => e['exerciseType'].toString())
          .toList(),
      meals: AppData.toMealRecordList(),
    );

    await AppData.healthBox?.put(todayKey, record);
    print('✅ Hive 저장 완료: $todayKey');

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalWater = _initialWater + _extraWater;
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
                  current: _initialWater,
                  total: totalWater,
                  controller: _waterController,
                  onConfirm: (v) => setState(() => _extraWater += v),
                ),
                _buildCounterCard(
                  title: '흡연량',
                  current: _initialSmoke,
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
              _buildAlcoholButton('맥주'),
              const SizedBox(width: 8),
              _buildAlcoholButton('소주'),
            ]),
            const SizedBox(height: 8),
            Text('음주에 사용한 금액 입력 (원)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _alcoholMoneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '예: 10000',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _alcoholSpentMoney = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('식단 입력', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...AppData.meals.keys.map((meal) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal),
                  subtitle: Text(AppData.meals[meal]!.isEmpty
                      ? '아직 입력된 식단이 없습니다.'
                      : AppData.meals[meal]!
                          .map((f) => f['foodName'])
                          .join(', ')),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealFoodScreen(mealType: meal),
                        ));
                    setState(() {});
                  },
                )),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _onSave,
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
            right: title == '음수량' ? 8 : 0, left: title == '흡연량' ? 8 : 0),
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
                title: title,
                ctrl: controller,
                onConfirm: onConfirm,
              ),
              child: const Text('수 추가 입력'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcoholButton(String type) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DrinkEntryScreen(drinkType: type),
            ),
          );
          if (result is int) setState(() => _alcoholCount += result);
        },
        child: Text(type),
      ),
    );
  }
}

/*
// EntryScreen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../app_data.dart';
import 'meal_food_screen.dart';
import 'drink_entry_screen.dart';
import '../services/health_service.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  int _initialWater = AppData.waterCount;
  int _initialSmoke = AppData.smokeCount;
  int _extraWater = 0;
  int _extraSmoke = 0;
  int _alcoholCount = 0;
  int _alcoholSpentMoney = 0;

  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();
  final _alcoholMoneyController = TextEditingController();
  final HealthService _healthService = HealthService();

  @override
  void dispose() {
    _waterController.dispose();
    _smokeController.dispose();
    _alcoholMoneyController.dispose();
    super.dispose();
  }

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
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
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

  Future<void> _onSave() async {
    AppData.waterCount = _initialWater + _extraWater;
    AppData.smokeCount = _initialSmoke + _extraSmoke;

    final healthData = await _healthService.getTodayHealthData();
    final mealRequestList = AppData.toMealRequestList();

    final payload = {
      'healthKit': {
        'period': {
          'startDateTime': DateTime.now()
              .subtract(const Duration(hours: 24))
              .toIso8601String(),
          'endDateTime': DateTime.now().toIso8601String(),
        },
        'customHealthKit': {
          'waterIntake': AppData.waterCount * 250,
          'smokedCigarettes': AppData.smokeCount,
          'consumedAlcoholDrinks': _alcoholCount,
          'alcoholSpentMoney': _alcoholSpentMoney,
        },
        'appleHealthKit': {
          'activity': {
            'stepCount': healthData['stepCount'],
            'distanceWalkingRunning': healthData['activity']
                ['distanceWalkingRunning'],
            'activeEnergyBurned': healthData['activity']['activeEnergyBurned'],
            'appleExerciseTime': healthData['activity']['appleExerciseTime'],
          },
          'sleepAnalysis': healthData['sleep'],
          'vitalSigns': healthData['vital'],
          'workouts': {
            'workoutTypes': healthData['exercise']
                .map((e) => e['exerciseType'])
                .toSet()
                .toList(),
          },
        }
      },
      'mealsRequest': {
        'mealRequestList': mealRequestList,
        'mealCount': mealRequestList.length,
      }
    };

    print('📤 전송할 JSON:');
    print(const JsonEncoder.withIndent('  ').convert(payload));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    print('📛 accessToken: $token');
    if (token.isEmpty) {
      print('❌ 저장된 액세스 토큰이 없거나 비어 있음');
      return;
    }

    final res = await http.post(
      Uri.parse('http://localhost:8080/health/report/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      print('✅ 전송 성공');
    } else {
      print('❌ 전송 실패: ${res.statusCode}');
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalWater = _initialWater + _extraWater;
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
                  current: _initialWater,
                  total: totalWater,
                  controller: _waterController,
                  onConfirm: (v) => setState(() => _extraWater += v),
                ),
                _buildCounterCard(
                  title: '흡연량',
                  current: _initialSmoke,
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
              _buildAlcoholButton('맥주'),
              const SizedBox(width: 8),
              _buildAlcoholButton('소주'),
            ]),
            const SizedBox(height: 8),
            Text('음주에 사용한 금액 입력 (원)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _alcoholMoneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '예: 10000',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _alcoholSpentMoney = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('식단 입력', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...AppData.meals.keys.map((meal) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal),
                  subtitle: Text(AppData.meals[meal]!.isEmpty
                      ? '아직 입력된 식단이 없습니다.'
                      : AppData.meals[meal]!
                          .map((f) => f['foodName'])
                          .join(', ')),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealFoodScreen(mealType: meal),
                        ));
                    setState(() {});
                  },
                )),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _onSave,
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
            right: title == '음수량' ? 8 : 0, left: title == '흡연량' ? 8 : 0),
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
                title: title,
                ctrl: controller,
                onConfirm: onConfirm,
              ),
              child: const Text('수 추가 입력'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcoholButton(String type) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DrinkEntryScreen(drinkType: type),
            ),
          );
          if (result is int) setState(() => _alcoholCount += result);
        },
        child: Text(type),
      ),
    );
  }
}
*/
