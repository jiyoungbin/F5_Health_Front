import 'package:hive/hive.dart';

part 'eaten_food.g.dart';

@HiveType(typeId: 1)
class EatenFood extends HiveObject {
  @HiveField(0)
  String foodCode;

  @HiveField(1)
  String foodName;

  @HiveField(2)
  double kcal; // 1인분 kcal

  @HiveField(3)
  double count; // 인분 수

  @HiveField(4)
  double carbohydrate; // 1인분당 탄수화물(g)

  @HiveField(5)
  double protein; // 1인분당 단백질(g)

  @HiveField(6)
  double fat; // 1인분당 지방(g)

  EatenFood({
    required this.foodCode,
    required this.foodName,
    required this.kcal,
    required this.count,
    required this.carbohydrate,
    required this.protein,
    required this.fat,
  });
}
