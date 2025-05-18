import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealFoodScreen extends StatefulWidget {
  final String mealType; // '아침', '점심', '저녁', '간식'

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
    // 이전에 저장된 식단 불러오기
    _selectedFoods =
        List<Map<String, dynamic>>.from(AppData.meals[widget.mealType] ?? []);
  }

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      print('❌ 액세스 토큰 없음');
      return;
    }

    final url = Uri.parse(
        'http://localhost:8080/food?foodSearchQuery=${Uri.encodeQueryComponent(query)}');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data['results']);
      });
    } else {
      print('❌ 검색 실패: ${res.statusCode}');
      setState(() => _searchResults = []);
    }
  }

  void _addFoodWithAmount(Map<String, dynamic> food) {
    final TextEditingController amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${food["foodName"]} 섭취 수량 입력'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '몇 인분인가요?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final count = int.tryParse(amountCtrl.text);
              if (count != null && count > 0) {
                setState(() {
                  // 같은 foodCode가 있으면 대체
                  _selectedFoods
                      .removeWhere((f) => f['foodCode'] == food['foodCode']);
                  _selectedFoods.add({
                    "foodCode": food["foodCode"],
                    "foodName": food["foodName"],
                    "amount": count,
                    "kcal": food["kcal"] * count,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _onCompleteSelection() {
    AppData.meals[widget.mealType] = _selectedFoods;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCodes =
        _selectedFoods.map((f) => f['foodCode']).toSet(); // 중복 방지

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealType} 음식 선택'),
        actions: [
          TextButton(
            onPressed: _selectedFoods.isEmpty ? null : _onCompleteSelection,
            child: Text(
              '완료',
              style: TextStyle(
                color: _selectedFoods.isEmpty
                    ? Colors.grey
                    : const Color.fromARGB(0, 0, 0, 0),
                fontWeight: FontWeight.bold,
              ),
            ),
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
                      final alreadySelected =
                          selectedCodes.contains(food['foodCode']);
                      return ListTile(
                        title: Text(food["foodName"]),
                        subtitle: Text('${food["kcal"]} kcal'),
                        trailing: alreadySelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.add),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._selectedFoods.map((f) => Text(
                      '• ${f["foodName"]} (${f["amount"]}인분, ${f["kcal"]}kcal)')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealFoodScreen extends StatefulWidget {
  final String mealType; // '아침', '점심', '저녁', '간식'

  const MealFoodScreen({super.key, required this.mealType});

  @override
  State<MealFoodScreen> createState() => _MealFoodScreenState();
}

class _MealFoodScreenState extends State<MealFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _selectedFoods = [];

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      print('❌ 액세스 토큰 없음');
      return;
    }

    final url = Uri.parse('http://localhost:8080/food?foodSearchQuery=$query');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data['results']);
      });
    } else {
      print('❌ 검색 실패: ${res.statusCode}');
      setState(() => _searchResults = []);
    }
  }

  void _addFoodWithAmount(Map<String, dynamic> food) {
    final TextEditingController amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${food["foodName"]} 섭취 수량 입력'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '몇 인분인가요?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final count = int.tryParse(amountCtrl.text);
              if (count != null && count > 0) {
                setState(() {
                  _selectedFoods.add({
                    "foodCode": food["foodCode"],
                    "foodName": food["foodName"],
                    "amount": count,
                    "kcal": food["kcal"] * count,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _onCompleteSelection() {
    AppData.meals[widget.mealType] = _selectedFoods;
    Navigator.pop(context);
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
            onPressed: _selectedFoods.isEmpty ? null : _onCompleteSelection,
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._selectedFoods.map((f) => Text(
                      '• ${f["foodName"]} (${f["amount"]}인분, ${f["kcal"]}kcal)')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
*/