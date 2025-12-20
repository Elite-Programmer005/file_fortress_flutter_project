import 'package:file_fortress/services/encryption/aes_encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

enum AuthType { pin, password, pattern }

class AuthProvider extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _encryptionService = AESEncryptionService();
  final _localAuth = LocalAuthentication();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthType _selectedAuthType = AuthType.pin;
  AuthType get selectedAuthType => _selectedAuthType;

  int _loginAttempts = 0;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _checkBiometrics();
    await _loadPreferences();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      _biometricAvailable = canAuthenticate;
    } catch (e) {
      _biometricAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final bioPref = await _secureStorage.read(key: 'biometric_enabled');
    _isBiometricEnabled = bioPref == 'true';

    final authTypeStr = await _secureStorage.read(key: 'auth_type');
    if (authTypeStr != null) {
      _selectedAuthType = AuthType.values.firstWhere(
        (e) => e.toString() == authTypeStr,
        orElse: () => AuthType.pin,
      );
    }
    notifyListeners();
  }

  Future<void> setAuthType(AuthType type) async {
    await _secureStorage.write(key: 'auth_type', value: type.toString());
    _selectedAuthType = type;
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool isEnabled) async {
    await _secureStorage.write(key: 'biometric_enabled', value: isEnabled.toString());
    _isBiometricEnabled = isEnabled;
    notifyListeners();
  }

  // Improved Biometric Unlock
  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricAvailable || !_isBiometricEnabled) return false;

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock FileFortress',
        options: const AuthenticationOptions(
          stickyAuth: true, // App background mein jaye tab bhi auth active rahe
          biometricOnly: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'No thanks',
          ),
          IOSAuthMessages(
            cancelButton: 'No thanks',
          ),
        ],
      );

      if (didAuthenticate) {
        login();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
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

  Future<bool> verifyCredential(String credential) async {
    final isValid = await _encryptionService.verifyMasterPassword(credential);

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
