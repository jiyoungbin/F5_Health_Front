import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../app_data.dart';
import 'meal_food_screen.dart';
import 'drink_entry_screen.dart';
import '../services/health_service.dart';
import '../models/eaten_food.dart';

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
  int _beerCount = 0;
  int _sojuCount = 0;
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

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final box = await Hive.openBox<List>('eatenFoods');
    final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'DESSERT'];
    List<Map<String, dynamic>> mealRequestList = [];

    for (final type in mealTypes) {
      final key = '$today|$type';
      final storedList =
          box.get(key, defaultValue: [])?.cast<EatenFood>() ?? [];
      if (storedList.isEmpty) continue;

      final mealEntry = {
        'mealType': type,
        'mealTime': DateTime.now().toIso8601String(),
        'mealFoodRequestList': storedList
            .map((e) => {
                  'foodCode': e.foodCode,
                  'count': e.count,
                })
            .toList()
      };

      mealRequestList.add(mealEntry);
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
          'waterIntake': AppData.waterCount * 250,
          'smokedCigarettes': AppData.smokeCount,
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
        }
      },
      'mealsRequest': {
        'mealRequestList': mealRequestList,
        'mealCount': mealRequestList.length,
      }
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    if (token.isEmpty) return;

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

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
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
                          builder: (_) => MealFoodScreen(mealType: meal)),
                    );
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
                  title: title, ctrl: controller, onConfirm: onConfirm),
              child: const Text('수 추가 입력'),
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
              builder: (_) => DrinkEntryScreen(drinkType: type),
            ),
          );
          if (result is int) onCountSelected(result);
        },
        child: Text(type),
      ),
    );
  }
}
