/// 日志页：路由记录 + 系统事件，chips 筛选，可清空。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';

enum _LogFilter { all, routes, events }

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.state});

  final AppState state;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  _LogFilter _filter = _LogFilter.all;
  bool _clearing = false;

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
          // 合并并排序（时间倒序）
          final items = <_LogItem>[];
          if (_filter != _LogFilter.events) {
            for (final r in ov?.routes ?? const <RouteEntry>[]) {
              items.add(_LogItem.route(r));
            }
          }
          if (_filter != _LogFilter.routes) {
            for (final e in ov?.events ?? const <EventEntry>[]) {
              items.add(_LogItem.event(e));
            }
          }
          items.sort((a, b) => b.t.compareTo(a.t));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip(_LogFilter.all, '全部'),
                            _chip(_LogFilter.routes, '路由记录'),
                            _chip(_LogFilter.events, '系统事件'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${items.length} 条',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.state.refreshNow,
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('暂无日志')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
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

  Widget _chip(_LogFilter f, String label) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
      ),
    );
  }

  Widget _tile(BuildContext context, _LogItem item) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isRoute = item.isRoute;
    final color = isRoute
        ? (item.ok ? Colors.green : Colors.red)
        : scheme.primary;
    final icon = isRoute
        ? (item.ok ? Icons.check_circle : Icons.cancel)
        : Icons.event_note;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 20),
        title: Text(item.title, style: t.bodyMedium),
        subtitle: Text(item.subtitle,
            style: t.bodySmall?.copyWith(color: scheme.outline),
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        trailing: Text(relativeTime(item.t), style: t.bodySmall),
      ),
    );
  }
}

/// 日志行统一结构。
class _LogItem {
  _LogItem.route(RouteEntry r)
      : t = r.t,
        isRoute = true,
        ok = r.ok,
        title = '路由 → ${r.name} ${r.ok ? '(成功)' : '(失败)'}',
        subtitle = 'HTTP ${r.status} · 尝试 ${r.attempts} 次 · ${r.ms}ms'
            '${r.model != null ? ' · ${r.model}' : ''}';

  _LogItem.event(EventEntry e)
      : t = e.t,
        isRoute = false,
        ok = true,
        title = _eventTitle(e),
        subtitle = _eventDetail(e);

  final DateTime t;
  final bool isRoute;
  final bool ok;
  final String title;
  final String subtitle;

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
