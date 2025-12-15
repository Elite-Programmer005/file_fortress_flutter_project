import 'dart:io';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart'; 
import 'package:uuid/uuid.dart';

import 'tabs/all_files_tab.dart';
import 'tabs/audio_tab.dart';
import 'tabs/documents_tab.dart';
import 'tabs/images_tab.dart';
import 'tabs/videos_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AESEncryptionService _encryptionService = AESEncryptionService();
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final pickedFile = File(result.files.single.path!);
      final originalName = path.basename(pickedFile.path);
      final fileType = lookupMimeType(pickedFile.path) ?? 'application/octet-stream';

      // 1. Read file bytes
      final fileBytes = await pickedFile.readAsBytes();

      // 2. Encrypt file bytes
      final encryptedBytes = await _encryptionService.encryptFile(fileBytes);

      // 3. Save encrypted file to app's private directory
      final appDir = await getApplicationDocumentsDirectory();
      final encryptedFileId = const Uuid().v4();
      final encryptedFileName = '$encryptedFileId.fflock';
      final encryptedFilePath = path.join(appDir.path, encryptedFileName);
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      // 4. Create metadata and save to Hive
      final fileEntity = FileEntity(
        id: encryptedFileId,
        originalName: originalName,
        encryptedPath: encryptedFilePath,
        fileType: fileType,
        creationDate: DateTime.now().millisecondsSinceEpoch,
      );

      final box = Hive.box<FileEntity>('files');
      await box.put(fileEntity.id, fileEntity);

      // 5. Delete original file
      await pickedFile.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File securely imported!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing file: \$e')),
      );
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FileFortress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, Routes.settings);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.all_inbox), text: 'All'),
            Tab(icon: Icon(Icons.image), text: 'Images'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Audio'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: const [
              AllFilesTab(),
              ImagesTab(),
              VideosTab(),
              AudioTab(),
              DocumentsTab(),
            ],
          ),
          if (_isImporting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Importing and encrypting...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isImporting ? null : _importFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
