/// 日志页：路由记录 + 系统事件。
/// 支持：关键词搜索、类型筛选（路由成功/失败、事件类型细分）、时间范围、
/// 结果统计、条目展开详情（轮询刷新不打断）、清空。
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

enum _MainFilter { all, routes, events }

enum _RouteFilter { all, ok, fail }

enum _TimeRange { all, m5, m30, h1 }

/// 错误码/原因 → 中文。
const _codeZh = {
  'rate_limited': '限流',
  'banned': '账号封禁',
  'country_blocked': '区域限制',
  'out_of_credits': '余额不足',
  'waiting_room': '排队中',
  'auth_rejected': '上游鉴权拒绝',
  'invalid_api_key': '密钥无效',
  'timeout': '超时',
  'connection_error': '连接失败',
  'dns_error': 'DNS 解析失败',
  'probe_failed': '探测失败',
  'quota_exhausted': '额度耗尽',
  'locked': '锁定',
  'unknown': '未知',
};

/// 后台操作类型 → 中文。
const _actionZh = {
  'save_config': '保存配置',
  'probe': '立即探测',
  'clear_pin': '解除常驻',
  'reset_config': '恢复环境变量',
  'clear_logs': '清空日志',
};

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.state});

  final AppState state;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  _MainFilter _main = _MainFilter.all;
  _RouteFilter _route = _RouteFilter.all;
  String? _eventType; // null = 全部事件
  _TimeRange _time = _TimeRange.all;
  final _queryCtrl = TextEditingController();
  String _query = '';
  String? _expandedId; // 展开详情的条目 id
  bool _clearing = false;

  static const _eventTypes = [
    ('status_change', '状态变化'),
    ('failover', '故障转移'),
    ('probe_failed', '探测失败'),
    ('admin_action', '后台操作'),
    ('maintenance', '维护模式'),
    ('smoke', '测试请求'),
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _clear() async {
    final api = widget.state.api;
    if (api == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空日志'),
        content: const Text('将清空路由记录与系统事件（环形缓冲），确定吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _clearing = true);
    try {
      await api.clearLogs();
      await widget.state.refreshNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('清空失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  /// 过滤 + 排序得到当前展示列表。
  List<_LogItem> _filtered() {
    final ov = widget.state.overview;
    final now = DateTime.now();
    final items = <_LogItem>[];
    if (_main != _MainFilter.events) {
      for (final r in ov?.routes ?? const <RouteEntry>[]) {
        if (_route == _RouteFilter.ok && !r.ok) continue;
        if (_route == _RouteFilter.fail && r.ok) continue;
        items.add(_LogItem.route(r));
      }
    }
    if (_main != _MainFilter.routes) {
      for (final e in ov?.events ?? const <EventEntry>[]) {
        if (_eventType != null && e.type != _eventType) continue;
        items.add(_LogItem.event(e));
      }
    }
    // 时间范围
    if (_time != _TimeRange.all) {
      final cutoff = switch (_time) {
        _TimeRange.m5 => now.subtract(const Duration(minutes: 5)),
        _TimeRange.m30 => now.subtract(const Duration(minutes: 30)),
        _TimeRange.h1 => now.subtract(const Duration(hours: 1)),
        _TimeRange.all => null,
      };
      if (cutoff != null) items.removeWhere((it) => it.t.isBefore(cutoff));
    }
    // 搜索
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items.removeWhere((it) =>
          !it.title.toLowerCase().contains(q) &&
          !it.subtitle.toLowerCase().contains(q) &&
          !it.detailText.toLowerCase().contains(q));
    }
    items.sort((a, b) => b.t.compareTo(a.t));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          IconButton(
            tooltip: '清空日志',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearing ? null : _clear,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final ov = widget.state.overview;
          if (ov == null && !widget.state.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _filtered();
          return Column(
            children: [
              _filters(context),
              _statsBar(context, items),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.state.refreshNow,
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Center(child: Text('暂无匹配的日志')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: items.length,
                          itemBuilder: (context, i) => KeyedSubtree(
                            key: ValueKey(items[i].id),
                            child: _tile(context, items[i]),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────── 筛选区 ───────────────────────────

  Widget _filters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          TextField(
            controller: _queryCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: '搜索代理名 / 模型 / 类型 / 内容…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _queryCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 主筛选
          _chipRow([
            _ChipData(_MainFilter.all, '全部', _main == _MainFilter.all, () => setState(() => _main = _MainFilter.all)),
            _ChipData(_MainFilter.routes, '路由记录', _main == _MainFilter.routes, () => setState(() => _main = _MainFilter.routes)),
            _ChipData(_MainFilter.events, '系统事件', _main == _MainFilter.events, () => setState(() => _main = _MainFilter.events)),
          ]),
          // 子筛选：路由成功/失败
          if (_main == _MainFilter.routes)
            _chipRow([
              _ChipData(_RouteFilter.all, '全部', _route == _RouteFilter.all, () => setState(() => _route = _RouteFilter.all)),
              _ChipData(_RouteFilter.ok, '✓ 成功', _route == _RouteFilter.ok, () => setState(() => _route = _RouteFilter.ok)),
              _ChipData(_RouteFilter.fail, '✗ 失败', _route == _RouteFilter.fail, () => setState(() => _route = _RouteFilter.fail)),
            ]),
          // 子筛选：事件类型
          if (_main == _MainFilter.events)
            _chipRow([
              _ChipData('__all__', '全部事件', _eventType == null, () => setState(() => _eventType = null)),
              for (final (type, label) in _eventTypes)
                _ChipData(type, label, _eventType == type, () => setState(() => _eventType = type)),
            ]),
          // 时间范围
          _chipRow([
            _ChipData(_TimeRange.all, '全部时间', _time == _TimeRange.all, () => setState(() => _time = _TimeRange.all)),
            _ChipData(_TimeRange.m5, '近 5 分钟', _time == _TimeRange.m5, () => setState(() => _time = _TimeRange.m5)),
            _ChipData(_TimeRange.m30, '近 30 分钟', _time == _TimeRange.m30, () => setState(() => _time = _TimeRange.m30)),
            _ChipData(_TimeRange.h1, '近 1 小时', _time == _TimeRange.h1, () => setState(() => _time = _TimeRange.h1)),
          ]),
        ],
      ),
    );
  }

  Widget _chipRow(List<_ChipData> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in chips)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(c.label),
                  selected: c.selected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => c.onTap(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statsBar(BuildContext context, List<_LogItem> items) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final routes = items.where((i) => i.isRoute).toList();
    final okCount = routes.where((i) => i.ok).length;
    final failCount = routes.length - okCount;
    final avgMs = routes.isEmpty
        ? null
        : (routes.fold<int>(0, (a, i) => a + i.ms) / routes.length).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          Text('共 ${items.length} 条', style: t.bodySmall),
          const SizedBox(width: 10),
          Text('路由 $okCount✓/$failCount✗',
              style: t.bodySmall?.copyWith(color: scheme.outline)),
          if (avgMs != null) ...[
            const SizedBox(width: 10),
            Text('平均 ${avgMs}ms',
                style: t.bodySmall?.copyWith(color: scheme.outline)),
          ],
          const Spacer(),
          if (widget.state.lastUpdated != null)
            Text('更新 ${relativeTime(widget.state.lastUpdated)}',
                style: t.bodySmall?.copyWith(color: scheme.outline)),
        ],
      ),
    );
  }

  // ─────────────────────────── 列表项 ───────────────────────────

  Widget _tile(BuildContext context, _LogItem item) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final expanded = _expandedId == item.id;
    final isRoute = item.isRoute;
    final color = isRoute
        ? (item.ok ? StatusColors.okFor(context) : StatusColors.downFor(context))
        : scheme.primary;
    final icon = isRoute
        ? (item.ok ? Icons.check_circle : Icons.cancel)
        : Icons.event_note;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expandedId = expanded ? null : item.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.title,
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(relativeTime(item.t), style: t.bodySmall),
                  const SizedBox(width: 4),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: scheme.outline),
                ],
              ),
              const SizedBox(height: 2),
              Text(item.subtitle,
                  style: t.bodySmall?.copyWith(color: scheme.outline),
                  maxLines: expanded ? null : 2,
                  overflow: expanded ? null : TextOverflow.ellipsis),
              if (expanded) ...[
                const Divider(height: 12),
                ...item.detailFields.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 84,
                            child: Text(f.$1,
                                style: t.bodySmall?.copyWith(color: scheme.outline)),
                          ),
                          Expanded(
                            child: SelectableText(f.$2, style: t.bodySmall),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipData {
  const _ChipData(this.value, this.label, this.selected, this.onTap);

  final Object value;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// 日志行统一结构。
class _LogItem {
  _LogItem.route(RouteEntry r)
      : id = 'r|${r.t.millisecondsSinceEpoch}|${r.name}|${r.status}|${r.ms}',
        t = r.t,
        isRoute = true,
        ok = r.ok,
        ms = r.ms,
        title = '路由 → ${r.name} ${r.ok ? '(成功)' : '(失败)'}',
        subtitle = 'HTTP ${r.status} · 尝试 ${r.attempts} 次 · ${r.ms}ms'
            '${r.model != null ? ' · ${r.model}' : ''}',
        detailFields = [
          ('代理', r.name),
          ('状态码', '${r.status}'),
          ('尝试次数', '${r.attempts}'),
          ('耗时', '${r.ms}ms'),
          if (r.model != null) ('模型', r.model!),
          ('结果', r.ok ? '成功' : '失败'),
          ('时间', _fullTime(r.t)),
        ];

  _LogItem.event(EventEntry e)
      // 确定性 id: 用 jsonEncode(detail) 而非 hashCode,
      // 保证轮询刷新重建时展开状态不丢
      : id = 'e|${e.t.millisecondsSinceEpoch}|${e.type}|${jsonEncode(e.detail)}',
        t = e.t,
        isRoute = false,
        ok = true,
        ms = 0,
        title = _eventTitle(e),
        subtitle = _eventSubtitle(e),
        detailFields = _eventFields(e);

  final String id;
  final DateTime t;
  final bool isRoute;
  final bool ok;
  final int ms;
  final String title;
  final String subtitle;
  final List<(String, String)> detailFields;

  /// 搜索用全文。
  String get detailText =>
      detailFields.map((f) => '${f.$1} ${f.$2}').join(' ');

  static String _fullTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  // ── 事件中文语义化渲染 ──

  static String _eventTitle(EventEntry e) {
    const names = {
      'status_change': '状态变化',
      'failover': '故障转移',
      'probe_failed': '探测失败',
      'admin_action': '后台操作',
      'maintenance': '维护模式',
      'smoke': '测试请求',
    };
    return names[e.type] ?? e.type;
  }

  static String _zh(String? code) => _codeZh[code] ?? (code ?? '');

  static String _eventSubtitle(EventEntry e) {
    final d = e.detail;
    switch (e.type) {
      case 'status_change':
        final name = d['name'] ?? '?';
        final from = statusLabel('${d['from'] ?? ''}');
        final to = statusLabel('${d['to'] ?? ''}');
        final reason = d['reason'];
        return '$name: $from → $to'
            '${reason != null && reason.toString().isNotEmpty ? ' · 原因: ${_zh(reason.toString())}' : ''}';
      case 'failover':
        final name = d['name'] ?? '?';
        final from = statusLabel('${d['from'] ?? ''}');
        final to = statusLabel('${d['to'] ?? ''}');
        final code = d['code'];
        final status = d['status'];
        return '$name: $from → $to'
            '${code != null && code.toString().isNotEmpty ? ' · ${_zh(code.toString())}' : ''}'
            '${status != null ? ' (HTTP $status)' : ''}';
      case 'probe_failed':
        final name = d['name'] ?? '?';
        final err = d['err'];
        final errText = err == null ? '' : err.toString().replaceAll('\n', ' ');
        return '$name 探测失败'
            '${errText.isNotEmpty ? ' · ${errText.length > 90 ? '${errText.substring(0, 90)}…' : errText}' : ''}';
      case 'admin_action':
        final action = _actionZh['${d['action'] ?? ''}'] ?? '${d['action'] ?? '操作'}';
        final extras = <String>[
          if (d['name'] != null) '代理 ${d['name']}',
          if (d['proxies'] != null) '代理 ${d['proxies']} 个',
          if (d['settings'] != null) '参数 ${d['settings']}',
          if (d['key'] != null) 'key ${d['key']}',
          if (d['result'] != null) '结果 ${d['result']}',
        ];
        return action + (extras.isEmpty ? '' : ' · ${extras.join(' · ')}');
      case 'maintenance':
        final name = d['name'] ?? '?';
        final on = d['on'] == true;
        return '$name 维护${on ? '已开启' : '已关闭'}';
      case 'smoke':
        final model = d['model'] ?? '?';
        final proxy = d['proxy'];
        final status = d['status'];
        final ms = d['ms'];
        final ok = d['ok'] == true;
        return '$model'
            '${proxy != null ? ' → $proxy' : ''}'
            ' · HTTP $status'
            '${ms != null ? ' · ${ms}ms' : ''}'
            ' · ${ok ? '成功' : '失败'}';
      default:
        return e.detail.entries.map((kv) => '${kv.key}=${kv.value}').join(' · ');
    }
  }

  /// 展开详情的字段：语义化优先，未覆盖的原始字段兜底。
  static List<(String, String)> _eventFields(EventEntry e) {
    final d = e.detail;
    final fields = <(String, String)>[
      ('类型', _eventTitle(e)),
    ];
    switch (e.type) {
      case 'status_change':
        fields.add(('代理', '${d['name'] ?? '?'}'));
        fields.add(('变化',
            '${statusLabel('${d['from'] ?? ''}')} → ${statusLabel('${d['to'] ?? ''}')}'));
        if (d['reason'] != null) {
          fields.add(('原因', '${d['reason']} (${_zh(d['reason'].toString())})'));
        }
        if (d['detail'] != null) fields.add(('详情', '${d['detail']}'));
      case 'failover':
        fields.add(('代理', '${d['name'] ?? '?'}'));
        fields.add(('变化',
            '${statusLabel('${d['from'] ?? ''}')} → ${statusLabel('${d['to'] ?? ''}')}'));
        if (d['code'] != null) {
          fields.add(('错误码', '${d['code']} (${_zh(d['code'].toString())})'));
        }
        if (d['status'] != null) fields.add(('HTTP', '${d['status']}'));
      case 'probe_failed':
        fields.add(('代理', '${d['name'] ?? '?'}'));
        if (d['status'] != null) fields.add(('状态', '${d['status']}'));
        if (d['err'] != null) fields.add(('错误', '${d['err']}'));
      case 'admin_action':
        fields.add(
            ('操作', '${_actionZh['${d['action'] ?? ''}'] ?? d['action'] ?? ''}'));
        for (final k in ['name', 'proxies', 'settings', 'result', 'key']) {
          if (d[k] != null) fields.add((k, '${d[k]}'));
        }
      case 'maintenance':
        fields.add(('代理', '${d['name'] ?? '?'}'));
        fields.add(('状态', d['on'] == true ? '已开启' : '已关闭'));
      case 'smoke':
        if (d['model'] != null) fields.add(('模型', '${d['model']}'));
        if (d['proxy'] != null) fields.add(('路由到', '${d['proxy']}'));
        if (d['status'] != null) fields.add(('HTTP', '${d['status']}'));
        if (d['ms'] != null) fields.add(('耗时', '${d['ms']}ms'));
        if (d['ok'] != null) fields.add(('结果', d['ok'] == true ? '成功' : '失败'));
      default:
        for (final kv in d.entries) {
          fields.add((kv.key, '${kv.value}'));
        }
    }
    // 未在语义化里覆盖的原始字段兜底
    final covered = <String>{for (final f in fields.skip(1)) f.$1};
    for (final kv in d.entries) {
      if (!covered.contains(kv.key)) fields.add((kv.key, '${kv.value}'));
    }
    fields.add(('时间', _fullTime(e.t)));
    return fields;
  }
}
