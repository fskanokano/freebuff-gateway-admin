/// 主框架：底部导航（手机）/ 侧边栏（宽屏自适应）。
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
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
    return Scaffold(
      // 保持各 tab 状态；宽屏（桌面）用 NavigationRail 而非底部栏
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 840;
        final content = IndexedStack(index: _index, children: _pages);
        if (wide) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('仪表盘')),
                  NavigationRailDestination(
                      icon: Icon(Icons.dns_outlined),
                      selectedIcon: Icon(Icons.dns),
                      label: Text('代理')),
                  NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('日志')),
                  NavigationRailDestination(
                      icon: Icon(Icons.science_outlined),
                      selectedIcon: Icon(Icons.science),
                      label: Text('测试')),
                  NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('设置')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        }
        return content;
      }),
      bottomNavigationBar: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 840) return const SizedBox.shrink();
        return NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: '仪表盘'),
            NavigationDestination(
                icon: Icon(Icons.dns_outlined),
                selectedIcon: Icon(Icons.dns),
                label: '代理'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: '日志'),
            NavigationDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: '测试'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置'),
          ],
        );
      }),
    );
  }
}
