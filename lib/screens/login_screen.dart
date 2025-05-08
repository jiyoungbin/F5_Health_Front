// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
// 카카오 SDK 패키지 임포트
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
// http 패키지 임포트 (추가)
import 'package:http/http.dart' as http;

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  /// 카카오 로그인 함수
  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      OAuthToken token;
      // 1) 카카오톡 앱이 설치되어 있으면 앱으로, 없으면 카카오계정 웹뷰로 로그인
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      if (!context.mounted) return;

      // 2) 로그인 성공 시 발급된 accessToken
      final String accessToken = token.accessToken;
      debugPrint('✅ 카카오 로그인 성공! accessToken: $accessToken');

      // 3) 백엔드에 토큰 전송 (URL 수정)
      final response = await http.post(
        Uri.parse('http://localhost:8080/signup/oauth2/kakao'), // 변경된 주소
        body: {'token': accessToken},
      );
      debugPrint('📡 백엔드 응답 코드: ${response.statusCode}');

      // 4) 홈 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      // 로그인 실패 처리
      debugPrint('❌ 카카오 로그인 실패: $error');

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

/*
// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
// 카카오 SDK 패키지 임포트
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  /// 카카오 SDK 초기화는 앱 시작 직후 main()에서 해주세요.
  /// 예시:
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   KakaoSdk.init(nativeAppKey: 'YOUR_NATIVE_APP_KEY');
  ///   runApp(const MyApp());
  /// }

  /// 카카오 로그인 함수
  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      OAuthToken token;
      // 1) 카카오톡 앱이 설치되어 있으면 앱으로, 없으면 카카오계정 웹뷰로 로그인
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      if (!context.mounted) return;

      // 2) 로그인 성공 시 발급된 accessToken //
      final String accessToken = token.accessToken;
      debugPrint('✅ 카카오 로그인 성공! accessToken: $accessToken');

      //3) (선택) 백엔드에 토큰 전송
      // await http.post(
      // Uri.parse('https://your.api/login/kakao'),
      // body: {'token': accessToken},
      // );

      // 4) 홈 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      // 로그인 실패 처리
      debugPrint('❌ 카카오 로그인 실패: $error');

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
        // Stack을 쓰지 않고 Column으로 간결하게 레이아웃
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 상단 로고/타이틀 영역
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

            // 카카오 로그인 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: IconButton(
                // 눌렀을 때 로그인 함수 호출
                onPressed: () => _loginWithKakao(context),
                // 오로지 카카오 로고 PNG만
                icon: Image.asset('assets/kakao_logo.png'),
                // 아이콘 사이즈가 너무 작으면 키울 수 있어요
                iconSize: 48,
                splashRadius: 28, // 터치 시 물결 효과 반경
              ),
            ),

            // 약관 동의 문구
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
