
import 'package:hive/hive.dart';

part 'file_entity.g.dart';

@HiveType(typeId: 0)
class FileEntity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalName;

  @HiveField(2)
  final String encryptedPath;

  @HiveField(3)
  final String fileType;

  @HiveField(4)
  final int creationDate; // Stored as milliseconds since epoch

  FileEntity({
    required this.id,
    required this.originalName,
    required this.encryptedPath,
    required this.fileType,
    required this.creationDate,
  });

  DateTime get creationDateAsDateTime => DateTime.fromMillisecondsSinceEpoch(creationDate);
}
