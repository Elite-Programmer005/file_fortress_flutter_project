import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _encryptionService = AESEncryptionService();
  bool _isLoading = false;

  Future<void> _createVault() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _encryptionService.saveMasterKey(_pinController.text);

        if (!mounted) return;

        // Navigate to the dashboard and remove all previous screens from the stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.dashboard,
          (route) => false,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create vault: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Create Your Vault',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a 6-digit master PIN for your vault.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _pinController,
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Enter 6-Digit PIN'),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'PIN must be exactly 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPinController,
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Confirm 6-Digit PIN'),
                  validator: (value) {
                    if (value != _pinController.text) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _createVault,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
                        child: const Text('Create Vault'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
