import 'dart:io';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:file_fortress/presentation/providers/theme_provider.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

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
    // Request full access on startup to allow deleting any file type
    _checkAllFilesPermission();
  }

  Future<void> _checkAllFilesPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Text("Action Required"),
                ],
              ),
              content: const Text("To hide files and remove them from public storage, please allow 'All Files Access' in the next screen."),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Permission.manageExternalStorage.request();
                  },
                  child: const Text("Enable Full Security"),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleFileUpload(File file, String originalName, String? mime) async {
    setState(() => _isImporting = true);
    try {
      final fileType = mime ?? lookupMimeType(originalName) ?? 'application/octet-stream';
      final fileBytes = await file.readAsBytes();
      final encryptedBytes = await _encryptionService.encryptFile(fileBytes);

      final appDir = await getApplicationDocumentsDirectory();
      final encryptedFileId = const Uuid().v4();
      final encryptedFileName = '$encryptedFileId.fflock';
      final encryptedFilePath = path.join(appDir.path, encryptedFileName);
      
      await File(encryptedFilePath).writeAsBytes(encryptedBytes);

      final fileEntity = FileEntity(
        id: encryptedFileId,
        originalName: originalName,
        encryptedPath: encryptedFilePath,
        fileType: fileType,
        creationDate: DateTime.now().millisecondsSinceEpoch,
      );

      final box = Hive.box<FileEntity>('files');
      await box.put(fileEntity.id, fileEntity);
      
      // Try to delete original file (Requires Manage External Storage)
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint("Direct delete failed, file might be in a restricted folder: $e");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File moved to Vault and removed from public storage!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blueAccent,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _pickMedia(RequestType type) async {
    PhotoManager.setIgnorePermissionCheck(true);
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(maxAssets: 1, requestType: type),
    );
    if (assets != null && assets.isNotEmpty) {
      final file = await assets.first.file;
      if (file != null) {
        await _handleFileUpload(file, await assets.first.titleAsync, assets.first.mimeType);
        // This is the most important part for Media (Images, Videos, Audio)
        // It triggers the system prompt to remove the file from MediaStore/Public view
        await PhotoManager.editor.deleteWithIds([assets.first.id]);
      }
    }
  }

  Future<void> _pickAnyFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _handleFileUpload(file, result.files.single.name, null);
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 10, left: 10, right: 10),
          child: Wrap(
            children: [
              Center(
                child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Secure Move to Vault', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text('Images & Videos'),
                subtitle: const Text('Remove from gallery and move to vault'),
                onTap: () { Navigator.pop(context); _pickMedia(RequestType.common); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.audiotrack, color: Colors.white)),
                title: const Text('Audio / Music'),
                subtitle: const Text('Remove from music player and move to vault'),
                onTap: () { Navigator.pop(context); _pickMedia(RequestType.audio); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.insert_drive_file, color: Colors.white)),
                title: const Text('Documents & Others'),
                subtitle: const Text('Move PDF, Docs, Zip to private vault'),
                onTap: () { Navigator.pop(context); _pickAnyFile(); },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(Icons.shield_moon_outlined, color: Colors.blueAccent, size: 32),
        ),
        title: const Text('FileFortress', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.pushNamed(context, Routes.settings)),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'All'), Tab(text: 'Images'), Tab(text: 'Videos'), Tab(text: 'Audio'), Tab(text: 'Docs')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AllFilesTab(), ImagesTab(), VideosTab(), AudioTab(), DocumentsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isImporting ? null : _showAddOptions,
        label: _isImporting ? const Text('Moving to Vault...') : const Text('Add File'),
        icon: _isImporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
