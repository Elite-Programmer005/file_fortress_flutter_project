// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileEntityAdapter extends TypeAdapter<FileEntity> {
  @override
  final int typeId = 0;

  @override
  FileEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileEntity(
      id: fields[0] as String,
      originalName: fields[1] as String,
      encryptedPath: fields[2] as String,
      fileType: fields[3] as String,
      creationDate: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FileEntity obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalName)
      ..writeByte(2)
      ..write(obj.encryptedPath)
      ..writeByte(3)
      ..write(obj.fileType)
      ..writeByte(4)
      ..write(obj.creationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
