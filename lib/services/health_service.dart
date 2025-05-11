import 'package:health/health.dart';
import '../models/workout.dart';

class HealthService {
  final Health _health = Health();

  Future<bool> requestAuthorization() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.WORKOUT,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    return await _health.requestAuthorization(types);
  }

  // ✅ fallback 추정 (metadata도 없고, value 타입도 못 쓸 때)
  String fallbackWorkoutType(HealthDataPoint point) {
    final unit = point.unit?.toString().toLowerCase() ?? '';
    final source = point.sourceName?.toLowerCase() ?? '';

    if (source.contains('run') || unit.contains('mile')) return 'RUNNING';
    if (source.contains('swim')) return 'SWIMMING';
    if (source.contains('walk')) return 'WALKING';
    if (source.contains('cycle')) return 'CYCLING';

    return 'UNKNOWN';
  }

  // ✅ value에서 workout 타입 추출
  String extractWorkoutType(HealthDataPoint point) {
  final value = point.value;
  if (value is WorkoutHealthValue) {
    final type = value.workoutActivityType
        .toString()
        .toUpperCase()
        .replaceAll('HKWORKOUTACTIVITYTYPE.', ''); // ← 요거 중요
    return type;
  }
  return fallbackWorkoutType(point);
}
  Future<List<Workout>> fetchTodayWorkouts() async {
    print('🚀 fetchTodayWorkouts() 시작됨');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final workoutData = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WORKOUT],
      startTime: startOfDay,
      endTime: now,
    );

    final calorieData = await _health.getHealthDataFromTypes(
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: startOfDay,
      endTime: now,
    );

    print('📊 운동 데이터 수: ${workoutData.length}');
    for (final w in workoutData) {
      print(
          '👟 Workout:\n  - value: ${w.value}\n  - unit: ${w.unit}\n  - source: ${w.sourceName}\n  - start: ${w.dateFrom}\n  - end: ${w.dateTo}\n  - metadata: ${w.metadata}');
    }

    print('📊 칼로리 데이터 수: ${calorieData.length}');
    for (final c in calorieData) {
      print(
          '🔥 Calorie:\n  - value: ${c.value}\n  - unit: ${c.unit}\n  - start: ${c.dateFrom}\n  - end: ${c.dateTo}\n  - type: ${c.type}');
    }

    final workouts = <Workout>[];

    for (final w in workoutData) {
      if (w.type == HealthDataType.WORKOUT) {
        final matchedCalories = calorieData.where((c) =>
            c.dateFrom.isBefore(w.dateTo) &&
            c.dateTo.isAfter(w.dateFrom) &&
            (c.value is num || c.value is NumericHealthValue));

        print('⚖️ ${matchedCalories.length}개의 칼로리 데이터가 운동 시간과 겹칩니다.');

        double calories = 0;
        for (final c in matchedCalories) {
          if (c.value is NumericHealthValue) {
            calories += (c.value as NumericHealthValue).numericValue;
          } else if (c.value is num) {
            calories += (c.value as num).toDouble();
          }
        }

        final workoutType = extractWorkoutType(w);

        print(
            '🆕 Workout 객체 생성\n  - type: $workoutType\n  - calories: $calories');

        workouts.add(Workout(
          type: workoutType,
          start: w.dateFrom,
          end: w.dateTo,
          calories: calories > 0 ? calories : -1,
        ));
      }
    }

    return workouts;
  }

  Future<int> fetchTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    print('📅 HealthKit 조회 범위: $startOfDay ~ $now');

    final stepData = await _health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: startOfDay,
      endTime: now,
    );

    print('📦 가져온 원시 데이터 수: ${stepData.length}');

    int totalSteps = 0;

    for (final d in stepData) {
      if (d.type == HealthDataType.STEPS && d.value is NumericHealthValue) {
        final numeric = (d.value as NumericHealthValue).numericValue;
        print('✅ NumericHealthValue로부터 추출된 값: $numeric');
        totalSteps += numeric.round();
      } else {
        print('🚫 건너뜀 - valueType: ${d.value.runtimeType}');
      }
    }

    print('✅ 최종 계산된 totalSteps: $totalSteps');

    return totalSteps;
  }
}
