/// FreeBuff Gateway Admin — 网关 API 客户端。
/// 对应 worker.js 的 /admin/api/* 契约，鉴权用 `Authorization: Bearer <ADMIN_KEY or API_KEY>`。
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class GatewayApi {
  GatewayApi({required this.baseUrl, required this.adminKey, http.Client? client})
      : _client = client ?? http.Client() {
    _base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  final String baseUrl;
  final String adminKey;
  final http.Client _client;
  late final String _base;

  static const _timeout = Duration(seconds: 30);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $adminKey',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Uri _uri(String path) => Uri.parse('$_base$path');

  /// 统一 GET。
  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await _client.get(_uri(path), headers: _headers).timeout(_timeout);
    return _decode(resp);
  }

  /// 统一 POST。
  Future<Map<String, dynamic>> _post(String path, [Object? body]) async {
    final resp = await _client
        .post(_uri(path),
            headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout);
    return _decode(resp);
  }

  /// 解析响应；非 2xx 且带 error 体时抛 GatewayException。
  Map<String, dynamic> _decode(http.Response resp) {
    Map<String, dynamic> json = {};
    try {
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is Map) json = decoded.cast<String, dynamic>();
    } catch (_) {
      // 非 JSON 响应（如网关 5xx 纯文本）
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) return json;
    final err = json['error'];
    if (err is Map) {
      throw GatewayException(
        '${err['message'] ?? '请求失败'}',
        code: err['code'] is String ? err['code'] as String : null,
        status: resp.statusCode,
        hint: err['hint'] is String ? err['hint'] as String : null,
      );
    }
    throw GatewayException('HTTP ${resp.statusCode}', status: resp.statusCode);
  }

  // ─────────────────────────── 端点 ───────────────────────────

  /// 总览：统计 + 代理状态 + 事件 + 路由记录。
  Future<OverviewData> overview() async {
    final j = await _get('/admin/api/overview');
    return OverviewData(
      stats: GatewayStats.fromJson(j['stats'] is Map
          ? j['stats'].cast<String, dynamic>()
          : null),
      proxies: (j['proxies'] is List)
          ? (j['proxies'] as List)
              .whereType<Map>()
              .map((e) => ProxyInfo.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <ProxyInfo>[],
      events: (j['events'] is List)
          ? (j['events'] as List)
              .whereType<Map>()
              .map((e) => EventEntry.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <EventEntry>[],
      routes: (j['routes'] is List)
          ? (j['routes'] as List)
              .whereType<Map>()
              .map((e) => RouteEntry.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <RouteEntry>[],
      timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? '')?.toLocal(),
    );
  }

  /// 生效配置（含完整 proxy apiKey，仅授权可见）。
  Future<GatewayConfig> config() async =>
      GatewayConfig.fromJson(await _get('/admin/api/config'));

  /// 模型聚合列表。
  Future<List<ModelInfo>> models() async {
    final j = await _get('/admin/api/models');
    return (j['data'] is List)
        ? (j['data'] as List)
            .whereType<Map>()
            .map((e) => ModelInfo.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <ModelInfo>[];
  }

  /// 保存代理列表（部分保存：只更新 proxies 字段）。
  Future<void> saveProxies(List<ProxyConfig> proxies) async {
    await _post('/admin/api/config', {'proxies': proxies.map((p) => p.toJson()).toList()});
  }

  /// 保存参数（部分保存：只更新 settings 里的字段）。
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _post('/admin/api/config', {'settings': settings});
  }

  /// 清除运行时配置，恢复环境变量。
  Future<void> resetConfig() async {
    await _post('/admin/api/config/reset');
  }

  /// 强制探测（name 为空则全部）。
  Future<List<ProbeResult>> probe({String? name}) async {
    final j = await _post('/admin/api/probe', name == null ? {} : {'name': name});
    return (j['results'] is List)
        ? (j['results'] as List)
            .whereType<Map>()
            .map((e) => ProbeResult.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <ProbeResult>[];
  }

  /// 出口 IP 探测：聚合各代理的 /egress/ip；name 非空时只探测单个代理。
  Future<List<EgressInfo>> egress({String? name}) async {
    final path = (name == null || name.isEmpty)
        ? '/admin/api/egress'
        : '/admin/api/egress?name=${Uri.encodeComponent(name)}';
    final j = await _get(path);
    return (j['results'] is List)
        ? (j['results'] as List)
            .whereType<Map>()
            .map((e) => EgressInfo.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <EgressInfo>[];
  }

  /// 清空日志。
  Future<void> clearLogs() async {
    await _post('/admin/api/logs/clear');
  }

  /// 维护开关。
  Future<void> setMaintenance(String name, bool on) async {
    await _post('/admin/api/maintenance', {'name': name, 'on': on});
  }

  /// 解除钉住（按客户端 sticky key）。
  Future<void> clearPin(String key) async {
    await _post('/admin/api/pin', {'key': key});
  }

  /// 当前会话钉住状态 + 最近路由。
  Future<PinStatus> pinStatus() async => PinStatus.fromJson(await _get('/admin/api/pin'));

  /// smoke 测试：走完整链路发真实请求。
  Future<SmokeResult> smoke({String? model, String prompt = 'ping', bool stream = false}) async {
    final j = await _post('/admin/api/smoke', {
      if (model != null && model.isNotEmpty) 'model': model,
      'prompt': prompt,
      'stream': stream,
    });
    return SmokeResult.fromJson(j);
  }

  /// 验证连接（供登录/设置页）：成功返回网关统计，失败抛异常。
  Future<GatewayStats> ping() async {
    final j = await _get('/admin/api/overview');
    return GatewayStats.fromJson(
        j['stats'] is Map ? j['stats'].cast<String, dynamic>() : null);
  }

  void dispose() => _client.close();
}

/// overview 完整响应。
class OverviewData {
  OverviewData({
    GatewayStats? stats,
    this.proxies = const [],
    this.events = const [],
    this.routes = const [],
    this.timestamp,
  }) : stats = stats ?? GatewayStats();

  final GatewayStats stats;
  final List<ProxyInfo> proxies;
  final List<EventEntry> events;
  final List<RouteEntry> routes;
  final DateTime? timestamp;
}
