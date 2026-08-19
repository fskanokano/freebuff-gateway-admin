/// 日志页：路由记录 + 系统事件。
/// 基于 flutter-shadcn-ui；支持搜索/类型筛选/时间范围/统计/展开详情（轮询不打断）/清空。
library;

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart' show SelectableText;

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
  String? _eventType;
  _TimeRange _time = _TimeRange.all;
  final _queryCtrl = TextEditingController();
  String _query = '';
  String? _expandedId;
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
    final ok = await showShadcnConfirm(
      context,
      title: '清空日志',
      message: '将清空路由记录与系统事件（环形缓冲），确定吗？',
      confirmText: '清空',
      destructive: true,
    );
    if (ok != true) return;
    setState(() => _clearing = true);
    try {
      await api.clearLogs();
      await widget.state.refreshNow();
    } catch (e) {
      if (mounted) showShadcnToast(context, '清空失败: $e');
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

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
                GlassAppBar(title: const Text('日志')),
                const Expanded(
                    child: Center(child: CupertinoActivityIndicator())),
              ],
            );
          }
          final items = _filtered();
          return Column(
            children: [
              GlassAppBar(
                title: const Text('日志'),
                actions: [
                  TapFeedback(
                    onTap: _clearing ? null : _clear,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(CupertinoIcons.trash, size: 19),
                    ),
                  ),
                ],
              ),
              _filters(context),
              _statsBar(context, items),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState('暂无匹配的日志')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (context, i) => KeyedSubtree(
                          key: ValueKey(items[i].id),
                          child: _tile(context, items[i]),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInput(
            controller: _queryCtrl,
            placeholder: Text('搜索代理名 / 模型 / 类型 / 内容…'),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 10),
          _pillRow(context, [
            ShadcnPill('全部', selected: _main == _MainFilter.all,
                onTap: () => setState(() => _main = _MainFilter.all)),
            ShadcnPill('路由记录', selected: _main == _MainFilter.routes,
                onTap: () => setState(() => _main = _MainFilter.routes)),
            ShadcnPill('系统事件', selected: _main == _MainFilter.events,
                onTap: () => setState(() => _main = _MainFilter.events)),
          ]),
          if (_main == _MainFilter.routes)
            _pillRow(context, [
              ShadcnPill('全部', selected: _route == _RouteFilter.all,
                  onTap: () => setState(() => _route = _RouteFilter.all)),
              ShadcnPill('✓ 成功', selected: _route == _RouteFilter.ok,
                  onTap: () => setState(() => _route = _RouteFilter.ok)),
              ShadcnPill('✗ 失败', selected: _route == _RouteFilter.fail,
                  onTap: () => setState(() => _route = _RouteFilter.fail)),
            ]),
          if (_main == _MainFilter.events)
            _pillRow(context, [
              ShadcnPill('全部事件', selected: _eventType == null,
                  onTap: () => setState(() => _eventType = null)),
              for (final (type, label) in _eventTypes)
                ShadcnPill(label, selected: _eventType == type,
                    onTap: () => setState(() => _eventType = type)),
            ]),
          _pillRow(context, [
            ShadcnPill('全部时间', selected: _time == _TimeRange.all,
                onTap: () => setState(() => _time = _TimeRange.all)),
            ShadcnPill('近 5 分钟', selected: _time == _TimeRange.m5,
                onTap: () => setState(() => _time = _TimeRange.m5)),
            ShadcnPill('近 30 分钟', selected: _time == _TimeRange.m30,
                onTap: () => setState(() => _time = _TimeRange.m30)),
            ShadcnPill('近 1 小时', selected: _time == _TimeRange.h1,
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
          Text('共 ${items.length} 条',
              style: ShadTheme.of(context).textTheme.small),
          const SizedBox(width: 10),
          Text('路由 $okCount✓/$failCount✗',
              style: ShadTheme.of(context).textTheme.small),
          if (avgMs != null) ...[
            const SizedBox(width: 10),
            Text('平均 ${avgMs}ms',
                style: ShadTheme.of(context).textTheme.small),
          ],
          const Spacer(),
          if (widget.state.lastUpdated != null)
            Text('更新 ${relativeTime(widget.state.lastUpdated)}',
                style: ShadTheme.of(context).textTheme.small),
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
                Text(relativeTime(item.t),
                    style: ShadTheme.of(context).textTheme.small),
                const SizedBox(width: 4),
                // 展开箭头: 旋转动画
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
            // 详情: AnimatedSize 平滑展开/收起
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
                              style: ShadTheme.of(context).textTheme.small),
                        ),
                        Expanded(
                          child: SelectableText(f.$2,
                              style: ShadTheme.of(context).textTheme.small),
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
    ),
    );
  }
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
    final covered = <String>{for (final f in fields.skip(1)) f.$1};
    for (final kv in d.entries) {
      if (!covered.contains(kv.key)) fields.add((kv.key, '${kv.value}'));
    }
    fields.add(('时间', _fullTime(e.t)));
    return fields;
  }
}
