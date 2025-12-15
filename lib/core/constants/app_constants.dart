// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'FileFortress';
  static const String appVersion = '1.0.0';
  static const String encryptedFileExtension = '.fflock';
  static const int pinLength = 6;
  static const int maxLoginAttempts = 5;
  static const Duration autoLogoutDuration = Duration(minutes: 5);
  static const Duration lockoutDuration = Duration(minutes: 15);

  // File categories
  static const List<String> fileCategories = [
    'All',
    'Images',
    'Documents',
    'Videos',
    'Audio',
    'Others',
  ];
}
