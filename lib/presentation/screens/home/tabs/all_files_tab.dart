import 'dart:io';
import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class AllFilesTab extends StatelessWidget {
  const AllFilesTab({super.key});

  IconData _getIconForFileType(String fileType) {
    if (fileType.startsWith('image')) return Icons.image;
    if (fileType.startsWith('video')) return Icons.video_library;
    if (fileType.startsWith('audio')) return Icons.audiotrack;
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  void _showProgressDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 25),
              Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              const Text("Securely decrypting your file...", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> previewFile(BuildContext context, FileEntity fileEntity) async {
    final encryptionService = AESEncryptionService();
    try {
      _showProgressDialog(context, "Opening File");

      final encryptedFile = File(fileEntity.encryptedPath);
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = await encryptionService.decryptFile(encryptedBytes);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileEntity.originalName));
      await tempFile.writeAsBytes(decryptedBytes);

      if (context.mounted) Navigator.pop(context); 
      await OpenFile.open(tempFile.path);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _restoreFile(BuildContext context, FileEntity fileEntity) async {
    final encryptionService = AESEncryptionService();
    try {
      _showProgressDialog(context, "Restoring File");

      final encryptedFile = File(fileEntity.encryptedPath);
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = await encryptionService.decryptFile(encryptedBytes);

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final restoredPath = path.join(downloadsDir!.path, fileEntity.originalName);
      final restoredFile = File(restoredPath);
      await restoredFile.writeAsBytes(decryptedBytes);

      await Hive.box<FileEntity>('files').delete(fileEntity.id);
      await encryptedFile.delete();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('${fileEntity.originalName} restored to Downloads')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

  void showFileOptions(BuildContext context, FileEntity file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.remove_red_eye, color: Colors.white, size: 20)),
                title: const Text('Preview'),
                onTap: () { Navigator.pop(context); previewFile(context, file); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.restore, color: Colors.white, size: 20)),
                title: const Text('Restore to Gallery'),
                subtitle: const Text('Decrypt and move back to phone storage'),
                onTap: () { Navigator.pop(context); _restoreFile(context, file); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.delete_forever, color: Colors.white, size: 20)),
                title: const Text('Delete Permanently'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, FileEntity file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete File?"),
        content: const Text("This action cannot be undone. The file will be permanently removed from the vault."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Hive.box<FileEntity>('files').delete(file.id);
              File(file.encryptedPath).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted permanently')));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FileEntity>('files').listenable(),
      builder: (context, Box<FileEntity> box, _) {
        final files = box.values.toList().cast<FileEntity>();
        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No files in this vault', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

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
                leading: Icon(_getIconForFileType(file.fileType), color: Colors.blueAccent, size: 30),
                title: Text(file.originalName, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(file.fileType.split('/').last.toUpperCase(), style: const TextStyle(fontSize: 12)),
                onTap: () => previewFile(context, file),
                onLongPress: () => showFileOptions(context, file),
                trailing: const Icon(Icons.more_vert, size: 18),
              ),
            );
          },
        );
      },
    );
  }
}
