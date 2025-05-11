import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout.dart';

class WorkoutApiService {
  final String baseUrl;

  WorkoutApiService({required this.baseUrl});

  Future<void> sendWorkouts(List<Workout> workouts) async {
    final url = Uri.parse('$baseUrl/api/workouts');

    final body = jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'workouts': workouts.map((w) => w.toJson()).toList(),
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('✅ 운동 기록 전송 성공');
    } else {
      print('❌ 운동 기록 전송 실패: ${response.statusCode}');
    }
  }
}
