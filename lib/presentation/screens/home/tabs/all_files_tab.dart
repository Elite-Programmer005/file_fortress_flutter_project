import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AllFilesTab extends StatelessWidget {
  const AllFilesTab({super.key});

  IconData _getIconForFileType(String fileType) {
    if (fileType.startsWith('image')) {
      return Icons.image;
    } else if (fileType.startsWith('video')) {
      return Icons.video_library;
    } else if (fileType.startsWith('audio')) {
      return Icons.audiotrack;
    } else if (fileType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else {
      return Icons.insert_drive_file; // Default icon for other documents
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FileEntity>('files').listenable(),
      builder: (context, Box<FileEntity> box, _) {
        final files = box.values.toList().cast<FileEntity>();

        if (files.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Your vault is empty',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first file',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(_getIconForFileType(file.fileType), size: 40),
                title: Text(
                  file.originalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  // Formatting the date to be more readable
                  '${file.creationDateAsDateTime.toLocal()} '.split(' ')[0],
                ),
                onTap: () {
                  // TODO: Implement secure file preview
                },
              ),
            );
          },
        );
      },
    );
  }
}
