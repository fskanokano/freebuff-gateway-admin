/// FreeBuff Gateway Admin — 数据模型。
/// 所有解析都是容错的：字段缺失/类型不符时使用默认值，绝不因单个字段异常导致页面崩溃。
library;

/// API 错误（网关统一返回 `{error:{message,type,code,hint}}`）。
class GatewayException implements Exception {
  GatewayException(this.message, {this.code, this.status, this.hint});

  final String message;
  final String? code;
  final int? status;
  final String? hint;

  @override
  String toString() =>
      code != null ? '[$code] $message' : message;
}

/// 代理配额（per-model）。
class QuotaInfo {
  QuotaInfo({
    this.limit,
    this.recentCount,
    this.resetAt,
    this.period,
  });

  final int? limit;
  final int? recentCount;
  final DateTime? resetAt;
  final String? period;

  factory QuotaInfo.fromJson(Map<String, dynamic>? j) {
    if (j == null) return QuotaInfo();
    return QuotaInfo(
      limit: _asInt(j['limit']),
      recentCount: _asInt(j['recent_count']),
      resetAt: _asDt(j['reset_at']),
      period: _asStr(j['period']),
    );
  }

  /// 用量百分比（0-100+）。limit 缺失时返回 null。
  double? get usagePercent {
    final l = limit;
    final r = recentCount;
    if (l == null || l <= 0 || r == null) return null;
    return (r / l * 100);
  }

  Map<String, dynamic> toJson() => {
        'limit': limit,
        'recent_count': recentCount,
        'reset_at': resetAt?.toIso8601String(),
        'period': period,
      };
}

/// 单个代理状态（来自 /admin/api/overview 的 proxies 数组）。
class ProxyInfo {
  ProxyInfo({
    required this.name,
    required this.url,
    required this.status,
    required this.maint,
    this.remark,
    this.reason = '',
    this.detail = '',
    this.score,
    this.usagePct,
    this.dailyLimit,
    this.messages24h,
    this.spendPct,
    this.spendLimit,
    this.spendDay,
    this.spendLimited,
    this.mode,
    this.bridgeTokens,
    this.risk,
    this.cooldownUntil,
    this.resetAt,
    this.retryAfterS,
    this.nextProbe,
    this.lastOk,
    this.lastError,
    this.consecutiveErrors = 0,
    this.requestsOk = 0,
    this.requestsFail = 0,
    this.quota = const {},
  });

  final String name;
  final String url;
  /// 可选备注（后台保存的代理备注）。
  final String? remark;
  /// ok / depleted / down / bad_config / maint / unknown
  final String status;
  final bool maint;
  final String reason;
  final String detail;
  final double? score;
  final double? usagePct;
  final int? dailyLimit;
  final int? messages24h;
  final double? spendPct;
  final double? spendLimit;
  final double? spendDay;
  final bool? spendLimited;
  final String? mode;
  final int? bridgeTokens;
  final String? risk;
  final DateTime? cooldownUntil;
  final DateTime? resetAt;
  final int? retryAfterS;
  final DateTime? nextProbe;
  final DateTime? lastOk;
  final DateTime? lastError;
  final int consecutiveErrors;
  final int requestsOk;
  final int requestsFail;
  final Map<String, QuotaInfo> quota;

  factory ProxyInfo.fromJson(Map<String, dynamic> j) {
    final quotaRaw = (j['quota'] is Map)
        ? (j['quota'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return ProxyInfo(
      name: _asStr(j['name']) ?? '?',
      url: _asStr(j['url']) ?? '',
      remark: _asStr(j['remark']),
      status: _asStr(j['status']) ?? 'unknown',
      maint: j['maint'] == true,
      reason: _asStr(j['reason']) ?? '',
      detail: _asStr(j['detail']) ?? '',
      score: _asNum(j['score']),
      usagePct: _asNum(j['usage_pct']),
      dailyLimit: _asInt(j['daily_limit']),
      messages24h: _asInt(j['messages_24h']),
      spendPct: _asNum(j['spend_pct']),
      spendLimit: _asNum(j['spend_limit']),
      spendDay: _asNum(j['spend_day']),
      spendLimited: j['spend_limited'] == true,
      mode: _asStr(j['mode']),
      bridgeTokens: _asInt(j['bridge_tokens']),
      risk: _asStr(j['risk']),
      cooldownUntil: _asDt(j['cooldown_until']),
      resetAt: _asDt(j['reset_at']),
      retryAfterS: _asInt(j['retry_after_s']),
      nextProbe: _asDt(j['next_probe']),
      lastOk: _asDt(j['last_ok']),
      lastError: _asDt(j['last_error']),
      consecutiveErrors: _asInt(j['consecutive_errors']) ?? 0,
      requestsOk: _asInt(j['requestsOk']) ?? 0,
      requestsFail: _asInt(j['requestsFail']) ?? 0,
      quota: quotaRaw.map((k, v) =>
          MapEntry(k, QuotaInfo.fromJson(v is Map ? v.cast<String, dynamic>() : null))),
    );
  }

  bool get isOk => !maint && status == 'ok';
  bool get isDepleted => !maint && status == 'depleted';
  bool get isDown => !maint && (status == 'down' || status == 'bad_config');
}

/// 总览统计（来自 /admin/api/overview 的 stats）。
class GatewayStats {
  GatewayStats({
    this.total = 0,
    this.ok = 0,
    this.depleted = 0,
    this.down = 0,
    this.requestsOk = 0,
    this.requestsFail = 0,
  });

  final int total;
  final int ok;
  final int depleted;
  final int down;
  final int requestsOk;
  final int requestsFail;

  factory GatewayStats.fromJson(Map<String, dynamic>? j) {
    if (j == null) return GatewayStats();
    return GatewayStats(
      total: _asInt(j['total']) ?? 0,
      ok: _asInt(j['ok']) ?? 0,
      depleted: _asInt(j['depleted']) ?? 0,
      down: _asInt(j['down']) ?? 0,
      requestsOk: _asInt(j['requestsOk']) ?? 0,
      requestsFail: _asInt(j['requestsFail']) ?? 0,
    );
  }
}

/// 系统事件日志条目。
class EventEntry {
  EventEntry({
    required this.t,
    required this.type,
    this.detail = const {},
  });

  final DateTime t;
  final String type;
  final Map<String, dynamic> detail;

  factory EventEntry.fromJson(Map<String, dynamic> j) {
    // 网关事件格式: pushEvent 把 detail 字段展开在顶层 ({t, type, ...detail})
    // 而非嵌套对象 —— 误找 j['detail'] 会导致所有事件字段丢失
    final detail = <String, dynamic>{};
    for (final e in j.entries) {
      final k = e.key;
      if (k == 't' || k == 'time' || k == 'type') continue;
      if (e.value != null) detail[k] = e.value;
    }
    // 兼容嵌套 detail 对象格式
    if (j['detail'] is Map) {
      final nested = (j['detail'] as Map).cast<String, dynamic>();
      nested.forEach((k, v) {
        if (v != null) detail[k] = v;
      });
    }
    return EventEntry(
      t: _asDt(j['t']) ?? _asDt(j['time']) ?? DateTime.now(),
      type: _asStr(j['type']) ?? 'unknown',
      detail: detail,
    );
  }
}

/// 路由记录条目（每次请求一条）。
class RouteEntry {
  RouteEntry({
    required this.t,
    this.name = '',
    this.status = 0,
    this.attempts = 1,
    this.ms = 0,
    this.model,
    this.ok = false,
  });

  final DateTime t;
  final String name;
  final int status;
  final int attempts;
  final int ms;
  final String? model;
  final bool ok;

  factory RouteEntry.fromJson(Map<String, dynamic> j) {
    return RouteEntry(
      t: _asDt(j['t']) ?? DateTime.now(),
      name: _asStr(j['name']) ?? '',
      status: _asInt(j['status']) ?? 0,
      attempts: _asInt(j['attempts']) ?? 1,
      ms: _asInt(j['ms']) ?? 0,
      model: _asStr(j['model']),
      ok: j['ok'] == true,
    );
  }
}

/// 常驻/最近路由状态（GET /admin/api/pin）。
class PinStatus {
  PinStatus({
    this.pinMode,
    this.stickyKey,
    this.pinnedProxy,
    this.recentProxies = const [],
  });

  final String? pinMode;
  final String? stickyKey;
  final String? pinnedProxy;
  final List<RecentProxy> recentProxies;

  factory PinStatus.fromJson(Map<String, dynamic> j) {
    return PinStatus(
      pinMode: _asStr(j['pin_mode']),
      stickyKey: _asStr(j['sticky_key']),
      pinnedProxy: _asStr(j['pinned_proxy']),
      recentProxies: ((j['recent_proxies'] is List)
              ? (j['recent_proxies'] as List)
                  .whereType<Map>()
                  .map((e) => RecentProxy.fromJson(e.cast<String, dynamic>()))
                  .toList()
              : <RecentProxy>[])
          .take(5)
          .toList(),
    );
  }
}

class RecentProxy {
  RecentProxy({required this.name, this.lastUsed, this.requestsOk = 0});

  final String name;
  final DateTime? lastUsed;
  final int requestsOk;

  factory RecentProxy.fromJson(Map<String, dynamic> j) => RecentProxy(
        name: _asStr(j['name']) ?? '?',
        lastUsed: _asDt(j['lastUsed']),
        requestsOk: _asInt(j['requestsOk']) ?? 0,
      );
}

/// 探测结果（POST /admin/api/probe）。
class ProbeResult {
  ProbeResult({required this.name, this.status, this.detail});

  final String name;
  final String? status;
  final String? detail;

  factory ProbeResult.fromJson(Map<String, dynamic> j) => ProbeResult(
        name: _asStr(j['name']) ?? '?',
        status: _asStr(j['status']),
        detail: _asStr(j['detail']),
      );
}

/// 模型信息（GET /admin/api/models）。
class ModelInfo {
  ModelInfo({required this.id, this.ok = 0, this.statuses = const {}, this.tiers = const {}});

  final String id;
  final int ok;
  final Map<String, int> statuses;
  final Map<String, int> tiers;

  factory ModelInfo.fromJson(Map<String, dynamic> j) {
    final st = (j['statuses'] is Map)
        ? (j['statuses'] as Map).cast<String, dynamic>().map((k, v) => MapEntry(k, _asInt(v) ?? 0))
        : <String, int>{};
    final ti = (j['tiers'] is Map)
        ? (j['tiers'] as Map).cast<String, dynamic>().map((k, v) => MapEntry(k, _asInt(v) ?? 0))
        : <String, int>{};
    return ModelInfo(
      id: _asStr(j['id']) ?? '?',
      ok: _asInt(j['ok']) ?? 0,
      statuses: st,
      tiers: ti,
    );
  }
}

/// smoke 测试结果（POST /admin/api/smoke）。
class SmokeResult {
  SmokeResult({
    required this.ok,
    required this.status,
    this.proxy,
    this.attempts = 1,
    this.ms = 0,
    this.content = '',
    this.error = '',
  });

  final bool ok;
  final int status;
  final String? proxy;
  final int attempts;
  final int ms;
  final String content;
  final String error;

  factory SmokeResult.fromJson(Map<String, dynamic> j) => SmokeResult(
        ok: j['ok'] == true,
        status: _asInt(j['status']) ?? 0,
        proxy: _asStr(j['proxy']),
        attempts: _asInt(j['attempts']) ?? 1,
        ms: _asInt(j['ms']) ?? 0,
        content: _asStr(j['content']) ?? '',
        error: _asStr(j['error']) ?? '',
      );
}

/// 生效配置（GET /admin/api/config）。
class GatewayConfig {
  GatewayConfig({
    this.proxies = const [],
    this.pinMode,
    this.probeMode,
    this.pinTtl,
    this.stateTtl,
    this.depletedProbe,
    this.downProbe,
    this.probeTimeout,
    this.chatTimeout,
    this.maxAttempts,
    this.adminUsesApiKey = false,
    this.apiKeyMasked,
    this.adminKeyMasked,
    this.proxyKeysMasked,
    this.runtimeManaged = false,
    this.hasRuntimeConfig = false,
    this.runtimeError,
  });

  final List<ProxyConfig> proxies;
  final String? pinMode;
  final String? probeMode;
  final int? pinTtl;
  final int? stateTtl;
  final int? depletedProbe;
  final int? downProbe;
  final int? probeTimeout;
  final int? chatTimeout;
  final int? maxAttempts;
  final bool adminUsesApiKey;
  final String? apiKeyMasked;
  final String? adminKeyMasked;
  final String? proxyKeysMasked;
  final bool runtimeManaged;
  final bool hasRuntimeConfig;
  final String? runtimeError;

  factory GatewayConfig.fromJson(Map<String, dynamic> j) {
    final c = (j['config'] is Map) ? j['config'].cast<String, dynamic>() : j;
    return GatewayConfig(
      proxies: (c['proxies'] is List)
          ? (c['proxies'] as List)
              .whereType<Map>()
              .map((e) => ProxyConfig.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <ProxyConfig>[],
      pinMode: _asStr(c['pin_mode']),
      probeMode: _asStr(c['probe_mode']),
      pinTtl: _asInt(c['pin_ttl']),
      stateTtl: _asInt(c['state_ttl']),
      depletedProbe: _asInt(c['depleted_probe']),
      downProbe: _asInt(c['down_probe']),
      probeTimeout: _asInt(c['probe_timeout']),
      chatTimeout: _asInt(c['chat_timeout']),
      maxAttempts: _asInt(c['max_attempts']),
      adminUsesApiKey: c['admin_uses_api_key'] == true,
      apiKeyMasked: _asStr(c['api_key_masked']),
      adminKeyMasked: _asStr(c['admin_key_masked']),
      proxyKeysMasked: _asStr(c['proxy_keys_masked']),
      runtimeManaged: c['runtime_managed'] == true,
      hasRuntimeConfig: c['has_runtime_config'] == true,
      runtimeError: _asStr(c['runtime_error']),
    );
  }
}

/// 代理配置项（config.proxies / 编辑表单用）。
class ProxyConfig {
  ProxyConfig({required this.name, required this.url, this.apiKey = '', this.remark});

  final String name;
  final String url;
  final String apiKey;
  /// 可选备注。
  final String? remark;

  factory ProxyConfig.fromJson(Map<String, dynamic> j) => ProxyConfig(
        name: _asStr(j['name']) ?? '',
        url: _asStr(j['url']) ?? '',
        apiKey: _asStr(j['apiKey']) ?? '',
        remark: _asStr(j['remark']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'apiKey': apiKey,
        if (remark != null && remark!.trim().isNotEmpty) 'remark': remark!.trim(),
      };
}

/// 出口 IP 探测结果（来自 /admin/api/egress 的 results[]）。
class EgressInfo {
  EgressInfo({
    this.name,
    this.url,
    this.ok = false,
    this.cached = false,
    this.ip,
    this.country,
    this.countryName,
    this.region,
    this.city,
    this.provider,
    this.error,
  });

  final String? name;
  final String? url;
  final bool ok;
  final bool cached;
  final String? ip;
  final String? country;
  final String? countryName;
  final String? region;
  final String? city;
  final String? provider;
  final String? error;

  factory EgressInfo.fromJson(Map<String, dynamic> j) => EgressInfo(
        name: _asStr(j['name']),
        url: _asStr(j['url']),
        ok: j['ok'] == true,
        cached: j['cached'] == true,
        ip: _asStr(j['ip']),
        country: _asStr(j['country']),
        countryName: _asStr(j['country_name']),
        region: _asStr(j['region']),
        city: _asStr(j['city']),
        provider: _asStr(j['provider']),
        error: _asStr(j['error']),
      );

  /// 位置摘要："United States · California · Los Angeles"，空则 ""。
  String get location {
    final parts = <String>[
      if (countryName != null && countryName!.isNotEmpty) countryName!,
      if (region != null && region!.isNotEmpty) region!,
      if (city != null && city!.isNotEmpty && city != region) city!,
    ];
    return parts.join(' · ');
  }
}

// ─────────────────────────── 工具 ───────────────────────────

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asNum(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asStr(dynamic v) => v is String ? v : (v == null ? null : '$v');

DateTime? _asDt(dynamic v) {
  if (v is DateTime) return v;
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is String) {
    final d = DateTime.tryParse(v);
    if (d != null) return d.toLocal();
  }
  return null;
}

/// 相对时间描述（"刚刚 / N 秒前 / N 分钟前 / HH:mm"）。
String relativeTime(DateTime? t) {
  if (t == null) return '—';
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 5) return '刚刚';
  if (diff.inSeconds < 60) return '${diff.inSeconds} 秒前';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '${t.month}/${t.day} $h:$m';
}

/// 代理状态的中文标签与颜色语义。
String statusLabel(String status) {
  switch (status) {
    case 'ok':
      return '正常';
    case 'depleted':
      return '额度耗尽';
    case 'down':
      return '故障';
    case 'bad_config':
      return '配置错误';
    case 'maint':
      return '维护中';
    default:
      return status;
  }
}
