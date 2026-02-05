import 'package:file_fortress/core/constants/app_constants.dart';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/core/utils/pattern_utils.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/presentation/widgets/entrance_animations.dart';
import 'package:file_fortress/presentation/widgets/loading_overlay.dart';
import 'package:file_fortress/presentation/widgets/pattern_pad.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupPatternScreen extends StatefulWidget {
  const SetupPatternScreen({super.key});

  @override
  State<SetupPatternScreen> createState() => _SetupPatternScreenState();
}

class _SetupPatternScreenState extends State<SetupPatternScreen> {
  final _pageController = PageController();
  final _encryptionService = AESEncryptionService();
  final _patternKey = GlobalKey<PatternPadState>();
  final _confirmKey = GlobalKey<PatternPadState>();

  List<int>? _firstPattern;
  bool _isLoading = false;
  bool _enableBiometricSetup = false;
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

  void _handleFirstPattern(List<int> pattern) {
    if (!isPatternValid(pattern)) {
      _showErrorMessage(
        'Pattern must connect at least ${AppConstants.patternMinLength} dots',
      );
      _patternKey.currentState?.clear();
      return;
    }

    setState(() {
      _showError = false;
      _firstPattern = List<int>.from(pattern);
    });

    _patternKey.currentState?.clear();
    _pageController.nextPage(
      duration: AppTheme.transitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _handleConfirmPattern(List<int> pattern) async {
    if (_firstPattern == null) return;

    if (!isPatternValid(pattern)) {
      _showErrorMessage(
        'Pattern must connect at least ${AppConstants.patternMinLength} dots',
      );
      _confirmKey.currentState?.clear();
      return;
    }

    if (serializePattern(pattern) != serializePattern(_firstPattern!)) {
      _showErrorMessage('Patterns do not match. Try again.');
      _confirmKey.currentState?.clear();
      return;
    }

    await _createVault(serializePattern(pattern));
  }

  Future<void> _createVault(String patternKey) async {
    setState(() => _isLoading = true);
    try {
      await _encryptionService.saveMasterKey(patternKey);

      if (_enableBiometricSetup) {
        await context.read<AuthProvider>().toggleBiometrics(true);
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.dashboard,
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Setting up your vault...',
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPatternStep(
                title: 'Create a Pattern',
                subtitle:
                    'Connect at least ${AppConstants.patternMinLength} dots',
                patternKey: _patternKey,
                colorScheme: colorScheme,
                onCompleted: _handleFirstPattern,
              ),
              _buildPatternStep(
                title: 'Confirm Pattern',
                subtitle: 'Draw the same pattern again',
                patternKey: _confirmKey,
                colorScheme: colorScheme,
                onCompleted: _handleConfirmPattern,
                showBiometricToggle: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternStep({
    required String title,
    required String subtitle,
    required GlobalKey<PatternPadState> patternKey,
    required ColorScheme colorScheme,
    required ValueChanged<List<int>> onCompleted,
    bool showBiometricToggle = false,
  }) {
    final padSize = MediaQuery.of(context).size.height < 700 ? 220.0 : 260.0;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.largeSpacing),
          FadeInScale(
            duration: AppTheme.transitionDuration,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.standardSpacing),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.pattern_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.largeSpacing),
          FadeInUp(
            delayMs: 100,
            child: Text(
              title,
              style: AppTheme.headlineLarge.copyWith(
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          FadeInUp(
            delayMs: 150,
            child: Text(
              subtitle,
              style: AppTheme.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.largeSpacing),
          SizedBox(
            height: padSize,
            width: padSize,
            child: PatternPad(
              key: patternKey,
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
          if (showBiometricToggle)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.largeSpacing),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (!authProvider.biometricAvailable) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    child: SwitchListTile(
                      title: Text(
                        'Enable Fingerprint Unlock',
                        style: AppTheme.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Use biometrics to unlock your vault faster',
                        style: AppTheme.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _enableBiometricSetup,
                      onChanged: (val) =>
                          setState(() => _enableBiometricSetup = val),
                    ),
                  );
                },
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => patternKey.currentState?.clear(),
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
