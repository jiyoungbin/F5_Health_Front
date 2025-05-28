import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../models/eaten_food.dart';
import '../config.dart';

class MealFoodScreen extends StatefulWidget {
  final String mealType; // '아침', '점심', '저녁', '간식'

  const MealFoodScreen({super.key, required this.mealType});

  @override
  State<MealFoodScreen> createState() => _MealFoodScreenState();
}

class _MealFoodScreenState extends State<MealFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<EatenFood> _selectedFoods = [];

  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
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

  String _generateKey() {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final mealTypeEnum = _getMealTypeEnum(widget.mealType);
    return '$date|$mealTypeEnum';
  }

  Future<void> _loadSavedFoods() async {
    final box = Hive.box<List<EatenFood>>('mealFoodsBox');
    final key = _generateKey();
    final stored = box.get(key);
    if (stored != null) {
      setState(() {
        _selectedFoods = List<EatenFood>.from(stored);
      });
    }
  }

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    final url = Uri.parse(
      '${Config.baseUrl}/foods/search?foodSearchQuery=${Uri.encodeQueryComponent(query)}',
    );

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data['results']);
      });
    } else {
      setState(() => _searchResults = []);
    }
  }

  Future<void> _showAmountDialog(Map<String, dynamic> food) async {
    double servingCount = 1.0;

    final stdStr = food['nutritionContentStdQuantity'] ?? '100g';
    final weightStr = food['foodWeight'] ?? '100g';

    final std =
        double.tryParse(stdStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100;
    final weight =
        double.tryParse(weightStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100;
    final ratio = weight / std;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, localSetState) {
              return AlertDialog(
                title: Text('${food['foodName']} 섭취량 설정'),
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        localSetState(() {
                          if (servingCount > 0.5) servingCount -= 0.5;
                        });
                      },
                    ),
                    Text('${servingCount.toStringAsFixed(1)} 인분'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        localSetState(() {
                          servingCount += 0.5;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: '상세보기',
                      onPressed: () async {
                        Navigator.pop(context);
                        await _showFoodDetail(food['foodCode']);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFoods.add(
                          EatenFood(
                            foodCode: food['foodCode'],
                            foodName: food['foodName'],
                            count: servingCount,
                            kcal: (food['kcal'] ?? 0).toDouble() * ratio,
                            carbohydrate:
                                (food['carbohydrate'] ?? 0).toDouble() * ratio,
                            protein: (food['protein'] ?? 0).toDouble() * ratio,
                            fat: (food['fat'] ?? 0).toDouble() * ratio,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('추가'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _showFoodDetail(String foodCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final url = Uri.parse('${Config.baseUrl}/foods/$foodCode');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final food = jsonDecode(utf8.decode(res.bodyBytes));
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(food['foodName']),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '📌 아래 영양정보는 ${food['nutritionContentStdQuantity'] ?? '100g'} 기준입니다.',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text('열량: ${food['kcal']} kcal'),
                  Text('탄수화물: ${food['carbohydrate']}g'),
                  Text('단백질: ${food['protein']}g'),
                  Text('지방: ${food['fat']}g'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _saveFoods() async {
    final box = Hive.box<List<EatenFood>>('mealFoodsBox');
    final key = _generateKey();
    await box.put(key, _selectedFoods);
    Navigator.pop(context, true);
  }

  void _removeFood(String foodCode) {
    setState(() {
      _selectedFoods.removeWhere((f) => f.foodCode == foodCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealType} 음식 선택'),
        actions: [
          TextButton(
            onPressed: _saveFoods,
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchFood,
              decoration: InputDecoration(
                hintText: '음식 이름 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child:
                _searchResults.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다.'))
                    : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (_, index) {
                        final food = _searchResults[index];
                        return ListTile(
                          title: Text(food['foodName']),
                          subtitle: Text('${food['kcal']} kcal'),
                          trailing: const Icon(Icons.add),
                          onTap: () => _showAmountDialog(food),
                        );
                      },
                    ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ 선택한 음식',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedFoods.length,
                      itemBuilder: (_, index) {
                        final f = _selectedFoods[index];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${f.foodName} (${f.count}인분, ${(f.kcal * f.count).toStringAsFixed(0)}kcal)',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeFood(f.foodCode),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
