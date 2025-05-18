import 'package:hive/hive.dart';

part 'health_record.g.dart';

@HiveType(typeId: 0)
class HealthDailyRecord {
  @HiveField(0)
  final int waterIntake; // ml 단위

  @HiveField(1)
  final int alcoholAmount;

  @HiveField(2)
  final int alcoholSpentMoney;

  @HiveField(3)
  final int smokingAmount;

  @HiveField(4)
  final int stepCount;

  @HiveField(5)
  final double distanceWalkingRunning;

  @HiveField(6)
  final int activeEnergyBurned;

  @HiveField(7)
  final int appleExerciseTime;

  @HiveField(8)
  final int heartRate;

  @HiveField(9)
  final int totalCaloriesBurned;

  @HiveField(10)
  final int sleepHours;

  @HiveField(11)
  final List<String> workoutTypes;

  @HiveField(12)
  final List<MealRecord> meals;

  HealthDailyRecord({
    required this.waterIntake,
    required this.alcoholAmount,
    required this.alcoholSpentMoney,
    required this.smokingAmount,
    required this.stepCount,
    required this.distanceWalkingRunning,
    required this.activeEnergyBurned,
    required this.appleExerciseTime,
    required this.heartRate,
    required this.totalCaloriesBurned,
    required this.sleepHours,
    required this.workoutTypes,
    required this.meals,
  });
}

@HiveType(typeId: 1)
class MealRecord {
  @HiveField(0)
  final String mealType;

  @HiveField(1)
  final DateTime mealTime;

  @HiveField(2)
  final List<FoodEntry> foods;

  MealRecord({
    required this.mealType,
    required this.mealTime,
    required this.foods,
  });
}

@HiveType(typeId: 2)
class FoodEntry {
  @HiveField(0)
  final String foodCode;

  @HiveField(1)
  final int count;

  FoodEntry({
    required this.foodCode,
    required this.count,
  });
}
