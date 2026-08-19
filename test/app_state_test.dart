import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_admin/api/gateway_api.dart';
import 'package:gateway_admin/state/app_state.dart';
import 'package:gateway_admin/state/key_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 模拟“写成功但读回超时”的 KeyStore（SecureKeyStore.read 吞异常返回 null）。
class _ReadFailsKeyStore implements KeyStore {
  String? stored;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {
    stored = value;
  }

  @override
  Future<void> delete(String key) async {
    stored = null;
  }
}

/// 可观测 close() 的 MockClient，用于验证 clearConnection 释放底层客户端。
class _CloseTrackingMockClient extends MockClient {
  _CloseTrackingMockClient(super.fn);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

GatewayApiFactory apiFactory(MockClient client) =>
    ({required String baseUrl, required String adminKey}) =>
        GatewayApi(baseUrl: baseUrl, adminKey: adminKey, client: client);

MockClient okClient() => MockClient((req) async {
      if (req.url.path == '/admin/api/overview') {
        return http.Response(
          jsonEncode({
            'stats': {
              'total': 1, 'ok': 1, 'depleted': 0, 'down': 0,
              'requestsOk': 5, 'requestsFail': 1,
            },
            'proxies': [
              {'name': 'a', 'url': 'https://a.x', 'status': 'ok', 'maint': false,
               'spend_24h': 2.5, 'tier': 'plus', 'country': 'US'},
            ],
            'events': [],
            'routes': [
              {'t': 1724060000000, 'name': 'a', 'status': 200, 'attempts': 1, 'ms': 5, 'ok': true},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.path == '/admin/api/pin') {
        return http.Response('{"pin_mode":"client","recent_proxies":[]}', 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 404);
    });

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('_init 迁移旧明文密钥到安全存储并清除明文', () async {
    SharedPreferences.setMockInitialValues({
      'gw_base_url': 'https://gw.x',
      'gw_admin_key': 'legacy-plaintext',
    });
    final store = InMemoryKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(okClient()));
    await settle();
    expect(state.loaded, isTrue);
    expect(state.baseUrl, 'https://gw.x');
    expect(state.adminKey, 'legacy-plaintext');
    expect(await store.read('gw_admin_key'), 'legacy-plaintext');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gw_admin_key'), isNull);
    state.dispose();
  });

  test('saveConnection 持久化到安全存储并清除明文', () async {
    final store = InMemoryKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(okClient()));
    await settle();
    await state.saveConnection('https://gw.x/', 'secret-key');
    await settle(); // 等待 saveConnection 触发的 in-flight refresh 完成，避免与 dispose 竞争
    expect(state.baseUrl, 'https://gw.x');
    expect(state.adminKey, 'secret-key');
    expect(await store.read('gw_admin_key'), 'secret-key');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gw_admin_key'), isNull);
    state.dispose();
  });

  test('refresh 成功更新 overview 并记录历史', () async {
    final store = InMemoryKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(okClient()));
    await settle();
    await state.saveConnection('https://gw.x', 'k');
    await settle();
    expect(state.overview, isNotNull);
    expect(state.hasError, isFalse);
    expect(state.overview!.proxies.first.spend24h, 2.5);
    expect(state.overview!.proxies.first.tier, 'plus');
    expect(state.overview!.proxies.first.country, 'US');
    expect(state.history, isNotEmpty);
    state.dispose();
  });

  test('refresh 失败置 hasError 且不抛异常', () async {
    final failing = MockClient((req) async => http.Response('Bad Gateway', 502));
    final store = InMemoryKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(failing));
    await settle();
    await state.saveConnection('https://gw.x', 'k');
    await settle();
    expect(state.hasError, isTrue);
    expect(state.lastError, isNotNull);
    state.dispose();
  });

  test('clearConnection 清空连接与历史', () async {
    final store = InMemoryKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(okClient()));
    await settle();
    await state.saveConnection('https://gw.x', 'k');
    await settle();
    await state.clearConnection();
    expect(state.baseUrl, isNull);
    expect(state.adminKey, isNull);
    expect(state.overview, isNull);
    expect(state.history, isEmpty);
    expect(await store.read('gw_admin_key'), isNull);
    state.dispose();
  });

  test('setThemeMode 持久化', () async {
    final store = InMemoryKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(okClient()));
    await settle();
    await state.setThemeMode(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('gw_theme'), ThemeMode.dark.index);
    state.dispose();
  });

  test('saveConnection 读回失败时回滚安全存储，仅明文留存', () async {
    final store = _ReadFailsKeyStore();
    final state = AppState(keyStore: store, apiFactory: apiFactory(okClient()));
    await settle();
    await state.saveConnection('https://gw.x', 'secret-key');
    await settle();
    expect(store.stored, isNull); // 已回滚，避免安全存储+明文双份
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gw_admin_key'), 'secret-key');
    state.dispose();
  });

  test('clearConnection 释放底层 http.Client', () async {
    final tracking = _CloseTrackingMockClient((req) async => http.Response(
        '{"stats":{}}', 200,
        headers: {'content-type': 'application/json'}));
    GatewayApi trackingFactory({required String baseUrl, required String adminKey}) =>
        GatewayApi(baseUrl: baseUrl, adminKey: adminKey, client: tracking);
    final state =
        AppState(keyStore: InMemoryKeyStore(), apiFactory: trackingFactory);
    await settle();
    await state.saveConnection('https://gw.x', 'k');
    await settle();
    expect(tracking.closed, isFalse);
    await state.clearConnection();
    expect(tracking.closed, isTrue);
    state.dispose();
  });
}
