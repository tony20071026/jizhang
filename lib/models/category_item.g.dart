// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryItemAdapter extends TypeAdapter<CategoryItem> {
  @override
  final int typeId = 2;

  @override
  CategoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryItem(
      name: fields[0] as String,
      iconCodePoint: fields[1] as int,
      colorValue: fields[2] as int,
      isExpense: fields[3] as bool,
      sortIndex: fields[4] as int,
      builtIn: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.iconCodePoint)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.isExpense)
      ..writeByte(4)
      ..write(obj.sortIndex)
      ..writeByte(5)
      ..write(obj.builtIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
