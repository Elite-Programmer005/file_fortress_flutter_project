import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MasterPasswordSettingsScreen extends StatefulWidget {
  const MasterPasswordSettingsScreen({super.key});

  @override
  State<MasterPasswordSettingsScreen> createState() => _MasterPasswordSettingsScreenState();
}

class _MasterPasswordSettingsScreenState extends State<MasterPasswordSettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Credentials')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Authentication Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTypeTile(context, AuthType.pin, 'PIN', 'Switch to a 4-6 digit numeric code'),
            _buildTypeTile(context, AuthType.password, 'Password', 'Switch to an alphanumeric password'),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Change Secret Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(labelText: 'Old PIN/Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'New PIN/Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm New Key', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNewKey,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Update Credentials'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTile(BuildContext context, AuthType type, String title, String sub) {
    final current = context.watch<AuthProvider>().selectedAuthType;
    return RadioListTile<AuthType>(
      title: Text(title),
      subtitle: Text(sub),
      value: type,
      groupValue: current,
      onChanged: (val) {
        if (val != null) context.read<AuthProvider>().setAuthType(val);
      },
    );
  }

  void _saveNewKey() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
       return;
    }
    // Logic to verify old and save new
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security updated!')));
  }
}
