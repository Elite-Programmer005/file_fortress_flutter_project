import 'package:file_fortress/core/constants/app_constants.dart';
import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/core/utils/pattern_utils.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_fortress/presentation/widgets/pattern_pad.dart';

class VerifyUpdateCredentialsScreen extends StatefulWidget {
  const VerifyUpdateCredentialsScreen({super.key});

  @override
  State<VerifyUpdateCredentialsScreen> createState() =>
      _VerifyUpdateCredentialsScreenState();
}

class _VerifyUpdateCredentialsScreenState
    extends State<VerifyUpdateCredentialsScreen> {
  final _credentialController = TextEditingController();
  final _encryptionService = AESEncryptionService();

  bool _obscureCredential = true;
  bool _isVerifying = false;
  bool _biometricChecked = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricIfAvailable();
    });
  }

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _attemptBiometricIfAvailable() async {
    if (_biometricChecked) return;
    _biometricChecked = true;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.biometricAvailable || !authProvider.isBiometricEnabled) {
      return;
    }

    setState(() => _isVerifying = true);
    final authenticated = await authProvider.authenticateWithBiometrics();
    if (!mounted) return;

    setState(() => _isVerifying = false);
    if (authenticated) {
      _goToUpdateScreen();
    }
  }

  Future<void> _verifyCredential() async {
    final credential = _credentialController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final isPassword = authProvider.selectedAuthType == AuthType.password;
    final isPin = authProvider.selectedAuthType == AuthType.pin;
    if (credential.isEmpty) {
      setState(() => _errorText = 'Please enter your credential');
      return;
    }
    if (isPin && credential.length != AppConstants.pinLength) {
      setState(() =>
          _errorText = 'PIN must be exactly ${AppConstants.pinLength} digits');
      return;
    }
    if (isPassword && credential.length < AppConstants.passwordMinLength) {
      setState(() => _errorText =
          'Password must be at least ${AppConstants.passwordMinLength} characters');
      return;
    }
    if (isPin && !RegExp(r'^\d+$').hasMatch(credential)) {
      setState(() => _errorText = 'PIN must contain only digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final isValid = await _encryptionService.verifyMasterPassword(credential);
    if (!mounted) return;

    setState(() => _isVerifying = false);
    if (isValid) {
      _goToUpdateScreen();
    } else {
      setState(() => _errorText = 'Credential does not match');
    }
  }

  Future<void> _verifyPattern(List<int> pattern) async {
    if (!isPatternValid(pattern)) {
      setState(() => _errorText =
          'Pattern must connect at least ${AppConstants.patternMinLength} dots');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final isValid = await _encryptionService
        .verifyMasterPassword(serializePattern(pattern));
    if (!mounted) return;

    setState(() => _isVerifying = false);
    if (isValid) {
      _goToUpdateScreen();
    } else {
      setState(() => _errorText = 'Pattern does not match');
    }
  }

  void _goToUpdateScreen() {
    final authType = context.read<AuthProvider>().selectedAuthType;
    if (authType == AuthType.pin) {
      Navigator.pushReplacementNamed(context, Routes.changePin);
      return;
    }
    if (authType == AuthType.pattern) {
      Navigator.pushReplacementNamed(context, Routes.changePattern);
      return;
    }
    Navigator.pushReplacementNamed(context, Routes.masterSettings);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPassword = authProvider.selectedAuthType == AuthType.password;
    final isPattern = authProvider.selectedAuthType == AuthType.pattern;
    final label = isPassword
        ? 'Password'
        : isPattern
            ? 'Pattern'
            : 'PIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify to Continue')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm your $label',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.standardSpacing),
              Text(
                'This is required to update security credentials.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.largeSpacing),
              if (!isPattern)
                TextField(
                  controller: _credentialController,
                  obscureText: _obscureCredential,
                  keyboardType:
                      isPassword ? TextInputType.text : TextInputType.number,
                  inputFormatters: [
                    if (!isPassword)
                      LengthLimitingTextInputFormatter(AppConstants.pinLength),
                    if (isPassword)
                      LengthLimitingTextInputFormatter(
                        AppConstants.passwordMaxLength,
                      ),
                    if (!isPassword) FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    errorText: _errorText,
                    prefixIcon: Icon(
                      isPassword ? Icons.lock_outline : Icons.pin,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCredential
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCredential = !_obscureCredential;
                        });
                      },
                    ),
                  ),
                  onSubmitted: (_) => _verifyCredential(),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: PatternPad(
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor:
                            Theme.of(context).colorScheme.outlineVariant,
                        errorColor: Theme.of(context).colorScheme.error,
                        showError: _errorText != null,
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                        onCompleted: _verifyPattern,
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: AppTheme.standardSpacing),
                      Text(
                        _errorText!,
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: AppTheme.largeSpacing),
              if (!isPattern)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCredential,
                    child: _isVerifying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                ),
              if (authProvider.biometricAvailable &&
                  authProvider.isBiometricEnabled) ...[
                const SizedBox(height: AppTheme.standardSpacing),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isVerifying ? null : _attemptBiometricIfAvailable,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Use Biometrics'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
