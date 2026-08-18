/// FreeBuff 网关管理 — 入口。
///
/// 连接 freebuff-proxy-gateway (Cloudflare Workers) 管理后台的原生应用。
/// Android + Windows 一套代码，产物由 GitHub Actions 构建。
library;

import 'package:flutter/material.dart';

import 'pages/connect_page.dart';
import 'pages/shell_page.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreeBuffApp());
}

class FreeBuffApp extends StatefulWidget {
  const FreeBuffApp({super.key});

  @override
  State<FreeBuffApp> createState() => _FreeBuffAppState();
}

class _FreeBuffAppState extends State<FreeBuffApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return MaterialApp(
          title: 'FreeBuff 网关管理',
          debugShowCheckedModeBanner: false,
          themeMode: _state.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3D5AFE),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/shell':
                return MaterialPageRoute(
                    builder: (_) => ShellPage(state: _state));
              case '/connect':
                return MaterialPageRoute(
                    builder: (_) => ConnectPage(state: _state));
              default:
                return MaterialPageRoute(
                    builder: (_) => _RootPage(state: _state));
            }
          },
        );
      },
    );
  }
}

/// 根页面：根据连接配置决定进入连接页还是主框架。
class _RootPage extends StatelessWidget {
  const _RootPage({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    // AppState 初始化是异步的（读取本地存储）；加载完成前显示 splash
    if (!state.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return state.configured ? ShellPage(state: state) : ConnectPage(state: state);
  }
}
