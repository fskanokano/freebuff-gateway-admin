/// 设置页：连接信息、运行时参数、主题、pin、登出。
/// 基于 flutter-shadcn-ui 组件（分组卡片 + 自绘行）。
library;

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;
  GatewayConfig? _cfg;

  @override
  void initState() {
    super.initState();
    _loadCfg();
  }

  Future<void> _loadCfg() async {
    final api = widget.state.api;
    if (api == null) return;
    try {
      final c = await api.config();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() action, {String? ok}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (ok != null && mounted) showShadcnToast(context, ok);
      await _loadCfg();
      await widget.state.refreshNow();
    } catch (e) {
      if (mounted) showShadcnToast(context, '操作失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editConnection() async {
    final url = widget.state.baseUrl ?? '';
    final key = widget.state.adminKey ?? '';
    final result = await showShadDialog<(String, String)>(
      context: context,
      builder: (ctx) => _ConnectionDialog(url: url, adminKey: key),
    );
    if (result != null && mounted) {
      await _run(() => widget.state.saveConnection(result.$1, result.$2),
          ok: '连接已更新');
    }
  }

  Future<void> _editParams() async {
    final c = _cfg;
    if (c == null || widget.state.api == null) return;
    final result = await showShadDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ParamsDialog(config: c),
    );
    if (result != null && mounted) {
      await _run(() => widget.state.api!.saveSettings(result), ok: '参数已保存并生效');
    }
  }

  Future<void> _resetConfig() async {
    final api = widget.state.api;
    if (api == null) return;
    final ok = await showShadcnConfirm(
      context,
      title: '恢复环境变量配置',
      message: '清除后台保存的运行时配置（代理列表与参数），恢复为部署时的环境变量。确定吗？',
      confirmText: '恢复',
      destructive: true,
    );
    if (ok == true) {
      await _run(() => api.resetConfig(), ok: '已恢复环境变量配置');
    }
  }

  Future<void> _clearPin() async {
    final api = widget.state.api;
    final key = widget.state.pinStatus?.stickyKey;
    if (api == null || key == null || key.isEmpty) return;
    await _run(() => api.clearPin(key), ok: '已解除常驻钉住');
  }

  Future<void> _logout() async {
    await widget.state.clearConnection();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/connect', (_) => false);
    }
  }

  /// 分组行。
  Widget _row({
    required String label,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    final color = destructive ? ShadcnColors.danger : fgColor(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: ShadTheme.of(context)
                      .textTheme
                      .p
                      .copyWith(color: color)),
            ),
            if (value != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  /// 分组卡片。
  Widget _group(BuildContext context, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) ShadcnDivider(indent: 14),
            r,
          ],
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final pin = widget.state.pinStatus;
          return Column(
            children: [
              GlassAppBar(
                title: const Text('设置'),
                actions: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _busy ? null : _loadCfg,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(CupertinoIcons.refresh, size: 19),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('连接'),
                      _group(context, [
                        _row(label: '网关地址', value: widget.state.baseUrl ?? '未配置'),
                        _row(label: '管理员密钥', value: widget.state.adminKey ?? '未配置'),
                        _row(label: '轮询状态',
                            value: widget.state.polling ? '每 5s 刷新' : '未运行'),
                        _row(label: '修改连接', onTap: _busy ? null : _editConnection,
                            trailing: Icon(CupertinoIcons.chevron_right,
                                size: 14, color: mutedColor(context))),
                        _row(label: '登出', destructive: true,
                            onTap: _busy ? null : _logout),
                      ]),
                      const SectionTitle('常驻代理'),
                      _group(context, [
                        _row(label: '当前常驻', value: pin?.pinnedProxy ?? '无'),
                        _row(label: 'Sticky Key', value: pin?.stickyKey ?? '—'),
                        _row(label: 'Pin 模式', value: pin?.pinMode ?? '—'),
                        _row(
                          label: '解除当前会话常驻',
                          onTap:
                              (_busy || (pin?.stickyKey ?? '').isEmpty) ? null : _clearPin,
                          trailing: Icon(CupertinoIcons.pin_slash,
                              size: 14, color: mutedColor(context)),
                        ),
                      ]),
                      const SectionTitle('运行时配置'),
                      if (c == null)
                        _group(context, [
                          _row(label: '无法读取配置（检查连接或密钥）'),
                        ])
                      else ...[
                        _group(context, [
                          _row(label: '代理数量', value: '${c.proxies.length}'),
                          _row(label: 'Pin 模式', value: c.pinMode ?? '—'),
                          _row(label: '探测模式', value: c.probeMode ?? '—'),
                          _row(
                            label: '来源',
                            value: c.hasRuntimeConfig
                                ? (c.runtimeManaged
                                    ? '后台运行时配置'
                                    : '环境变量 + 运行时参数')
                                : '环境变量',
                          ),
                        ]),
                        _group(context, [
                          _row(label: '客户端 Key', value: c.apiKeyMasked ?? '—'),
                          if (c.adminUsesApiKey)
                            _row(label: '管理鉴权', value: '复用 API_KEY')
                          else
                            _row(label: '管理 Key',
                                value: c.adminKeyMasked ?? '—'),
                          _row(label: '代理 Key',
                              value: c.proxyKeysMasked ?? '—'),
                          if (c.runtimeError != null)
                            _row(label: '运行时代理异常', value: c.runtimeError),
                        ]),
                        _group(context, [
                          _row(label: '编辑参数',
                              onTap: _busy ? null : _editParams,
                              trailing: Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 14,
                                  color: mutedColor(context))),
                          _row(label: '恢复环境变量',
                              onTap: _busy ? null : _resetConfig,
                              trailing: Icon(
                                  CupertinoIcons.arrow_counterclockwise,
                                  size: 14,
                                  color: mutedColor(context))),
                        ]),
                      ],
                      const SectionTitle('外观'),
                      _group(context, [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('主题', style: ShadTheme.of(context).textTheme.p),
                              _themePicker(context),
                            ],
                          ),
                        ),
                      ]),
                      const SectionTitle('关于'),
                      _group(context, [
                        _row(label: '应用', value: 'FreeBuff 网关管理'),
                        _row(label: '后端', value: 'freebuff-proxy-gateway'),
                        _row(label: '接口', value: '/admin/api/*'),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _themePicker(BuildContext context) {
    final current = widget.state.themeMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (mode, label) in const [
          (ThemeMode.system, '系统'),
          (ThemeMode.light, '亮'),
          (ThemeMode.dark, '暗'),
        ])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ShadcnPill(
              label,
              selected: current == mode,
              onTap: () => widget.state.setThemeMode(mode),
            ),
          ),
      ],
    );
  }
}

class _ConnectionDialog extends StatefulWidget {
  const _ConnectionDialog({required this.url, required this.adminKey});

  final String url;
  final String adminKey;

  @override
  State<_ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<_ConnectionDialog> {
  late final TextEditingController _url;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.url);
    _key = TextEditingController(text: widget.adminKey);
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('修改连接'),
      description: const SizedBox(),
      // ignore: sort_child_properties_last
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ShadInput(controller: _url, placeholder: Text('网关地址')),
          const SizedBox(height: 10),
          ShadInput(
              controller: _key, placeholder: Text('管理员密钥'), obscureText: true),
        ],
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ShadButton(
          onPressed: () {
            final u = _url.text.trim();
            final k = _key.text.trim();
            if (u.isEmpty || k.isEmpty) {
              showShadcnToast(context, '地址与密钥不能为空');
              return;
            }
            Navigator.pop(context, (u, k));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _ParamsDialog extends StatefulWidget {
  const _ParamsDialog({required this.config});

  final GatewayConfig config;

  @override
  State<_ParamsDialog> createState() => _ParamsDialogState();
}

class _ParamsDialogState extends State<_ParamsDialog> {
  late final TextEditingController _pinTtl;
  late final TextEditingController _stateTtl;
  late final TextEditingController _depletedProbe;
  late final TextEditingController _downProbe;
  late final TextEditingController _probeTimeout;
  late final TextEditingController _chatTimeout;
  late final TextEditingController _maxAttempts;
  late String _pinMode;
  late String _probeMode;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _pinTtl = TextEditingController(text: '${c.pinTtl ?? 3600}');
    _stateTtl = TextEditingController(text: '${c.stateTtl ?? 60}');
    _depletedProbe = TextEditingController(text: '${c.depletedProbe ?? 60}');
    _downProbe = TextEditingController(text: '${c.downProbe ?? 60}');
    _probeTimeout = TextEditingController(text: '${c.probeTimeout ?? 8000}');
    _chatTimeout = TextEditingController(text: '${c.chatTimeout ?? 120000}');
    _maxAttempts = TextEditingController(text: '${c.maxAttempts ?? 3}');
    _pinMode = c.pinMode ?? 'client';
    _probeMode = c.probeMode ?? 'smart';
  }

  @override
  void dispose() {
    for (final c in [
      _pinTtl,
      _stateTtl,
      _depletedProbe,
      _downProbe,
      _probeTimeout,
      _chatTimeout,
      _maxAttempts
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 6),
              ShadInput(controller: c, placeholder: Text('请输入')),
            ],
          ),
        );
    return ShadDialog(
      title: const Text('编辑运行参数'),
      description: const SizedBox(),
      // ignore: sort_child_properties_last
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _modePicker(context, 'Pin 模式', _pinMode, const [
              ('client', 'client — 按网关 Key 钉住'),
              ('header', 'header — 按 X-Sticky-Id 钉住'),
              ('off', 'off — 关闭钉住'),
            ], (v) => setState(() => _pinMode = v)),
            const SizedBox(height: 10),
            _modePicker(context, '探测模式', _probeMode, const [
              ('smart', 'smart — 智能懒探测'),
              ('scan', 'scan — 周期扫描'),
            ], (v) => setState(() => _probeMode = v)),
            const SizedBox(height: 10),
            field(_pinTtl, 'Pin 有效期（秒, ≥60）'),
            field(_stateTtl, '状态 TTL（秒, ≥60）'),
            field(_depletedProbe, '耗尽重探测间隔（秒, ≥60）'),
            field(_downProbe, '故障重探测间隔（秒, ≥30）'),
            field(_probeTimeout, '探测超时（毫秒, ≥500）'),
            field(_chatTimeout, '转发超时（毫秒, ≥1000）'),
            field(_maxAttempts, '最大尝试次数（1-6）'),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ShadButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _modePicker(BuildContext context, String label, String value,
      List<(String, String)> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ShadTheme.of(context).textTheme.small),
          const SizedBox(height: 6),
          ShadSelect<String>(
            minWidth: double.infinity,
            placeholder: Text(value),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            selectedOptionBuilder: (context, v) => Text(v),
            options: [
              for (final (v, l) in options) ShadOption(value: v, child: Text(l)),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    int? parse(TextEditingController c) => int.tryParse(c.text.trim());
    final pinTtl = parse(_pinTtl);
    final stateTtl = parse(_stateTtl);
    final depletedProbe = parse(_depletedProbe);
    final downProbe = parse(_downProbe);
    final probeTimeout = parse(_probeTimeout);
    final chatTimeout = parse(_chatTimeout);
    final maxAttempts = parse(_maxAttempts);

    String? err;
    if (pinTtl == null || pinTtl < 60) err = 'pinTtl 必须 ≥ 60';
    if (err == null && (stateTtl == null || stateTtl < 60)) err = 'stateTtl 必须 ≥ 60';
    if (err == null && (depletedProbe == null || depletedProbe < 60)) {
      err = 'depletedProbe 必须 ≥ 60';
    }
    if (err == null && (downProbe == null || downProbe < 30)) err = 'downProbe 必须 ≥ 30';
    if (err == null && (probeTimeout == null || probeTimeout < 500)) {
      err = 'probeTimeout 必须 ≥ 500';
    }
    if (err == null && (chatTimeout == null || chatTimeout < 1000)) {
      err = 'chatTimeout 必须 ≥ 1000';
    }
    if (err == null && (maxAttempts == null || maxAttempts < 1 || maxAttempts > 6)) {
      err = 'maxAttempts 必须在 1-6';
    }
    if (err != null) {
      showShadcnToast(context, err);
      return;
    }
    Navigator.pop(context, {
      'pinMode': _pinMode,
      'probeMode': _probeMode,
      'pinTtl': pinTtl,
      'stateTtl': stateTtl,
      'depletedProbe': depletedProbe,
      'downProbe': downProbe,
      'probeTimeout': probeTimeout,
      'chatTimeout': chatTimeout,
      'maxAttempts': maxAttempts,
    });
  }
}
