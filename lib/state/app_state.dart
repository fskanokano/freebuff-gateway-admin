/// FreeBuff Gateway Admin — 全局状态。
/// 负责：连接配置（baseUrl/adminKey）持久化、overview 轮询、主题模式。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/gateway_api.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  static const _kBaseUrl = 'gw_base_url';
  static const _kAdminKey = 'gw_admin_key';
  static const _kTheme = 'gw_theme';

  AppState() {
    _init();
  }

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
  DateTime? lastUpdated;

  Timer? _timer;
  static const pollInterval = Duration(seconds: 5);

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_kBaseUrl);
    adminKey = prefs.getString(_kAdminKey);
    themeMode = ThemeMode.values[prefs.getInt(_kTheme) ?? ThemeMode.system.index];
    loaded = true;
    if (configured) {
      _applyApi();
      startPolling();
    }
    notifyListeners();
  }

  void _applyApi() {
    api = GatewayApi(baseUrl: baseUrl!, adminKey: adminKey!);
  }

  /// 保存连接配置并立即应用。
  Future<void> saveConnection(String url, String key) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    adminKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl!);
    await prefs.setString(_kAdminKey, adminKey!);
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
    final tmp = GatewayApi(baseUrl: url, adminKey: key);
    await tmp.ping();
    await saveConnection(url, key);
    return true;
  }

  /// 清除连接配置（登出）。
  Future<void> clearConnection() async {
    stopPolling();
    api = null;
    baseUrl = null;
    adminKey = null;
    overview = null;
    pinStatus = null;
    hasError = false;
    lastError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBaseUrl);
    await prefs.remove(_kAdminKey);
    notifyListeners();
  }

  void startPolling() {
    if (polling || api == null) return;
    polling = true;
    refresh();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
    notifyListeners();
  }

  void stopPolling() {
    polling = false;
    _timer?.cancel();
    _timer = null;
  }

  /// 拉取 overview + pin（每轮一次，串行避免重入）。
  Future<void> refresh() async {
    final client = api;
    if (client == null || !polling) return;
    try {
      final ov = await client.overview();
      overview = ov;
      hasError = false;
      lastError = null;
      lastUpdated = DateTime.now();
    } catch (e) {
      hasError = true;
      lastError = e.toString();
      // 单次失败不中断轮询（网关偶发超时）
    }
    try {
      pinStatus = await client.pinStatus();
    } catch (_) {
      // pin 失败不影响主数据
    }
    notifyListeners();
  }

  /// 手动刷新（下拉/按钮）。
  Future<void> refreshNow() => refresh();

  @override
  void dispose() {
    _timer?.cancel();
    api?.dispose();
    super.dispose();
  }
}
