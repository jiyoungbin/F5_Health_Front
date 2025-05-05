// lib/main.dart

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'screens/login_screen.dart'; // 방금 만든 로그인 화면
import 'screens/home_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/report_screen.dart';
import 'screens/setting_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ① 카카오 SDK 초기화 (네이티브 앱 키)
  KakaoSdk.init(nativeAppKey: '4926d9b83bfc6c66402f3d42d84b7f52');

  runApp(const MyApp()); // ← 이게 없어서 앱이 시작 안되고 흰 화면만 나오는 것임
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F5 Health',
      debugShowCheckedModeBanner: false, // 우측 상단 DEBUG 라벨 숨기기
      theme: ThemeData(
        // 필요한 테마 커스터마이징만 남기고 나머지 기본값 사용
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // ② 초기 진입 화면을 로그인으로 설정
      // initialRoute: '/login',
      initialRoute: '/home', // 홈 화면 테스트 끝나고 위의 주석으로 교체
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(), // HomeScreen은 별도 구현
        '/entry': (_) => EntryScreen(),
        '/savings': (_) => Scaffold(body: Center(child: Text('절약 금액 화면'))),
        '/report': (_) => const ReportScreen(),
        '/badge': (_) => Scaffold(body: Center(child: Text('배지 화면'))),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
