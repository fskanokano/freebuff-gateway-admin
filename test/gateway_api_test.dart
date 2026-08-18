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
}
