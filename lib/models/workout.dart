class Workout {
  final String type;
  final DateTime start;
  final DateTime end;
  final double calories;

  Workout({
    required this.type,
    required this.start,
    required this.end,
    required this.calories,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'calories': calories,
    };
  }
}
