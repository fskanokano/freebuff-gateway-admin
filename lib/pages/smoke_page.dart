/// 测试页：smoke 全链路测试（真实请求走完整路由链路）。
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('模型列表拉取失败（可手动输入模型名）: $e')));
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
      final model = _models.contains(_model) ? _model : (_customModel.text.trim().isEmpty ? null : _customModel.text.trim());
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
    return Scaffold(
      appBar: AppBar(title: const Text('测试')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _loadingModels
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<String>(
                                initialValue: _model,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: '模型',
                                    border: OutlineInputBorder(),
                                    isDense: true),
                                items: _models
                                    .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) => setState(() => _model = v),
                              ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: '刷新模型列表',
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadModels,
                      ),
                    ],
                  ),
                  if (!_models.contains(_model))
                    const SizedBox(height: 8),
                  TextField(
                    controller: _customModel,
                    decoration: const InputDecoration(
                      labelText: '或手动输入模型名',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'freebuff-1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _prompt,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '测试提示词',
                      border: OutlineInputBorder(),
                      hintText: 'ping',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _running ? null : _run,
                          icon: _running
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.science),
                          label: Text(_running ? '请求中…' : '发送测试请求'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SectionTitle('本次结果'),
            _resultCard(context, _result!),
          ],
          if (_history.isNotEmpty) ...[
            const SectionTitle('历史记录'),
            ..._history.take(10).map((r) => _resultCard(context, r, compact: true)),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, SmokeResult r, {bool compact = false}) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ok = r.ok && r.error.isEmpty;
    final accent = ok ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.error, color: accent, size: 20),
                const SizedBox(width: 6),
                Text(
                  'HTTP ${r.status} ${ok ? '成功' : '失败'}'
                  '${r.proxy != null ? ' · 路由到 ${r.proxy}' : ''}'
                  ' · 尝试 ${r.attempts} 次 · ${r.ms}ms',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (!compact) ...[
              if (r.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(r.content,
                    style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              if (r.error.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(r.error,
                    style: t.bodySmall?.copyWith(color: scheme.error)),
              ],
            ] else if (r.content.isNotEmpty || r.error.isNotEmpty)
              const SizedBox(height: 6),
            if (compact)
              Text(
                (r.content.isNotEmpty ? r.content : r.error).replaceAll('\n', ' '),
                style: t.bodySmall?.copyWith(color: scheme.outline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
