/// 连接配置页（首次进入 / 登出后）。
/// 基于 flutter-shadcn-ui 组件。
library;

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/l10n_ext.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key, required this.state});

  final AppState state;

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  late final TextEditingController _url;
  late final TextEditingController _key;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.state.baseUrl ?? 'https://');
    _key = TextEditingController(text: widget.state.adminKey ?? '');
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _url.text.trim();
    final key = _key.text.trim();
    if (url.isEmpty) {
      setState(() => _error = context.l10n.connectErrUrlEmpty);
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _error = context.l10n.connectErrUrlScheme);
      return;
    }
    if (key.isEmpty) {
      setState(() => _error = context.l10n.connectErrKeyEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.state.testAndSave(url, key);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/shell');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = schemeColor(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(CupertinoIcons.arrow_2_circlepath,
                      size: 56, color: primary),
                  const SizedBox(height: 14),
                  Text(context.l10n.connectTitle,
                      textAlign: TextAlign.center,
                      style: ShadTheme.of(context).textTheme.h1),
                  const SizedBox(height: 6),
                  Text(context.l10n.connectSubtitle,
                      textAlign: TextAlign.center,
                      style: ShadTheme.of(context).textTheme.muted),
                  const SizedBox(height: 30),
                  ShadInput(
                    controller: _url,
                    placeholder: Text(context.l10n.connectUrlPlaceholder),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  ShadInput(
                    controller: _key,
                    placeholder: Text(context.l10n.connectKeyPlaceholder),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.connectKeyHint,
                    textAlign: TextAlign.center,
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: ShadcnColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  ShadButton(
                    width: double.infinity,
                    onPressed: _busy ? null : _connect,
                    child: _busy
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white)
                        : Text(context.l10n.connectButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
