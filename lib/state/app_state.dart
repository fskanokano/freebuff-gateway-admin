/// FreeBuff Gateway Admin — 全局状态。
/// 负责：连接配置（baseUrl/adminKey）持久化、overview 轮询、主题模式。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/gateway_api.dart';
import '../models/models.dart';
import 'key_store.dart';

/// 可注入的 API 客户端工厂（测试用 MockClient；默认直连）。
typedef GatewayApiFactory = GatewayApi Function(
    {required String baseUrl, required String adminKey});

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static const _kBaseUrl = 'gw_base_url';
  static const _kAdminKey = 'gw_admin_key';
  static const _kTheme = 'gw_theme';

  /// [keyStore] 可注入（测试用 InMemoryKeyStore）；默认平台安全存储。
  /// [apiFactory] 可注入（测试用 MockClient）；默认直连网关。
  AppState({KeyStore? keyStore, GatewayApiFactory? apiFactory})
      : _keyStore = keyStore ?? SecureKeyStore(),
        _apiFactory = apiFactory ?? _defaultApiFactory {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _init();
  }

  final KeyStore _keyStore;
  final GatewayApiFactory _apiFactory;

  static GatewayApi _defaultApiFactory(
          {required String baseUrl, required String adminKey}) =>
      GatewayApi(baseUrl: baseUrl, adminKey: adminKey);

  String? baseUrl;
  String? adminKey;
  ThemeMode themeMode = ThemeMode.system;

  /// 本地存储是否已加载完成（区分"加载中"与"确实未配置"）。
  bool loaded = false;

  /// 最近一次成功的连接配置（用于设置页显示"已配置"）。
  bool get configured => (baseUrl?.isNotEmpty ?? false) && (adminKey?.isNotEmpty ?? false);

  /// 当前 API 客户端（仅在 configured 时可用）。
  GatewayApi? api;

  // ── 轮询数据 ──
  OverviewData? overview;
  PinStatus? pinStatus;
  bool polling = false;
  bool hasError = false;
  String? lastError;
  /// 错误归类（UI 层本地化）：'unauthorized' | 'connection' | null（网关错误）。
  String? lastErrorKind;
  DateTime? lastUpdated;

  /// 轮询历史环形缓冲（分析页趋势图），最多保留 [_maxHistory] 个点。
  static const _maxHistory = 120;
  final List<HistoryPoint> history = [];

  Timer? _timer;
  static const pollInterval = Duration(seconds: 5);
  static const _maxPollInterval = Duration(seconds: 60);
  bool _refreshing = false; // 重入锁：避免定时器与手动刷新并发重叠
  int _consecutiveFailures = 0;
  Duration _currentInterval = pollInterval;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_kBaseUrl);
    // 优先读安全存储；缺失则尝试从旧版本明文 prefs 一次性迁移。
    var key = await _keyStore.read(_kAdminKey);
    if (key == null || key.isEmpty) {
      final legacy = prefs.getString(_kAdminKey);
      if (legacy != null && legacy.isNotEmpty) {
        key = legacy;
        if (await _persistKey(legacy)) {
          await prefs.remove(_kAdminKey); // 迁移成功，清除明文
        }
      }
    }
    adminKey = (key == null || key.isEmpty) ? null : key;
    themeMode = ThemeMode.values[prefs.getInt(_kTheme) ?? ThemeMode.system.index];
    loaded = true;
    if (configured) {
      _applyApi();
      startPolling();
    }
    notifyListeners();
  }

  /// 写安全存储并做往返校验；失败返回 false（调用方回退明文 prefs）。
  Future<bool> _persistKey(String key) async {
    try {
      await _keyStore.write(_kAdminKey, key);
      if (await _keyStore.read(_kAdminKey) == key) return true;
      // 写成功但读回失败（如平台通道超时）：回滚安全存储，
      // 避免密钥同时残留在安全存储与明文 prefs 两处。
      await _keyStore.delete(_kAdminKey);
      return false;
    } catch (_) {
      return false;
    }
  }

  void _applyApi() {
    api = _apiFactory(baseUrl: baseUrl!, adminKey: adminKey!);
  }

  /// 保存连接配置并立即应用。
  Future<void> saveConnection(String url, String key) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    adminKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl!);
    if (await _persistKey(adminKey!)) {
      await prefs.remove(_kAdminKey); // 安全存储可用，清除明文
    } else {
      await prefs.setString(_kAdminKey, adminKey!); // 回退明文
    }
    _applyApi();
    if (!polling) startPolling();
    await refresh();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, mode.index);
    notifyListeners();
  }

  /// 验证连接（登录页用）：成功返回 true 并保存，失败抛异常。
  Future<bool> testAndSave(String url, String key) async {
    final tmp = _apiFactory(baseUrl: url, adminKey: key);
    try {
      await tmp.ping();
    } finally {
      tmp.dispose(); // 修复原实现泄漏 http.Client 的问题
    }
    await saveConnection(url, key);
    return true;
  }

  /// 清除连接配置（登出）。
  Future<void> clearConnection() async {
    stopPolling();
    api?.dispose();
    api = null;
    baseUrl = null;
    adminKey = null;
    overview = null;
    pinStatus = null;
    hasError = false;
    lastError = null;
    lastErrorKind = null;
    history.clear();
    final prefs = await SharedPreferences.getInstance();
    await _keyStore.delete(_kAdminKey);
    await prefs.remove(_kBaseUrl);
    await prefs.remove(_kAdminKey); // 兼容明文回退残留
    notifyListeners();
  }

  void startPolling() {
    if (polling || api == null) return;
    polling = true;
    _currentInterval = pollInterval;
    _consecutiveFailures = 0;
    refresh();
    _scheduleNext();
    notifyListeners();
  }

  void stopPolling() {
    polling = false;
    _timer?.cancel();
    _timer = null;
  }

  /// 自调度单次定时器（按退避后的 [_currentInterval] 重排）。
  void _scheduleNext() {
    _timer?.cancel();
    if (!polling) return;
    _timer = Timer(_currentInterval, () async {
      await refresh();
      if (polling) _scheduleNext();
    });
  }

  /// 失败指数退避：2^n 拉长轮询间隔，上限 60s；恢复后复位。
  void _bumpBackoff() {
    final exp = 1 << _consecutiveFailures.clamp(0, 10);
    _currentInterval = Duration(
      seconds: (pollInterval.inSeconds * exp)
          .clamp(pollInterval.inSeconds, _maxPollInterval.inSeconds),
    );
  }

  /// 拉取 overview + pin（每轮一次；重入锁避免定时器与手动刷新并发重叠）。
  Future<void> refresh() async {
    final client = api;
    if (client == null || !polling || _refreshing) return;
    _refreshing = true;
    try {
      try {
        final ov = await client.overview();
        overview = ov;
        hasError = false;
        lastError = null;
        lastErrorKind = null;
        _consecutiveFailures = 0;
        _currentInterval = pollInterval; // 恢复即复位退避
        lastUpdated = DateTime.now();
        _recordHistory(ov);
      } catch (e) {
        hasError = true;
        _captureError(e);
        _consecutiveFailures++;
        _bumpBackoff(); // 连续失败拉长轮询间隔
      }
      try {
        pinStatus = await client.pinStatus();
      } catch (_) {
        // pin 失败不影响主数据
      }
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  /// 手动刷新（下拉/按钮）。
  Future<void> refreshNow() => refresh();

  /// 网络/鉴权错误 → 归类（UI 层本地化）；401 明确提示密钥失效。
  void _captureError(Object e) {
    if (e is GatewayException) {
      lastError = e.message;
      lastErrorKind = e.status == 401 ? 'unauthorized' : null;
    } else {
      lastError = e.toString();
      lastErrorKind = 'connection';
    }
  }

  void _recordHistory(OverviewData ov) {
    double? avgMs;
    if (ov.routes.isNotEmpty) {
      var sum = 0.0;
      for (final r in ov.routes) {
        sum += r.ms;
      }
      avgMs = sum / ov.routes.length;
    }
    history.add(HistoryPoint(
      t: DateTime.now(),
      requestsOk: ov.stats.requestsOk,
      requestsFail: ov.stats.requestsFail,
      avgMs: avgMs,
    ));
    if (history.length > _maxHistory) history.removeAt(0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (configured && !polling) startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        stopPolling(); // 后台暂停轮询（省电省流量）
        break;
      case AppLifecycleState.inactive:
        break; // 短暂失焦不打断
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _timer?.cancel();
    api?.dispose();
    super.dispose();
  }
}
