import 'package:file_fortress/core/constants/app_constants.dart';
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
              subtitle: '${AppConstants.pinLength}-digit numeric code',
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
              subtitle: 'Min ${AppConstants.passwordMinLength} characters',
              onTap: () {
                context.read<AuthProvider>().setAuthType(AuthType.password);
                Navigator.pushNamed(context, Routes.setupPin);
              },
            ),
            const SizedBox(height: 16),
            _buildAuthOption(
              context,
              icon: Icons.gesture_rounded,
              title: 'Pattern',
              subtitle:
                  'Connect at least ${AppConstants.patternMinLength} dots',
              onTap: () {
                context.read<AuthProvider>().setAuthType(AuthType.pattern);
                Navigator.pushNamed(context, Routes.setupPattern);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
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
}
