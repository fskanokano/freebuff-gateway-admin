/// FreeBuff Gateway Admin — 共用小组件。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';

/// 状态彩色徽标。
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  Color _color(BuildContext context) {
    final s = status;
    if (s == 'ok') return Colors.green;
    if (s == 'depleted') return Colors.orange;
    if (s == 'maint') return Colors.blueGrey;
    if (s == 'bad_config') return Colors.purple;
    if (s == 'down') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: c,
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 仪表盘统计卡。
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: c),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: c, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// 用量进度条（带百分比文字）。
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.percent,
    this.label,
    this.height = 6,
  });

  /// 0-100+，超过 100 按 100 显示但颜色变红。
  final double? percent;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = percent;
    final scheme = Theme.of(context).colorScheme;
    final clamped = p == null ? 0.0 : p.clamp(0, 100).toDouble();
    final over = (p ?? 0) > 100;
    final danger = (p ?? 0) > 80;
    final color = over || danger ? Colors.red : (danger ? Colors.orange : scheme.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(label!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: height,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 分区卡片标题。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 通用错误提示条。
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

/// 连接信息行（key: value，可复制）。
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.selectable = true});

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: Theme.of(context).textTheme.bodyMedium)
                : Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
