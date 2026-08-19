import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_admin/models/models.dart';

void main() {
  group('ProxyInfo', () {
    test('解析完整字段', () {
      final j = {
        'name': 'proxy-a',
        'url': 'https://a.example.com',
        'remark': '主线路',
        'status': 'ok',
        'maint': false,
        'reason': '',
        'detail': '',
        'score': 12.5,
        'usage_pct': 34.2,
        'daily_limit': 100,
        'messages_24h': 34,
        'requestsOk': 12,
        'requestsFail': 3,
        'consecutive_errors': 0,
        'quota': {
          'freebuff-1': {
            'limit': 50,
            'recent_count': 20,
            'reset_at': '2026-08-19T12:00:00Z',
            'period': '24h',
          }
        },
      };
      final p = ProxyInfo.fromJson(j);
      expect(p.name, 'proxy-a');
      expect(p.status, 'ok');
      expect(p.remark, '主线路');
      expect(p.isOk, isTrue);
      expect(p.score, 12.5);
      expect(p.usagePct, 34.2);
      expect(p.requestsOk, 12);
      expect(p.quota['freebuff-1']!.limit, 50);
      expect(p.quota['freebuff-1']!.recentCount, 20);
      expect(p.quota['freebuff-1']!.usagePercent, closeTo(40, 0.01));
    });

    test('缺失字段容错', () {
      final p = ProxyInfo.fromJson({'name': 'x'});
      expect(p.status, 'unknown');
      expect(p.maint, isFalse);
      expect(p.score, isNull);
      expect(p.quota, isEmpty);
      expect(p.isOk, isFalse);
      expect(p.isDown, isFalse);
    });

    test('维护状态优先', () {
      final p = ProxyInfo.fromJson({'name': 'x', 'status': 'ok', 'maint': true});
      expect(p.isOk, isFalse);
      expect(p.status, 'ok'); // 原始 status 保留，展示层用 maint 徽标
    });

    test('解析扩展字段（spend/tier/country）', () {
      final p = ProxyInfo.fromJson({
        'name': 'x',
        'spend_24h': 1.5,
        'spend_week': 10.25,
        'spend_month': 45.0,
        'tier': 'plus',
        'country': 'US',
      });
      expect(p.spend24h, 1.5);
      expect(p.spendWeek, 10.25);
      expect(p.spendMonth, 45.0);
      expect(p.tier, 'plus');
      expect(p.country, 'US');
    });

    test('扩展字段缺失容错', () {
      final p = ProxyInfo.fromJson({'name': 'x'});
      expect(p.spend24h, isNull);
      expect(p.spendWeek, isNull);
      expect(p.spendMonth, isNull);
      expect(p.tier, isNull);
      expect(p.country, isNull);
    });
  });

  group('GatewayStats', () {
    test('统计解析', () {
      final s = GatewayStats.fromJson({
        'total': 3, 'ok': 2, 'depleted': 1, 'down': 0,
        'requestsOk': 99, 'requestsFail': 1,
      });
      expect(s.total, 3);
      expect(s.ok, 2);
      expect(s.depleted, 1);
      expect(s.down, 0);
      expect(s.requestsOk, 99);
      expect(s.requestsFail, 1);
    });

    test('空统计默认值', () {
      final s = GatewayStats.fromJson(null);
      expect(s.total, 0);
      expect(s.ok, 0);
    });
  });

  group('EventEntry', () {
    test('解析 detail 与类型', () {
      final e = EventEntry.fromJson({
        't': 1724060000000,
        'type': 'failover',
        'detail': {'name': 'p1', 'from': 'ok', 'to': 'depleted', 'code': 'rate_limited', 'status': 429},
      });
      expect(e.type, 'failover');
      expect(e.detail['code'], 'rate_limited');
      expect(e.t.millisecondsSinceEpoch, 1724060000000);
    });

    test('detail 字段展开在顶层时也能解析（网关真实格式）', () {
      // pushEvent: {t, type, ...detail} — detail 直接展开在顶层
      final e = EventEntry.fromJson({
        't': 1724060000000,
        'type': 'status_change',
        'name': 'proxy-a',
        'from': 'ok',
        'to': 'depleted',
        'reason': 'rate_limited',
        'detail': '429 from upstream',
      });
      expect(e.detail['name'], 'proxy-a');
      expect(e.detail['from'], 'ok');
      expect(e.detail['to'], 'depleted');
      expect(e.detail['reason'], 'rate_limited');
      expect(e.detail['detail'], '429 from upstream');
    });

    test('缺失字段容错', () {
      final e = EventEntry.fromJson({'t': 1, 'type': 'x'});
      expect(e.detail, isEmpty);
    });
  });

  group('RouteEntry', () {
    test('解析路由记录', () {
      final r = RouteEntry.fromJson({
        't': '2026-08-19T10:00:00+08:00',
        'name': 'p1',
        'status': 200,
        'attempts': 1,
        'ms': 123,
        'model': 'freebuff-1',
        'ok': true,
      });
      expect(r.name, 'p1');
      expect(r.ok, isTrue);
      expect(r.status, 200);
      expect(r.model, 'freebuff-1');
    });
  });

  group('PinStatus', () {
    test('解析最近路由并截断 5 条', () {
      final j = {
        'pin_mode': 'client',
        'sticky_key': 'k1',
        'pinned_proxy': 'p2',
        'recent_proxies': [
          for (var i = 0; i < 8; i++)
            {'name': 'p$i', 'lastUsed': 1724060000000 - i * 1000, 'requestsOk': i},
        ],
      };
      final s = PinStatus.fromJson(j);
      expect(s.pinnedProxy, 'p2');
      expect(s.stickyKey, 'k1');
      expect(s.recentProxies.length, 5);
      expect(s.recentProxies.first.name, 'p0');
    });
  });

  group('SmokeResult', () {
    test('解析成功结果', () {
      final r = SmokeResult.fromJson({
        'status': 200, 'proxy': 'p1', 'attempts': 1, 'ms': 500,
        'ok': true, 'content': 'hi', 'error': '',
      });
      expect(r.ok, isTrue);
      expect(r.proxy, 'p1');
      expect(r.content, 'hi');
    });

    test('解析失败结果', () {
      final r = SmokeResult.fromJson({
        'status': 429, 'ok': false, 'error': 'rate_limited', 'ms': 10,
      });
      expect(r.ok, isFalse);
      expect(r.error, 'rate_limited');
    });
  });

  group('GatewayConfig', () {
    test('解析配置（含 apiKey）', () {
      final j = {
        'config': {
          'proxies': [
            {'name': 'a', 'url': 'https://a.x', 'apiKey': 'sk-123'},
            {'name': 'b', 'url': 'https://b.x', 'apiKey': 'sk-456'},
          ],
          'pin_mode': 'header',
          'probe_mode': 'smart',
          'pin_ttl': 3600,
          'max_attempts': 3,
          'admin_uses_api_key': false,
          'admin_key_masked': 'ab***cd',
          'runtime_managed': true,
          'has_runtime_config': true,
        }
      };
      final c = GatewayConfig.fromJson(j);
      expect(c.proxies.length, 2);
      expect(c.proxies[0].apiKey, 'sk-123');
      expect(c.pinMode, 'header');
      expect(c.pinTtl, 3600);
      expect(c.runtimeManaged, isTrue);
      expect(c.adminKeyMasked, 'ab***cd');
    });

    test('toJson/fromJson 往返（可保存字段）', () {
      final c = GatewayConfig(
        proxies: [
          ProxyConfig(name: 'p1', url: 'https://a.x', apiKey: 'secret', remark: '主线路'),
        ],
        pinMode: 'header',
        probeMode: 'scan',
        pinTtl: 120,
        stateTtl: 90,
        depletedProbe: 300,
        downProbe: 60,
        probeTimeout: 5000,
        chatTimeout: 60000,
        maxAttempts: 4,
      );
      final round = GatewayConfig.fromJson(c.toJson());
      expect(round.proxies.length, 1);
      expect(round.proxies.first.name, 'p1');
      expect(round.proxies.first.apiKey, 'secret');
      expect(round.proxies.first.remark, '主线路');
      expect(round.pinMode, 'header');
      expect(round.probeMode, 'scan');
      expect(round.pinTtl, 120);
      expect(round.stateTtl, 90);
      expect(round.depletedProbe, 300);
      expect(round.downProbe, 60);
      expect(round.probeTimeout, 5000);
      expect(round.chatTimeout, 60000);
      expect(round.maxAttempts, 4);
    });
  });

  group('工具', () {

    test('ProxyConfig toJson 往返', () {
      final p = ProxyConfig(name: 'a', url: 'https://a.x', apiKey: 'k', remark: '备用');
      final j = jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;
      expect(j['name'], 'a');
      expect(j['apiKey'], 'k');
      expect(j['remark'], '备用');
    });

    test('ProxyConfig 空备注不序列化', () {
      final p = ProxyConfig(name: 'a', url: 'https://a.x', apiKey: 'k');
      final j = jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;
      expect(j.containsKey('remark'), isFalse);
    });
  });
}
