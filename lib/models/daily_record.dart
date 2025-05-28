import 'package:hive/hive.dart';

part 'daily_record.g.dart';

@HiveType(typeId: 2)
class DailyRecord extends HiveObject {
  @HiveField(0)
  int waterCount;

  @HiveField(1)
  int smokeCount;

  DailyRecord({
    required this.waterCount,
    required this.smokeCount,
  });
}
