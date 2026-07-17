// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentNotificationAdapter extends TypeAdapter<StudentNotification> {
  @override
  final int typeId = 3;

  @override
  StudentNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentNotification(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      timestamp: fields[3] as DateTime,
      isRead: fields[4] as bool,
      type: fields[5] as String,
      subject: fields[6] as String?,
      status: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentNotification obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isRead)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.subject)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
