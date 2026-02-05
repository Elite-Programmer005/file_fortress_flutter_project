import 'dart:math' as math;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 700;
        final hasBiometric = showBiometricToggle &&
            context.watch<AuthProvider>().biometricAvailable;
        final scaleBase = (constraints.maxHeight / 760).clamp(0.68, 1.0);
        final scale = hasBiometric ? scaleBase * 0.92 : scaleBase;
        final spacingLarge =
            (isCompact ? AppTheme.mediumSpacing : AppTheme.largeSpacing) *
                scale;
        final spacingSmall =
            (isCompact ? AppTheme.smallSpacing : AppTheme.standardSpacing) *
                scale;
        final iconSize = (isCompact ? 44.0 : 56.0) * scale;

        final titleFontSize = (AppTheme.headlineLarge.fontSize ?? 28) * scale;
        final bodyFontSize = (AppTheme.bodyMedium.fontSize ?? 14) * scale;

        final padSize = math.min(
          constraints.maxWidth * 0.68,
          constraints.maxHeight * (hasBiometric ? 0.26 : 0.30),
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
            vertical: spacingSmall,
          ),
          child: Column(
            children: [
              SizedBox(height: spacingLarge),
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
                    size: iconSize,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: spacingLarge),
              FadeInUp(
                delayMs: 100,
                child: Text(
                  title,
                  style: AppTheme.headlineLarge.copyWith(
                    color: colorScheme.onBackground,
                    fontSize: titleFontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: spacingSmall),
              FadeInUp(
                delayMs: 150,
                child: Text(
                  subtitle,
                  style: AppTheme.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: bodyFontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Center(
                        child: SizedBox(
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
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    if (_showError)
                      Text(
                        _errorMessage,
                        style: AppTheme.bodySmall.copyWith(
                          color: colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (showBiometricToggle)
                      Padding(
                        padding: EdgeInsets.only(top: spacingSmall),
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (!authProvider.biometricAvailable) {
                              return const SizedBox.shrink();
                            }
                            return Card(
                              margin: EdgeInsets.zero,
                              child: SwitchListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.standardSpacing,
                                  vertical: AppTheme.smallSpacing * 0.5,
                                ),
                                title: Text(
                                  'Enable Fingerprint Unlock',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: colorScheme.onSurface,
                                    fontSize:
                                        (AppTheme.titleMedium.fontSize ?? 16) *
                                            scale,
                                  ),
                                ),
                                subtitle: Text(
                                  'Use biometrics to unlock your vault faster',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize:
                                        (AppTheme.bodySmall.fontSize ?? 12) *
                                            scale,
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
                    SizedBox(height: spacingSmall),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => patternKey.currentState?.clear(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset Pattern'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
