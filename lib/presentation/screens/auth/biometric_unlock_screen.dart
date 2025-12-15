
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/core/constants/routes.dart';

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final authProvider = context.read<AuthProvider>();
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        authProvider.login();
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      } else {
        // User cancelled authentication
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      // Handle error (e.g., biometric not available)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 80),
            SizedBox(height: 20),
            Text('Authenticating...', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
