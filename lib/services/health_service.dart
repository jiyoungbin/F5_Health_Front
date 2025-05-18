import 'package:health/health.dart';
import '../models/workout.dart';
import 'dart:math';

class HealthService {
  final Health _health = Health();

  Future<bool> requestAuthorization() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.EXERCISE_TIME,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.WORKOUT,
    ];
    return await _health.requestAuthorization(types);
  }

  Future<int> fetchTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: startOfDay,
      endTime: now,
    );
    int total = 0;
    for (final d in data) {
      if (d.value is NumericHealthValue) {
        total += (d.value as NumericHealthValue).numericValue.round();
      }
    }
    return total;
  }

  Future<List<Workout>> fetchTodayWorkouts() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final workouts = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WORKOUT],
      startTime: start,
      endTime: now,
    );
    final calories = await _health.getHealthDataFromTypes(
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: start,
      endTime: now,
    );
    List<Workout> result = [];
    for (final w in workouts) {
      if (w.type == HealthDataType.WORKOUT) {
        double kcal = 0;
        for (final c in calories) {
          if (c.dateFrom.isBefore(w.dateTo) && c.dateTo.isAfter(w.dateFrom)) {
            if (c.value is NumericHealthValue) {
              kcal += (c.value as NumericHealthValue).numericValue;
            }
          }
        }
        final value = w.value;
        String type = 'UNKNOWN';
        if (value is WorkoutHealthValue) {
          type = value.workoutActivityType
              .toString()
              .replaceAll('HealthWorkoutActivityType.', '')
              .toUpperCase();
        }
        result.add(Workout(
          exerciseType: type,
          start: w.dateFrom,
          end: w.dateTo,
          calories: kcal,
        ));
      }
    }
    return result;
  }

  Future<Map<String, int>> fetchSleepData() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final data = await _health.getHealthDataFromTypes(
      types: [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
      ],
      startTime: start,
      endTime: now,
    );
    final Map<String, int> result = {
      'inBed': 0,
      'awake': 0,
      'asleepCore': 0,
      'asleepDeep': 0,
      'asleepREM': 0,
    };
    for (final d in data) {
      final duration = d.dateTo.difference(d.dateFrom).inMinutes;
      switch (d.type) {
        case HealthDataType.SLEEP_IN_BED:
          result['inBed'] = result['inBed']! + duration;
          break;
        case HealthDataType.SLEEP_AWAKE:
          result['awake'] = result['awake']! + duration;
          break;
        case HealthDataType.SLEEP_LIGHT:
          result['asleepCore'] = result['asleepCore']! + duration;
          break;
        case HealthDataType.SLEEP_DEEP:
          result['asleepDeep'] = result['asleepDeep']! + duration;
          break;
        case HealthDataType.SLEEP_REM:
          result['asleepREM'] = result['asleepREM']! + duration;
          break;
        default:
          break;
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> fetchVitalSigns() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final result = {
      'heartRate': 1,
      'oxygenSaturation': 1,
      'bodyTemperature': 1.0,
    };
    final heart = await _health.getHealthDataFromTypes(
      types: [HealthDataType.HEART_RATE],
      startTime: start,
      endTime: now,
    );
    if (heart.isNotEmpty && heart.first.value is NumericHealthValue) {
      result['heartRate'] =
          (heart.first.value as NumericHealthValue).numericValue.round();
    }
    final oxygen = await _health.getHealthDataFromTypes(
      types: [HealthDataType.BLOOD_OXYGEN],
      startTime: start,
      endTime: now,
    );
    if (oxygen.isNotEmpty && oxygen.first.value is NumericHealthValue) {
      result['oxygenSaturation'] =
          (oxygen.first.value as NumericHealthValue).numericValue.round();
    }
    final temp = await _health.getHealthDataFromTypes(
      types: [HealthDataType.BODY_TEMPERATURE],
      startTime: start,
      endTime: now,
    );
    if (temp.isNotEmpty && temp.first.value is NumericHealthValue) {
      result['bodyTemperature'] =
          (temp.first.value as NumericHealthValue).numericValue.toDouble();
    }
    return result;
  }

  Future<Map<String, dynamic>> getTodayHealthData() async {
    final stepCount = await fetchTodaySteps();
    final workouts = await fetchTodayWorkouts();
    final vital = await fetchVitalSigns();
    final sleep = await fetchSleepData();

    final exerciseList = workouts.map((w) => w.toJson()).toList();
    final totalCalories =
        workouts.fold(0.0, (sum, w) => sum + (w.calories ?? 0.0));
    final exerciseTime = max(1, workouts.length * 10); // 최소 1분
    final distanceWalkingRunning = 1.0; // 기본값 (추후 측정 가능)

    return {
      'stepCount': max(1, stepCount),
      'exercise': exerciseList,
      'vital': vital,
      'sleep': sleep,
      'activity': {
        'stepCount': max(1, stepCount),
        'activeEnergyBurned': max(1.0, totalCalories),
        'appleExerciseTime': exerciseTime,
        'distanceWalkingRunning': distanceWalkingRunning,
      },
    };
  }
}
/* 일단 가려둠
  Future<Map<String, dynamic>> getTodayHealthData() async {
    final stepCount = await fetchTodaySteps();
    final workouts = await fetchTodayWorkouts();
    final vital = await fetchVitalSigns();
    final sleep = await fetchSleepData();

    return {
      'stepCount': stepCount,
      'exercise': workouts.map((w) => w.toJson()).toList(),
      'vital': vital,
      'sleep': sleep,
    };
  }
}
*/


/*
import 'package:health/health.dart';
import '../models/workout.dart';

class HealthService {
  final Health _health = Health();

  Future<bool> requestAuthorization() async {
    final types = [
      // 활동
      HealthDataType.STEPS, // 걸음 수
      HealthDataType.DISTANCE_WALKING_RUNNING, //걷거나 달려서 이동한 거리
      HealthDataType.ACTIVE_ENERGY_BURNED, // 소모한 활성 에너지 (kcal)
      HealthDataType.EXERCISE_TIME, // 운동 시간(분)
      // HealthDataType.MOVE_TIME, // 전신 움직임 소요 시간(분)

      // 수면
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,

      // 활력징후
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_OXYGEN, // 산소 포화도
      HealthDataType.BODY_TEMPERATURE,

      // 운동 유형
      HealthDataType.WORKOUT,
    ];

    return await _health.requestAuthorization(types);
  }

  String fallbackWorkoutType(HealthDataPoint point) {
    final unit = point.unit?.toString().toLowerCase() ?? '';
    final source = point.sourceName?.toLowerCase() ?? '';

    if (source.contains('run') || unit.contains('mile')) return 'RUNNING';
    if (source.contains('swim')) return 'SWIMMING';
    if (source.contains('walk')) return 'WALKING';
    if (source.contains('cycle')) return 'CYCLING';

    return 'UNKNOWN';
  }

  String extractWorkoutType(HealthDataPoint point) {
    final value = point.value;
    if (value is WorkoutHealthValue) {
      final raw = value.workoutActivityType.toString();
      print('🔍 raw workoutActivityType: $raw');

      final cleaned =
          raw.toUpperCase().replaceAll('HEALTHWORKOUTACTIVITYTYPE.', '');

      print('✅ cleaned type: $cleaned');
      return cleaned;
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
          exerciseType: workoutType,
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

    final stepData = await _health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: startOfDay,
      endTime: now,
    );

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
*/