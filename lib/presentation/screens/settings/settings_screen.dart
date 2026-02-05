import 'dart:io';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRestoring = false;

  Future<void> _restoreAllFiles() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: const Text("Restore All Files?"),
        content: const Text(
            "This will decrypt all files and move them back to your Downloads folder. The vault will be emptied."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Restore All",
                  style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);
    final box = Hive.box<FileEntity>('files');
    final files = box.values.toList();
    final encryptionService = AESEncryptionService();
    int successCount = 0;

    try {
      for (var fileEntity in files) {
        final encryptedFile = File(fileEntity.encryptedPath);
        if (await encryptedFile.exists()) {
          final encryptedBytes = await encryptedFile.readAsBytes();
          final decryptedBytes =
              await encryptionService.decryptFile(encryptedBytes);

          Directory? downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }

          final restoredPath =
              path.join(downloadsDir!.path, fileEntity.originalName);
          await File(restoredPath).writeAsBytes(decryptedBytes);

          await encryptedFile.delete();
          await box.delete(fileEntity.id);
          successCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully restored $successCount files to Downloads folder!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error during restore: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppTheme.pagePadding / 2),
            children: [
              _buildSectionTitle(context, 'Security'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Security Credentials'),
                      subtitle:
                          const Text('Change PIN/Password or auth method'),
                      onTap: () => Navigator.pushNamed(
                          context, Routes.verifyUpdateCredentials),
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SwitchListTile(
                          secondary: const Icon(Icons.fingerprint),
                          title: const Text('Biometric Unlock'),
                          subtitle: const Text(
                              'Enable or disable biometric authentication'),
                          value: authProvider.isBiometricEnabled,
                          onChanged: authProvider.biometricAvailable
                              ? (bool value) =>
                                  authProvider.toggleBiometrics(value)
                              : null,
                          activeColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.surfaceVariant,
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildSectionTitle(context, 'Data Management'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore,
                      color: colorScheme.secondary),
                  title: const Text('Restore All Files'),
                  subtitle:
                      const Text('Decrypt everything and move back to phone'),
                  onTap: _isRestoring ? null : _restoreAllFiles,
                ),
              ),
              _buildSectionTitle(context, 'About'),
              Card(
                child: const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
              ),
            ],
          ),
          if (_isRestoring)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text("Restoring all files...\nPlease do not close the app",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.largeSpacing,
        bottom: AppTheme.smallSpacing, // Changed from standardSpacing
        left: AppTheme.standardSpacing,
        right: AppTheme.standardSpacing,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
