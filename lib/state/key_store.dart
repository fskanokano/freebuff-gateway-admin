/// 密钥存储抽象：隔离平台安全存储，便于测试注入与失败回退。
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class KeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// 生产实现：FlutterSecureStorage（Android Keystore / iOS Keychain / Windows DPAPI）。
/// 平台不支持或加解密上下文失败时静默回退（read→null，write/delete→no-op），
/// 绝不因安全存储异常把用户卡在登录页。
class SecureKeyStore implements KeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// 平台通道无响应时的兜底超时，避免把用户卡在登录页加载态。
  static const _timeout = Duration(seconds: 3);

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key).timeout(_timeout);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value).timeout(_timeout);
    } catch (_) {
      // 回退：无法加密时由调用方降级到明文 prefs。
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key).timeout(_timeout);
    } catch (_) {}
  }
}

/// 测试/降级实现：内存键值存储。
class InMemoryKeyStore implements KeyStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}
