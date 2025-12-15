// lib/data/models/file_model.dart
import 'package:hive/hive.dart';

part 'file_model.g.dart';

@HiveType(typeId: 0)
class FileModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String originalPath;

  @HiveField(3)
  final String encryptedPath;

  @HiveField(4)
  final String fileType;

  @HiveField(5)
  final int fileSize;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String? thumbnailPath;

  FileModel({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.encryptedPath,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    this.thumbnailPath,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get category {
    if (fileType.startsWith('image/')) return 'Images';
    if (fileType.startsWith('video/')) return 'Videos';
    if (fileType.startsWith('audio/')) return 'Audio';
    if (fileType.contains('pdf') ||
        fileType.contains('document') ||
        fileType.contains('text')) {
      return 'Documents';
    }
    return 'Others';
  }
}
