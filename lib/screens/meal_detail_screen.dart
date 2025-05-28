import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/eaten_food.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealType;

  const MealDetailScreen({super.key, required this.mealType});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  List<EatenFood> eatenFoods = [];
  String selectedMeal = '';

  @override
  void initState() {
    super.initState();
    selectedMeal = widget.mealType;
    _loadMealData();
  }

  String _getMealTypeEnum(String kr) {
    switch (kr) {
      case '아침':
        return 'BREAKFAST';
      case '점심':
        return 'LUNCH';
      case '저녁':
        return 'DINNER';
      case '간식':
        return 'DESSERT';
      default:
        return 'UNKNOWN';
    }
  }

  Future<void> _loadMealData() async {
    final box = Hive.box<List<EatenFood>>('mealFoodsBox');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final mealTypeEnum = _getMealTypeEnum(selectedMeal);
    final key = '$today|$mealTypeEnum';

    final storedList = box.get(key, defaultValue: <EatenFood>[])!;
    final newEatenFoods = List<EatenFood>.from(storedList);

    setState(() {
      eatenFoods = newEatenFoods;
    });
  }

  double get totalKcal =>
      eatenFoods.fold(0.0, (sum, food) => sum + food.kcal * food.count);
  double get totalCarb =>
      eatenFoods.fold(0.0, (sum, food) => sum + food.carbohydrate * food.count);
  double get totalProtein =>
      eatenFoods.fold(0.0, (sum, food) => sum + food.protein * food.count);
  double get totalFat =>
      eatenFoods.fold(0.0, (sum, food) => sum + food.fat * food.count);

  Widget _buildNutrientTile(
      String label, String level, double value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8)),
          child: Text(level, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Text('$label ${value.toStringAsFixed(1)}g'),
      ],
    );
  }

  String _getLevel(double value, String type) {
    if (type == '탄수화물') return value > 130 ? '초과' : '적정';
    if (type == '단백질') return value < 50 ? '부족' : '적정';
    if (type == '지방') return value > 70 ? '초과' : '적정';
    return '적정';
  }

  Color _getColor(String level) {
    switch (level) {
      case '초과':
        return Colors.redAccent;
      case '부족':
        return Colors.orangeAccent;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedMeal 영양정보'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['아침', '점심', '저녁', '간식'].map((meal) {
                final selected = selectedMeal == meal;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? Colors.black : Colors.grey[200],
                    foregroundColor: selected ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedMeal = meal;
                    });
                    _loadMealData();
                  },
                  child: Text(meal),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$selectedMeal 총 영양정보',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('열량: ${totalKcal.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildNutrientTile('탄수화물', _getLevel(totalCarb, '탄수화물'),
                        totalCarb, _getColor(_getLevel(totalCarb, '탄수화물'))),
                    const SizedBox(height: 8),
                    _buildNutrientTile(
                        '단백질',
                        _getLevel(totalProtein, '단백질'),
                        totalProtein,
                        _getColor(_getLevel(totalProtein, '단백질'))),
                    const SizedBox(height: 8),
                    _buildNutrientTile('지방', _getLevel(totalFat, '지방'),
                        totalFat, _getColor(_getLevel(totalFat, '지방'))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (eatenFoods.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: eatenFoods.length,
                  itemBuilder: (context, index) {
                    final food = eatenFoods[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(food.foodName),
                        subtitle: Text(
                            '열량: ${(food.kcal * food.count).toStringAsFixed(0)} kcal\n'
                            '탄: ${(food.carbohydrate * food.count).toStringAsFixed(1)}g, '
                            '단: ${(food.protein * food.count).toStringAsFixed(1)}g, '
                            '지: ${(food.fat * food.count).toStringAsFixed(1)}g'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
