import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_admin/api/gateway_api.dart';
import 'package:gateway_admin/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final base = 'https://gw.example.com';

  GatewayApi apiWith(MockClient client) =>
      GatewayApi(baseUrl: base, adminKey: 'admin-secret', client: client);

  group('鉴权头', () {
    test('所有请求带 Bearer', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('{"stats":{}}', 200,
            headers: {'content-type': 'application/json'});
      });
      await apiWith(client).ping();
      expect(captured.headers['Authorization'], 'Bearer admin-secret');
      expect(captured.headers['Accept'], 'application/json');
      expect(captured.url.toString(), '$base/admin/api/overview');
    });
  });

  group('overview', () {
    test('解析完整响应', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'stats': {'total': 2, 'ok': 1, 'depleted': 1, 'down': 0, 'requestsOk': 10, 'requestsFail': 2},
            'proxies': [
              {'name': 'a', 'url': 'https://a.x', 'status': 'ok', 'maint': false},
              {'name': 'b', 'url': 'https://b.x', 'status': 'depleted', 'maint': false},
            ],
            'events': [{'t': 1724060000000, 'type': 'failover', 'detail': {'name': 'a'}}],
            'routes': [{'t': 1724060000000, 'name': 'a', 'status': 200, 'attempts': 1, 'ms': 5, 'ok': true}],
            'timestamp': '2026-08-19T02:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final ov = await apiWith(client).overview();
      expect(ov.stats.total, 2);
      expect(ov.proxies.length, 2);
      expect(ov.proxies[1].status, 'depleted');
      expect(ov.events.length, 1);
      expect(ov.events.first.type, 'failover');
      expect(ov.routes.length, 1);
      expect(ov.routes.first.ok, isTrue);
      expect(ov.timestamp, isNotNull);
    });
  });

  group('错误处理', () {
    test('网关错误体抛 GatewayException', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'error': {
              'message': 'Invalid admin key',
              'type': 'gateway_error',
              'code': 'invalid_api_key',
              'hint': 'check key',
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      try {
        await apiWith(client).ping();
        fail('应抛出异常');
      } on GatewayException catch (e) {
        expect(e.code, 'invalid_api_key');
        expect(e.status, 401);
        expect(e.message, contains('Invalid admin key'));
      }
    });

    test('非 JSON 错误响应', () async {
      final client = MockClient((req) async => http.Response('Bad Gateway', 502));
      try {
        await apiWith(client).ping();
        fail('应抛出异常');
      } on GatewayException catch (e) {
        expect(e.status, 502);
      }
    });
  });

  group('POST 端点', () {
    test('saveProxies 发送 JSON body 与正确路径', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('{"saved":true}', 200,
            headers: {'content-type': 'application/json'});
      });
      await apiWith(client)
          .saveProxies([ProxyConfig(name: 'a', url: 'https://a.x', apiKey: 'k')]);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/admin/api/config');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['proxies'], hasLength(1));
      expect((body['proxies'] as List).first['apiKey'], 'k');
    });

    test('saveSettings 只带 settings 字段', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('{"saved":true}', 200,
            headers: {'content-type': 'application/json'});
      });
      await apiWith(client).saveSettings({'pinMode': 'header', 'maxAttempts': 3});
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.containsKey('proxies'), isFalse);
      expect((body['settings'] as Map)['pinMode'], 'header');
    });

    test('smoke 请求字段', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
            '{"status":200,"proxy":"a","attempts":1,"ms":10,"ok":true,"content":"hi"}',
            200,
            headers: {'content-type': 'application/json'});
      });
      final r = await apiWith(client).smoke(model: 'm1', prompt: 'hello', stream: true);
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'm1');
      expect(body['prompt'], 'hello');
      expect(body['stream'], isTrue);
      expect(r.ok, isTrue);
      expect(r.content, 'hi');
    });

    test('maintenance 请求字段', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('{"name":"a","maintenance":true}', 200,
            headers: {'content-type': 'application/json'});
      });
      await apiWith(client).setMaintenance('a', true);
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['name'], 'a');
      expect(body['on'], isTrue);
    });
  });

  group('baseUrl 规范化', () {
    test('去尾部斜杠', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('{"stats":{}}', 200,
            headers: {'content-type': 'application/json'});
      });
      final api = GatewayApi(
          baseUrl: 'https://gw.example.com///', adminKey: 'k', client: client);
      await api.ping();
      expect(captured.url.toString(), 'https://gw.example.com/admin/api/overview');
    });
  });

  group('备份导出/导入', () {
    test('exportBundle 生成带版本号 bundle 且 settings 为 camelCase', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/admin/api/config');
        return http.Response(
          jsonEncode({
            'config': {
              'proxies': [
                {'name': 'a', 'url': 'https://a.x', 'apiKey': 'k1', 'remark': 'r'}
              ],
              'pin_mode': 'header',
              'probe_mode': 'scan',
              'pin_ttl': 120,
              'state_ttl': 90,
              'depleted_probe': 300,
              'down_probe': 60,
              'probe_timeout': 5000,
              'chat_timeout': 60000,
              'max_attempts': 4,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final bundle = await apiWith(client).exportBundle();
      expect(bundle['version'], 1);
      expect(bundle['kind'], 'freebuff-gateway-admin-backup');
      expect(bundle['exportedAt'], isA<String>());
      expect(bundle['proxies'], hasLength(1));
      final settings = bundle['settings'] as Map;
      expect(settings['pinMode'], 'header');
      expect(settings['pinTtl'], 120);
      expect(settings.containsKey('pin_mode'), isFalse);
    });

    test('importBundle 空代理列表抛 GatewayException', () async {
      final client = MockClient(
          (req) async => http.Response('{"saved":true}', 200,
              headers: {'content-type': 'application/json'}));
      await expectLater(
        apiWith(client).importBundle({'version': 1, 'proxies': []}),
        throwsA(isA<GatewayException>()),
      );
    });

    test('importBundle 非法 URL 抛 GatewayException', () async {
      final client = MockClient(
          (req) async => http.Response('{"saved":true}', 200,
              headers: {'content-type': 'application/json'}));
      await expectLater(
        apiWith(client).importBundle({
          'version': 1,
          'proxies': [
            {'url': 'ftp://x', 'apiKey': 'k'}
          ]
        }),
        throwsA(isA<GatewayException>()),
      );
    });

    test('importBundle 缺 apiKey 抛 GatewayException', () async {
      final client = MockClient(
          (req) async => http.Response('{"saved":true}', 200,
              headers: {'content-type': 'application/json'}));
      await expectLater(
        apiWith(client).importBundle({
          'version': 1,
          'proxies': [
            {'url': 'https://a.x'}
          ]
        }),
        throwsA(isA<GatewayException>()),
      );
    });

    test('importBundle 不支持的版本抛 GatewayException', () async {
      final client = MockClient(
          (req) async => http.Response('{"saved":true}', 200,
              headers: {'content-type': 'application/json'}));
      await expectLater(
        apiWith(client).importBundle({'version': 2, 'proxies': [{'url': 'https://a.x', 'apiKey': 'k'}]}),
        throwsA(isA<GatewayException>()),
      );
    });

    test('importBundle 成功依次保存 proxies 与 settings', () async {
      final captured = <http.Request>[];
      final client = MockClient((req) async {
        captured.add(req);
        return http.Response('{"saved":true}', 200,
            headers: {'content-type': 'application/json'});
      });
      await apiWith(client).importBundle({
        'version': 1,
        'proxies': [
          {'name': 'a', 'url': 'https://a.x', 'apiKey': 'k'}
        ],
        'settings': {'pinMode': 'client', 'maxAttempts': 3},
      });
      expect(captured, hasLength(2));
      final b1 = jsonDecode(captured[0].body) as Map<String, dynamic>;
      expect(b1.containsKey('proxies'), isTrue);
      final b2 = jsonDecode(captured[1].body) as Map<String, dynamic>;
      expect((b2['settings'] as Map)['pinMode'], 'client');
      expect((b2['settings'] as Map)['maxAttempts'], 3);
    });

    test('importBundle 非法/越界 settings 在写入前即抛异常（原子性）', () async {
      var requests = 0;
      final client = MockClient((req) async {
        requests++;
        return http.Response('{"saved":true}', 200,
            headers: {'content-type': 'application/json'});
      });
      Future<void> run(Map<String, dynamic> settings) => apiWith(client)
          .importBundle({
            'version': 1,
            'proxies': [
              {'url': 'https://a.x', 'apiKey': 'k'}
            ],
            'settings': settings,
          });
      await expectLater(
          run({'pinMode': 'bogus'}), throwsA(isA<GatewayException>()));
      await expectLater(
          run({'probeMode': 'invalid'}), throwsA(isA<GatewayException>()));
      await expectLater(
          run({'maxAttempts': 99}), throwsA(isA<GatewayException>()));
      await expectLater(
          run({'maxAttempts': 0}), throwsA(isA<GatewayException>()));
      await expectLater(
          run({'pinTtl': 1}), throwsA(isA<GatewayException>()));
      await expectLater(
          run({'probeTimeout': 100}), throwsA(isA<GatewayException>()));
      expect(requests, 0); // 所有非法输入都未触发任何网络写入
    });
  });
}
