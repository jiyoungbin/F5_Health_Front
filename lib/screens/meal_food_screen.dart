import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealFoodScreen extends StatefulWidget {
  final String mealType;

  const MealFoodScreen({super.key, required this.mealType});

  @override
  State<MealFoodScreen> createState() => _MealFoodScreenState();
}

class _MealFoodScreenState extends State<MealFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedFoods = [];

  @override
  void initState() {
    super.initState();
    _selectedFoods = List<Map<String, dynamic>>.from(AppData.meals[widget.mealType] ?? []);
  }

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      print('❌ 액세스 토큰 없음');
      return;
    }

    final url = Uri.parse('http://localhost:8080/foods/search?foodSearchQuery=${Uri.encodeQueryComponent(query)}');
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
      print('❌ 검색 실패: ${res.statusCode}');
      setState(() => _searchResults = []);
    }
  }

  Future<void> _addFoodWithAmount(Map<String, dynamic> food) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final foodCode = food['foodCode'];

    if (accessToken == null) {
      print('❌ 액세스 토큰 없음');
      return;
    }

    final detailUrl = Uri.parse('http://localhost:8080/foods/$foodCode');
    final res = await http.get(
      detailUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (res.statusCode != 200) {
      print('❌ 상세 정보 불러오기 실패');
      return;
    }

    final foodDetail = jsonDecode(utf8.decode(res.bodyBytes));
    double servingCount = 1.0;
    final String weightStr = foodDetail['foodWeight'];
    final double weightPerServing = double.parse(weightStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    final bool isMl = weightStr.contains('ml');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, localSetState) {
          final double totalAmount = servingCount * weightPerServing;
          double kcal = (foodDetail['kcal'] / 100) * totalAmount;
          double carb = (foodDetail['carbohydrate'] / 100) * totalAmount;
          double protein = (foodDetail['protein'] / 100) * totalAmount;
          double fat = (foodDetail['fat'] / 100) * totalAmount;

          return AlertDialog(
            title: Text('${foodDetail["foodName"]} 섭취량 설정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                  ],
                ),
                const SizedBox(height: 12),
                Text('총 섭취량: ${totalAmount.toStringAsFixed(1)}${isMl ? 'ml' : 'g'}'),
                Text('칼로리: ${kcal.toStringAsFixed(0)} kcal'),
                Text('탄수화물: ${carb.toStringAsFixed(1)}g'),
                Text('단백질: ${protein.toStringAsFixed(1)}g'),
                Text('지방: ${fat.toStringAsFixed(1)}g'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFoods.add({
                      "foodCode": foodDetail["foodCode"],
                      "foodName": foodDetail["foodName"],
                      "amount": servingCount,
                      "volume": totalAmount,
                      "kcal": kcal,
                      "carbohydrate": carb,
                      "protein": protein,
                      "fat": fat,
                    });
                    AppData.meals[widget.mealType] = _selectedFoods;
                  });
                  Navigator.pop(context);
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

  void _removeFood(dynamic foodCode) {
    if (foodCode == null) return;
    setState(() {
      _selectedFoods.removeWhere((f) => f['foodCode'] == foodCode);
      AppData.meals[widget.mealType] = _selectedFoods;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealType} 음식 선택'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchFood,
              decoration: InputDecoration(
                hintText: '음식 이름을 검색하세요',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final food = _searchResults[index];
                      return ListTile(
                        title: Text(food["foodName"]),
                        subtitle: Text('${food["kcal"]} kcal'),
                        trailing: const Icon(Icons.add),
                        onTap: () => _addFoodWithAmount(food),
                      );
                    },
                  ),
          ),
          if (_selectedFoods.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ 선택한 음식',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._selectedFoods.map(
                    (f) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('• ${f["foodName"]} (${f["amount"]}인분, ${f["kcal"].toStringAsFixed(0)}kcal)'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeFood(f['foodCode']),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
