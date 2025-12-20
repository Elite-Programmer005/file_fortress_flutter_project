import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'all_files_tab.dart';

class VideosTab extends StatelessWidget {
  const VideosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FileEntity>('files').listenable(),
      builder: (context, Box<FileEntity> box, _) {
        final files = box.values.where((file) => file.fileType.startsWith('video/')).toList().cast<FileEntity>();

        if (files.isEmpty) return const Center(child: Text('No videos in vault'));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 80),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: const Icon(Icons.video_library, color: Colors.redAccent, size: 30),
                title: Text(file.originalName, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('VIDEO', style: TextStyle(fontSize: 12)),
                onTap: () => const AllFilesTab().previewFile(context, file),
                onLongPress: () => const AllFilesTab().showFileOptions(context, file),
                trailing: const Icon(Icons.more_vert, size: 18),
              ),
            );
          },
        );
      },
    );
  }
}
