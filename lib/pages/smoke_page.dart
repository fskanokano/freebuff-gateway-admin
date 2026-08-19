/// 测试页：smoke 全链路测试。
/// 基于 flutter-shadcn-ui 组件。
library;

import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SmokePage extends StatefulWidget {
  const SmokePage({super.key, required this.state});

  final AppState state;

  @override
  State<SmokePage> createState() => _SmokePageState();
}

class _SmokePageState extends State<SmokePage> {
  final _prompt = TextEditingController(text: 'ping');
  final _customModel = TextEditingController();
  List<String> _models = const [];
  String? _model;
  bool _loadingModels = false;
  bool _running = false;
  SmokeResult? _result;
  final List<SmokeResult> _history = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _prompt.dispose();
    _customModel.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    final api = widget.state.api;
    if (api == null) return;
    setState(() => _loadingModels = true);
    try {
      final list = await api.models();
      if (!mounted) return;
      setState(() {
        _models = list.map((m) => m.id).toList();
        _model = _models.isNotEmpty ? _models.first : null;
      });
    } catch (e) {
      if (mounted) {
        showShadcnToast(context, '模型列表拉取失败（可手动输入模型名）: $e');
      }
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _run() async {
    final api = widget.state.api;
    if (api == null || _running) return;
    setState(() {
      _running = true;
      _result = null;
    });
    try {
      final model = _models.contains(_model)
          ? _model
          : (_customModel.text.trim().isEmpty ? null : _customModel.text.trim());
      final r = await api.smoke(
        model: model,
        prompt: _prompt.text.trim().isEmpty ? 'ping' : _prompt.text.trim(),
        stream: true,
      );
      if (!mounted) return;
      setState(() {
        _result = r;
        _history.insert(0, r);
        if (_history.length > 20) _history.removeLast();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = SmokeResult(ok: false, status: 0, error: e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          const GlassAppBar(title: Text('测试')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 请求配置
                  ShadCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _modelPicker(context),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _loadModels,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child:
                                    Icon(CupertinoIcons.refresh, size: 17),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ShadInput(
                          controller: _customModel,
                          placeholder: Text('或手动输入模型名（如 freebuff-1）'),
                        ),
                        const SizedBox(height: 12),
                        ShadInput(
                          controller: _prompt,
                          placeholder: Text('测试提示词'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        ShadButton(
                          width: double.infinity,
                          onPressed: _running ? null : _run,
                          child: _running
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white)
                              : const Text('发送测试请求'),
                        ),
                      ],
                    ),
                  ),
                  if (_result != null) ...[
                    const SectionTitle('本次结果'),
                    _resultCard(context, _result!),
                  ],
                  if (_history.isNotEmpty) ...[
                    const SectionTitle('历史记录'),
                    ..._history
                        .take(10)
                        .map((r) => _resultCard(context, r, compact: true)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelPicker(BuildContext context) {
    if (_loadingModels) {
      return const Row(
        children: [
          CupertinoActivityIndicator(radius: 8),
          SizedBox(width: 10),
          Text('加载模型…', style: TextStyle(fontSize: 13)),
        ],
      );
    }
    if (_models.isEmpty) {
      return Text('无可用模型（可手动输入）',
          style: ShadTheme.of(context).textTheme.small);
    }
    return ShadSelect<String>(
      minWidth: double.infinity,
      placeholder: Text(_model ?? '选择模型'),
      onChanged: (v) {
        if (v != null) setState(() => _model = v);
      },
      selectedOptionBuilder: (context, v) => Text(v),
      options: [
        for (final m in _models) ShadOption(value: m, child: Text(m)),
      ],
    );
  }

  Widget _resultCard(BuildContext context, SmokeResult r,
      {bool compact = false}) {
    final ok = r.ok && r.error.isEmpty;
    final accent = ok ? ShadcnColors.ok : ShadcnColors.danger;
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  ok
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: accent,
                  size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'HTTP ${r.status} ${ok ? '成功' : '失败'}'
                  '${r.proxy != null ? ' · 路由到 ${r.proxy}' : ''}'
                  ' · 尝试 ${r.attempts} 次 · ${r.ms}ms',
                  style: ShadTheme.of(context)
                      .textTheme
                      .p
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (r.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.content,
                style: ShadTheme.of(context).textTheme.small,
                maxLines: compact ? 1 : null,
                overflow: compact ? TextOverflow.ellipsis : null),
          ],
          if (r.error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.error,
                style: ShadTheme.of(context)
                    .textTheme
                    .small
                    .copyWith(color: ShadcnColors.danger),
                maxLines: compact ? 1 : null,
                overflow: compact ? TextOverflow.ellipsis : null),
          ],
        ],
      ),
    );
  }
}
