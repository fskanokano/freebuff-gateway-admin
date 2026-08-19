/// 分析页：消费柱状图 + 额度用量 + 请求趋势（客户端环形缓冲）+ 模型可用性矩阵。
/// 数据全部来自现有 overview（spend/tier/country 已由后端下发）与客户端轮询历史，零后端改动。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show RefreshIndicator, Tooltip;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum _SpendWindow { day, week, month }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.state});

  final AppState state;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  _SpendWindow _window = _SpendWindow.month;
  List<ModelInfo> _models = [];
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final api = widget.state.api;
    if (api == null) return;
    setState(() => _loadingModels = true);
    try {
      final list = await api.models();
      if (mounted) setState(() => _models = list);
    } catch (_) {
      if (mounted) setState(() => _models = []);
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          return Column(
            children: [
              GlassAppBar(
                title: Text(context.l10n.tabAnalytics),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: context.l10n.commonRefresh,
                      child: TapFeedback(
                        onTap: widget.state.refreshNow,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(CupertinoIcons.refresh, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.state.refreshNow,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(context.l10n.analyticsSpendByProxy),
                      _spendCard(context),
                      SectionTitle(context.l10n.analyticsUsage),
                      _usageCard(context),
                      SectionTitle(context.l10n.analyticsTrend),
                      _trendCard(context),
                      SectionTitle(context.l10n.analyticsModels),
                      _modelsCard(context),
                    ],
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

  double? _spendOf(ProxyInfo p) => switch (_window) {
        _SpendWindow.day => p.spend24h,
        _SpendWindow.week => p.spendWeek,
        _SpendWindow.month => p.spendMonth,
      };

  Widget _spendCard(BuildContext context) {
    final proxies = widget.state.overview?.proxies ?? const <ProxyInfo>[];
    final entries = <(String, double)>[];
    for (final p in proxies) {
      final v = _spendOf(p);
      if (v != null && v > 0) entries.add((p.name, v));
    }
    final primary = schemeColor(context);
    final muted = mutedColor(context);
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_windowLabel(),
                  style: ShadTheme.of(context).textTheme.small.copyWith(color: muted)),
              const Spacer(),
              for (final (w, label) in [
                (_SpendWindow.day, context.l10n.analyticsWindow24h),
                (_SpendWindow.week, context.l10n.analyticsWindowWeek),
                (_SpendWindow.month, context.l10n.analyticsWindowMonth),
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ShadcnPill(
                    label,
                    selected: _window == w,
                    onTap: () => setState(() => _window = w),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            _empty(context, context.l10n.analyticsNoSpend)
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: entries.map((e) => e.$2).reduce((a, b) => a > b ? a : b) * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _niceInterval(entries.map((e) => e.$2).reduce((a, b) => a > b ? a : b)),
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: borderColor(context).withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (v, meta) => Text(
                          context.l10n.compact(v),
                          style: ShadTheme.of(context).textTheme.small.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= entries.length) return const SizedBox();
                          final name = entries[i].$1;
                          final short = name.length > 6 ? name.substring(0, 6) : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(short,
                                style: ShadTheme.of(context)
                                    .textTheme
                                    .small
                                    .copyWith(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: entries[i].$2,
                          color: primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _windowLabel() => switch (_window) {
        _SpendWindow.day => context.l10n.analyticsSpend24h,
        _SpendWindow.week => context.l10n.analyticsSpendWeek,
        _SpendWindow.month => context.l10n.analyticsSpendMonth,
      };

  Widget _usageCard(BuildContext context) {
    final proxies = widget.state.overview?.proxies ?? const <ProxyInfo>[];
    if (proxies.isEmpty) return _card(_empty(context, context.l10n.analyticsNoProxies));
    return ShadCard(
      child: Column(
        children: [
          for (final (i, p) in proxies.indexed) ...[
            if (i > 0) const ShadcnDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 110, child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ShadTheme.of(context).textTheme.small)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UsageBar(percent: p.usagePct),
                        if (p.dailyLimit != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '24h ${formatCount(p.messages24h ?? 0)} / ${formatCount(p.dailyLimit!)}',
                              style: ShadTheme.of(context).textTheme.small.copyWith(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trendCard(BuildContext context) {
    final history = widget.state.history;
    if (history.length < 2) {
      return _card(_empty(context, context.l10n.analyticsCollecting));
    }
    final okSpots = <FlSpot>[];
    final failSpots = <FlSpot>[];
    for (var i = 1; i < history.length; i++) {
      final prev = history[i - 1];
      final cur = history[i];
      final x = (i - 1).toDouble();
      final okDelta = (cur.requestsOk - prev.requestsOk).clamp(0, 1 << 30);
      final failDelta = (cur.requestsFail - prev.requestsFail).clamp(0, 1 << 30);
      okSpots.add(FlSpot(x, okDelta.toDouble()));
      failSpots.add(FlSpot(x, failDelta.toDouble()));
    }
    final maxY = okSpots.map((s) => s.y).fold<double>(1, (a, b) => a > b ? a : b);
    final okColor = ShadcnColors.ok;
    final failColor = ShadcnColors.danger;
    final latest = history.last;
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(okColor),
              Text(' ${context.l10n.analyticsSuccess}', style: ShadTheme.of(context).textTheme.small),
              const SizedBox(width: 12),
              _legendDot(failColor),
              Text(' ${context.l10n.analyticsFail}', style: ShadTheme.of(context).textTheme.small),
              const Spacer(),
              if (latest.avgMs != null)
                Text(context.l10n.analyticsAvgLatency(latest.avgMs!.round()),
                    style: ShadTheme.of(context).textTheme.small.copyWith(color: mutedColor(context))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (okSpots.length - 1).toDouble(),
                minY: 0,
                maxY: (maxY * 1.2).clamp(1, double.infinity),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: borderColor(context).withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) => Text(
                        context.l10n.compact(v),
                        style: ShadTheme.of(context).textTheme.small.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: okSpots,
                    isCurved: true,
                    color: okColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: okColor.withValues(alpha: 0.12)),
                  ),
                  LineChartBarData(
                    spots: failSpots,
                    isCurved: true,
                    color: failColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: failColor.withValues(alpha: 0.12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelsCard(BuildContext context) {
    if (_loadingModels) {
      return _card(const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CupertinoActivityIndicator()),
      ));
    }
    if (_models.isEmpty) {
      return _card(_empty(context, context.l10n.analyticsNoModels));
    }
    return ShadCard(
      child: Column(
        children: [
          for (final (i, m) in _models.indexed) ...[
            if (i > 0) const ShadcnDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(m.id, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: ShadTheme.of(context).textTheme.small),
                  ),
                  _modelBadge(context, 'ok', m.statuses['ok'] ?? 0, ShadcnColors.ok),
                  _modelBadge(context, context.l10n.analyticsModelDepleted,
                      m.statuses['depleted'] ?? 0, ShadcnColors.warning),
                  _modelBadge(context, context.l10n.analyticsModelDown,
                      m.statuses['down'] ?? 0, ShadcnColors.danger),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modelBadge(BuildContext context, String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark(context) ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(kBadgeRadius),
      ),
      child: Text('$label $count',
          style: ShadTheme.of(context).textTheme.small.copyWith(fontSize: 10)),
    );
  }

  Widget _legendDot(Color c) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _empty(BuildContext context, String msg) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(msg,
              style: ShadTheme.of(context).textTheme.small.copyWith(color: mutedColor(context))),
        ),
      );

  Widget _card(Widget child) => ShadCard(child: child);

  double _niceInterval(double maxV) {
    if (maxV <= 0) return 1;
    const mag = [1.0, 2.0, 5.0, 10.0];
    var exp = 1.0;
    while (exp * 10 < maxV) {
      exp *= 10;
    }
    for (final m in mag) {
      if (m * exp >= maxV / 4) return m * exp;
    }
    return exp * 10;
  }
}
