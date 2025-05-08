// lib/app_data.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppData {
  static int waterCount = 0;
  static int smokeCount = 0;

  static TimeOfDay? alarmTime; // 전역 알람 시간

  static Map<String, String> meals = {
    '아침': '',
    '점심': '',
    '저녁': '',
    '간식': '',
  };

  static DateTime lastReset = DateTime.now();

  static void maybeResetDailyData() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final last = DateFormat('yyyy-MM-dd').format(lastReset);

    if (today != last) {
      waterCount = 0;
      smokeCount = 0;
      meals = {
        '아침': '',
        '점심': '',
        '저녁': '',
        '간식': '',
      };
      lastReset = DateTime.now();
    }
  }
}
