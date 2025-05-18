// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthDailyRecordAdapter extends TypeAdapter<HealthDailyRecord> {
  @override
  final int typeId = 0;

  @override
  HealthDailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthDailyRecord(
      waterIntake: fields[0] as int,
      alcoholAmount: fields[1] as int,
      alcoholSpentMoney: fields[2] as int,
      smokingAmount: fields[3] as int,
      stepCount: fields[4] as int,
      distanceWalkingRunning: fields[5] as double,
      activeEnergyBurned: fields[6] as int,
      appleExerciseTime: fields[7] as int,
      heartRate: fields[8] as int,
      totalCaloriesBurned: fields[9] as int,
      sleepHours: fields[10] as int,
      workoutTypes: (fields[11] as List).cast<String>(),
      meals: (fields[12] as List).cast<MealRecord>(),
    );
  }

  @override
  void write(BinaryWriter writer, HealthDailyRecord obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.waterIntake)
      ..writeByte(1)
      ..write(obj.alcoholAmount)
      ..writeByte(2)
      ..write(obj.alcoholSpentMoney)
      ..writeByte(3)
      ..write(obj.smokingAmount)
      ..writeByte(4)
      ..write(obj.stepCount)
      ..writeByte(5)
      ..write(obj.distanceWalkingRunning)
      ..writeByte(6)
      ..write(obj.activeEnergyBurned)
      ..writeByte(7)
      ..write(obj.appleExerciseTime)
      ..writeByte(8)
      ..write(obj.heartRate)
      ..writeByte(9)
      ..write(obj.totalCaloriesBurned)
      ..writeByte(10)
      ..write(obj.sleepHours)
      ..writeByte(11)
      ..write(obj.workoutTypes)
      ..writeByte(12)
      ..write(obj.meals);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthDailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealRecordAdapter extends TypeAdapter<MealRecord> {
  @override
  final int typeId = 1;

  @override
  MealRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealRecord(
      mealType: fields[0] as String,
      mealTime: fields[1] as DateTime,
      foods: (fields[2] as List).cast<FoodEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, MealRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.mealType)
      ..writeByte(1)
      ..write(obj.mealTime)
      ..writeByte(2)
      ..write(obj.foods);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 2;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      foodCode: fields[0] as String,
      count: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.foodCode)
      ..writeByte(1)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
