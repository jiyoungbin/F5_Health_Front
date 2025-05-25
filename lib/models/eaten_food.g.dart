// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eaten_food.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EatenFoodAdapter extends TypeAdapter<EatenFood> {
  @override
  final int typeId = 1;

  @override
  EatenFood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EatenFood(
      foodCode: fields[0] as String,
      foodName: fields[1] as String,
      kcal: fields[2] as double,
      count: fields[3] as double,
      carbohydrate: fields[4] as double,
      protein: fields[5] as double,
      fat: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, EatenFood obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.foodCode)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.kcal)
      ..writeByte(3)
      ..write(obj.count)
      ..writeByte(4)
      ..write(obj.carbohydrate)
      ..writeByte(5)
      ..write(obj.protein)
      ..writeByte(6)
      ..write(obj.fat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EatenFoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
