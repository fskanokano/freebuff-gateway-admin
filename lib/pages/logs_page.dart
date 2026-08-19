/// 日志页：路由记录 + 系统事件。
/// 支持：关键词搜索、类型筛选（路由成功/失败、事件类型细分）、时间范围、
/// 结果统计、条目展开详情、清空。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';

enum _MainFilter { all, routes, events }

enum _RouteFilter { all, ok, fail }

enum _TimeRange { all, m5, m30, h1 }

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
                          itemBuilder: (context, i) => _tile(context, items[i]),
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
        ? (item.ok ? Colors.green : Colors.red)
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
      : id = 'r-${r.t.millisecondsSinceEpoch}-${r.name}-${r.status}',
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
      : id = 'e-${e.t.millisecondsSinceEpoch}-${e.type}-${e.detail.hashCode}',
        t = e.t,
        isRoute = false,
        ok = true,
        ms = 0,
        title = _eventTitle(e),
        subtitle = _eventDetail(e),
        detailFields = [
          ('类型', _eventTitle(e)),
          ('原始类型', e.type),
          for (final kv in e.detail.entries) (kv.key, '${kv.value}'),
          ('时间', _fullTime(e.t)),
        ];

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

  static String _eventDetail(EventEntry e) {
    final d = e.detail;
    String pair(String k) {
      final v = d[k];
      return v == null ? '' : '$k=$v';
    }

    switch (e.type) {
      case 'status_change':
        return [pair('name'), pair('from'), pair('to'), pair('reason')]
            .where((s) => s.isNotEmpty)
            .join(' · ');
      case 'failover':
        return [pair('name'), pair('from'), pair('to'), pair('code'), pair('status')]
            .where((s) => s.isNotEmpty)
            .join(' · ');
      case 'probe_failed':
        return [pair('name'), pair('status'), pair('err')]
            .where((s) => s.isNotEmpty)
            .join(' · ');
      case 'admin_action':
        return [pair('action'), pair('name'), pair('proxies'), pair('settings'), pair('result'), pair('key')]
            .where((s) => s.isNotEmpty)
            .join(' · ');
      case 'maintenance':
        return [pair('name'), pair('on')].where((s) => s.isNotEmpty).join(' · ');
      case 'smoke':
        return [pair('model'), pair('status'), pair('proxy'), pair('ms'), pair('ok')]
            .where((s) => s.isNotEmpty)
            .join(' · ');
      default:
        return d.entries.map((e2) => '${e2.key}=${e2.value}').join(' · ');
    }
  }
}
