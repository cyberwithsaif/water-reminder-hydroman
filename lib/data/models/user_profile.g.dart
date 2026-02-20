// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      gender: fields[0] as String,
      weightKg: fields[1] as double,
      dailyGoalMl: fields[2] as int,
      wakeTime: fields[3] as String,
      sleepTime: fields[4] as String,
      isOnboarded: fields[5] as bool,
      name: fields[6] as String,
      weightUnit: fields[7] as String,
      notificationsEnabled: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.gender)
      ..writeByte(1)
      ..write(obj.weightKg)
      ..writeByte(2)
      ..write(obj.dailyGoalMl)
      ..writeByte(3)
      ..write(obj.wakeTime)
      ..writeByte(4)
      ..write(obj.sleepTime)
      ..writeByte(5)
      ..write(obj.isOnboarded)
      ..writeByte(6)
      ..write(obj.name)
      ..writeByte(7)
      ..write(obj.weightUnit)
      ..writeByte(8)
      ..write(obj.notificationsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
