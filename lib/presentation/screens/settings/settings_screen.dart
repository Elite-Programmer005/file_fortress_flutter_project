import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Master PIN'),
            subtitle: const Text('Update your master PIN for the vault'),
            onTap: () {
              Navigator.pushNamed(context, Routes.changePin);
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric Unlock'),
                subtitle: const Text('Enable or disable fingerprint/face unlock'),
                // Only show the switch if biometrics are available on the device
                trailing: authProvider.biometricAvailable
                    ? Switch(
                        value: authProvider.isBiometricEnabled,
                        onChanged: (bool value) {
                          authProvider.toggleBiometrics(value);
                        },
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
