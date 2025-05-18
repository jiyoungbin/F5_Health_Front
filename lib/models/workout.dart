class Workout {
  final String exerciseType; // ✅ 변수명도 서버와 일치
  final DateTime start;
  final DateTime end;
  final double calories;

  Workout({
    required this.exerciseType,
    required this.start,
    required this.end,
    required this.calories,
  });

  Map<String, dynamic> toJson() {
    final durationSeconds = end.difference(start).inSeconds;
    return {
      'exerciseType': exerciseType,
      'exerciseDuration': durationSeconds,
      'exerciseCalories': calories.round(),
    };
  }
}
