/// 本地化便捷层：context.l10n 访问器 + 语义/时间/数字/错误的本地化工具。
library;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// `context.l10n.xxx` 便捷访问器。
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// 挂到生成的 AppLocalizations 上的本地化工具。
extension L10nExt on AppLocalizations {
  bool get _isZh => localeName.startsWith('zh');

  /// 代理状态的中文/英文标签。
  String statusLabel(String status) {
    switch (status) {
      case 'ok':
        return statusOk;
      case 'depleted':
        return statusDepleted;
      case 'down':
        return statusDown;
      case 'bad_config':
        return statusBadConfig;
      case 'maint':
        return statusMaint;
      default:
        return status;
    }
  }

  /// 相对时间描述（刚刚 / N 秒前 / …）。
  String relativeTime(DateTime? t) {
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.isNegative || diff.inSeconds < 5) return relJustNow;
    if (diff.inSeconds < 60) return '${diff.inSeconds} $relSecondsAgo';
    if (diff.inMinutes < 60) return '${diff.inMinutes} $relMinutesAgo';
    if (diff.inHours < 24) return '${diff.inHours} $relHoursAgo';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${t.month}/${t.day} $h:$m';
  }

  /// 紧凑数字（中文：万/亿；英文：K/M/B）。
  String compact(num n) {
    if (_isZh) {
      if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}$unitYi';
      if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}$unitWan';
    } else {
      if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}$unitB';
      if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}$unitM';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}$unitK';
    }
    return _thousands(n.round());
  }

  /// 金额（$ 前缀 + 紧凑；null → —）。
  String money(double? v) {
    if (v == null) return '—';
    if (v == 0) return '\$0';
    if (v.abs() < 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${compact(v)}';
  }

  /// 错误码 → 本地化标签。
  String codeLabel(String? code) {
    switch (code) {
      case 'rate_limited': return codeRateLimited;
      case 'banned': return codeBanned;
      case 'country_blocked': return codeCountryBlocked;
      case 'out_of_credits': return codeOutOfCredits;
      case 'waiting_room': return codeWaitingRoom;
      case 'auth_rejected': return codeAuthRejected;
      case 'invalid_api_key': return codeInvalidApiKey;
      case 'timeout': return codeTimeout;
      case 'connection_error': return codeConnectionError;
      case 'dns_error': return codeDnsError;
      case 'probe_failed': return codeProbeFailed;
      case 'quota_exhausted': return codeQuotaExhausted;
      case 'locked': return codeLocked;
      case 'unknown': return codeUnknown;
      default: return code ?? '';
    }
  }

  /// 后台操作类型 → 本地化标签。
  String actionLabel(String? action) {
    switch (action) {
      case 'save_config': return actionSaveConfig;
      case 'probe': return actionProbe;
      case 'clear_pin': return actionClearPin;
      case 'reset_config': return actionResetConfig;
      case 'clear_logs': return actionClearLogs;
      default: return action ?? '';
    }
  }

  /// 事件类型 → 本地化标签。
  String eventTypeLabel(String? type) {
    switch (type) {
      case 'status_change': return logsEventStatusChange;
      case 'failover': return logsEventFailover;
      case 'probe_failed': return logsEventProbeFailed;
      case 'admin_action': return logsEventAdminAction;
      case 'maintenance': return logsEventMaintenance;
      case 'smoke': return logsEventSmoke;
      default: return type ?? '';
    }
  }

  /// 错误信息本地化（kind: unauthorized | connection | null）。
  String errorText(String? kind, String? detail) {
    if (kind == 'unauthorized') return err401;
    if (kind == 'connection') return errConnFailed(detail ?? '');
    return detail ?? '';
  }

  String _thousands(int n) {
    final neg = n < 0;
    final s = n.abs().toString();
    final parts = <String>[];
    for (int i = s.length; i > 0; i -= 3) {
      final start = (i - 3) < 0 ? 0 : (i - 3);
      parts.insert(0, s.substring(start, i));
    }
    return (neg ? '-' : '') + parts.join(',');
  }
}
