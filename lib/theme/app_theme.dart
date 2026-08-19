/// FreeBuff 网关管理 — Material 3 设计系统。
///
/// 参考 (2026-08 调研):
/// - Material 3 官方色彩系统: seed → tonal palette, 26+ 色彩角色, tone-based surface
/// - M3 Elevation: 用色调表面色表达层次, 阴影克制
/// - Material 3 Expressive (2025): 圆角分级/丰富色彩/排版引导/containment
/// - Dribbble 顶级 dashboard 作品模式: 卡片网格 + 大数字 + 语义色点缀
library;

import 'package:flutter/material.dart';

/// 品牌种子色 (靛蓝)。
const kSeedColor = Color(0xFF3D5AFE);

/// 卡片统一圆角 (Expressive 大圆角)。
const kCardRadius = 16.0;
const kInputRadius = 12.0;
const kButtonRadius = 12.0;

/// 数据大数字样式 (Expressive 排版引导: 大而粗, 负字距)。
TextStyle kNumberStyle(double size, {Color? color}) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
      color: color,
    );

ThemeData buildLightTheme() => _build(Brightness.light);

ThemeData buildDarkTheme() => _build(Brightness.dark);

ThemeData _build(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );

  // 表面层次: 用色调表面色表达 (M3 elevation 原则)
  final surface = scheme.surface;
  final cardColor = dark ? scheme.surfaceContainerLow : Colors.white;

  final textTheme = base.textTheme.copyWith(
    // 页面大标题 (仪表盘等)
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: scheme.onSurface,
    ),
    // 区块标题
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: scheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.3,
      color: scheme.onSurface,
    ),
    // 正文
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.45,
      color: scheme.onSurface,
    ),
    // 次要文字
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.35,
      color: scheme.onSurfaceVariant,
    ),
    // 标签
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: scheme.onSurfaceVariant,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: surface,
    canvasColor: surface,
    // 卡片: 圆角 16, 无投影 (层次靠表面色)
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
    ),
    // 导航栏: 表面色, 中心标题
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    // 底部导航
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? scheme.surfaceContainer : Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall!.copyWith(fontSize: 12),
      ),
    ),
    // 按钮: 圆角 12, 主按钮用 primary
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    // 输入框: 圆角 12, 填充背景
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    // 筛选 chip: 基础形态; 状态颜色在 FilterChip 处按选中态显式传 (见 logs_page)
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      checkmarkColor: scheme.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    // 列表 tile
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: textTheme.bodySmall,
    ),
    // 分割线: 极淡
    dividerTheme: DividerThemeData(
      color: dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      thickness: 1,
      space: 1,
    ),
    // 对话框
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? scheme.surfaceContainerHigh : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    // 开关
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? scheme.primary.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest,
      ),
    ),
    // 提示条
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? scheme.inverseSurface : Colors.black.withValues(alpha: 0.85),
      contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // 弹层阴影 (仅交互元素)
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? scheme.inverseSurface : Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
    ),
  );
}

/// 状态语义色 (不随主题变化, M3 语义色原则)。
class StatusColors {
  const StatusColors._();

  static const ok = Color(0xFF2E7D32);
  static const okDark = Color(0xFF81C784);
  static const depleted = Color(0xFFEF6C00);
  static const depletedDark = Color(0xFFFFB74D);
  static const down = Color(0xFFC62828);
  static const downDark = Color(0xFFEF9A9A);
  static const maint = Color(0xFF757575);

  static Color okFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? okDark : ok;
  static Color depletedFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? depletedDark : depleted;
  static Color downFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? downDark : down;
  static Color maintFor(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? maint.withValues(alpha: 0.8) : maint;
}
