import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _encryptionService = AESEncryptionService(); // Instantiate the service

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  int _loginAttempts = 0;

  AuthProvider() {
    _checkBiometrics();
    _loadBiometricPreference();
  }

  Future<void> _checkBiometrics() async {
    final localAuth = LocalAuthentication();
    try {
      _biometricAvailable = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
    } catch (e) {
      _biometricAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _loadBiometricPreference() async {
    final pref = await _secureStorage.read(key: 'biometric_enabled');
    _isBiometricEnabled = pref == 'true';
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool isEnabled) async {
    await _secureStorage.write(key: 'biometric_enabled', value: isEnabled.toString());
    _isBiometricEnabled = isEnabled;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    _loginAttempts = 0;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    // Use the actual encryption service to verify the PIN
    final isValid = await _encryptionService.verifyMasterPassword(pin);

    if (isValid) {
      login();
      return true;
    } else {
      _loginAttempts++;
      notifyListeners();
      return false;
    }
  }

  int getRemainingAttempts() {
    const maxLoginAttempts = 5;
    return maxLoginAttempts - _loginAttempts;
  }
}
