/// 主框架：自绘底部导航（手机）/ 侧边栏（宽屏），无 Material 组件。
library;

import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../l10n/l10n_ext.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'analytics_page.dart';
import 'logs_page.dart';
import 'overview_page.dart';
import 'proxies_page.dart';
import 'settings_page.dart';
import 'smoke_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.state});

  final AppState state;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  late final List<Widget> _pages;

  List<(IconData, IconData, String)> _tabs(BuildContext context) => [
        (CupertinoIcons.chart_bar, CupertinoIcons.chart_bar_fill,
            context.l10n.tabDashboard),
        (CupertinoIcons.chart_pie, CupertinoIcons.chart_pie_fill,
            context.l10n.tabAnalytics),
        (CupertinoIcons.square_stack, CupertinoIcons.square_stack_fill,
            context.l10n.tabProxies),
        (CupertinoIcons.list_bullet, CupertinoIcons.list_bullet_indent,
            context.l10n.tabLogs),
        (CupertinoIcons.wand_stars, CupertinoIcons.wand_stars,
            context.l10n.tabSmoke),
        (CupertinoIcons.settings, CupertinoIcons.settings_solid,
            context.l10n.tabSettings),
      ];

  @override
  void initState() {
    super.initState();
    _pages = [
      OverviewPage(state: widget.state),
      AnalyticsPage(state: widget.state),
      ProxiesPage(state: widget.state),
      LogsPage(state: widget.state),
      SmokePage(state: widget.state),
      SettingsPage(state: widget.state),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w >= 840;
    final extraWide = w >= 1200;
    final content = IndexedStack(index: _index, children: _pages);
    final animated = TweenAnimationBuilder<double>(
      key: ValueKey(_index),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(20 * (1 - v), 0),
          child: child,
        ),
      ),
      child: content,
    );
    return CupertinoPageScaffold(
      child: wide
          ? Row(
              children: [
                _rail(context, extraWide: extraWide),
                Expanded(child: animated),
              ],
            )
          : Column(
              children: [
                Expanded(child: animated),
                _bottomBar(context),
              ],
            ),
    );
  }

  /// 自绘底部导航（毛玻璃 + shadcn 风格）。
  Widget _bottomBar(BuildContext context) {
    final primary = schemeColor(context);
    final muted = mutedColor(context);
    final dark = isDark(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: (dark ? const Color(0xFF09090B) : CupertinoColors.white)
                .withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: borderColor(context).withValues(alpha: 0.7)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  for (final (i, t) in _tabs(context).indexed)
                    Expanded(
                      child: TapFeedback(
                        onTap: () => setState(() => _index = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                i == _index ? t.$2 : t.$1,
                                size: 22,
                                color: i == _index ? primary : muted,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.$3,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: i == _index
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: i == _index ? primary : muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 自绘宽屏侧边栏：≥1200px 显示文字横排（224px），否则图标竖排（88px）。
  Widget _rail(BuildContext context, {bool extraWide = false}) {
    final primary = schemeColor(context);
    final muted = mutedColor(context);
    final dark = isDark(context);
    final tabs = _tabs(context);
    return Container(
      width: extraWide ? 224 : 88,
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF09090B) : CupertinoColors.white)
            .withValues(alpha: 0.8),
        border: Border(
          right: BorderSide(color: borderColor(context).withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              extraWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: extraWide ? 20 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.arrow_2_circlepath,
                      size: 26, color: primary),
                  if (extraWide) ...[
                    const SizedBox(width: 10),
                    Text('FreeBuff',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: fgColor(context))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final (i, t) in tabs.indexed)
              extraWide
                  ? _railItemWide(context, i, t, primary, muted)
                  : _railItemNarrow(context, i, t, primary, muted),
          ],
        ),
      ),
    );
  }

  Widget _railItemNarrow(BuildContext context, int i,
      (IconData, IconData, String) t, Color primary, Color muted) {
    return TapFeedback(
      onTap: () => setState(() => _index = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          children: [
            Icon(i == _index ? t.$2 : t.$1,
                size: 22, color: i == _index ? primary : muted),
            const SizedBox(height: 4),
            Text(t.$3,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i == _index ? FontWeight.w600 : FontWeight.w500,
                    color: i == _index ? primary : muted)),
          ],
        ),
      ),
    );
  }

  Widget _railItemWide(BuildContext context, int i,
      (IconData, IconData, String) t, Color primary, Color muted) {
    final selected = i == _index;
    return TapFeedback(
      onTap: () => setState(() => _index = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: isDark(context) ? 0.2 : 0.1)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(selected ? t.$2 : t.$1,
                  size: 20, color: selected ? primary : muted),
              const SizedBox(width: 12),
              Text(t.$3,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? primary : muted)),
            ],
          ),
        ),
      ),
    );
  }
}
