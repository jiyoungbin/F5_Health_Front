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

    final res = await http.get(
      Uri.parse('http://localhost:8080/health/report?date=$dateStr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final meals = decoded['mealsResponse']?['mealResponseList'];
      setState(() {
        mealList = meals ?? [];
      });
    }
  }

  Future<List<dynamic>> _fetchMealDetails(int mealId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final url = Uri.parse('http://localhost:8080/meal/$mealId');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded['mealFoodResponseList'] ?? [];
    }

    return [];
  }

  Widget _buildMealCard(String mealType, List<dynamic> mealList) {
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;
    List<Widget> foodWidgets = [];

    for (var meal in mealList) {
      totalCarb += (meal['totalCarbohydrate'] ?? 0.0);
      totalProtein += (meal['totalProtein'] ?? 0.0);
      totalFat += (meal['totalFat'] ?? 0.0);

      final mealFoods = meal['mealFoodResponseList'];

      if (mealFoods == null) {
        _fetchMealDetails(meal['mealId']).then((fetchedFoods) {
          setState(() {
            meal['mealFoodResponseList'] = fetchedFoods;
          });
        });
        continue;
      }

      if (mealFoods is List) {
        for (var mealFood in mealFoods) {
          final food = mealFood['foodResponse'] ?? {};
          final count = (mealFood['count'] ?? 1).toDouble();

          final foodWeightStr = food['foodWeight'] ?? '100g';
          final stdQuantityStr = food['nutritionContentStdQuantity'] ?? '100g';

          final foodWeight = double.tryParse(foodWeightStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
          final stdQuantity = double.tryParse(stdQuantityStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
          final ratio = foodWeight / stdQuantity;

          final kcal = (food['kcal'] ?? 0.0) * ratio * count;
          final carb = (food['carbohydrate'] ?? 0.0) * ratio * count;
          final protein = (food['protein'] ?? 0.0) * ratio * count;
          final fat = (food['fat'] ?? 0.0) * ratio * count;

          foodWidgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(food['foodName'] ?? '이름 없음',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                Text('(${count.toStringAsFixed(1)}인분) 탄 ${carb.toStringAsFixed(1)}g, 단 ${protein.toStringAsFixed(1)}g, 지 ${fat.toStringAsFixed(1)}g, 총칼로리: ${kcal.toStringAsFixed(1)}kcal')
              ],
            ),
          );
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$mealType 총 영양정보',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('탄수화물: ${totalCarb.toStringAsFixed(1)}g'),
            Text('단백질: ${totalProtein.toStringAsFixed(1)}g'),
            Text('지방: ${totalFat.toStringAsFixed(1)}g'),
            const SizedBox(height: 8),
            foodWidgets.isNotEmpty
                ? Column(children: foodWidgets)
                : const Text('음식 상세 정보 없음'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 MM월 dd일').format(widget.date);

    Map<String, List<dynamic>> groupedMeals = {
      '아침': [],
      '점심': [],
      '저녁': [],
      '간식': [],
    };
    for (var meal in mealList) {
      final label = meal['mealTypeLabel'];
      if (groupedMeals.containsKey(label)) {
        groupedMeals[label]!.add(meal);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$dateStr 식단 상세'),
      ),
      body: mealList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: groupedMeals.entries
                  .where((entry) => entry.value.isNotEmpty)
                  .map<Widget>(
                    (entry) => _buildMealCard(entry.key, entry.value),
                  )
                  .toList(),
            ),
    );
  }
}
