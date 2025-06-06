import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_service.dart'; // ✅ 헬스 서비스 import
import '../config.dart';

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
        'deviceInfo': {'udid': udid, 'os': os},
      };

      final signinRes = await http.post(
        Uri.parse('${Config.baseUrl}/signin/oauth2/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginPayload),
      );

      if (signinRes.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // ✅ 서버 응답에서 JWT accessToken 파싱
        final decoded = jsonDecode(signinRes.body);
        final serverAccessToken = decoded['tokenResponse']['accessToken'];

        if (serverAccessToken == null || !serverAccessToken.contains('.')) {
          return;
        }

        // ✅ 서버 accessToken 저장 (카카오 accessToken 아님!)
        await prefs.setString('accessToken', serverAccessToken);

        // ✅ HealthKit 권한 요청
        final healthService = HealthService();

        await healthService.requestAuthorization();
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
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카카오 로그인에 실패했습니다.')));
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
