import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  Future<void> _createVault() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _encryptionService.saveMasterKey(_pinController.text);
        
        // Save biometric preference if chosen
        if (_enableBiometricSetup) {
          await context.read<AuthProvider>().toggleBiometrics(true);
        }

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.dashboard, (route) => false);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            _buildOnboardingPage(
              icon: Icons.security_rounded,
              title: 'Welcome to FileFortress',
              description: 'Your private photos, videos, and documents are now safe. We use military-grade encryption to protect your privacy.',
              buttonText: 'Get Started',
              onPressed: _nextPage,
            ),
            _buildOnboardingPage(
              icon: Icons.fingerprint_rounded,
              title: 'Fast & Secure',
              description: 'Unlock your vault instantly with your fingerprint. No need to type your PIN every time.',
              buttonText: 'Next',
              onPressed: _nextPage,
            ),
            _buildSetupPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({required IconData icon, required String title, required String description, required String buttonText, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text(description, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(buttonText, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    final authProvider = context.watch<AuthProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.shield_rounded, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text('Setup Master Key', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextFormField(
              controller: _pinController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter Master PIN/Password',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.length < 4) ? 'Must be at least 4 characters' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPinController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Master Key',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value != _pinController.text ? 'Keys do not match' : null,
            ),
            const SizedBox(height: 24),
            
            // Biometric Option during Setup
            if (authProvider.biometricAvailable)
              SwitchListTile(
                title: const Text('Enable Fingerprint Unlock'),
                subtitle: const Text('Use biometrics to unlock your vault'),
                value: _enableBiometricSetup,
                onChanged: (val) => setState(() => _enableBiometricSetup = val),
              ),
            
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _createVault,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Complete Setup', style: TextStyle(fontSize: 18)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
