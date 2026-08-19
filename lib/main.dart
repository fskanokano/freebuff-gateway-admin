/// FreeBuff 网关管理 — 入口。
///
/// UI 基于 flutter-shadcn-ui (shadcn/ui 移植) + 苹果设计语言：
/// - shadcn zinc 中性色板 + 苹果系统蓝 primary
/// - 毛玻璃导航栏/底部栏（自绘）
/// - 大标题 + 负字距排版
library;

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'l10n/app_localizations.dart';

import 'pages/connect_page.dart';
import 'pages/shell_page.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreeBuffApp());
}

/// 苹果系统蓝（亮/暗）。
const _blueLight = Color(0xFF007AFF);
const _blueDark = Color(0xFF0A84FF);

ShadThemeData _buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  return ShadThemeData(
    brightness: b,
    colorScheme: dark
        ? const ShadZincColorScheme.dark(
            primary: _blueDark,
            ring: _blueDark,
            selection: Color(0xFF264F78),
          )
        : const ShadZincColorScheme.light(
            primary: _blueLight,
            ring: _blueLight,
          ),
    textTheme: ShadTextTheme(
      // 页面大标题
      h1: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: dark ? const Color(0xfffafafa) : const Color(0xff09090b),
      ),
      h2: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
        color: dark ? const Color(0xfffafafa) : const Color(0xff09090b),
      ),
      h3: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: dark ? const Color(0xfffafafa) : const Color(0xff09090b),
      ),
      h4: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: dark ? const Color(0xfffafafa) : const Color(0xff09090b),
      ),
      p: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: dark ? const Color(0xfffafafa) : const Color(0xff09090b),
      ),
      small: TextStyle(
        fontSize: 12.5,
        height: 1.4,
        color: dark ? const Color(0xfffafafa) : const Color(0xff09090b),
      ),
      muted: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: dark ? const Color(0xffa1a1aa) : const Color(0xff71717a),
      ),
    ),
  );
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
        return ShadApp(
          debugShowCheckedModeBanner: false,
          themeMode: _state.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            GlobalShadLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/shell':
                return CupertinoPageRoute(
                    builder: (_) => ShellPage(state: _state));
              case '/connect':
                return CupertinoPageRoute(
                    builder: (_) => ConnectPage(state: _state));
              default:
                return CupertinoPageRoute(
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
    if (!state.loaded) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return state.configured ? ShellPage(state: state) : ConnectPage(state: state);
  }
}
