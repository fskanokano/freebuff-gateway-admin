/// 日志页：路由记录 + 系统事件。
/// 基于 flutter-shadcn-ui；支持搜索/类型筛选/时间范围/统计/展开详情（轮询不打断）/清空。
library;

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart' show RefreshIndicator, SelectableText, Tooltip;

import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
  String? _eventType;
  _TimeRange _time = _TimeRange.all;
  final _queryCtrl = TextEditingController();
  String _query = '';
  String? _expandedId;
  bool _clearing = false;

  static const _eventTypes = [
    'status_change', 'failover', 'probe_failed',
    'admin_action', 'maintenance', 'smoke',
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _clear() async {
    final api = widget.state.api;
    if (api == null) return;
    final l10n = context.l10n;
    final ok = await showShadcnConfirm(
      context,
      title: l10n.logsClearTitle,
      message: l10n.logsClearMessage,
      confirmText: l10n.logsClear,
      destructive: true,
    );
    if (ok != true) return;
    setState(() => _clearing = true);
    try {
      await api.clearLogs();
      await widget.state.refreshNow();
    } catch (e) {
      if (mounted) showShadcnToast(context, l10n.logsClearFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  List<_LogItem> _filtered() {
    final ov = widget.state.overview;
    final l10n = context.l10n;
    final now = DateTime.now();
    final items = <_LogItem>[];
    if (_main != _MainFilter.events) {
      for (final r in ov?.routes ?? const <RouteEntry>[]) {
        if (_route == _RouteFilter.ok && !r.ok) continue;
        if (_route == _RouteFilter.fail && r.ok) continue;
        items.add(_LogItem.route(r, l10n));
      }
    }
    if (_main != _MainFilter.routes) {
      for (final e in ov?.events ?? const <EventEntry>[]) {
        if (_eventType != null && e.type != _eventType) continue;
        items.add(_LogItem.event(e, l10n));
      }
    }
    if (_time != _TimeRange.all) {
      final cutoff = switch (_time) {
        _TimeRange.m5 => now.subtract(const Duration(minutes: 5)),
        _TimeRange.m30 => now.subtract(const Duration(minutes: 30)),
        _TimeRange.h1 => now.subtract(const Duration(hours: 1)),
        _TimeRange.all => null,
      };
      if (cutoff != null) items.removeWhere((it) => it.t.isBefore(cutoff));
    }
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
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final ov = widget.state.overview;
          if (ov == null && !widget.state.hasError) {
            return Column(
              children: [
                GlassAppBar(title: Text(context.l10n.tabLogs)),
                const Expanded(
                    child: Center(child: CupertinoActivityIndicator())),
              ],
            );
          }
          final items = _filtered();
          return Column(
            children: [
              GlassAppBar(
                title: Text(context.l10n.tabLogs),
                actions: [
                  Tooltip(
                    message: context.l10n.logsClear,
                    child: TapFeedback(
                      onTap: _clearing ? null : _clear,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(CupertinoIcons.trash, size: 19),
                      ),
                    ),
                  ),
                ],
              ),
              _filters(context),
              _statsBar(context, items),
              _insightsCard(context),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(context.l10n.logsEmpty)
                    : RefreshIndicator(
                        onRefresh: widget.state.refreshNow,
                        child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInput(
            controller: _queryCtrl,
            placeholder: Text(l10n.logsSearchPlaceholder),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 10),
          _pillRow(context, [
            ShadcnPill(l10n.logsAll, selected: _main == _MainFilter.all,
                onTap: () => setState(() => _main = _MainFilter.all)),
            ShadcnPill(l10n.logsRoutes, selected: _main == _MainFilter.routes,
                onTap: () => setState(() => _main = _MainFilter.routes)),
            ShadcnPill(l10n.logsEvents, selected: _main == _MainFilter.events,
                onTap: () => setState(() => _main = _MainFilter.events)),
          ]),
          if (_main == _MainFilter.routes)
            _pillRow(context, [
              ShadcnPill(l10n.logsAll, selected: _route == _RouteFilter.all,
                  onTap: () => setState(() => _route = _RouteFilter.all)),
              ShadcnPill(l10n.logsSuccess, selected: _route == _RouteFilter.ok,
                  onTap: () => setState(() => _route = _RouteFilter.ok)),
              ShadcnPill(l10n.logsFail, selected: _route == _RouteFilter.fail,
                  onTap: () => setState(() => _route = _RouteFilter.fail)),
            ]),
          if (_main == _MainFilter.events)
            _pillRow(context, [
              ShadcnPill(l10n.logsAllEvents, selected: _eventType == null,
                  onTap: () => setState(() => _eventType = null)),
              for (final type in _eventTypes)
                ShadcnPill(l10n.eventTypeLabel(type), selected: _eventType == type,
                    onTap: () => setState(() => _eventType = type)),
            ]),
          _pillRow(context, [
            ShadcnPill(l10n.logsAllTime, selected: _time == _TimeRange.all,
                onTap: () => setState(() => _time = _TimeRange.all)),
            ShadcnPill(l10n.logsLast5m, selected: _time == _TimeRange.m5,
                onTap: () => setState(() => _time = _TimeRange.m5)),
            ShadcnPill(l10n.logsLast30m, selected: _time == _TimeRange.m30,
                onTap: () => setState(() => _time = _TimeRange.m30)),
            ShadcnPill(l10n.logsLast1h, selected: _time == _TimeRange.h1,
                onTap: () => setState(() => _time = _TimeRange.h1)),
          ]),
        ],
      ),
    );
  }

  Widget _pillRow(BuildContext context, List<Widget> pills) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final p in pills) ...[p, const SizedBox(width: 6)],
          ],
        ),
      ),
    );
  }

  Widget _statsBar(BuildContext context, List<_LogItem> items) {
    final l10n = context.l10n;
    final routes = items.where((i) => i.isRoute).toList();
    final okCount = routes.where((i) => i.ok).length;
    final failCount = routes.length - okCount;
    final avgMs = routes.isEmpty
        ? null
        : (routes.fold<int>(0, (a, i) => a + i.ms) / routes.length).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Row(
        children: [
          Text(l10n.logsCount(items.length),
              style: ShadTheme.of(context).textTheme.small),
          const SizedBox(width: 10),
          Text(l10n.logsRouteCount(okCount, failCount),
              style: ShadTheme.of(context).textTheme.small),
          if (avgMs != null) ...[
            const SizedBox(width: 10),
            Text(l10n.logsAvgMs(avgMs),
                style: ShadTheme.of(context).textTheme.small),
          ],
          const Spacer(),
          if (widget.state.lastUpdated != null)
            Text(l10n.logsUpdated(l10n.relativeTime(widget.state.lastUpdated)),
                style: ShadTheme.of(context).textTheme.small),
        ],
      ),
    );
  }

  /// 聚合洞察：HTTP 状态码 / 失败原因码 / 事件类型 分布（来自原始 overview，不受筛选影响）。
  Widget _insightsCard(BuildContext context) {
    final l10n = context.l10n;
    final ov = widget.state.overview;
    final routes = ov?.routes ?? const <RouteEntry>[];
    final events = ov?.events ?? const <EventEntry>[];

    final statusCounts = <int, int>{};
    for (final r in routes) {
      if (r.status > 0) statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
    }
    final codeCounts = <String, int>{};
    final typeCounts = <String, int>{};
    for (final e in events) {
      final c = e.detail['code'];
      if (c != null && c.toString().isNotEmpty) {
        final k = c.toString();
        codeCounts[k] = (codeCounts[k] ?? 0) + 1;
      }
      typeCounts[e.type] = (typeCounts[e.type] ?? 0) + 1;
    }

    final rows = <Widget>[];
    if (statusCounts.isNotEmpty) {
      final s = statusCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      rows.add(_insightRow(context, l10n.logsInsightStatus,
          s.take(6).map((e) => '${e.key} ×${e.value}').toList()));
    }
    if (codeCounts.isNotEmpty) {
      final s = codeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      rows.add(_insightRow(context, l10n.logsInsightFailReason,
          s.take(6).map((e) => '${l10n.codeLabel(e.key)} ×${e.value}').toList()));
    }
    if (typeCounts.isNotEmpty) {
      final s = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      rows.add(_insightRow(context, l10n.logsInsightEventType,
          s.take(6).map((e) => '${l10n.eventTypeLabel(e.key)} ×${e.value}').toList()));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ShadCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
      ),
    );
  }

  Widget _insightRow(BuildContext context, String label, List<String> chips) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: ShadTheme.of(context)
                  .textTheme
                  .small
                  .copyWith(color: mutedColor(context))),
          const SizedBox(height: 5),
          Wrap(spacing: 6, runSpacing: 4, children: [for (final c in chips) TagChip(c)]),
        ],
      ),
    );
  }

  // ─────────────────────────── 列表项 ───────────────────────────

  Widget _tile(BuildContext context, _LogItem item) {
    final expanded = _expandedId == item.id;
    final isRoute = item.isRoute;
    final color = isRoute
        ? (item.ok ? ShadcnColors.ok : ShadcnColors.danger)
        : schemeColor(context);
    final icon = isRoute
        ? (item.ok
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.xmark_circle_fill)
        : CupertinoIcons.flag_fill;
    return fadeSlideIn(Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: TapFeedback(
          onTap: () => setState(() => _expandedId = expanded ? null : item.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.title,
                      style: ShadTheme.of(context)
                          .textTheme
                          .p
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(context.l10n.relativeTime(item.t),
                      style: ShadTheme.of(context).textTheme.small),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 13,
                      color: mutedColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: ShadTheme.of(context).textTheme.small,
                maxLines: expanded ? null : 2,
                overflow: expanded ? null : TextOverflow.ellipsis,
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? Column(
                          key: ValueKey('detail-${item.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ShadcnDivider(),
                            const SizedBox(height: 6),
                            ...item.detailFields.map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1.5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 82,
                                    child: Text(f.$1,
                                        style: ShadTheme.of(context)
                                            .textTheme
                                            .small),
                                  ),
                                  Expanded(
                                    child: SelectableText(f.$2,
                                        style: ShadTheme.of(context)
                                            .textTheme
                                            .small),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

/// 日志行统一结构。
class _LogItem {
  _LogItem.route(RouteEntry r, AppLocalizations l10n)
      : id = 'r|${r.t.millisecondsSinceEpoch}|${r.name}|${r.status}|${r.ms}',
        t = r.t,
        isRoute = true,
        ok = r.ok,
        ms = r.ms,
        title = l10n.logsRouteTitle(
            r.name, r.ok ? l10n.logsRouteOk : l10n.logsRouteFail),
        subtitle = l10n.logsHttpAttempts(r.status, r.attempts, r.ms) +
            (r.model != null ? ' · ${r.model}' : ''),
        detailFields = [
          (l10n.fieldProxy, r.name),
          (l10n.fieldStatusCode, '${r.status}'),
          (l10n.fieldAttempts, '${r.attempts}'),
          (l10n.fieldLatency, '${r.ms}ms'),
          if (r.model != null) (l10n.fieldModel, r.model!),
          (l10n.fieldResult, r.ok ? l10n.smokeOk : l10n.smokeFail),
          (l10n.fieldTime, _fullTime(r.t)),
        ];

  _LogItem.event(EventEntry e, AppLocalizations l10n)
      : id = 'e|${e.t.millisecondsSinceEpoch}|${e.type}|${jsonEncode(e.detail)}',
        t = e.t,
        isRoute = false,
        ok = true,
        ms = 0,
        title = _eventTitle(l10n, e),
        subtitle = _eventSubtitle(l10n, e),
        detailFields = _eventFields(l10n, e);

  final String id;
  final DateTime t;
  final bool isRoute;
  final bool ok;
  final int ms;
  final String title;
  final String subtitle;
  final List<(String, String)> detailFields;

  String get detailText =>
      detailFields.map((f) => '${f.$1} ${f.$2}').join(' ');

  static String _fullTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  static String _eventTitle(AppLocalizations l10n, EventEntry e) =>
      l10n.eventTypeLabel(e.type);

  static String _eventSubtitle(AppLocalizations l10n, EventEntry e) {
    final d = e.detail;
    switch (e.type) {
      case 'status_change':
        final name = d['name'] ?? '?';
        final from = l10n.statusLabel('${d['from'] ?? ''}');
        final to = l10n.statusLabel('${d['to'] ?? ''}');
        final reason = d['reason'] != null
            ? ' · ${l10n.proxiesReason}: ${l10n.codeLabel(d['reason'].toString())}'
            : '';
        return '$name: $from → $to$reason';
      case 'failover':
        final name = d['name'] ?? '?';
        final from = l10n.statusLabel('${d['from'] ?? ''}');
        final to = l10n.statusLabel('${d['to'] ?? ''}');
        return '$name: $from → $to';
      case 'probe_failed':
        final name = d['name'] ?? '?';
        final code = d['code'];
        final msg = code != null
            ? l10n.codeLabel(code.toString())
            : (d['error'] ?? l10n.codeProbeFailed);
        return '$name: $msg';
      case 'admin_action':
        final action = d['action'] ?? '';
        final extras = <String>[
          if (d['name'] != null) '${l10n.fieldProxy} ${d['name']}',
          if (d['proxies'] != null) l10n.fieldProxiesCount('${d['proxies']}'),
          if (d['settings'] != null) l10n.fieldParamsCount('${d['settings']}'),
          if (d['key'] != null) '${l10n.fieldKey} ${d['key']}',
          if (d['result'] != null) '${l10n.fieldResult} ${d['result']}',
        ];
        return '${l10n.actionLabel(action)}${extras.isNotEmpty ? ' · ${extras.join(' · ')}' : ''}';
      case 'maintenance':
        final name = d['name'] ?? '?';
        final on = d['on'] == true;
        return '$name: ${on ? l10n.fieldEnabled : l10n.fieldDisabled}';
      case 'smoke':
        final status = d['status'];
        final ms = d['ms'];
        final ok = d['ok'] == true;
        final proxy = d['proxy'];
        final parts = <String>[
          if (status != null) 'HTTP $status',
          ok ? l10n.smokeOk : l10n.smokeFail,
          if (proxy != null) '${l10n.fieldRouteTo} $proxy',
          if (ms != null) '${ms}ms',
        ];
        return parts.join(' · ');
      default:
        return '$d';
    }
  }

  static List<(String, String)> _eventFields(AppLocalizations l10n, EventEntry e) {
    final d = e.detail;
    final fields = <(String, String)>[(l10n.fieldType, _eventTitle(l10n, e))];
    switch (e.type) {
      case 'status_change':
        fields.add((l10n.fieldProxy, '${d['name'] ?? '?'}'));
        fields.add((l10n.fieldChange,
            '${l10n.statusLabel('${d['from'] ?? ''}')} → ${l10n.statusLabel('${d['to'] ?? ''}')}'));
        if (d['reason'] != null) {
          fields.add((l10n.proxiesReason,
              '${d['reason']} (${l10n.codeLabel(d['reason'].toString())})'));
        }
        if (d['detail'] != null) fields.add((l10n.proxiesDetail, '${d['detail']}'));
        break;
      case 'failover':
        fields.add((l10n.fieldProxy, '${d['name'] ?? '?'}'));
        fields.add((l10n.fieldChange,
            '${l10n.statusLabel('${d['from'] ?? ''}')} → ${l10n.statusLabel('${d['to'] ?? ''}')}'));
        break;
      case 'probe_failed':
        fields.add((l10n.fieldProxy, '${d['name'] ?? '?'}'));
        if (d['code'] != null) {
          fields.add((l10n.fieldErrorCode, l10n.codeLabel(d['code'].toString())));
        }
        if (d['error'] != null) fields.add((l10n.fieldError, '${d['error']}'));
        break;
      case 'admin_action':
        fields.add((l10n.fieldAction, l10n.actionLabel(d['action']?.toString())));
        for (final kv in d.entries) {
          if (kv.key == 'action') continue;
          fields.add((kv.key, '${kv.value}'));
        }
        break;
      case 'maintenance':
        fields.add((l10n.fieldProxy, '${d['name'] ?? '?'}'));
        fields.add((l10n.fieldStatus,
            d['on'] == true ? l10n.fieldEnabled : l10n.fieldDisabled));
        break;
      case 'smoke':
        if (d['model'] != null) fields.add((l10n.fieldModel, '${d['model']}'));
        if (d['proxy'] != null) fields.add((l10n.fieldRouteTo, '${d['proxy']}'));
        if (d['status'] != null) fields.add(('HTTP', '${d['status']}'));
        if (d['ms'] != null) fields.add((l10n.fieldLatency, '${d['ms']}ms'));
        if (d['ok'] != null) {
          fields.add((l10n.fieldResult, d['ok'] == true ? l10n.smokeOk : l10n.smokeFail));
        }
        break;
      default:
        for (final kv in d.entries) {
          fields.add((kv.key, '${kv.value}'));
        }
    }
    final covered = <String>{for (final f in fields.skip(1)) f.$1};
    for (final kv in d.entries) {
      if (!covered.contains(kv.key)) fields.add((kv.key, '${kv.value}'));
    }
    fields.add((l10n.fieldTime, _fullTime(e.t)));
    return fields;
  }
}
