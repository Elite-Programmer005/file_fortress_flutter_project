import 'dart:io';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:file_fortress/presentation/providers/theme_provider.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:file_fortress/services/platform_file_service.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AESEncryptionService _encryptionService = AESEncryptionService();
  final PlatformFileService _platformFileService = PlatformFileService();
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
              content: const Text(
                  "To hide files and remove them from public storage, please allow 'All Files Access' in the next screen."),
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

  Future<void> _handleFileUpload(
    File file,
    String originalName,
    String? mime, {
    String? contentUri,
    bool requireDeletion = false,
  }) async {
    setState(() => _isImporting = true);
    try {
      final fileType =
          mime ?? lookupMimeType(originalName) ?? 'application/octet-stream';
      final fileBytes = await file.readAsBytes();
      final encryptedBytes = await _encryptionService.encryptFile(fileBytes);

      final appDir = await getApplicationDocumentsDirectory();
      final encryptedFileId = const Uuid().v4();
      final encryptedFileName = '$encryptedFileId.fflock';
      final encryptedFilePath = path.join(appDir.path, encryptedFileName);

      await File(encryptedFilePath).writeAsBytes(encryptedBytes);

      final deleted = await _deleteOriginalFile(file, contentUri: contentUri);

      if (requireDeletion && !deleted) {
        await File(encryptedFilePath).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to remove original file from public storage. File was not added to the vault.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final fileEntity = FileEntity(
        id: encryptedFileId,
        originalName: originalName,
        encryptedPath: encryptedFilePath,
        fileType: fileType,
        creationDate: DateTime.now().millisecondsSinceEpoch,
      );

      final box = Hive.box<FileEntity>('files');
      await box.put(fileEntity.id, fileEntity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted
                  ? 'File moved to Vault and removed from public storage!'
                  : 'File moved to Vault. Unable to remove original from storage.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: deleted ? Colors.blueAccent : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<bool> _deleteOriginalFile(File file, {String? contentUri}) async {
    if (!await file.exists()) return true;

    if (Platform.isAndroid) {
      final granted = await _ensureManageExternalStoragePermission();
      if (!granted) return false;
    }

    try {
      var deletedFromPublicStorage = false;
      if (contentUri != null && contentUri.startsWith('content://')) {
        deletedFromPublicStorage =
            await _platformFileService.deleteByContentUri(contentUri);
      }

      if (await file.exists()) {
        await file.delete();
      }

      if (contentUri != null && contentUri.startsWith('content://')) {
        return deletedFromPublicStorage;
      }

      return !await file.exists();
    } catch (e) {
      debugPrint('Failed to delete original file: $e');
      return false;
    }
  }

  Future<bool> _ensureManageExternalStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;

    final requested = await Permission.manageExternalStorage.request();
    return requested.isGranted;
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
        await _handleFileUpload(
          file,
          await assets.first.titleAsync,
          assets.first.mimeType,
        );
        // This is the most important part for Media (Images, Videos, Audio)
        // It triggers the system prompt to remove the file from MediaStore/Public view
        await PhotoManager.editor.deleteWithIds([assets.first.id]);
      }
    }
  }

  Future<void> _pickAnyFile() async {
    if (Platform.isAndroid) {
      final granted = await _ensureManageExternalStoragePermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to delete documents.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final platformFile = result.files.single;
      File file = File(platformFile.path!);
      await _handleFileUpload(
        file,
        platformFile.name,
        null,
        contentUri: platformFile.identifier,
        requireDeletion: true,
      );
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.largeRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppTheme.standardSpacing,
            top: AppTheme.mediumSpacing,
            left: AppTheme.standardSpacing,
            right: AppTheme.standardSpacing,
          ),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.largeSpacing),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.standardSpacing,
                  vertical: AppTheme.mediumSpacing,
                ),
                child: Text(
                  'Secure Move to Vault',
                  style: AppTheme.headlineMedium.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.standardSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF2196F3)),
                  ),
                  title: const Text('Images & Videos'),
                  subtitle: const Text('Remove from gallery and move to vault'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(RequestType.common);
                  },
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.standardSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF9800).withOpacity(0.2),
                    child: const Icon(Icons.audiotrack_rounded,
                        color: Color(0xFFFF9800)),
                  ),
                  title: const Text('Audio / Music'),
                  subtitle:
                      const Text('Remove from music player and move to vault'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(RequestType.audio);
                  },
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.standardSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                    child: const Icon(Icons.insert_drive_file_rounded,
                        color: Color(0xFF4CAF50)),
                  ),
                  title: const Text('Documents & Others'),
                  subtitle: const Text('Move PDF, Docs, Zip to private vault'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAnyFile();
                  },
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ),
              ),
              const SizedBox(height: AppTheme.largeSpacing),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppTheme.standardSpacing),
          child: Center(
            child: Icon(
              Icons.shield_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
        ),
        title: Text(
          'FileFortress',
          style: AppTheme.headlineMedium.copyWith(
            color: colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_round_outlined,
              color: colorScheme.onBackground,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: colorScheme.onBackground,
            ),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Images'),
              Tab(text: 'Videos'),
              Tab(text: 'Audio'),
              Tab(text: 'Docs'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AllFilesTab(),
          ImagesTab(),
          VideosTab(),
          AudioTab(),
          DocumentsTab()
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isImporting ? null : _showAddOptions,
        label: _isImporting
            ? const Text('Moving to Vault...')
            : const Text('Add File'),
        icon: _isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_rounded),
        tooltip: 'Add files to vault',
      ),
    );
  }
}
