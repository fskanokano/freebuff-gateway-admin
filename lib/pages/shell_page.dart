/// 主框架：自绘底部导航（手机）/ 侧边栏（宽屏），无 Material 组件。
library;

import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
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

  static const _tabs = [
    (CupertinoIcons.chart_bar, CupertinoIcons.chart_bar_fill, '仪表盘'),
    (CupertinoIcons.square_stack, CupertinoIcons.square_stack_fill, '代理'),
    (CupertinoIcons.list_bullet, CupertinoIcons.list_bullet_indent, '日志'),
    (CupertinoIcons.wand_stars, CupertinoIcons.wand_stars, '测试'),
    (CupertinoIcons.settings, CupertinoIcons.settings_solid, '设置'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      OverviewPage(state: widget.state),
      ProxiesPage(state: widget.state),
      LogsPage(state: widget.state),
      SmokePage(state: widget.state),
      SettingsPage(state: widget.state),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 840;
    final content = IndexedStack(index: _index, children: _pages);
    // Tab 切换: 内容区淡入（IndexedStack 保持各页状态）
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
                _rail(context),
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
                  for (final (i, t) in _tabs.indexed)
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

  /// 自绘宽屏侧边栏。
  Widget _rail(BuildContext context) {
    final primary = schemeColor(context);
    final muted = mutedColor(context);
    final dark = isDark(context);
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF09090B) : CupertinoColors.white)
            .withValues(alpha: 0.8),
        border: Border(
          right: BorderSide(color: borderColor(context).withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Icon(CupertinoIcons.arrow_2_circlepath,
                size: 26, color: primary),
            const SizedBox(height: 20),
            for (final (i, t) in _tabs.indexed)
              TapFeedback(
                onTap: () => setState(() => _index = i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Column(
                    children: [
                      Icon(
                        i == _index ? t.$2 : t.$1,
                        size: 22,
                        color: i == _index ? primary : muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.$3,
                        style: TextStyle(
                          fontSize: 11,
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
          ],
        ),
      ),
    );
  }
}
