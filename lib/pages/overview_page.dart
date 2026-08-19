/// 仪表盘页：统计卡 + 最近路由 + 代理健康概览。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('仪表盘')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final ov = state.overview;
          if (ov == null && !state.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: state.refreshNow,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context),
                if (state.hasError)
                  ErrorBanner(
                    state.lastError ?? '连接失败',
                    onRetry: state.refreshNow,
                  ),
                if (ov != null) ...[
                  _stats(context, ov.stats),
                  const SectionTitle('最近路由'),
                  _recentRoutes(context),
                  const SectionTitle('代理健康'),
                  ...ov.proxies.map((p) => _proxyRow(context, p)),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final updated = state.lastUpdated;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.cloud_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.baseUrl ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    updated == null
                        ? '等待数据…'
                        : '更新于 ${relativeTime(updated)} · 每 5s 轮询',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '立即刷新',
              icon: const Icon(Icons.refresh),
              onPressed: state.refreshNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(BuildContext context, GatewayStats s) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: [
        StatCard(label: '代理总数', value: '${s.total}', icon: Icons.dns),
        StatCard(label: '正常', value: '${s.ok}', color: Colors.green, icon: Icons.check_circle),
        StatCard(label: '额度耗尽', value: '${s.depleted}', color: Colors.orange, icon: Icons.hourglass_bottom),
        StatCard(label: '故障/配置错误', value: '${s.down}', color: Colors.red, icon: Icons.error),
        StatCard(label: '累计成功请求', value: '${s.requestsOk}', color: Colors.teal, icon: Icons.thumb_up),
        StatCard(label: '累计失败请求', value: '${s.requestsFail}', color: Colors.redAccent, icon: Icons.thumb_down),
      ],
    );
  }

  Widget _recentRoutes(BuildContext context) {
    // 与日志页同源（overview.routes，每次请求都记录），
    // 保证仪表盘与日志数据一致；不依赖 last-used（仅成功路由写入）。
    final routes = state.overview?.routes ?? const <RouteEntry>[];
    final recent = [...routes]..sort((a, b) => b.t.compareTo(a.t));
    final list = recent.take(5).toList();
    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('暂无路由记录 — 发一条聊天请求后这里会显示路由事实。',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final (i, r) in list.indexed) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Icon(
                r.ok ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: r.ok ? Colors.green : Colors.red,
              ),
              title: Text('路由 → ${r.name}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                'HTTP ${r.status} · 尝试 ${r.attempts} 次 · ${r.ms}ms'
                '${r.model != null ? ' · ${r.model}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(relativeTime(r.t),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ],
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

  Widget _proxyRow(BuildContext context, ProxyInfo p) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusBadge(p.status, dense: true),
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.url, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            UsageBar(
              percent: p.usagePct ?? _firstQuotaUsage(p),
              height: 4,
            ),
          ],
        ),
        trailing: Text(
          '${p.requestsOk}✓ / ${p.requestsFail}✗',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ),
    );
  }
}
