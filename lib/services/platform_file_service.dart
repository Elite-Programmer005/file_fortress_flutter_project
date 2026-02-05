import 'package:flutter/services.dart';

class PlatformFileService {
  static const MethodChannel _channel = MethodChannel('file_fortress/file_ops');

  Future<bool> deleteByContentUri(String uri) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('deleteUri', <String, dynamic>{'uri': uri});
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
