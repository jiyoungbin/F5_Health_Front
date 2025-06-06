import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  String badgeLabel = '';
  String badgeKey = 'beginner';
  int totalScore = 0;
  List<Map<String, dynamic>> badgeModels = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBadgeData();
  }

  Future<void> fetchBadgeData() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      return;
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/v1/members/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      setState(() {
        badgeLabel = data['myBadge']['label'];
        badgeKey =
            data['myBadge']['value'].toString().toLowerCase(); // ✅ 여기 수정됨!
        totalScore = data['totalScore'];
        badgeModels = List<Map<String, dynamic>>.from(data['badgeModels']);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = 'assets/badges/badge_$badgeKey.png';

    return Scaffold(
      appBar: AppBar(title: const Text('등급 가이드')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          imagePath,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('누적 건강 점수: $totalScore'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      '등급별 목표',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: badgeModels.length,
                        itemBuilder: (context, index) {
                          final badge = badgeModels[index];
                          return BadgeRow(
                            grade: badge['label'],
                            hp: badge['cutOffScore'],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (i) {
          if (i == 4) return;
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

class BadgeRow extends StatelessWidget {
  final String grade;
  final int hp;

  const BadgeRow({super.key, required this.grade, required this.hp});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.star, color: Colors.amber),
      title: Text(grade),
      trailing: Text('$hp점 이상'),
    );
  }
}
