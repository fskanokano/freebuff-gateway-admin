/// FreeBuff 网关管理 — shadcn/ui × Apple 融合设计系统。
///
/// shadcn/ui (Vercel/Linear 设计语言):
/// - 中性色板 (zinc): 背景/卡片/边框/文字三级中性
/// - 层次靠 1px 细边框 + 极淡填充, 不靠阴影
/// - 圆角克制: 卡片 8 / 控件 6 / 徽标 4
/// - 排版: 系统字体, 字重分级
///
/// 苹果质感:
/// - 系统蓝 primary (007AFF / 0A84FF)
/// - 毛玻璃导航栏/底部栏 (页面实现)
/// - 大标题 + 负字距排版
library;

import 'package:flutter/material.dart';

/// 品牌主色: 苹果系统蓝。
const kPrimaryLight = Color(0xFF007AFF);
const kPrimaryDark = Color(0xFF0A84FF);

/// shadcn 圆角: 卡片 8 / 控件 6 / 徽标 4。
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

/// shadcn 中性色板 (zinc)。
class ShadcnColors {
  const ShadcnColors._();

  // 亮色
  static const bgLight = Color(0xFFF7F7F8);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8E8EA);
  static const fgLight = Color(0xFF101013);
  static const secondaryLight = Color(0xFFF0F0F2);
  static const mutedFgLight = Color(0xFF6F6F78);
  static const inputLight = Color(0xFFE8E8EA);

  // 暗色
  static const bgDark = Color(0xFF09090B);
  static const cardDark = Color(0xFF131316);
  static const borderDark = Color(0xFF26262A);
  static const fgDark = Color(0xFFFAFAFA);
  static const secondaryDark = Color(0xFF1F1F23);
  static const mutedFgDark = Color(0xFFA1A1AA);
  static const inputDark = Color(0xFF26262A);

  // 状态 (语义色, 不随主题大幅变化)
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

ThemeData buildLightTheme() => _build(Brightness.light);

ThemeData buildDarkTheme() => _build(Brightness.dark);

ThemeData _build(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? ShadcnColors.bgDark : ShadcnColors.bgLight;
  final card = dark ? ShadcnColors.cardDark : ShadcnColors.cardLight;
  final border = dark ? ShadcnColors.borderDark : ShadcnColors.borderLight;
  final fg = dark ? ShadcnColors.fgDark : ShadcnColors.fgLight;
  final mutedFg = dark ? ShadcnColors.mutedFgDark : ShadcnColors.mutedFgLight;
  final secondary = dark ? ShadcnColors.secondaryDark : ShadcnColors.secondaryLight;
  final primary = dark ? kPrimaryDark : kPrimaryLight;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: primary.withValues(alpha: dark ? 0.24 : 0.12),
    onPrimaryContainer: primary,
    secondary: secondary,
    onSecondary: fg,
    secondaryContainer: secondary,
    onSecondaryContainer: fg,
    tertiary: primary.withValues(alpha: 0.8),
    onTertiary: Colors.white,
    tertiaryContainer: primary.withValues(alpha: dark ? 0.18 : 0.10),
    onTertiaryContainer: primary,
    error: ShadcnColors.danger,
    onError: Colors.white,
    errorContainer: ShadcnColors.danger.withValues(alpha: dark ? 0.24 : 0.12),
    onErrorContainer: ShadcnColors.danger,
    surface: bg,
    onSurface: fg,
    surfaceContainerLowest: card,
    surfaceContainerLow: card,
    surfaceContainer: card,
    surfaceContainerHigh: secondary,
    surfaceContainerHighest: secondary,
    onSurfaceVariant: mutedFg,
    outline: border,
    outlineVariant: border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? Colors.white : Colors.black,
    onInverseSurface: dark ? Colors.black : Colors.white,
    inversePrimary: dark ? kPrimaryLight : kPrimaryDark,
  );

  final textTheme = TextTheme(
    // 页面大标题 (苹果大标题 + shadcn 克制字重)
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: fg,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.25,
      color: fg,
    ),
    // 卡片/区块标题
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: fg,
    ),
    titleMedium: TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.3,
      color: fg,
    ),
    // 正文
    bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: fg),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: fg),
    // 次要文字
    bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: mutedFg),
    // 标签
    labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedFg, letterSpacing: 0.2),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    splashFactory: InkSparkle.splashFactory,
    textTheme: textTheme,
    // ── shadcn 卡片: 白底 + 1px 边框, 无阴影 ──
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    // ── 导航栏: 透明底(毛玻璃由页面 GlassAppBar 实现), 无投影 ──
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: mutedFg),
    ),
    // ── 底部导航 ──
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primary.withValues(alpha: dark ? 0.22 : 0.12),
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? primary : mutedFg,
        ),
      ),
    ),
    // ── 按钮: shadcn 风格 (圆角 8, 无阴影) ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kControlRadius)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        elevation: 0,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kControlRadius)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // ── 输入框: shadcn (白底 + 边框 + 圆角 8) ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1C1C20) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: TextStyle(fontSize: 13.5, color: mutedFg),
      labelStyle: TextStyle(fontSize: 13.5, color: mutedFg),
      errorStyle: const TextStyle(fontSize: 12, color: ShadcnColors.danger),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kControlRadius),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kControlRadius),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kControlRadius),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kControlRadius),
        borderSide: const BorderSide(color: ShadcnColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kControlRadius),
        borderSide: const BorderSide(color: ShadcnColors.danger, width: 1.5),
      ),
    ),
    // ── 筛选 chip: shadcn 风格 ──
    chipTheme: baseChipTheme(dark, fg, mutedFg, secondary, border),
    // ── 列表 ──
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      titleTextStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: textTheme.bodySmall,
      iconColor: mutedFg,
    ),
    dividerTheme: DividerThemeData(
      color: border.withValues(alpha: 0.6),
      thickness: 1,
      space: 1,
    ),
    // ── 对话框 ──
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    // ── 开关: 苹果系统开关 ──
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const Color(0xFF34C759)
            : border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    // ── 提示条 ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF1F1F23) : const Color(0xFF101013),
      contentTextStyle: TextStyle(color: dark ? ShadcnColors.fgDark : Colors.white, fontSize: 13.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    // ── 进度指示器: 细条 ──
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: secondary,
      circularTrackColor: secondary,
    ),
    // ── 弹窗菜单 ──
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F1F23) : const Color(0xFF101013),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

/// shadcn 风格 chip (选中: primary 浅底; 未选中: 边框 + 灰底)。
ChipThemeData baseChipTheme(bool dark, Color fg, Color mutedFg, Color secondary, Color border) {
  return ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBadgeRadius)),
    side: BorderSide(color: border),
    backgroundColor: secondary,
    selectedColor: dark
        ? const Color(0xFF0A84FF).withValues(alpha: 0.22)
        : const Color(0xFF007AFF).withValues(alpha: 0.12),
    checkmarkColor: dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
    labelStyle: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: fg,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    showCheckmark: true,
  );
}
