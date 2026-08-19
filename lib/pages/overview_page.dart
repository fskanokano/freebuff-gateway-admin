/// 仪表盘页：连接状态 + 代理统计 + 最近路由 + 代理健康。
/// 基于 flutter-shadcn-ui 组件。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show RefreshIndicator, Tooltip;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final ov = state.overview;
          return Column(
            children: [
              GlassAppBar(
                title: Text(context.l10n.tabDashboard),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: context.l10n.commonRefresh,
                      child: TapFeedback(
                        onTap: state.refreshNow,
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
                child: ov == null && !state.hasError
                    ? const Center(child: CupertinoActivityIndicator())
                    : RefreshIndicator(
                        onRefresh: state.refreshNow,
                        child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _connectionCard(context),
                            if (state.hasError)
                              ErrorBanner(
                                  context.l10n.errorText(
                                      state.lastErrorKind, state.lastError),
                                  onRetry: state.refreshNow),
                            if (ov != null) ...[
                              SectionTitle(context.l10n.overviewProxyStatus),
                              _statsGrid(context, ov.stats),
                              SectionTitle(context.l10n.overviewRecentRoutes),
                              _recentRoutes(context),
                              SectionTitle(context.l10n.overviewProxyHealth),
                              _proxyList(context, ov.proxies),
                            ],
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

  Widget _connectionCard(BuildContext context) {
    final updated = state.lastUpdated;
    final ok = !state.hasError && state.overview != null;
    return ShadCard(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ok
                  ? ShadcnColors.ok
                  : (state.hasError ? ShadcnColors.danger : ShadcnColors.neutral),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.baseUrl ?? '',
                    style: ShadTheme.of(context).textTheme.p,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  updated == null
                      ? context.l10n.overviewWaiting
                      : context.l10n.overviewUpdatedAt(
                          context.l10n.relativeTime(updated)),
                  style: ShadTheme.of(context).textTheme.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(BuildContext context, GatewayStats s) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        fadeSlideIn(StatCard(
            label: context.l10n.overviewTotalProxies,
            value: '${s.total}',
            icon: CupertinoIcons.square_stack,
            subtitle: context.l10n.overviewSubConfigured),
            delayMs: 0),
        fadeSlideIn(StatCard(
            label: context.l10n.overviewOk,
            value: '${s.ok}',
            color: ShadcnColors.okFor(context),
            icon: CupertinoIcons.checkmark_circle,
            subtitle: context.l10n.overviewSubAvailable),
            delayMs: 40),
        fadeSlideIn(StatCard(
            label: context.l10n.overviewDepleted,
            value: '${s.depleted}',
            color: ShadcnColors.warningFor(context),
            icon: CupertinoIcons.hourglass,
            subtitle: context.l10n.overviewSubWaitReset),
            delayMs: 80),
        fadeSlideIn(StatCard(
            label: context.l10n.overviewDown,
            value: '${s.down}',
            color: ShadcnColors.dangerFor(context),
            icon: CupertinoIcons.exclamationmark_triangle,
            subtitle: context.l10n.overviewSubInclBadCfg),
            delayMs: 120),
        fadeSlideIn(StatCard(
            label: context.l10n.overviewReqOk,
            value: formatCount(s.requestsOk),
            color: schemeColor(context),
            icon: CupertinoIcons.hand_thumbsup,
            subtitle: context.l10n.overviewSubCumulative),
            delayMs: 160),
        fadeSlideIn(StatCard(
            label: context.l10n.overviewReqFail,
            value: formatCount(s.requestsFail),
            color: ShadcnColors.dangerFor(context),
            icon: CupertinoIcons.hand_thumbsdown,
            subtitle: context.l10n.overviewSubCumulative),
            delayMs: 200),
      ],
    );
  }

  Widget _recentRoutes(BuildContext context) {
    final routes = state.overview?.routes ?? const <RouteEntry>[];
    final recent = [...routes]..sort((a, b) => b.t.compareTo(a.t));
    final list = recent.take(5).toList();
    if (list.isEmpty) {
      return ShadCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(context.l10n.overviewNoRoutes,
                style: ShadTheme.of(context).textTheme.small),
          ),
        ),
      );
    }
    return fadeSlideIn(ShadCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, r) in list.indexed) ...[
            if (i > 0) ShadcnDivider(indent: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    r.ok
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.xmark_circle_fill,
                    size: 18,
                    color: r.ok ? ShadcnColors.ok : ShadcnColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            context.l10n.logsRouteTitle(
                                r.name,
                                r.ok
                                    ? context.l10n.logsRouteOk
                                    : context.l10n.logsRouteFail),
                            style: ShadTheme.of(context).textTheme.p,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          context.l10n.logsHttpAttempts(r.status, r.attempts, r.ms) +
                              (r.model != null ? ' · ${r.model}' : ''),
                          style: ShadTheme.of(context).textTheme.small,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(context.l10n.relativeTime(r.t),
                      style: ShadTheme.of(context).textTheme.small),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _proxyList(BuildContext context, List<ProxyInfo> proxies) {
    if (proxies.isEmpty) {
      return ShadCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(context.l10n.overviewNoProxies,
                style: ShadTheme.of(context).textTheme.small),
          ),
        ),
      );
    }
    return ShadCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, p) in proxies.indexed) ...[
            if (i > 0) ShadcnDivider(indent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  _avatar(context, p.name),
                  const SizedBox(width: 10),
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
                                      .p
                                      .copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor(context, p.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        UsageBar(percent: p.usagePct ?? _firstQuotaUsage(p)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${formatCount(p.requestsOk)}✓/${formatCount(p.requestsFail)}✗',
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, String name) {
    final primary = schemeColor(context);
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark(context) ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
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
