
// lib/services/encryption/aes_encryption_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart'; // Using the standard crypto package

class AESEncryptionService {
  static const int keyLength = 32; // 256 bits
  static const int ivLength = 16; // 128 bits

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Generate encryption key from master password using a simple SHA-256 hash
  Future<Uint8List> _generateKey(String masterPassword, String salt) async {
    final passwordBytes = utf8.encode(masterPassword);
    final saltBytes = utf8.encode(salt);

    // Combine password and salt
    final combined = <int>[...saltBytes, ...passwordBytes];

    // Hash the combination to produce a 256-bit (32-byte) key
    final digest = sha256.convert(combined);
    // Correctly convert the List<int> to a Uint8List
    return Uint8List.fromList(digest.bytes);
  }

  // Save master key securely
  Future<void> saveMasterKey(String masterPassword) async {
    try {
      final salt = _generateSalt();
      final key = await _generateKey(masterPassword, salt);

      // Store salt and key
      await _secureStorage.write(key: 'encryption_salt', value: salt);
      await _secureStorage.write(key: 'master_key', value: base64Encode(key));
    } catch (e) {
      throw Exception('Failed to save master key: \$e');
    }
  }

  // Get encryption key
  Future<Key> getEncryptionKey() async {
    try {
      final storedKey = await _secureStorage.read(key: 'master_key');
      if (storedKey == null) {
        throw Exception('No encryption key found');
      }
      return Key.fromBase64(storedKey);
    } catch (e) {
      throw Exception('Failed to get encryption key: \$e');
    }
  }

  // Encrypt file
  Future<Uint8List> encryptFile(Uint8List fileBytes) async {
    try {
      final key = await getEncryptionKey();
      final iv = IV.fromSecureRandom(ivLength);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Combine IV + encrypted data
      final result = Uint8List(ivLength + encrypted.bytes.length);
      result.setAll(0, iv.bytes);
      result.setAll(ivLength, encrypted.bytes);

      return result;
    } catch (e) {
      throw Exception('Encryption failed: \$e');
    }
  }

  // Decrypt file
  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    try {
      final key = await getEncryptionKey();

      // Extract IV (first 16 bytes)
      final iv = IV(encryptedBytes.sublist(0, ivLength));

      // Extract encrypted data
      final encryptedData = encryptedBytes.sublist(ivLength);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decryptBytes(
        Encrypted(encryptedData),
        iv: iv,
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: \$e');
    }
  }

  // Generate random salt
  String _generateSalt() {
    // A salt for SHA-256 should be random. 16 bytes is a good size.
    final salt = IV.fromSecureRandom(16);
    return base64Encode(salt.bytes);
  }

  // Verify master password
  Future<bool> verifyMasterPassword(String password) async {
    try {
      final salt = await _secureStorage.read(key: 'encryption_salt');
      if (salt == null) return false;

      final storedKey = await _secureStorage.read(key: 'master_key');
      if (storedKey == null) return false;

      final generatedKey = await _generateKey(password, salt);
      return base64Encode(generatedKey) == storedKey;
    } catch (e) {
      return false;
    }
  }

  // Change master password
  Future<bool> changeMasterPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // First, verify the old password is correct
      final isOldPasswordValid = await verifyMasterPassword(oldPassword);

      if (isOldPasswordValid) {
        // If valid, save the new password as the master key
        await saveMasterKey(newPassword);
        return true;
      } else {
        // If the old password was incorrect, do nothing and return false
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
