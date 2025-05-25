// server_meal_report.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MealDetailScreenServer extends StatefulWidget {
  final DateTime date;

  const MealDetailScreenServer({super.key, required this.date});

  @override
  State<MealDetailScreenServer> createState() => _MealDetailScreenServerState();
}

class _MealDetailScreenServerState extends State<MealDetailScreenServer> {
  List<dynamic> mealList = [];

  @override
  void initState() {
    super.initState();
    _loadMealDetails();
  }

  Future<void> _loadMealDetails() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    print('📅 요청 날짜: $dateStr');
    print('🔑 Access Token: $token');

    final res = await http.get(
      Uri.parse('http://localhost:8080/health/report?date=$dateStr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('🌐 상태 코드: ${res.statusCode}');
    print('📥 응답 바디: ${res.body}');

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() {
        mealList = decoded['mealsResponse']?['mealResponseList'] ?? [];
      });
    }
  }

  Widget _buildMealCard(dynamic meal) {
    final Map<String, dynamic> mealMap = Map<String, dynamic>.from(meal);
    final mealType = mealMap['mealTypeLabel'] ?? '-';
    final mealFoods = (mealMap['mealFoodResponseList'] ?? []) as List;
    final foods = mealFoods.map((e) => e['foodResponse']).toList();

    print('🧾 불러온 식사: $mealType');
    print('🥗 음식 목록: $foods');

    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var food in foods) {
      totalCarb += food['carbohydrate'] ?? 0.0;
      totalProtein += food['protein'] ?? 0.0;
      totalFat += food['fat'] ?? 0.0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$mealType 총 영양정보',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('탄수화물: ${totalCarb.toStringAsFixed(1)}g'),
            Text('단백질: ${totalProtein.toStringAsFixed(1)}g'),
            Text('지방: ${totalFat.toStringAsFixed(1)}g'),
            const SizedBox(height: 8),
            if (foods.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: foods.map<Widget>((food) {
                  return ListTile(
                    title: Text(food['foodName'] ?? '이름 없음'),
                    subtitle: Text(
                        '탄 ${food['carbohydrate']}g, 단 ${food['protein']}g, 지 ${food['fat']}g'),
                  );
                }).toList(),
              )
            else
              const Text('기록된 음식 없음'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 MM월 dd일').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text('$dateStr 식단 상세'),
      ),
      body: mealList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: mealList.map<Widget>(_buildMealCard).toList(),
            ),
    );
  }
}
