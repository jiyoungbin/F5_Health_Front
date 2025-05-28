import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/report_screen.dart';
import 'screens/setting_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/saving_screen.dart';
import 'screens/badge_screen.dart';
import 'services/notification_service.dart';

import 'models/eaten_food.dart';
import 'models/daily_record.dart'; // DailyRecord 모델 import
import 'package:hive_flutter/hive_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 어댑터 등록
  Hive.registerAdapter(EatenFoodAdapter());
  Hive.registerAdapter(DailyRecordAdapter());

  // MealFoods 데이터를 위한 박스
  await Hive.openBox<List<EatenFood>>('mealFoodsBox');

  // DailyRecord(음수량/흡연량) 데이터를 위한 박스
  await Hive.openBox<DailyRecord>('dailyData');

  // 알림 서비스 초기화
  await initNotification();

  // SharedPreferences에서 알림 시간 불러오기 및 예약
  final prefs = await SharedPreferences.getInstance();
  final timeStr = prefs.getString('alarm_time');
  if (timeStr != null) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final alarmTime = TimeOfDay(hour: hour, minute: minute);
        await scheduleDailyAlarm(alarmTime);
      }
    }
  }

  // 로그인 여부 확인
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Kakao SDK 초기화
  KakaoSdk.init(nativeAppKey: '4926d9b83bfc6c66402f3d42d84b7f52');

  // 앱 실행
  runApp(MyApp(initialRoute: isLoggedIn ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'F5 Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/entry': (_) => EntryScreen(),
        '/savings': (_) => const SavingScreen(),
        '/report': (_) => const ReportScreen(),
        '/badge': (_) => const BadgeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/survey': (_) => const SurveyScreen(),
      },
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:f5_health/app_data.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/report_screen.dart';
import 'screens/setting_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/saving_screen.dart';
import 'services/notification_service.dart';
import 'screens/badge_screen.dart';

import 'models/eaten_food.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/daily_record.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(EatenFoodAdapter());

  // ✅ 여기서 한 번만 열어두기
  await Hive.openBox<List<EatenFood>>('mealFoodsBox');

  // ✅ 알림 초기화
  await initNotification();

  // ✅ SharedPreferences에서 알림 시간 불러오기
  final prefs = await SharedPreferences.getInstance();
  final timeStr = prefs.getString('alarm_time');
  if (timeStr != null) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        AppData.alarmTime = TimeOfDay(hour: hour, minute: minute);
        await scheduleDailyAlarm(AppData.alarmTime!);
      }
    }
  }

  // ✅ 로그인 여부 확인
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // ✅ Kakao SDK 초기화
  KakaoSdk.init(nativeAppKey: '4926d9b83bfc6c66402f3d42d84b7f52');

  // ✅ 앱 실행
  runApp(MyApp(initialRoute: isLoggedIn ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'F5 Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/entry': (_) => EntryScreen(),
        '/savings': (_) => const SavingScreen(),
        '/report': (_) => const ReportScreen(),
        '/badge': (_) => const BadgeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/survey': (_) => const SurveyScreen(),
      },
    );
  }
}
*/
