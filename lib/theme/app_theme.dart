/// FreeBuff 网关管理 — 设计令牌（shadcn/ui × Apple 融合）。
///
/// 这里只保留纯 token（圆角 / 数字样式 / 语义色）：
/// - 圆角克制: 卡片 10 / 控件 8 / 徽标 6
/// - 大数字排版: 大而粗 + 负字距
/// - 语义色: ok / warning / danger / neutral（亮暗自适应）
///
/// 真正的主题（ShadThemeData）在 lib/main.dart 的 _buildTheme() 定义，
/// 避免双真相源漂移。
library;

import 'package:flutter/material.dart';

/// shadcn 圆角: 卡片 10 / 控件 8 / 徽标 6。
const kCardRadius = 10.0;
const kControlRadius = 8.0;
const kBadgeRadius = 6.0;

/// 数据大数字样式 (排版引导: 大而粗, 负字距)。
TextStyle kNumberStyle(double size, {Color? color}) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.1,
      color: color,
    );

/// shadcn 语义色板 (状态色, 不随主题大幅变化)。
class ShadcnColors {
  const ShadcnColors._();

  static const ok = Color(0xFF22C55E); // green-500
  static const okDark = Color(0xFF4ADE80);
  static const warning = Color(0xFFF59E0B); // amber-500
  static const warningDark = Color(0xFFFBBF24);
  static const danger = Color(0xFFEF4444); // red-500
  static const dangerDark = Color(0xFFF87171);
  static const neutral = Color(0xFF71717A); // zinc-500

  static Color okFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? okDark : ok;
  static Color warningFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? warningDark : warning;
  static Color dangerFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dangerDark : danger;
}
