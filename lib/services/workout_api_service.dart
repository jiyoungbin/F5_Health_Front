import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ✅ 필요
import '../models/workout.dart';

class WorkoutApiService {
  final String baseUrl;

  WorkoutApiService({required this.baseUrl});

  Future<void> sendWorkouts(List<Workout> workouts, int stepCount) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken'); // ✅ 저장된 토큰 사용

    if (accessToken == null) {
      print('❌ 저장된 액세스 토큰이 없습니다.');
      return;
    }

    final url = Uri.parse('$baseUrl/api/feedback/generate');

    final body = jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'stepCount': stepCount,
      'workouts': workouts.map((w) {
        final json = w.toJson();

        final durationSeconds = w.end.difference(w.start).inSeconds;
        json['duration'] = durationSeconds;

        json.remove('startTime');
        json.remove('endTime');

        return json;
      }).toList(),
    });

    // ✅ 디버깅 로그 추가
    print('🧪 accessToken: $accessToken');
    print('📡 전송 URL: $url');
    print('📡 전송 헤더: Authorization: Bearer $accessToken');
    print('📡 전송 바디: $body');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // ✅ 여기 필수!
      },
      body: body,
    );

    if (response.statusCode == 200) {
      print('✅ 운동 기록 전송 성공');
    } else {
      print('❌ 운동 기록 전송 실패: ${response.statusCode}');
      print('🧾 서버 응답: ${response.body}');
    }
  }
}