import 'package:file_fortress/core/constants/app_constants.dart';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/presentation/widgets/animated_button.dart';
import 'package:file_fortress/presentation/widgets/entrance_animations.dart';
import 'package:file_fortress/presentation/widgets/loading_overlay.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _encryptionService = AESEncryptionService();
  bool _isLoading = false;
  bool _enableBiometricSetup = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _pageController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppTheme.transitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _createVault() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _encryptionService.saveMasterKey(_pinController.text);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: [
            _buildOnboardingPage1(),
            _buildOnboardingPage2(),
            _buildSetupPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: AppTheme.largeSpacing,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.extraLargeSpacing),
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.extraLargeSpacing),
            FadeInUp(
              delayMs: 100,
              child: Text(
                'Welcome to FileFortress',
                style: AppTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.standardSpacing),
            FadeInUp(
              delayMs: 200,
              child: Text(
                'Your private photos, videos, and documents are now safe. We use military-grade encryption to protect your privacy.',
                style: AppTheme.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.extraLargeSpacing),
            FadeInUp(
              delayMs: 300,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedButton(
                  onPressed: _nextPage,
                  label: 'Get Started',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.largeSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage2() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: AppTheme.largeSpacing,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.extraLargeSpacing),
            FadeInScale(
              duration: AppTheme.transitionDuration,
              delayMs: 50,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.standardSpacing),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.extraLargeSpacing),
            FadeInUp(
              delayMs: 150,
              child: Text(
                'Fast & Secure',
                style: AppTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.standardSpacing),
            FadeInUp(
              delayMs: 250,
              child: Text(
                'Unlock your vault instantly with your fingerprint. No need to type your PIN every time.',
                style: AppTheme.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.extraLargeSpacing),
            FadeInUp(
              delayMs: 350,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedButton(
                  onPressed: _nextPage,
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.largeSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPage() {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isPassword = authProvider.selectedAuthType == AuthType.password;
    final isPin = authProvider.selectedAuthType == AuthType.pin;
    final inputFormatters = <TextInputFormatter>[
      if (isPin) LengthLimitingTextInputFormatter(AppConstants.pinLength),
      if (isPin) FilteringTextInputFormatter.digitsOnly,
      if (isPassword)
        LengthLimitingTextInputFormatter(AppConstants.passwordMaxLength),
    ];
    final label = isPassword ? 'Password' : 'PIN';
    final minHint = isPassword
        ? 'Min ${AppConstants.passwordMinLength} characters'
        : 'Exactly ${AppConstants.pinLength} digits';

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Setting up your vault...',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppTheme.extraLargeSpacing),

              // ─────────────────────────────────────────────────────────────
              // HEADER
              // ─────────────────────────────────────────────────────────────
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
                    Icons.shield_rounded,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.largeSpacing),

              FadeInUp(
                delayMs: 100,
                child: Text(
                  'Setup Master Key',
                  style: AppTheme.headlineLarge.copyWith(
                    color: colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.extraLargeSpacing),

              // ─────────────────────────────────────────────────────────────
              // PIN INPUT FIELDS
              // ─────────────────────────────────────────────────────────────
              FadeInUp(
                delayMs: 150,
                child: TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType:
                      isPassword ? TextInputType.text : TextInputType.number,
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    labelText: 'Enter Master $label',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () {
                        setState(() => _obscurePin = !_obscurePin);
                      },
                    ),
                    hintText: minHint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your $label';
                    }
                    if (isPin && value.length != AppConstants.pinLength) {
                      return 'PIN must be exactly ${AppConstants.pinLength} digits';
                    }
                    if (isPassword &&
                        value.length < AppConstants.passwordMinLength) {
                      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
                    }
                    if (isPin && !RegExp(r'^\d+$').hasMatch(value)) {
                      return 'PIN must contain only digits';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.standardSpacing),

              FadeInUp(
                delayMs: 200,
                child: TextFormField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirmPin,
                  keyboardType:
                      isPassword ? TextInputType.text : TextInputType.number,
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    labelText: 'Confirm Master $label',
                    prefixIcon: const Icon(Icons.vpn_key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPin
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () {
                        setState(
                            () => _obscureConfirmPin = !_obscureConfirmPin);
                      },
                    ),
                    hintText: 'Re-enter your $label',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your $label';
                    }
                    if (isPin && value.length != AppConstants.pinLength) {
                      return 'PIN must be exactly ${AppConstants.pinLength} digits';
                    }
                    if (isPassword &&
                        value.length < AppConstants.passwordMinLength) {
                      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
                    }
                    if (value != _pinController.text) {
                      return 'Keys do not match';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.extraLargeSpacing),

              // ─────────────────────────────────────────────────────────────
              // BIOMETRIC OPTION
              // ─────────────────────────────────────────────────────────────
              if (authProvider.biometricAvailable)
                FadeInUp(
                  delayMs: 250,
                  child: Card(
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
                  ),
                ),

              const SizedBox(height: AppTheme.extraLargeSpacing),

              // ─────────────────────────────────────────────────────────────
              // ACTION BUTTONS
              // ─────────────────────────────────────────────────────────────
              FadeInUp(
                delayMs: 300,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: AppTheme.transitionDuration,
                                    curve: Curves.easeInOutCubic,
                                  )
                              : null,
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.standardSpacing),
                    Expanded(
                      child: AnimatedButton(
                        onPressed: _createVault,
                        label: 'Complete Setup',
                        icon: Icons.done_rounded,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.largeSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
