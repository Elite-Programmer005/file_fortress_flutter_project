// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileModelAdapter extends TypeAdapter<FileModel> {
  @override
  final int typeId = 0;

  @override
  FileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileModel(
      id: fields[0] as int,
      name: fields[1] as String,
      originalPath: fields[2] as String,
      encryptedPath: fields[3] as String,
      fileType: fields[4] as String,
      fileSize: fields[5] as int,
      createdAt: fields[6] as DateTime,
      thumbnailPath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.originalPath)
      ..writeByte(3)
      ..write(obj.encryptedPath)
      ..writeByte(4)
      ..write(obj.fileType)
      ..writeByte(5)
      ..write(obj.fileSize)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
