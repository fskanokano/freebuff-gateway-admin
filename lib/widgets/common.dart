/// FreeBuff Gateway Admin — 共用组件（基于 flutter-shadcn-ui）。
///
/// shadcn/ui 组件 + 少量自绘（毛玻璃导航/筛选胶囊/分区标题等）。
library;

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';

/// 状态语义色（亮暗自适应）。
Color statusColor(BuildContext context, String status) {
  switch (status) {
    case 'ok':
      return ShadcnColors.okFor(context);
    case 'depleted':
      return ShadcnColors.warningFor(context);
    case 'down':
    case 'bad_config':
      return ShadcnColors.dangerFor(context);
    case 'maint':
      return ShadcnColors.neutral;
    default:
      return ShadTheme.of(context).colorScheme.mutedForeground;
  }
}

/// 取色便捷函数。
Color schemeColor(BuildContext context) => ShadTheme.of(context).colorScheme.primary;
Color fgColor(BuildContext context) => ShadTheme.of(context).colorScheme.foreground;
Color mutedColor(BuildContext context) => ShadTheme.of(context).colorScheme.mutedForeground;
Color borderColor(BuildContext context) => ShadTheme.of(context).colorScheme.border;
Color cardColor(BuildContext context) => ShadTheme.of(context).colorScheme.card;
Color pageBg(BuildContext context) => ShadTheme.of(context).colorScheme.background;
bool isDark(BuildContext context) => ShadTheme.of(context).brightness == Brightness.dark;

/// 毛玻璃导航栏（自绘：SafeArea + 背景模糊 + 半透明）。
class GlassAppBar extends StatelessWidget {
  const GlassAppBar({super.key, required this.title, this.actions});

  final Widget title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: (dark ? const Color(0xFF09090B) : CupertinoColors.white)
                .withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(color: borderColor(context).withValues(alpha: 0.7)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: DefaultTextStyle(
                          style: ShadTheme.of(context)
                              .textTheme
                              .h3
                              .copyWith(color: fgColor(context)),
                          child: title,
                        ),
                      ),
                    ),
                    ...?actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 状态徽标（shadcn Badge + 语义色）。
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark(context) ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(kBadgeRadius),
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

/// 统计卡（shadcn Card + 圆点 + 大数字）。
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
    final c = color ?? schemeColor(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                        color: mutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value,
              style: kNumberStyle(26).copyWith(color: fgColor(context))),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: ShadTheme.of(context).textTheme.small,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// 用量进度条（shadcn Progress）。
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.percent,
    this.label,
    this.height = 6,
    this.showPercent = false,
  });

  final double? percent;
  final String? label;
  final double height;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final p = percent;
    final clamped = p == null ? 0.0 : p.clamp(0, 100).toDouble();
    final over = (p ?? 0) > 100;
    final danger = (p ?? 0) > 80;
    final color = over || danger
        ? ShadcnColors.dangerFor(context)
        : (danger ? ShadcnColors.warningFor(context) : schemeColor(context));
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
                      style: ShadTheme.of(context).textTheme.small.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                if (showPercent && p != null)
                  Text('${p.toStringAsFixed(0)}%',
                      style: ShadTheme.of(context).textTheme.small),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: borderColor(context)),
                FractionallySizedBox(
                  widthFactor: clamped / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
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

/// 筛选胶囊（自绘）。
class ShadcnPill extends StatelessWidget {
  const ShadcnPill(this.label, {super.key, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = schemeColor(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark(context) ? 0.25 : 0.12)
              : (isDark(context)
                  ? const Color(0xFF1C1C20)
                  : const Color(0xFFF4F4F5)),
          borderRadius: BorderRadius.circular(kBadgeRadius),
          border: Border.all(
            color: selected ? primary : borderColor(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : fgColor(context),
          ),
        ),
      ),
    );
  }
}

/// 自绘分割线。
class ShadcnDivider extends StatelessWidget {
  const ShadcnDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent),
      color: borderColor(context).withValues(alpha: 0.6),
    );
  }
}

/// 分区标题。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: ShadTheme.of(context).textTheme.h4.copyWith(
                    color: fgColor(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 错误提示条。
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final danger = ShadcnColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: isDark(context) ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle_fill,
              size: 16, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: danger)),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('重试',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: danger)),
              ),
            ),
        ],
      ),
    );
  }
}

/// 信息行（key: value）。
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.selectable = true});

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: ShadTheme.of(context).textTheme.small),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value,
                    style: ShadTheme.of(context).textTheme.p)
                : Text(value, style: ShadTheme.of(context).textTheme.p),
          ),
        ],
      ),
    );
  }
}

/// 空状态。
class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = CupertinoIcons.tray});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(icon, size: 44, color: mutedColor(context).withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(message,
              style: TextStyle(fontSize: 13.5, color: mutedColor(context))),
        ],
      ),
    );
  }
}

/// shadcn toast（经 ShadToaster）。
void showShadcnToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 96,
      left: 40,
      right: 40,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(kControlRadius),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2200), () {
    entry.remove();
  });
}

/// 确认对话框（shadcn Dialog）。
Future<bool> showShadcnConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确定',
  bool destructive = false,
}) async {
  return await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            ),
          ],
        ),
      ) ??
      false;
}
