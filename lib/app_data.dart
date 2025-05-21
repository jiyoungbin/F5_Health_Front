import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppData {
  static int waterCount = 0;
  static int smokeCount = 0;
  static TimeOfDay? alarmTime;

  static Map<String, List<Map<String, dynamic>>> meals = {
    '아침': [],
    '점심': [],
    '저녁': [],
    '간식': [],
  };

  static DateTime lastReset = DateTime.now();

  static void maybeResetDailyData() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final last = DateFormat('yyyy-MM-dd').format(lastReset);

    if (today != last) {
      waterCount = 0;
      smokeCount = 0;
      meals = {
        '아침': [],
        '점심': [],
        '저녁': [],
        '간식': [],
      };
      lastReset = DateTime.now();
    }
  }

  static String getMealTypeEnum(String kr) {
    switch (kr) {
      case '아침':
        return 'BREAKFAST';
      case '점심':
        return 'LUNCH';
      case '저녁':
        return 'DINNER';
      case '간식':
        return 'DESSERT';
      default:
        return 'UNKNOWN';
    }
  }

  static List<Map<String, dynamic>> toMealRequestList() {
    final List<Map<String, dynamic>> result = [];
    meals.forEach((mealTypeKr, foodList) {
      if (foodList.isEmpty) return;

      result.add({
        'mealType': getMealTypeEnum(mealTypeKr),
        'mealTime': DateTime.now().toIso8601String(),
        'mealFoodRequestList': foodList
            .map((f) => {
                  'foodCode': f['foodCode'],
                  'count': (f['amount'] ?? 1).toDouble(),
                })
            .toList(),
      });
    });
    return result;
  }

  static List<String> extractFoodCodes() {
    return meals.values
        .expand((list) => list)
        .map((f) => f['foodCode'].toString())
        .toSet()
        .toList();
  }

  static List<int> getMealCounts() {
    return meals.values.map((list) => list.length).toList();
  }
}

/*
// ✅ AppData.dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppData {
  static int waterCount = 0;
  static int smokeCount = 0;
  static TimeOfDay? alarmTime;
  static Box? healthBox;

  static Map<String, List<Map<String, dynamic>>> meals = {
    '아침': [],
    '점심': [],
    '저녁': [],
    '간식': [],
  };

  static DateTime lastReset = DateTime.now();

  static void maybeResetDailyData() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final last = DateFormat('yyyy-MM-dd').format(lastReset);

    if (today != last) {
      waterCount = 0;
      smokeCount = 0;
      meals = {
        '아침': [],
        '점심': [],
        '저녁': [],
        '간식': [],
      };
      lastReset = DateTime.now();
    }
  }

  static String getMealTypeEnum(String kr) {
    switch (kr) {
      case '아침':
        return 'BREAKFAST';
      case '점심':
        return 'LUNCH';
      case '저녁':
        return 'DINNER';
      case '간식':
        return 'DESSERT';
      default:
        return 'UNKNOWN';
    }
  }

  static List<Map<String, dynamic>> toMealRequestList() {
    final List<Map<String, dynamic>> result = [];
    meals.forEach((mealTypeKr, foodList) {
      if (foodList.isEmpty) return;

      result.add({
        'mealType': getMealTypeEnum(mealTypeKr),
        'mealTime': DateTime.now().toIso8601String(),
        'mealFoodRequestList': foodList
            .map((f) => {
                  'foodCode': f['foodCode'],
                  'count': (f['amount'] ?? 1).toDouble(),
                })
            .toList(), // ✅ 올바른 필드명
      });
    });
    return result;
  }

  static List<String> extractFoodCodes() {
    return meals.values
        .expand((list) => list)
        .map((f) => f['foodCode'].toString())
        .toSet()
        .toList();
  }

  static List<int> getMealCounts() {
    return meals.values.map((list) => list.length).toList();
  }
}
*/
