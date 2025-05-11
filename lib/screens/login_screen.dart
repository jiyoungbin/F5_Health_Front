import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_service.dart'; // ✅ 헬스 서비스 import

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      OAuthToken token;

      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      if (!context.mounted) return;

      final accessToken = token.accessToken;
      debugPrint('✅ 카카오 로그인 성공! accessToken: $accessToken');

      final deviceInfoPlugin = DeviceInfoPlugin();
      String udid = 'unknown';
      String os = 'unknown';

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        udid = info.id;
        os = 'ANDROID';
      } else {
        final info = await deviceInfoPlugin.iosInfo;
        udid = info.identifierForVendor ?? 'unknown';
        os = 'iOS';
      }

      final loginPayload = {
        'accessToken': accessToken,
        'deviceInfo': {
          'udid': udid,
          'os': os,
        }
      };

      final signinRes = await http.post(
        Uri.parse('http://localhost:8080/signin/oauth2/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginPayload),
      );

      debugPrint('📡 signin 응답 코드: ${signinRes.statusCode}');
      debugPrint('📦 signin 응답 바디: ${signinRes.body}');

      if (signinRes.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // ✅ HealthKit 권한 요청
        final healthService = HealthService();
        final authorized = await healthService.requestAuthorization();
        if (authorized) {
          debugPrint('✅ HealthKit 권한 허용됨');
        } else {
          debugPrint('❌ HealthKit 권한 거부됨');
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else if (signinRes.statusCode == 302) {
        Navigator.pushReplacementNamed(
          context,
          '/survey',
          arguments: loginPayload,
        );
      } else {
        throw Exception('로그인 실패: ${signinRes.statusCode}');
      }
    } catch (error) {
      debugPrint('❌ 로그인 또는 회원가입 실패: $error');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'F5 Health',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: IconButton(
                onPressed: () => _loginWithKakao(context),
                icon: Image.asset('assets/kakao_logo.png'),
                iconSize: 48,
                splashRadius: 28,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                '앱 이용 약관 및 개인정보 처리방침에 동의합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF828282), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/*
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      OAuthToken token;

      // 카카오톡 앱 설치 여부에 따라 로그인 방식 선택
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      if (!context.mounted) return;

      final accessToken = token.accessToken;
      debugPrint('✅ 카카오 로그인 성공! accessToken: $accessToken');

      // 디바이스 정보 수집
      final deviceInfoPlugin = DeviceInfoPlugin();
      String udid = 'unknown';
      String os = 'unknown';

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        udid = info.id;
        os = 'ANDROID';
      } else {
        final info = await deviceInfoPlugin.iosInfo;
        udid = info.identifierForVendor ?? 'unknown';
        os = 'iOS';
      }

      final loginPayload = {
        'accessToken': accessToken,
        'deviceInfo': {
          'udid': udid,
          'os': os,
        }
      };

      // 로그인 API 호출
      final signinRes = await http.post(
        Uri.parse(
            'http://localhost:8080/signin/oauth2/kakao'), // 실제 서버 주소로 변경 필요
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginPayload),
      );

      debugPrint('📡 signin 응답 코드: ${signinRes.statusCode}');
      debugPrint('📦 signin 응답 바디: ${signinRes.body}');

      if (signinRes.statusCode == 200) {
        // 로그인 성공
        Navigator.pushReplacementNamed(context, '/home');
      } else if (signinRes.statusCode == 302) {
        // 신규 회원 → 설문 데이터와 함께 회원가입
        final signupPayload = {
          'loginRequest': loginPayload,
          'memberCheckUp': {
            'birthDate': '2000-04-18',
            'gender': 'MALE',
            'height': 173,
            'weight': 65,
            'bloodType': 'AB',
            'daySmokingAvg': 8,
            'weekAlcoholAvg': 6,
            'weekExerciseFreq': 3
          }
        };

        final signupRes = await http.post(
          Uri.parse(
              'http://localhost:8080/signup/oauth2/kakao'), // 실제 서버 주소로 변경 필요
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(signupPayload),
        );

        debugPrint('📡 signup 응답 코드: ${signupRes.statusCode}');
        debugPrint('📦 signup 응답 바디: ${signupRes.body}');

        if (signupRes.statusCode == 201) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          throw Exception('회원가입 실패');
        }
      } else {
        throw Exception('로그인 실패: ${signinRes.statusCode}');
      }
    } catch (error) {
      debugPrint('❌ 로그인 또는 회원가입 실패: $error');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'F5 Health',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: IconButton(
                onPressed: () => _loginWithKakao(context),
                icon: Image.asset('assets/kakao_logo.png'),
                iconSize: 48,
                splashRadius: 28,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                '앱 이용 약관 및 개인정보 처리방침에 동의합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF828282),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
