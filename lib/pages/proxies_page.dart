/// 代理管理页：状态卡片、维护开关、立即探测、增删改。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ProxiesPage extends StatefulWidget {
  const ProxiesPage({super.key, required this.state});

  final AppState state;

  @override
  State<ProxiesPage> createState() => _ProxiesPageState();
}

class _ProxiesPageState extends State<ProxiesPage> {
  bool _busy = false;
  String? _toast;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _toast = null;
    });
    try {
      await action();
      if (success != null && mounted) {
        setState(() => _toast = success);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _toast = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) widget.state.refreshNow();
  }

  Future<void> _toggleMaintenance(ProxyInfo p, bool on) async {
    final api = widget.state.api;
    if (api == null) return;
    await _run(() => api.setMaintenance(p.name, on));
  }

  Future<void> _probeOne(ProxyInfo p) async {
    final api = widget.state.api;
    if (api == null) return;
    await _run(() async {
      final r = await api.probe(name: p.name);
      final res = r.isEmpty ? null : r.first;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res == null
              ? '探测完成'
              : '${res.name}: ${statusLabel(res.status ?? 'unknown')}'
                  '${res.detail != null && res.detail!.isNotEmpty ? ' · ${res.detail}' : ''}'),
        ));
      }
    });
  }

  Future<void> _probeAll() async {
    final api = widget.state.api;
    if (api == null) return;
    await _run(() async {
      final results = await api.probe();
      final lines = results.map((r) => '${r.name}: ${statusLabel(r.status ?? '?')}').join('\n');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('探测完成\n$lines')));
      }
    });
  }

  Future<void> _editProxy([ProxyInfo? existing]) async {
    final api = widget.state.api;
    if (api == null) return;
    final cfg = await api.config();
    if (!mounted) return;
    // 编辑时传入现有 apiKey，留空则保持原值（后端要求 apiKey 非空）
    final currentKey = existing == null
        ? ''
        : cfg.proxies
            .where((x) => x.name == existing.name)
            .map((x) => x.apiKey)
            .firstOrNull ?? '';
    final result = await showDialog<ProxyConfig>(
      context: context,
      builder: (_) => _ProxyEditDialog(
          api: api, existing: existing, currentApiKey: currentKey),
    );
    if (result != null && mounted) {
      // 读-改-写：从当前 config 取出完整列表，替换/追加目标项
      final proxies = List<ProxyConfig>.from(cfg.proxies);
      final idx = existing == null ? -1 : proxies.indexWhere((p) => p.name == existing.name);
      if (idx >= 0) {
        proxies[idx] = result;
      } else {
        proxies.add(result);
      }
      await _run(() => api.saveProxies(proxies), success: existing == null ? '已添加代理' : '已保存修改');
    }
  }

  Future<void> _deleteProxy(ProxyInfo p) async {
    final api = widget.state.api;
    if (api == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除代理'),
        content: Text('确定删除代理 "${p.name}" 吗？\n\n删除的是后台运行时配置中的代理列表；若代理来自环境变量，恢复默认会重新出现。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final cfg = await api.config();
    final proxies = cfg.proxies.where((x) => x.name != p.name).toList();
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('至少需要保留一个代理')));
      }
      return;
    }
    await _run(() => api.saveProxies(proxies), success: '已删除 ${p.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('代理'),
        actions: [
          IconButton(
            tooltip: '全部立即探测',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _busy ? null : _probeAll,
          ),
          IconButton(
            tooltip: '添加代理',
            icon: const Icon(Icons.add),
            onPressed: _busy ? null : () => _editProxy(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final proxies = widget.state.overview?.proxies ?? const <ProxyInfo>[];
          if (proxies.isEmpty && !widget.state.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: widget.state.refreshNow,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.state.hasError)
                      ErrorBanner(widget.state.lastError ?? '连接失败',
                          onRetry: widget.state.refreshNow),
                    ...proxies.map((p) => _proxyCard(context, p)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_toast != null)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(_toast!,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '添加代理',
        onPressed: _busy ? null : () => _editProxy(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _proxyCard(BuildContext context, ProxyInfo p) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(p.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p.name,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (p.score != null)
                  Text('score ${p.score!.toStringAsFixed(0)}',
                      style: t.bodySmall?.copyWith(color: scheme.outline)),
              ],
            ),
            const SizedBox(height: 4),
            Text(p.url,
                style: t.bodySmall?.copyWith(color: scheme.outline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // 用量条：优先 usage_pct，其次第一个模型配额
            UsageBar(percent: p.usagePct ?? _firstQuotaUsage(p), label: '用量'),
            const SizedBox(height: 8),
            // 配额摘要
            if (p.quota.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: p.quota.entries.map((e) {
                  final q = e.value;
                  final u = q.usagePercent;
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '${e.key}: ${q.recentCount ?? 0}/${q.limit ?? '∞'}'
                      '${u != null ? ' (${u.toStringAsFixed(0)}%)' : ''}',
                      style: t.bodySmall,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 4),
            _timeRows(context, p),
            const Divider(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _probeOne(p),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('立即探测'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _editProxy(p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('编辑'),
                  ),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: _busy ? null : () => _deleteProxy(p),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            // 维护开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('维护模式'),
              subtitle: Text(p.maint ? '维护中，路由会排除该代理' : '开启后从选路池排除',
                  style: t.bodySmall),
              value: p.maint,
              onChanged: _busy ? null : (v) => _toggleMaintenance(p, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeRows(BuildContext context, ProxyInfo p) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rows = <(String, String)>[
      if (p.reason.isNotEmpty) ('原因', p.reason),
      if (p.detail.isNotEmpty) ('详情', p.detail),
      if (p.cooldownUntil != null) ('冷却至', relativeTime(p.cooldownUntil)),
      if (p.resetAt != null) ('重置于', relativeTime(p.resetAt)),
      if (p.nextProbe != null) ('下次探测', relativeTime(p.nextProbe)),
      if (p.lastOk != null) ('上次成功', relativeTime(p.lastOk)),
      if (p.lastError != null) ('上次失败', relativeTime(p.lastError)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(r.$1,
                          style: t.bodySmall?.copyWith(color: scheme.outline)),
                    ),
                    Expanded(
                        child: Text(r.$2, style: t.bodySmall)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  double? _firstQuotaUsage(ProxyInfo p) {
    for (final q in p.quota.values) {
      final u = q.usagePercent;
      if (u != null) return u;
    }
    return null;
  }
}

/// 代理编辑对话框（添加/修改）。
class _ProxyEditDialog extends StatefulWidget {
  const _ProxyEditDialog({
    required this.api,
    this.existing,
    this.currentApiKey = '',
  });

  final dynamic api; // GatewayApi
  final ProxyInfo? existing;

  /// 编辑模式下代理现有 apiKey（留空时回填）。
  final String currentApiKey;

  @override
  State<_ProxyEditDialog> createState() => _ProxyEditDialogState();
}

class _ProxyEditDialogState extends State<_ProxyEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _url = TextEditingController(text: widget.existing?.url ?? 'https://');
    _key = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '添加代理' : '编辑代理 ${widget.existing!.name}'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: '名称（可选，自动规范化）',
                      border: OutlineInputBorder()),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isNotEmpty &&
                        !RegExp(r'^[a-z0-9-]+$').hasMatch(s.toLowerCase())) {
                      return '仅允许小写字母/数字/连字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      labelText: '代理地址 *', border: OutlineInputBorder()),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (!s.startsWith('http://') && !s.startsWith('https://')) {
                      return '需以 http(s):// 开头';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _key,
                  autocorrect: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: widget.existing == null
                        ? '代理 API Key *'
                        : '代理 API Key（留空则保持原值）',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                  ),
                  validator: (v) =>
                      (widget.existing == null && (v?.trim().isEmpty ?? true))
                          ? '新增代理必须填写 Key'
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cfg = widget.existing;
    final name = _name.text.trim().isEmpty
        ? (cfg?.name ?? '')
        : _name.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    // 新增必须填 key；编辑留空则回填现有 key（后端要求 apiKey 非空）
    final key = _key.text.trim().isEmpty ? widget.currentApiKey : _key.text.trim();
    Navigator.pop(
      context,
      ProxyConfig(
        name: name,
        url: _url.text.trim().replaceAll(RegExp(r'/+$'), ''),
        apiKey: key,
      ),
    );
  }
}
