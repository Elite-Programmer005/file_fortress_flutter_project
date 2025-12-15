import 'package:file_fortress/core/constants/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_fortress/core/constants/app_constants.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final List<int> _enteredPin = [];
  bool _showError = false;
  String _errorMessage = '';

  void _onNumberPressed(int number) {
    if (_enteredPin.length < AppConstants.pinLength) {
      setState(() {
        _enteredPin.add(number);
        _showError = false;
      });

      if (_enteredPin.length == AppConstants.pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _showError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final authProvider = context.read<AuthProvider>();
    final pin = _enteredPin.join();

    final isValid = await authProvider.verifyPin(pin);

    if (isValid) {
      // Navigate to dashboard
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      final attemptsLeft = authProvider.getRemainingAttempts();

      setState(() {
        _showError = true;
        _errorMessage = attemptsLeft > 0
            ? 'Incorrect PIN. $attemptsLeft attempts remaining'
            : 'Account locked. Try again in ${AppConstants.lockoutDuration.inMinutes} minutes';
        _enteredPin.clear();
      });

      // Vibrate on wrong attempt
      HapticFeedback.heavyImpact();
    }
  }

  Widget _buildPinCircle(int index) {
    bool filled = index < _enteredPin.length;

    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.blue : Colors.transparent,
        border: Border.all(color: filled ? Colors.blue : Colors.grey, width: 2),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[800],
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              Column(
                children: [
                  const Icon(Icons.lock_outlined, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure File Vault',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // PIN Circles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AppConstants.pinLength,
                  (index) => _buildPinCircle(index),
                ),
              ),

              // Error Message
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 48),

              // Number Pad
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  children: [
                    for (int i = 1; i <= 9; i++) _buildNumberButton(i),
                    Container(), // Empty space
                    _buildNumberButton(0),
                    // Backspace Button
                    InkWell(
                      onTap: _onBackspacePressed,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Biometric Option
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  // Only show button if biometrics are supported AND enabled by the user
                  if (authProvider.biometricAvailable && authProvider.isBiometricEnabled) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.biometric);
                        },
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Use Biometric'),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
