import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  int smokingSavedMoney = 0;
  int alcoholSavedMoney = 0;
  String recommendation = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavingData();
  }

  // 금액을 포맷하고 음수일 때 "낭비했어요" 라벨 붙이기
  String _formatMoneyLabel(int amount) {
    final absFormatted = NumberFormat('#,###').format(amount.abs());
    if (amount < 0) {
      return '$absFormatted원 지출';
    }
    return '$absFormatted원';
  }

  // 금액에 따른 색 반환 (+: green, -: red)
  Color _moneyColor(int amount) {
    return amount < 0 ? const Color.fromARGB(255, 192, 36, 36) : Colors.green;
  }

  Future<void> _fetchSavingData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    if (token.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://localhost:8080/v1/members/me/savings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          smokingSavedMoney = decoded['smokingSavedMoney'] ?? 0;
          alcoholSavedMoney = decoded['alcoholSavedMoney'] ?? 0;
          recommendation = decoded['healthItemsRecommend'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSaved = smokingSavedMoney + alcoholSavedMoney;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('절약 금액'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '절약한 금액으로 건강에 투자해보세요 💪',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // 총 절약 금액 카드
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '총 절약 금액',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatMoneyLabel(totalSaved),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _moneyColor(totalSaved),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('흡연'),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatMoneyLabel(smokingSavedMoney),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _moneyColor(smokingSavedMoney),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('음주'),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatMoneyLabel(alcoholSavedMoney),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _moneyColor(alcoholSavedMoney),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AI 추천 카드
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI 맞춤형 건강 물품 추천',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('✔️ $recommendation'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/entry');
              break;
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
}


/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  int smokingSavedMoney = 0;
  int alcoholSavedMoney = 0;
  String recommendation = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavingData();
  }

  Future<void> _fetchSavingData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    if (token.isEmpty) {
      print('❌ 액세스 토큰 없음');
      setState(() => isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://localhost:8080/v1/members/me/savings'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        // ✅ 수정된 부분: UTF-8로 명시적으로 디코딩
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));

        setState(() {
          smokingSavedMoney = decoded['smokingSavedMoney'] ?? 0;
          alcoholSavedMoney = decoded['alcoholSavedMoney'] ?? 0;
          recommendation = decoded['healthItemsRecommend'] ?? '';
          isLoading = false;
        });
      } else {
        print('❌ API 호출 실패: ${res.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ 네트워크 예외 발생: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSaved = smokingSavedMoney + alcoholSavedMoney;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('절약 금액'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '절약한 금액으로 건강에 투자해보세요 💪',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  /// 절약 금액 카드
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('총 절약 금액',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('₩${totalSaved.toString()}',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('흡연'),
                                  const SizedBox(height: 4),
                                  Text('₩${smokingSavedMoney.toString()}',
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('음주'),
                                  const SizedBox(height: 4),
                                  Text('₩${alcoholSavedMoney.toString()}',
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// AI 추천 카드
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI 맞춤형 건강 물품 추천',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text('✔️ $recommendation'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

      /// 바텀 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/entry');
              break;
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
}
*/