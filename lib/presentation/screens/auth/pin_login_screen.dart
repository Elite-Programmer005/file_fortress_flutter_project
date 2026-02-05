import 'dart:math' as math;

import 'package:file_fortress/core/constants/app_constants.dart';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/core/utils/pattern_utils.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/presentation/widgets/animated_pin_circle.dart';
import 'package:file_fortress/presentation/widgets/entrance_animations.dart';
import 'package:file_fortress/presentation/widgets/pattern_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen>
    with SingleTickerProviderStateMixin {
  final List<int> _enteredPin = [];
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<PatternPadState> _patternKey = GlobalKey<PatternPadState>();

  late final AuthProvider _authProvider;
  late AnimationController _errorAnimationController;

  bool _biometricChecked = false;
  bool _showError = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _errorAnimationController = AnimationController(
      duration: AppTheme.animationDuration,
      vsync: this,
    );

    _authProvider = context.read<AuthProvider>();
    _authProvider.addListener(_handleAuthProviderChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthProviderChange);
    _errorAnimationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthProviderChange() {
    if (!_biometricChecked && _authProvider.isInitialized) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    if (_biometricChecked) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isInitialized) return;

    if (authProvider.biometricAvailable && authProvider.isBiometricEnabled) {
      setState(() {
        _biometricChecked = true;
      });

      final authenticated = await authProvider.authenticateWithBiometrics();
      if (authenticated && mounted) {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      }
      return;
    }

    setState(() {
      _biometricChecked = true;
    });
  }

  void _onNumberPressed(int number) {
    if (_enteredPin.length >= AppConstants.pinLength) return;

    setState(() {
      _enteredPin.add(number);
      _showError = false;
      _errorAnimationController.reset();
    });

    if (_enteredPin.length == AppConstants.pinLength) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty) return;

    setState(() {
      _enteredPin.removeLast();
      _showError = false;
      _errorAnimationController.reset();
    });
  }

  Future<void> _verifyPin() async {
    final authProvider = context.read<AuthProvider>();
    final pin = _enteredPin.join();

    final isValid = await authProvider.verifyCredential(pin);
    if (isValid) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      }
      return;
    }

    final attemptsLeft = authProvider.getRemainingAttempts();
    setState(() {
      _showError = true;
      _errorMessage = attemptsLeft > 0
          ? 'Incorrect PIN. $attemptsLeft attempts remaining'
          : 'Account locked. Try again in ${AppConstants.lockoutDuration.inMinutes} minutes';
      _enteredPin.clear();
    });

    HapticFeedback.heavyImpact();
    _errorAnimationController.forward();
  }

  Future<void> _verifyPassword() async {
    final authProvider = context.read<AuthProvider>();
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = 'Please enter your password';
      });
      _errorAnimationController.forward(from: 0);
      return;
    }

    if (password.length < AppConstants.passwordMinLength) {
      setState(() {
        _showError = true;
        _errorMessage =
            'Password must be at least ${AppConstants.passwordMinLength} characters';
      });
      _errorAnimationController.forward(from: 0);
      return;
    }

    final isValid = await authProvider.verifyCredential(password);
    if (isValid) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      }
      return;
    }

    final attemptsLeft = authProvider.getRemainingAttempts();
    setState(() {
      _showError = true;
      _errorMessage = attemptsLeft > 0
          ? 'Incorrect password. $attemptsLeft attempts remaining'
          : 'Account locked. Try again in ${AppConstants.lockoutDuration.inMinutes} minutes';
    });

    HapticFeedback.heavyImpact();
    _errorAnimationController.forward(from: 0);
  }

  Future<void> _verifyPattern(List<int> pattern) async {
    final authProvider = context.read<AuthProvider>();

    if (!isPatternValid(pattern)) {
      setState(() {
        _showError = true;
        _errorMessage =
            'Pattern must connect at least ${AppConstants.patternMinLength} dots';
      });
      _patternKey.currentState?.clear();
      _errorAnimationController.forward(from: 0);
      return;
    }

    final serialized = serializePattern(pattern);
    final isValid = await authProvider.verifyCredential(serialized);
    if (isValid) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      }
      return;
    }

    final attemptsLeft = authProvider.getRemainingAttempts();
    setState(() {
      _showError = true;
      _errorMessage = attemptsLeft > 0
          ? 'Incorrect pattern. $attemptsLeft attempts remaining'
          : 'Account locked. Try again in ${AppConstants.lockoutDuration.inMinutes} minutes';
    });

    HapticFeedback.heavyImpact();
    _patternKey.currentState?.clear();
    _errorAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final isPassword = authProvider.selectedAuthType == AuthType.password;
    final isPattern = authProvider.selectedAuthType == AuthType.pattern;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _LayoutConfig(constraints: constraints);
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
                vertical: layout.verticalPadding,
              ),
              child: Column(
                children: [
                  SizedBox(height: layout.edgeSpacing),
                  _buildHeader(colorScheme, layout: layout),
                  SizedBox(height: layout.sectionSpacing),
                  _buildPinIndicator(
                    colorScheme: colorScheme,
                    isPassword: isPassword,
                    isPattern: isPattern,
                    indicatorSpacing: layout.indicatorSpacing,
                    patternSize: layout.patternSize,
                  ),
                  _buildErrorMessage(colorScheme),
                  SizedBox(height: layout.sectionSpacing),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _buildActionsOrPad(
                        authProvider: authProvider,
                        colorScheme: colorScheme,
                        isPassword: isPassword,
                        isPattern: isPattern,
                        gridAspectRatio: layout.gridAspectRatio,
                        gridSpacing: layout.gridSpacing,
                        keypadFontSize: layout.keypadFontSize,
                        keypadIconSize: layout.keypadIconSize,
                      ),
                    ),
                  ),
                  SizedBox(height: layout.edgeSpacing),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme,
      {required _LayoutConfig layout}) {
    return FadeInScale(
      duration: AppTheme.transitionDuration,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(layout.headerIconPadding),
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
              Icons.shield_rounded,
              size: layout.headerIconSize,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: layout.headerTitleSpacing),
          Text(
            AppConstants.appName,
            style: AppTheme.displayMedium.copyWith(
              color: colorScheme.onBackground,
              fontSize: layout.titleFontSize,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.headerSubtitleSpacing),
          Text(
            'Secure File Vault',
            style: AppTheme.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: layout.subtitleFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinIndicator({
    required ColorScheme colorScheme,
    required bool isPassword,
    required bool isPattern,
    required double indicatorSpacing,
    required double patternSize,
  }) {
    return FadeInUp(
      delayMs: 100,
      child: Column(
        children: [
          Text(
            isPassword
                ? 'Enter your Password'
                : isPattern
                    ? 'Draw your Pattern'
                    : 'Enter your PIN',
            style: AppTheme.titleMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: indicatorSpacing),
          if (isPassword)
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  AppConstants.passwordMaxLength,
                ),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verifyPassword(),
              decoration: InputDecoration(
                hintText: 'Min ${AppConstants.passwordMinLength} characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            )
          else if (isPattern)
            SizedBox(
              height: patternSize,
              width: patternSize,
              child: PatternPad(
                key: _patternKey,
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.outlineVariant,
                errorColor: colorScheme.error,
                showError: _showError,
                onChanged: (_) {
                  if (_showError) {
                    setState(() => _showError = false);
                  }
                },
                onCompleted: _verifyPattern,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                AppConstants.pinLength,
                (index) => AnimatedPinCircle(
                  filled: index < _enteredPin.length,
                  filledColor: colorScheme.primary,
                  emptyColor: colorScheme.outlineVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    if (!_showError) return const SizedBox.shrink();

    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.only(top: AppTheme.mediumSpacing),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0)
              .animate(_errorAnimationController),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.standardSpacing),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              border: Border.all(
                color: colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.mediumSpacing),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: AppTheme.bodySmall.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsOrPad({
    required AuthProvider authProvider,
    required ColorScheme colorScheme,
    required bool isPassword,
    required bool isPattern,
    required double gridAspectRatio,
    required double gridSpacing,
    required double keypadFontSize,
    required double keypadIconSize,
  }) {
    if (isPassword) {
      return FadeInUp(
        delayMs: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _verifyPassword,
                child: const Text('Login'),
              ),
            ),
            if (authProvider.biometricAvailable &&
                authProvider.isBiometricEnabled) ...[
              const SizedBox(height: AppTheme.standardSpacing),
              OutlinedButton.icon(
                onPressed: _checkBiometrics,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Use Biometrics'),
              ),
            ],
          ],
        ),
      );
    }

    if (isPattern) {
      return FadeInUp(
        delayMs: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _patternKey.currentState?.clear(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Pattern'),
              ),
            ),
            if (authProvider.biometricAvailable &&
                authProvider.isBiometricEnabled) ...[
              const SizedBox(height: AppTheme.standardSpacing),
              OutlinedButton.icon(
                onPressed: _checkBiometrics,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Use Biometrics'),
              ),
            ],
          ],
        ),
      );
    }

    return FadeInUp(
      delayMs: 200,
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: gridAspectRatio,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(12, (index) {
          if (index == 9) {
            return (authProvider.biometricAvailable &&
                    authProvider.isBiometricEnabled)
                ? _buildIconButton(
                    Icons.fingerprint_rounded,
                    _checkBiometrics,
                    colorScheme,
                    'Biometric',
                    iconSize: keypadIconSize,
                  )
                : const SizedBox.shrink();
          }
          if (index == 10) {
            return _buildNumberButton(0, colorScheme, fontSize: keypadFontSize);
          }
          if (index == 11) {
            return _buildIconButton(
              Icons.backspace_outlined,
              _onBackspacePressed,
              colorScheme,
              'Delete',
              iconSize: keypadIconSize,
              isEnabled: _enteredPin.isNotEmpty,
            );
          }
          return _buildNumberButton(index + 1, colorScheme,
              fontSize: keypadFontSize);
        }),
      ),
    );
  }

  Widget _buildNumberButton(
    int number,
    ColorScheme colorScheme, {
    required double fontSize,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            color: colorScheme.surfaceVariant,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: AppTheme.headlineSmall.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
    String tooltip, {
    required double iconSize,
    bool isEnabled = true,
  }) {
    final isBlue = isEnabled && tooltip == 'Biometric';
    final buttonColor = isBlue ? colorScheme.primary : Colors.grey;
    final bgColor = isBlue
        ? colorScheme.primary.withOpacity(0.15)
        : Colors.grey.withOpacity(0.1);
    final borderColor = isBlue
        ? colorScheme.primary.withOpacity(0.3)
        : Colors.grey.withOpacity(0.2);

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              color: bgColor,
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: buttonColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayoutConfig {
  final bool isCompact;
  final bool isUltraCompact;
  final double verticalPadding;
  final double edgeSpacing;
  final double sectionSpacing;
  final double gridAspectRatio;
  final double gridSpacing;
  final double headerIconSize;
  final double headerIconPadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double headerTitleSpacing;
  final double headerSubtitleSpacing;
  final double indicatorSpacing;
  final double keypadFontSize;
  final double keypadIconSize;
  final double patternSize;

  _LayoutConfig({required BoxConstraints constraints})
      : isCompact = constraints.maxHeight < 700,
        isUltraCompact = constraints.maxHeight < 600,
        verticalPadding = constraints.maxHeight < 600
            ? AppTheme.smallSpacing * 0.5
            : constraints.maxHeight < 700
                ? AppTheme.smallSpacing
                : AppTheme.mediumSpacing,
        edgeSpacing = constraints.maxHeight < 600
            ? AppTheme.smallSpacing * 0.5
            : constraints.maxHeight < 700
                ? AppTheme.smallSpacing
                : AppTheme.mediumSpacing,
        sectionSpacing = constraints.maxHeight < 600
            ? AppTheme.smallSpacing
            : constraints.maxHeight < 700
                ? AppTheme.mediumSpacing
                : AppTheme.largeSpacing,
        gridAspectRatio = constraints.maxHeight < 600
            ? 1.8
            : constraints.maxHeight < 700
                ? 1.5
                : 1.2,
        gridSpacing = constraints.maxHeight < 600
            ? 10
            : constraints.maxHeight < 700
                ? 14
                : AppTheme.mediumSpacing,
        headerIconSize = constraints.maxHeight < 600
            ? 36
            : constraints.maxHeight < 700
                ? 44
                : 56,
        headerIconPadding = constraints.maxHeight < 600
            ? AppTheme.smallSpacing
            : AppTheme.standardSpacing,
        titleFontSize = constraints.maxHeight < 600
            ? 28
            : constraints.maxHeight < 700
                ? 34
                : 45,
        subtitleFontSize = constraints.maxHeight < 600
            ? 12
            : constraints.maxHeight < 700
                ? 14
                : 16,
        headerTitleSpacing = constraints.maxHeight < 600
            ? AppTheme.smallSpacing
            : constraints.maxHeight < 700
                ? AppTheme.standardSpacing
                : AppTheme.largeSpacing,
        headerSubtitleSpacing =
            constraints.maxHeight < 600 ? 4 : AppTheme.smallSpacing,
        indicatorSpacing = constraints.maxHeight < 600
            ? AppTheme.smallSpacing
            : constraints.maxHeight < 700
                ? AppTheme.standardSpacing
                : AppTheme.largeSpacing,
        keypadFontSize = constraints.maxHeight < 600
            ? 22
            : constraints.maxHeight < 700
                ? 26
                : 28,
        keypadIconSize = constraints.maxHeight < 600
            ? 22
            : constraints.maxHeight < 700
                ? 26
                : 28,
        patternSize = math.min(
          constraints.maxWidth * 0.78,
          constraints.maxHeight < 600
              ? constraints.maxHeight * 0.26
              : constraints.maxHeight < 700
                  ? constraints.maxHeight * 0.30
                  : constraints.maxHeight * 0.34,
        );
}
