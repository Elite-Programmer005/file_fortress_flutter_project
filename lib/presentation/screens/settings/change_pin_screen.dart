import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/material.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _encryptionService = AESEncryptionService();
  
  bool _isLoading = false;
  bool _arePinsVisible = false; // Single boolean to control all fields

  Future<void> _changePin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final success = await _encryptionService.changeMasterPassword(
        oldPassword: _oldPinController.text,
        newPassword: _newPinController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to change PIN. Is your old PIN correct?')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Master PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPinController,
                obscureText: !_arePinsVisible,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Old PIN'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old PIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPinController,
                obscureText: !_arePinsVisible,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'New PIN'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'PIN must be at least 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPinController,
                obscureText: !_arePinsVisible,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Confirm New PIN'),
                validator: (value) {
                  if (value != _newPinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _arePinsVisible,
                    onChanged: (value) {
                      setState(() {
                        _arePinsVisible = value ?? false;
                      });
                    },
                  ),
                  const Text('Show PINs'),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changePin,
                      child: const Text('Save Changes'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
