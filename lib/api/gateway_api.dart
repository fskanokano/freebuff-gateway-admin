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
    try {
      final resp =
          await _client.get(_uri(path), headers: _headers).timeout(_timeout);
      return _decode(resp);
    } on GatewayException {
      rethrow;
    } catch (e) {
      throw _asNetworkError(e);
    }
  }

  /// 统一 POST。
  Future<Map<String, dynamic>> _post(String path, [Object? body]) async {
    try {
      final resp = await _client
          .post(_uri(path),
              headers: _headers, body: body == null ? null : jsonEncode(body))
          .timeout(_timeout);
      return _decode(resp);
    } on GatewayException {
      rethrow;
    } catch (e) {
      throw _asNetworkError(e);
    }
  }

  /// 网络/超时异常 → GatewayException，统一 UI 提示（不泄漏原始 SocketException 文本）。
  GatewayException _asNetworkError(Object e) {
    if (e is TimeoutException) {
      return GatewayException('请求超时（30s 无响应）', code: 'timeout');
    }
    return GatewayException('网络不可达或连接失败', code: 'network_error');
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

  /// 导出配置备份 bundle（含明文 proxy apiKey，UI 需警告用户勿外传）。
  Future<Map<String, dynamic>> exportBundle() async {
    final cfg = await config();
    return {
      'version': 1,
      'kind': 'freebuff-gateway-admin-backup',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'proxies': cfg.proxies.map((p) => p.toJson()).toList(),
      'settings': _settingsToCamel(cfg),
    };
  }

  /// 导入备份 bundle：先本地校验，再 saveProxies + saveSettings（沿用"部分保存"语义，
  /// 避免整体替换）。校验失败抛 GatewayException(code=invalid_bundle)。
  Future<void> importBundle(Map<String, dynamic> bundle) async {
    if (bundle['version'] is! int || bundle['version'] != 1) {
      throw GatewayException('不支持的备份版本（需 version=1）', code: 'invalid_bundle');
    }
    final proxies = _parseBundleProxies(bundle);
    final settings = _parseBundleSettings(bundle);
    await saveProxies(proxies);
    if (settings.isNotEmpty) await saveSettings(settings);
  }

  static Map<String, dynamic> _settingsToCamel(GatewayConfig c) => {
        if (c.pinMode != null) 'pinMode': c.pinMode,
        if (c.probeMode != null) 'probeMode': c.probeMode,
        if (c.pinTtl != null) 'pinTtl': c.pinTtl,
        if (c.stateTtl != null) 'stateTtl': c.stateTtl,
        if (c.depletedProbe != null) 'depletedProbe': c.depletedProbe,
        if (c.downProbe != null) 'downProbe': c.downProbe,
        if (c.probeTimeout != null) 'probeTimeout': c.probeTimeout,
        if (c.chatTimeout != null) 'chatTimeout': c.chatTimeout,
        if (c.maxAttempts != null) 'maxAttempts': c.maxAttempts,
      };

  static List<ProxyConfig> _parseBundleProxies(Map<String, dynamic> bundle) {
    final raw = bundle['proxies'];
    if (raw is! List || raw.isEmpty) {
      throw GatewayException('备份缺少代理列表（proxies 必须为非空数组）', code: 'invalid_bundle');
    }
    final seen = <String>{};
    final seenUrls = <String>{};
    final out = <ProxyConfig>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) {
        throw GatewayException('代理 #${i + 1} 格式非法', code: 'invalid_bundle');
      }
      final m = item.cast<String, dynamic>();
      final url = (m['url']?.toString() ?? '').replaceAll(RegExp(r'/+$'), '');
      if (!RegExp(r'^https?://[^/]+').hasMatch(url)) {
        throw GatewayException('代理 #${i + 1}: URL 非法（需 http(s)://）', code: 'invalid_bundle');
      }
      final apiKey = m['apiKey']?.toString() ?? '';
      if (apiKey.isEmpty) {
        throw GatewayException('代理 #${i + 1}: 缺少 apiKey', code: 'invalid_bundle');
      }
      final rawName = (m['name']?.toString() ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9-]'), '');
      final name = rawName.isEmpty ? 'p${i + 1}' : rawName;
      if (seen.contains(name)) {
        throw GatewayException('代理名称重复: $name', code: 'invalid_bundle');
      }
      if (seenUrls.contains(url)) {
        throw GatewayException('代理 URL 重复: $url', code: 'invalid_bundle');
      }
      seen.add(name);
      seenUrls.add(url);
      out.add(ProxyConfig(
        name: name,
        url: url,
        apiKey: apiKey,
        remark: m['remark']?.toString(),
      ));
    }
    return out;
  }

  static Map<String, dynamic> _parseBundleSettings(Map<String, dynamic> bundle) {
    final raw = bundle['settings'];
    if (raw == null) return <String, dynamic>{};
    if (raw is! Map) {
      throw GatewayException('settings 必须是对象', code: 'invalid_bundle');
    }
    final s = raw.cast<String, dynamic>();
    final out = <String, dynamic>{};

    // 枚举校验（与后端 /admin/api/config 校验矩阵一致）。
    final pinMode = s['pinMode']?.toString();
    if (pinMode != null && pinMode.isNotEmpty) {
      if (!const {'client', 'header', 'off'}.contains(pinMode)) {
        throw GatewayException('pinMode 非法（需 client/header/off）',
            code: 'invalid_bundle');
      }
      out['pinMode'] = pinMode;
    }
    final probeMode = s['probeMode']?.toString();
    if (probeMode != null && probeMode.isNotEmpty) {
      if (!const {'smart', 'scan'}.contains(probeMode)) {
        throw GatewayException('probeMode 非法（需 smart/scan）',
            code: 'invalid_bundle');
      }
      out['probeMode'] = probeMode;
    }

    // 整数范围校验（与后端校验矩阵一致）。
    int parseInt(Object? v, String label) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return n;
      }
      throw GatewayException('$label 非法（需整数）', code: 'invalid_bundle');
    }

    const specs = <String, (String, int, int?)>{
      'pinTtl': ('pinTtl', 60, null),
      'stateTtl': ('stateTtl', 60, null),
      'depletedProbe': ('depletedProbe', 60, null),
      'downProbe': ('downProbe', 30, null),
      'probeTimeout': ('probeTimeout', 500, null),
      'chatTimeout': ('chatTimeout', 1000, null),
      'maxAttempts': ('maxAttempts', 1, 6),
    };
    for (final e in specs.entries) {
      final v = s[e.key];
      if (v == null) continue;
      final (label, min, max) = e.value;
      final n = parseInt(v, label);
      if (n < min || (max != null && n > max)) {
        throw GatewayException(
          max == null ? '$label 越界（需 ≥ $min）' : '$label 越界（需 $min-$max）',
          code: 'invalid_bundle',
        );
      }
      out[e.key] = n;
    }
    return out;
  }

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
