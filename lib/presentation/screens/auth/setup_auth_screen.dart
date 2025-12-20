import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupAuthScreen extends StatefulWidget {
  const SetupAuthScreen({super.key});

  @override
  State<SetupAuthScreen> createState() => _SetupAuthScreenState();
}

class _SetupAuthScreenState extends State<SetupAuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how to protect your files:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildAuthOption(
              context,
              icon: Icons.pin,
              title: 'PIN',
              subtitle: '4-6 digit numeric code',
              onTap: () {
                context.read<AuthProvider>().setAuthType(AuthType.pin);
                Navigator.pushNamed(context, Routes.setupPin);
              },
            ),
            const SizedBox(height: 16),
            _buildAuthOption(
              context,
              icon: Icons.password,
              title: 'Password',
              subtitle: 'Alphanumeric secure password',
              onTap: () {
                 context.read<AuthProvider>().setAuthType(AuthType.password);
                 // We'll reuse the setup logic but with a different UI
                 _showPasswordSetupDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showPasswordSetupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 4) return;
              // Save logic
              await context.read<AuthProvider>().verifyCredential(controller.text); // This saves too if handled correctly
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, Routes.dashboard);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
