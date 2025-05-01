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

      // 2) 로그인 성공 시 발급된 accessToken //
      final String accessToken = token.accessToken;
      debugPrint('✅ 카카오 로그인 성공! accessToken: $accessToken');

      // 3) (선택) 백엔드에 토큰 전송
      // await http.post(
      //   Uri.parse('https://your.api/login/kakao'),
      //   body: {'token': accessToken},
      // );

      // 4) 홈 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      // 로그인 실패 처리
      debugPrint('❌ 카카오 로그인 실패: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500), // 카카오 옐로우
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _loginWithKakao(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // assets/kakao_logo.png 파일을 준비해 두세요
                    Image.asset(
                      'assets/kakao_logo.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '카카오로 로그인',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
