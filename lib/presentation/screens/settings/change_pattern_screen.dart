import 'package:file_fortress/core/constants/app_constants.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/core/utils/pattern_utils.dart';
import 'package:file_fortress/presentation/widgets/pattern_pad.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';

class ChangePatternScreen extends StatefulWidget {
  const ChangePatternScreen({super.key});

  @override
  State<ChangePatternScreen> createState() => _ChangePatternScreenState();
}

class _ChangePatternScreenState extends State<ChangePatternScreen> {
  final _pageController = PageController();
  final _encryptionService = AESEncryptionService();
  final _oldKey = GlobalKey<PatternPadState>();
  final _newKey = GlobalKey<PatternPadState>();
  final _confirmKey = GlobalKey<PatternPadState>();

  String? _oldPatternSerialized;
  List<int>? _newPattern;
  bool _isSaving = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showErrorMessage(String message) {
    setState(() {
      _showError = true;
      _errorMessage = message;
    });
  }

  Future<void> _verifyOldPattern(List<int> pattern) async {
    if (!isPatternValid(pattern)) {
      _showErrorMessage(
        'Pattern must connect at least ${AppConstants.patternMinLength} dots',
      );
      _oldKey.currentState?.clear();
      return;
    }

    final serialized = serializePattern(pattern);
    final isValid = await _encryptionService.verifyMasterPassword(serialized);
    if (!mounted) return;

    if (!isValid) {
      _showErrorMessage('Current pattern does not match');
      _oldKey.currentState?.clear();
      return;
    }

    setState(() {
      _showError = false;
      _oldPatternSerialized = serialized;
    });

    _oldKey.currentState?.clear();
    _pageController.nextPage(
      duration: AppTheme.transitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  void _setNewPattern(List<int> pattern) {
    if (!isPatternValid(pattern)) {
      _showErrorMessage(
        'Pattern must connect at least ${AppConstants.patternMinLength} dots',
      );
      _newKey.currentState?.clear();
      return;
    }

    setState(() {
      _showError = false;
      _newPattern = List<int>.from(pattern);
    });

    _newKey.currentState?.clear();
    _pageController.nextPage(
      duration: AppTheme.transitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _confirmNewPattern(List<int> pattern) async {
    if (_oldPatternSerialized == null || _newPattern == null) return;

    if (!isPatternValid(pattern)) {
      _showErrorMessage(
        'Pattern must connect at least ${AppConstants.patternMinLength} dots',
      );
      _confirmKey.currentState?.clear();
      return;
    }

    if (serializePattern(pattern) != serializePattern(_newPattern!)) {
      _showErrorMessage('Patterns do not match');
      _confirmKey.currentState?.clear();
      return;
    }

    setState(() => _isSaving = true);
    final success = await _encryptionService.changeMasterPassword(
      oldPassword: _oldPatternSerialized!,
      newPassword: serializePattern(pattern),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pattern updated successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      _showErrorMessage('Failed to update pattern');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final padSize = MediaQuery.of(context).size.height < 700 ? 220.0 : 260.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Change Pattern')),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep(
                title: 'Verify Current Pattern',
                subtitle: 'Draw your existing pattern',
                padKey: _oldKey,
                onCompleted: _verifyOldPattern,
                padSize: padSize,
                colorScheme: colorScheme,
              ),
              _buildStep(
                title: 'Create New Pattern',
                subtitle:
                    'Connect at least ${AppConstants.patternMinLength} dots',
                padKey: _newKey,
                onCompleted: _setNewPattern,
                padSize: padSize,
                colorScheme: colorScheme,
              ),
              _buildStep(
                title: 'Confirm New Pattern',
                subtitle: 'Draw the new pattern again',
                padKey: _confirmKey,
                onCompleted: _confirmNewPattern,
                padSize: padSize,
                colorScheme: colorScheme,
              ),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required GlobalKey<PatternPadState> padKey,
    required ValueChanged<List<int>> onCompleted,
    required double padSize,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.largeSpacing),
          Text(
            title,
            style: AppTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.largeSpacing),
          SizedBox(
            height: padSize,
            width: padSize,
            child: PatternPad(
              key: padKey,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.outlineVariant,
              errorColor: colorScheme.error,
              showError: _showError,
              onChanged: (_) {
                if (_showError) {
                  setState(() => _showError = false);
                }
              },
              onCompleted: onCompleted,
            ),
          ),
          const SizedBox(height: AppTheme.largeSpacing),
          if (_showError)
            Text(
              _errorMessage,
              style: AppTheme.bodySmall.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => padKey.currentState?.clear(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Pattern'),
            ),
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
        ],
      ),
    );
  }
}
