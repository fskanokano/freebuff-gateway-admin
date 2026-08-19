/// 代理管理页：状态卡片、维护开关、立即探测、增删改、常驻标识、备注。
/// 基于 flutter-shadcn-ui 组件。
library;

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProxiesPage extends StatefulWidget {
  const ProxiesPage({super.key, required this.state});

  final AppState state;

  @override
  State<ProxiesPage> createState() => _ProxiesPageState();
}

class _ProxiesPageState extends State<ProxiesPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (success != null && mounted) showShadcnToast(context, success);
    } catch (e) {
      if (mounted) showShadcnToast(context, '操作失败: $e');
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
        showShadcnToast(
            context,
            res == null
                ? '探测完成'
                : '${res.name}: ${statusLabel(res.status ?? 'unknown')}'
                    '${res.detail != null && res.detail!.isNotEmpty ? ' · ${res.detail}' : ''}');
      }
    });
  }

  Future<void> _probeAll() async {
    final api = widget.state.api;
    if (api == null) return;
    await _run(() async {
      final results = await api.probe();
      final lines =
          results.map((r) => '${r.name}: ${statusLabel(r.status ?? '?')}').join('\n');
      if (mounted) showShadcnToast(context, '探测完成\n$lines');
    });
  }

  Future<void> _unpin() async {
    final api = widget.state.api;
    final key = widget.state.pinStatus?.stickyKey;
    if (api == null || key == null || key.isEmpty) return;
    await _run(() => api.clearPin(key), success: '已解除常驻');
  }

  Future<void> _editProxy([ProxyInfo? existing]) async {
    final api = widget.state.api;
    if (api == null) return;
    final cfg = await api.config();
    if (!mounted) return;
    final currentKey = existing == null
        ? ''
        : cfg.proxies
                .where((x) => x.name == existing.name)
                .map((x) => x.apiKey)
                .firstOrNull ??
            '';
    final result = await showShadDialog<ProxyConfig>(
      context: context,
      builder: (_) => _ProxyEditDialog(
          api: api, existing: existing, currentApiKey: currentKey),
    );
    if (result != null && mounted) {
      final proxies = List<ProxyConfig>.from(cfg.proxies);
      final idx =
          existing == null ? -1 : proxies.indexWhere((p) => p.name == existing.name);
      if (idx >= 0) {
        proxies[idx] = result;
      } else {
        proxies.add(result);
      }
      await _run(() => api.saveProxies(proxies),
          success: existing == null ? '已添加代理' : '已保存修改');
    }
  }

  Future<void> _deleteProxy(ProxyInfo p) async {
    final api = widget.state.api;
    if (api == null) return;
    final ok = await showShadcnConfirm(
      context,
      title: '删除代理',
      message: '确定删除代理 "${p.name}" 吗？\n\n删除的是后台运行时配置中的代理列表；若代理来自环境变量，恢复默认会重新出现。',
      confirmText: '删除',
      destructive: true,
    );
    if (ok != true) return;
    final cfg = await api.config();
    final proxies = cfg.proxies.where((x) => x.name != p.name).toList();
    if (proxies.isEmpty) {
      if (mounted) showShadcnToast(context, '至少需要保留一个代理');
      return;
    }
    await _run(() => api.saveProxies(proxies), success: '已删除 ${p.name}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final proxies = widget.state.overview?.proxies ?? const <ProxyInfo>[];
          if (proxies.isEmpty && !widget.state.hasError) {
            return Column(
              children: [
                GlassAppBar(
                  title: const Text('代理'),
                  actions: [_navActions(context)],
                ),
                const Expanded(
                    child: Center(child: CupertinoActivityIndicator())),
              ],
            );
          }
          return Column(
            children: [
              GlassAppBar(
                title: const Text('代理'),
                actions: [_navActions(context)],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.state.hasError)
                        ErrorBanner(widget.state.lastError ?? '连接失败',
                            onRetry: widget.state.refreshNow),
                      _pinnedBanner(context),
                      ...proxies.map((p) => fadeSlideIn(
                          _proxyCard(context, p,
                              widget.state.pinStatus?.pinnedProxy),
                          delayMs: 0)),
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

  Widget _navActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TapFeedback(
            onTap: _busy ? null : _probeAll,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(CupertinoIcons.play_circle, size: 20),
            ),
          ),
          const SizedBox(width: 4),
          TapFeedback(
            onTap: _busy ? null : () => _editProxy(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(CupertinoIcons.add, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinnedBanner(BuildContext context) {
    final pinned = widget.state.pinStatus?.pinnedProxy;
    final stickyKey = widget.state.pinStatus?.stickyKey;
    if (pinned == null || pinned.isEmpty) return const SizedBox.shrink();
    final blue = schemeColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: blue.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.pin_fill, size: 15, color: blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前常驻代理：$pinned',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: blue,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TapFeedback(
            onTap: (stickyKey == null || stickyKey.isEmpty) ? null : _unpin,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('解除',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: blue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proxyCard(BuildContext context, ProxyInfo p, String? pinnedProxy) {
    final isPinned = pinnedProxy != null &&
        pinnedProxy.isNotEmpty &&
        pinnedProxy == p.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 常驻顶部细条
          if (isPinned)
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: schemeColor(context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(kCardRadius)),
              ),
            ),
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                _avatar(context, p.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(p.name,
                                style: ShadTheme.of(context)
                                    .textTheme
                                    .h4
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(CupertinoIcons.pin_fill,
                                size: 13, color: schemeColor(context)),
                          ],
                        ],
                      ),
                      Text(p.url,
                          style: ShadTheme.of(context).textTheme.small,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StatusBadge(p.status),
              ],
            ),
          ),
          // 备注
          if (p.remark != null && p.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                children: [
                  Icon(CupertinoIcons.doc_text,
                      size: 12, color: mutedColor(context)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      p.remark!,
                      style: ShadTheme.of(context)
                          .textTheme
                          .small
                          .copyWith(fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // 用量
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('用量', style: ShadTheme.of(context).textTheme.small),
                    const Spacer(),
                    if (p.score != null)
                      Text('score ${p.score!.toStringAsFixed(0)}',
                          style: ShadTheme.of(context).textTheme.small),
                  ],
                ),
                const SizedBox(height: 5),
                UsageBar(percent: p.usagePct ?? _firstQuotaUsage(p)),
              ],
            ),
          ),
          // 配额
          if (p.quota.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: p.quota.entries.map((e) {
                  final q = e.value;
                  final u = q.usagePercent;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark(context)
                          ? const Color(0xFF1C1C20)
                          : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${e.key}  ${q.recentCount ?? 0}/${q.limit ?? '∞'}'
                      '${u != null ? ' (${u.toStringAsFixed(0)}%)' : ''}',
                      style: ShadTheme.of(context).textTheme.small,
                    ),
                  );
                }).toList(),
              ),
            ),
          // 时间信息
          _timeRows(context, p),
          // 操作
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: _busy ? null : () => _probeOne(p),
                    child: const Text('探测'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: _busy ? null : () => _editProxy(p),
                    child: const Text('编辑'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: _busy ? null : () => _deleteProxy(p),
                    child: const Text('删除',
                        style: TextStyle(color: ShadcnColors.danger)),
                  ),
                ),
              ],
            ),
          ),
          // 维护开关
          ShadcnDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('维护模式',
                      style: ShadTheme.of(context).textTheme.p),
                ),
                ShadSwitch(
                  value: p.maint,
                  onChanged: _busy ? null : (v) => _toggleMaintenance(p, v),
                ),
              ],
            ),
          ),
          if (p.maint)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text('维护中，路由会排除该代理',
                  style: ShadTheme.of(context).textTheme.small),
            ),
        ],
      ),
      ),
    );
  }

  Widget _avatar(BuildContext context, String name) {
    final primary = schemeColor(context);
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark(context) ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }

  Widget _timeRows(BuildContext context, ProxyInfo p) {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(r.$1,
                            style: ShadTheme.of(context).textTheme.small),
                      ),
                      Expanded(
                          child: Text(r.$2,
                              style: ShadTheme.of(context).textTheme.small)),
                    ],
                  ),
                ))
            .toList(),
      ),
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
  final String currentApiKey;

  @override
  State<_ProxyEditDialog> createState() => _ProxyEditDialogState();
}

class _ProxyEditDialogState extends State<_ProxyEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _key;
  late final TextEditingController _remark;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _url = TextEditingController(text: widget.existing?.url ?? 'https://');
    _key = TextEditingController(text: '');
    _remark = TextEditingController(text: widget.existing?.remark ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(widget.existing == null ? '添加代理' : '编辑代理 ${widget.existing!.name}'),
      description: const SizedBox(),
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ShadInput(
              controller: _name,
              placeholder: Text('名称（可选，自动规范化）'),
            ),
            const SizedBox(height: 10),
            ShadInput(
              controller: _url,
              placeholder: Text('代理地址（http(s)://…）'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            ShadInput(
              controller: _key,
              placeholder: Text(widget.existing == null
                  ? '代理 API Key'
                  : '代理 API Key（留空保持原值）'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ShadInput(
              controller: _remark,
              placeholder: Text('备注（可选，如：主线路）'),
              maxLength: 200,
              maxLines: 2,
            ),
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

  void _submit() {
    final url = _url.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      showShadcnToast(context, '地址需以 http(s):// 开头');
      return;
    }
    final nameRaw = _name.text.trim();
    if (nameRaw.isNotEmpty &&
        !RegExp(r'^[a-z0-9-]+$').hasMatch(nameRaw.toLowerCase())) {
      showShadcnToast(context, '名称仅允许小写字母/数字/连字符');
      return;
    }
    final cfg = widget.existing;
    final name = nameRaw.isEmpty
        ? (cfg?.name ?? '')
        : nameRaw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    final key =
        _key.text.trim().isEmpty ? widget.currentApiKey : _key.text.trim();
    if (key.isEmpty) {
      showShadcnToast(context, '新增代理必须填写 Key');
      return;
    }
    final remark = _remark.text.trim();
    Navigator.pop(
      context,
      ProxyConfig(
        name: name,
        url: url.replaceAll(RegExp(r'/+$'), ''),
        apiKey: key,
        remark: remark.isEmpty ? null : remark,
      ),
    );
  }
}
