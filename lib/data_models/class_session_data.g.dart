// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_session_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionStatsAdapter extends TypeAdapter<SessionStats> {
  @override
  final int typeId = 2;

  @override
  SessionStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionStats()
      ..classSessionId = fields[0] as int
      ..presentCount = fields[1] as int
      ..absentCount = fields[2] as int
      ..subject = fields[3] as String
      ..date = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, SessionStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.classSessionId)
      ..writeByte(1)
      ..write(obj.presentCount)
      ..writeByte(2)
      ..write(obj.absentCount)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
