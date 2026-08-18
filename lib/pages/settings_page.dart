/// 设置页：连接信息、运行时参数、主题、pin、登出。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
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
    } catch (_) {
      // 忽略，页面显示"无法读取配置"
    }
  }

  Future<void> _run(Future<void> Function() action, {String? ok}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (ok != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ok)));
      }
      await _loadCfg();
      await widget.state.refreshNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editConnection() async {
    final url = widget.state.baseUrl ?? '';
    final key = widget.state.adminKey ?? '';
    final result = await showDialog<(String, String)>(
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
    final result = await showDialog<Map<String, dynamic>>(
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复环境变量配置'),
        content: const Text('清除后台保存的运行时配置（代理列表与参数），恢复为部署时的环境变量。确定吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('恢复')),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            tooltip: '重新读取配置',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _loadCfg,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle('连接'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      InfoRow(label: '网关地址', value: widget.state.baseUrl ?? '未配置'),
                      InfoRow(label: '管理员密钥', value: widget.state.adminKey ?? '未配置'),
                      InfoRow(label: '轮询状态', value: widget.state.polling ? '每 5s 刷新' : '未运行'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _editConnection,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('修改连接'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _logout,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('登出'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SectionTitle('常驻代理'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(
                        label: '当前常驻',
                        value: widget.state.pinStatus?.pinnedProxy ?? '无',
                      ),
                      InfoRow(
                        label: 'Sticky Key',
                        value: widget.state.pinStatus?.stickyKey ?? '—',
                      ),
                      InfoRow(
                        label: 'Pin 模式',
                        value: widget.state.pinStatus?.pinMode ?? '—',
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: (_busy || (widget.state.pinStatus?.stickyKey ?? '').isEmpty)
                              ? null
                              : _clearPin,
                          icon: const Icon(Icons.push_pin, size: 16),
                          label: const Text('解除当前会话常驻'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SectionTitle('运行时配置'),
              if (c == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('无法读取配置（检查连接或密钥）'),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoRow(label: '代理数量', value: '${c.proxies.length}'),
                        InfoRow(label: 'Pin 模式', value: c.pinMode ?? '—'),
                        InfoRow(label: '探测模式', value: c.probeMode ?? '—'),
                        InfoRow(
                            label: '来源',
                            value: c.hasRuntimeConfig
                                ? (c.runtimeManaged ? '后台运行时配置' : '环境变量 + 运行时参数')
                                : '环境变量'),
                        InfoRow(label: '客户端 Key', value: c.apiKeyMasked ?? '—'),
                        if (c.adminUsesApiKey)
                          InfoRow(label: '管理鉴权', value: '复用 API_KEY')
                        else
                          InfoRow(label: '管理 Key', value: c.adminKeyMasked ?? '—'),
                        InfoRow(label: '代理 Key', value: c.proxyKeysMasked ?? '—'),
                        if (c.runtimeError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('运行时代理异常: ${c.runtimeError}',
                                style: TextStyle(color: scheme.error, fontSize: 12)),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _editParams,
                                icon: const Icon(Icons.tune, size: 18),
                                label: const Text('编辑参数'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _resetConfig,
                                icon: const Icon(Icons.settings_backup_restore, size: 18),
                                label: const Text('恢复环境变量'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              SectionTitle('外观'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('主题'),
                  trailing: DropdownButton<ThemeMode>(
                    value: widget.state.themeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('亮色')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
                    ],
                    onChanged: (v) {
                      if (v != null) widget.state.setThemeMode(v);
                    },
                  ),
                ),
              ),
              SectionTitle('关于'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      InfoRow(label: '应用', value: 'FreeBuff 网关管理'),
                      InfoRow(label: '后端', value: 'freebuff-proxy-gateway (Cloudflare Workers)'),
                      InfoRow(label: '接口', value: '/admin/api/*'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
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
    return AlertDialog(
      title: const Text('修改连接'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: '网关地址', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _key,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: '管理员密钥', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final u = _url.text.trim();
            final k = _key.text.trim();
            if (u.isEmpty || k.isEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('地址与密钥不能为空')));
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
    for (final c in [_pinTtl, _stateTtl, _depletedProbe, _downProbe, _probeTimeout, _chatTimeout, _maxAttempts]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minLabels = const {
      'pinTtl': 'Pin 有效期（秒, ≥60）',
      'stateTtl': '状态 TTL（秒, ≥60）',
      'depletedProbe': '耗尽重探测间隔（秒, ≥60）',
      'downProbe': '故障重探测间隔（秒, ≥30）',
      'probeTimeout': '探测超时（毫秒, ≥500）',
      'chatTimeout': '转发超时（毫秒, ≥1000）',
      'maxAttempts': '最大尝试次数（1-6）',
    };
    Widget field(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder(), isDense: true),
          ),
        );
    return AlertDialog(
      title: const Text('编辑运行参数'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _pinMode,
                decoration: const InputDecoration(
                    labelText: 'Pin 模式', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'client', child: Text('client — 按网关 Key 钉住')),
                  DropdownMenuItem(value: 'header', child: Text('header — 按 X-Sticky-Id 钉住')),
                  DropdownMenuItem(value: 'off', child: Text('off — 关闭钉住')),
                ],
                onChanged: (v) => setState(() => _pinMode = v ?? _pinMode),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _probeMode,
                decoration: const InputDecoration(
                    labelText: '探测模式', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'smart', child: Text('smart — 智能懒探测')),
                  DropdownMenuItem(value: 'scan', child: Text('scan — 周期扫描')),
                ],
                onChanged: (v) => setState(() => _probeMode = v ?? _probeMode),
              ),
              const SizedBox(height: 12),
              field(_pinTtl, minLabels['pinTtl']!),
              field(_stateTtl, minLabels['stateTtl']!),
              field(_depletedProbe, minLabels['depletedProbe']!),
              field(_downProbe, minLabels['downProbe']!),
              field(_probeTimeout, minLabels['probeTimeout']!),
              field(_chatTimeout, minLabels['chatTimeout']!),
              field(_maxAttempts, minLabels['maxAttempts']!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  void _submit() {
    int? parse(TextEditingController c) {
      final v = int.tryParse(c.text.trim());
      return v;
    }

    final pinTtl = parse(_pinTtl);
    final stateTtl = parse(_stateTtl);
    final depletedProbe = parse(_depletedProbe);
    final downProbe = parse(_downProbe);
    final probeTimeout = parse(_probeTimeout);
    final chatTimeout = parse(_chatTimeout);
    final maxAttempts = parse(_maxAttempts);

    // 与服务端校验一致的约束
    if (pinTtl == null || pinTtl < 60) return _err('pinTtl 必须 ≥ 60');
    if (stateTtl == null || stateTtl < 60) return _err('stateTtl 必须 ≥ 60');
    if (depletedProbe == null || depletedProbe < 60) return _err('depletedProbe 必须 ≥ 60');
    if (downProbe == null || downProbe < 30) return _err('downProbe 必须 ≥ 30');
    if (probeTimeout == null || probeTimeout < 500) return _err('probeTimeout 必须 ≥ 500');
    if (chatTimeout == null || chatTimeout < 1000) return _err('chatTimeout 必须 ≥ 1000');
    if (maxAttempts == null || maxAttempts < 1 || maxAttempts > 6) return _err('maxAttempts 必须在 1-6');

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

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
