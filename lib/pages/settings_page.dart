/// 设置页：连接信息、运行时参数、主题、pin、登出。
/// 基于 flutter-shadcn-ui 组件（分组卡片 + 自绘行）。
library;

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart' show RefreshIndicator, ThemeMode, Tooltip;

import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;
  bool _revealAdminKey = false;
  GatewayConfig? _cfg;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadCfg();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {}
  }

  Future<void> _loadCfg() async {
    final api = widget.state.api;
    if (api == null) return;
    try {
      final c = await api.config();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() action, {String? ok}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (ok != null && mounted) showShadcnToast(context, ok);
      await _loadCfg();
      await widget.state.refreshNow();
    } catch (e) {
      if (mounted) {
        showShadcnToast(context, context.l10n.proxiesOpFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editConnection() async {
    final url = widget.state.baseUrl ?? '';
    final key = widget.state.adminKey ?? '';
    final result = await showShadDialog<(String, String)>(
      context: context,
      builder: (ctx) => _ConnectionDialog(url: url, adminKey: key),
    );
    if (result != null && mounted) {
      await _run(() => widget.state.saveConnection(result.$1, result.$2),
          ok: context.l10n.settingsConnUpdated);
    }
  }

  Future<void> _editParams() async {
    final c = _cfg;
    if (c == null || widget.state.api == null) return;
    final result = await showShadDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ParamsDialog(config: c),
    );
    if (result != null && mounted) {
      await _run(() => widget.state.api!.saveSettings(result),
          ok: context.l10n.settingsParamsSaved);
    }
  }

  Future<void> _resetConfig() async {
    final api = widget.state.api;
    if (api == null) return;
    final l10n = context.l10n;
    final ok = await showShadcnConfirm(
      context,
      title: l10n.settingsResetTitle,
      message: l10n.settingsResetMessage,
      confirmText: l10n.settingsResetConfirm,
      destructive: true,
    );
    if (ok == true) {
      await _run(() => api.resetConfig(), ok: l10n.settingsResetDone);
    }
  }

  Future<void> _clearPin() async {
    final api = widget.state.api;
    final key = widget.state.pinStatus?.stickyKey;
    if (api == null || key == null || key.isEmpty) return;
    await _run(() => api.clearPin(key), ok: context.l10n.settingsPinCleared);
  }

  Future<void> _exportBackup() async {
    final api = widget.state.api;
    if (api == null) return;
    try {
      final bundle = await api.exportBundle();
      await Clipboard.setData(ClipboardData(text: jsonEncode(bundle)));
      if (mounted) showShadcnToast(context, context.l10n.settingsExportDone);
    } catch (e) {
      if (mounted) showShadcnToast(context, context.l10n.settingsExportFailed(e.toString()));
    }
  }

  Future<void> _importBackup() async {
    final api = widget.state.api;
    if (api == null) return;
    final l10n = context.l10n;
    final text = await showShadDialog<String>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final ok = await showShadcnConfirm(
      context,
      title: l10n.settingsImportTitle,
      message: l10n.settingsImportMessage,
      confirmText: l10n.commonImport,
      destructive: true,
    );
    if (ok != true) return;
    try {
      final decoded = jsonDecode(text.trim());
      if (decoded is! Map) throw FormatException(l10n.settingsBadJson);
      await api.importBundle(decoded.cast<String, dynamic>());
      if (mounted) {
        showShadcnToast(context, l10n.settingsImportDone);
        await _loadCfg();
        await widget.state.refreshNow();
      }
    } catch (e) {
      if (mounted) showShadcnToast(context, l10n.settingsImportFailed(e.toString()));
    }
  }

  Future<void> _logout() async {
    await widget.state.clearConnection();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/connect', (_) => false);
    }
  }

  /// 分组行。
  Widget _row({
    required String label,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    final color = destructive ? ShadcnColors.danger : fgColor(context);
    return TapFeedback(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: ShadTheme.of(context)
                      .textTheme
                      .p
                      .copyWith(color: color)),
            ),
            if (value != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  /// 分组卡片。
  Widget _group(BuildContext context, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) ShadcnDivider(indent: 14),
            r,
          ],
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final pin = widget.state.pinStatus;
          return Column(
            children: [
              GlassAppBar(
                title: Text(context.l10n.tabSettings),
                actions: [
                  Tooltip(
                    message: context.l10n.commonRefresh,
                    child: TapFeedback(
                      onTap: _busy ? null : _loadCfg,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(CupertinoIcons.refresh, size: 19),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.state.refreshNow,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(context.l10n.settingsSectionConn),
                      _group(context, [
                        _row(label: context.l10n.settingsGatewayUrl,
                            value: widget.state.baseUrl ?? context.l10n.commonUnconfigured),
                        _row(
                          label: context.l10n.settingsAdminKey,
                          value: _revealAdminKey
                              ? (widget.state.adminKey ?? context.l10n.commonUnconfigured)
                              : maskKey(widget.state.adminKey),
                          onTap: (widget.state.adminKey == null || widget.state.adminKey!.isEmpty)
                              ? null
                              : () => setState(() => _revealAdminKey = !_revealAdminKey),
                          trailing: (widget.state.adminKey == null || widget.state.adminKey!.isEmpty)
                              ? null
                              : Icon(
                                  _revealAdminKey
                                      ? CupertinoIcons.eye_slash
                                      : CupertinoIcons.eye,
                                  size: 14,
                                  color: mutedColor(context),
                                ),
                        ),
                        _row(label: context.l10n.settingsPolling,
                            value: widget.state.polling
                                ? context.l10n.settingsPollingRunning
                                : context.l10n.settingsPollingStopped),
                        _row(label: context.l10n.settingsEditConn,
                            onTap: _busy ? null : _editConnection,
                            trailing: Icon(CupertinoIcons.chevron_right,
                                size: 14, color: mutedColor(context))),
                        _row(label: context.l10n.settingsLogout, destructive: true,
                            onTap: _busy ? null : _logout),
                      ]),
                      SectionTitle(context.l10n.settingsSectionPin),
                      _group(context, [
                        _row(label: context.l10n.settingsCurrentPin,
                            value: pin?.pinnedProxy ?? context.l10n.commonNone),
                        _row(label: context.l10n.settingsStickyKey,
                            value: pin?.stickyKey ?? '—'),
                        _row(label: context.l10n.settingsPinMode,
                            value: pin?.pinMode ?? '—'),
                        _row(
                          label: context.l10n.settingsClearPin,
                          onTap:
                              (_busy || (pin?.stickyKey ?? '').isEmpty) ? null : _clearPin,
                          trailing: Icon(CupertinoIcons.pin_slash,
                              size: 14, color: mutedColor(context)),
                        ),
                      ]),
                      SectionTitle(context.l10n.settingsSectionRuntime),
                      if (c == null)
                        _group(context, [
                          _row(label: context.l10n.settingsCfgUnreadable),
                        ])
                      else ...[
                        _group(context, [
                          _row(label: context.l10n.settingsProxyCount,
                              value: '${c.proxies.length}'),
                          _row(label: context.l10n.settingsPinMode,
                              value: c.pinMode ?? '—'),
                          _row(label: context.l10n.settingsProbeMode,
                              value: c.probeMode ?? '—'),
                          _row(
                            label: context.l10n.settingsSource,
                            value: c.hasRuntimeConfig
                                ? (c.runtimeManaged
                                    ? context.l10n.settingsSourceRuntime
                                    : context.l10n.settingsSourceMixed)
                                : context.l10n.settingsSourceEnv,
                          ),
                        ]),
                        _group(context, [
                          _row(label: context.l10n.settingsClientKey,
                              value: c.apiKeyMasked ?? '—'),
                          if (c.adminUsesApiKey)
                            _row(label: context.l10n.settingsAdminAuth,
                                value: context.l10n.settingsReuseApiKey)
                          else
                            _row(label: context.l10n.settingsAdminKeyMasked,
                                value: c.adminKeyMasked ?? '—'),
                          _row(label: context.l10n.settingsProxyKey,
                              value: c.proxyKeysMasked ?? '—'),
                          if (c.runtimeError != null)
                            _row(label: context.l10n.settingsRuntimeErr,
                                value: c.runtimeError),
                        ]),
                        _group(context, [
                          _row(label: context.l10n.settingsEditParams,
                              onTap: _busy ? null : _editParams,
                              trailing: Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 14,
                                  color: mutedColor(context))),
                          _row(label: context.l10n.settingsResetEnv,
                              onTap: _busy ? null : _resetConfig,
                              trailing: Icon(
                                  CupertinoIcons.arrow_counterclockwise,
                                  size: 14,
                                  color: mutedColor(context))),
                        ]),
                      ],
                      SectionTitle(context.l10n.settingsSectionAppearance),
                      _group(context, [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.l10n.settingsTheme,
                                  style: ShadTheme.of(context).textTheme.p),
                              _themePicker(context),
                            ],
                          ),
                        ),
                      ]),
                      SectionTitle(context.l10n.settingsSectionBackup),
                      _group(context, [
                        _row(
                          label: context.l10n.settingsExport,
                          onTap: _busy ? null : _exportBackup,
                          trailing: Icon(CupertinoIcons.doc_on_clipboard,
                              size: 14, color: mutedColor(context)),
                        ),
                        _row(
                          label: context.l10n.settingsImport,
                          onTap: _busy ? null : _importBackup,
                          trailing: Icon(CupertinoIcons.arrow_down_to_line,
                              size: 14, color: mutedColor(context)),
                        ),
                      ]),
                      SectionTitle(context.l10n.settingsSectionAbout),
                      _group(context, [
                        _row(label: context.l10n.settingsApp, value: 'FreeBuff 网关管理'),
                        if (_appVersion.isNotEmpty)
                          _row(label: context.l10n.settingsVersion, value: _appVersion),
                        _row(label: context.l10n.settingsBackend, value: 'freebuff-proxy-gateway'),
                        _row(label: context.l10n.settingsApi, value: '/admin/api/*'),
                      ]),
                    ],
                  ),
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _themePicker(BuildContext context) {
    final current = widget.state.themeMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (mode, label) in [
          (ThemeMode.system, context.l10n.settingsThemeSystem),
          (ThemeMode.light, context.l10n.settingsThemeLight),
          (ThemeMode.dark, context.l10n.settingsThemeDark),
        ])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ShadcnPill(
              label,
              selected: current == mode,
              onTap: () => widget.state.setThemeMode(mode),
            ),
          ),
      ],
    );
  }
}

class _ConnectionDialog extends StatefulWidget {
  const _ConnectionDialog({required this.url, required this.adminKey});

  final String url;
  final String adminKey;

  @override
  State<_ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<_ConnectionDialog> {
  late final TextEditingController _url;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.url);
    _key = TextEditingController(text: widget.adminKey);
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(context.l10n.settingsEditConnTitle),
      description: const SizedBox(),
      // ignore: sort_child_properties_last
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ShadInput(controller: _url,
              placeholder: Text(context.l10n.settingsGatewayUrl)),
          const SizedBox(height: 10),
          ShadInput(
              controller: _key,
              placeholder: Text(context.l10n.settingsAdminKey),
              obscureText: true),
        ],
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        ShadButton(
          onPressed: () {
            final u = _url.text.trim();
            final k = _key.text.trim();
            if (u.isEmpty || k.isEmpty) {
              showShadcnToast(context, context.l10n.settingsUrlKeyEmpty);
              return;
            }
            Navigator.pop(context, (u, k));
          },
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}

/// 导入备份对话框：粘贴 JSON。
class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(context.l10n.settingsImportTitle),
      description: Text(context.l10n.settingsImportDesc),
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: 380,
        child: ShadInput(
          controller: _ctrl,
          maxLines: 8,
          minLines: 5,
          placeholder: Text(context.l10n.settingsImportPlaceholder),
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        ShadButton(
          onPressed: () {
            final text = _ctrl.text.trim();
            if (text.isEmpty) {
              showShadcnToast(context, context.l10n.settingsImportPasteFirst);
              return;
            }
            Navigator.pop(context, text);
          },
          child: Text(context.l10n.commonImport),
        ),
      ],
    );
  }
}

class _ParamsDialog extends StatefulWidget {
  const _ParamsDialog({required this.config});

  final GatewayConfig config;

  @override
  State<_ParamsDialog> createState() => _ParamsDialogState();
}

class _ParamsDialogState extends State<_ParamsDialog> {
  late final TextEditingController _pinTtl;
  late final TextEditingController _stateTtl;
  late final TextEditingController _depletedProbe;
  late final TextEditingController _downProbe;
  late final TextEditingController _probeTimeout;
  late final TextEditingController _chatTimeout;
  late final TextEditingController _maxAttempts;
  late String _pinMode;
  late String _probeMode;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _pinTtl = TextEditingController(text: '${c.pinTtl ?? 3600}');
    _stateTtl = TextEditingController(text: '${c.stateTtl ?? 60}');
    _depletedProbe = TextEditingController(text: '${c.depletedProbe ?? 60}');
    _downProbe = TextEditingController(text: '${c.downProbe ?? 60}');
    _probeTimeout = TextEditingController(text: '${c.probeTimeout ?? 8000}');
    _chatTimeout = TextEditingController(text: '${c.chatTimeout ?? 120000}');
    _maxAttempts = TextEditingController(text: '${c.maxAttempts ?? 3}');
    _pinMode = c.pinMode ?? 'client';
    _probeMode = c.probeMode ?? 'smart';
  }

  @override
  void dispose() {
    for (final c in [
      _pinTtl,
      _stateTtl,
      _depletedProbe,
      _downProbe,
      _probeTimeout,
      _chatTimeout,
      _maxAttempts
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 6),
              ShadInput(controller: c,
                  placeholder: Text(context.l10n.settingsInput)),
            ],
          ),
        );
    return ShadDialog(
      title: Text(context.l10n.settingsEditParamsTitle),
      description: const SizedBox(),
      // ignore: sort_child_properties_last
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _modePicker(context, context.l10n.settingsPinMode, _pinMode, [
              ('client', context.l10n.settingsPinModeClient),
              ('header', context.l10n.settingsPinModeHeader),
              ('off', context.l10n.settingsPinModeOff),
            ], (v) => setState(() => _pinMode = v)),
            const SizedBox(height: 10),
            _modePicker(context, context.l10n.settingsProbeMode, _probeMode, [
              ('smart', context.l10n.settingsProbeSmart),
              ('scan', context.l10n.settingsProbeScan),
            ], (v) => setState(() => _probeMode = v)),
            const SizedBox(height: 10),
            field(_pinTtl, context.l10n.settingsPinTtl),
            field(_stateTtl, context.l10n.settingsStateTtl),
            field(_depletedProbe, context.l10n.settingsDepletedProbe),
            field(_downProbe, context.l10n.settingsDownProbe),
            field(_probeTimeout, context.l10n.settingsProbeTimeout),
            field(_chatTimeout, context.l10n.settingsChatTimeout),
            field(_maxAttempts, context.l10n.settingsMaxAttempts),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        ShadButton(
          onPressed: _submit,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }

  Widget _modePicker(BuildContext context, String label, String value,
      List<(String, String)> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ShadTheme.of(context).textTheme.small),
          const SizedBox(height: 6),
          ShadSelect<String>(
            minWidth: double.infinity,
            placeholder: Text(value),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            selectedOptionBuilder: (context, v) => Text(v),
            options: [
              for (final (v, l) in options) ShadOption(value: v, child: Text(l)),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    int? parse(TextEditingController c) => int.tryParse(c.text.trim());
    final pinTtl = parse(_pinTtl);
    final stateTtl = parse(_stateTtl);
    final depletedProbe = parse(_depletedProbe);
    final downProbe = parse(_downProbe);
    final probeTimeout = parse(_probeTimeout);
    final chatTimeout = parse(_chatTimeout);
    final maxAttempts = parse(_maxAttempts);

    String? err;
    if (pinTtl == null || pinTtl < 60) err = context.l10n.settingsErrPinTtl;
    if (err == null && (stateTtl == null || stateTtl < 60)) {
      err = context.l10n.settingsErrStateTtl;
    }
    if (err == null && (depletedProbe == null || depletedProbe < 60)) {
      err = context.l10n.settingsErrDepletedProbe;
    }
    if (err == null && (downProbe == null || downProbe < 30)) {
      err = context.l10n.settingsErrDownProbe;
    }
    if (err == null && (probeTimeout == null || probeTimeout < 500)) {
      err = context.l10n.settingsErrProbeTimeout;
    }
    if (err == null && (chatTimeout == null || chatTimeout < 1000)) {
      err = context.l10n.settingsErrChatTimeout;
    }
    if (err == null && (maxAttempts == null || maxAttempts < 1 || maxAttempts > 6)) {
      err = context.l10n.settingsErrMaxAttempts;
    }
    if (err != null) {
      showShadcnToast(context, err);
      return;
    }
    Navigator.pop(context, {
      'pinMode': _pinMode,
      'probeMode': _probeMode,
      'pinTtl': pinTtl,
      'stateTtl': stateTtl,
      'depletedProbe': depletedProbe,
      'downProbe': downProbe,
      'probeTimeout': probeTimeout,
      'chatTimeout': chatTimeout,
      'maxAttempts': maxAttempts,
    });
  }
}
