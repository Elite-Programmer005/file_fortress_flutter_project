import 'package:file_fortress/presentation/screens/auth/pin_login_screen.dart';
import 'package:file_fortress/presentation/screens/auth/setup_pin_screen.dart';
import 'package:file_fortress/presentation/screens/home/dashboard_screen.dart';
import 'package:file_fortress/presentation/screens/settings/change_pin_screen.dart';
import 'package:file_fortress/presentation/screens/settings/settings_screen.dart';
import 'package:file_fortress/presentation/screens/settings/master_password_settings_screen.dart';
import 'package:flutter/material.dart';

class Routes {
  static const String pinLogin = '/pin-login';
  static const String setupPin = '/setup-pin';
  static const String biometric = '/biometric';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String changePin = '/change-pin';
  static const String masterSettings = '/master-settings'; // New Route

  static Map<String, WidgetBuilder> get routes => {
        pinLogin: (context) => const PinLoginScreen(),
        setupPin: (context) => const SetupPinScreen(),
        dashboard: (context) => const DashboardScreen(),
        settings: (context) => const SettingsScreen(),
        changePin: (context) => const ChangePinScreen(),
        masterSettings: (context) => const MasterPasswordSettingsScreen(),
      };
}
