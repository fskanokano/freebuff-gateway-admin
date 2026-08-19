/// FreeBuff Gateway Admin — 共用小组件（Material 3 + Expressive 风格）。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// 状态语义色（亮暗自适应）。
Color statusColor(BuildContext context, String status) {
  switch (status) {
    case 'ok':
      return StatusColors.okFor(context);
    case 'depleted':
      return StatusColors.depletedFor(context);
    case 'down':
    case 'bad_config':
      return StatusColors.downFor(context);
    case 'maint':
      return StatusColors.maintFor(context);
    default:
      return Theme.of(context).colorScheme.outline;
  }
}

/// 状态彩色徽标（圆点 + 文字，低饱和底）。
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(context, status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dense ? 5 : 6,
            height: dense ? 5 : 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            statusLabel(status),
            style: TextStyle(
              color: c,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 仪表盘统计卡（Expressive 风格：渐变强调底 + 图标徽章 + 大数字）。
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kCardRadius),
        // 渐变强调底（Expressive: 丰富色彩; 深色下加深）
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [c.withValues(alpha: 0.22), c.withValues(alpha: 0.08)]
              : [c.withValues(alpha: 0.12), c.withValues(alpha: 0.04)],
        ),
        border: Border.all(
          color: c.withValues(alpha: dark ? 0.25 : 0.12),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 图标徽章: 圆形浅色底
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: dark ? 0.28 : 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.info_outline,
                  size: 16,
                  color: c,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 大数字: Expressive 排版引导（大而粗、负字距）
          Text(
            value,
            style: kNumberStyle(28).copyWith(color: scheme.onSurface),
            maxLines: 1,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// 用量进度条（渐变填充 + 可选百分比）。
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.percent,
    this.label,
    this.height = 6,
    this.showPercent = false,
  });

  /// 0-100+，超过 100 按 100 显示但颜色变红。
  final double? percent;
  final String? label;
  final double height;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final p = percent;
    final scheme = Theme.of(context).colorScheme;
    final clamped = p == null ? 0.0 : p.clamp(0, 100).toDouble();
    final over = (p ?? 0) > 100;
    final danger = (p ?? 0) > 80;
    final color = over || danger
        ? StatusColors.downFor(context)
        : (danger ? StatusColors.depletedFor(context) : scheme.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercent)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (showPercent && p != null)
                  Text(
                    '${p.toStringAsFixed(0)}%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: scheme.surfaceContainerHighest),
                FractionallySizedBox(
                  widthFactor: clamped / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.75), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13)),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
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
