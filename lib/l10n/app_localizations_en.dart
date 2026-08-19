// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonImport => 'Import';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonUnconfigured => 'Not configured';

  @override
  String get commonNone => 'None';

  @override
  String get statusOk => 'Healthy';

  @override
  String get statusDepleted => 'Depleted';

  @override
  String get statusDown => 'Down';

  @override
  String get statusBadConfig => 'Bad config';

  @override
  String get statusMaint => 'Maintenance';

  @override
  String get relJustNow => 'just now';

  @override
  String get relSecondsAgo => 's ago';

  @override
  String get relMinutesAgo => 'm ago';

  @override
  String get relHoursAgo => 'h ago';

  @override
  String get unitWan => '万';

  @override
  String get unitYi => '亿';

  @override
  String get unitK => 'K';

  @override
  String get unitM => 'M';

  @override
  String get unitB => 'B';

  @override
  String get connectTitle => 'FreeBuff Gateway Admin';

  @override
  String get connectSubtitle =>
      'Connect to your freebuff-proxy-gateway instance';

  @override
  String get connectUrlPlaceholder => 'https://gateway.example.workers.dev';

  @override
  String get connectKeyPlaceholder => 'ADMIN_KEY or API_KEY';

  @override
  String get connectKeyHint =>
      'Key is stored locally only, used to call /admin/api/*';

  @override
  String get connectButton => 'Connect & verify';

  @override
  String get connectErrUrlEmpty => 'Please enter the gateway URL';

  @override
  String get connectErrUrlScheme => 'Must start with http:// or https://';

  @override
  String get connectErrKeyEmpty => 'Please enter the key';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabAnalytics => 'Analytics';

  @override
  String get tabProxies => 'Proxies';

  @override
  String get tabLogs => 'Logs';

  @override
  String get tabSmoke => 'Smoke';

  @override
  String get tabSettings => 'Settings';

  @override
  String get overviewProxyStatus => 'Proxy status';

  @override
  String get overviewRecentRoutes => 'Recent routes';

  @override
  String get overviewProxyHealth => 'Proxy health';

  @override
  String get overviewWaiting => 'Waiting for data…';

  @override
  String get overviewConnFailed => 'Connection failed';

  @override
  String overviewUpdatedAt(String time) {
    return 'Updated $time · polling every 5s';
  }

  @override
  String get overviewTotalProxies => 'Total proxies';

  @override
  String get overviewOk => 'Healthy';

  @override
  String get overviewDepleted => 'Depleted';

  @override
  String get overviewDown => 'Down';

  @override
  String get overviewReqOk => 'Requests OK';

  @override
  String get overviewReqFail => 'Requests failed';

  @override
  String get overviewSubConfigured => 'configured';

  @override
  String get overviewSubAvailable => 'available';

  @override
  String get overviewSubWaitReset => 'awaiting reset';

  @override
  String get overviewSubInclBadCfg => 'incl. bad config';

  @override
  String get overviewSubCumulative => 'cumulative';

  @override
  String get overviewNoRoutes =>
      'No routes yet — send a chat request and routing facts will appear here.';

  @override
  String get overviewNoProxies => 'No proxies';

  @override
  String proxiesPinned(String name) {
    return 'Pinned proxy: $name';
  }

  @override
  String get proxiesUnpin => 'Unpin';

  @override
  String get proxiesProbe => 'Probe';

  @override
  String get proxiesEdit => 'Edit';

  @override
  String get proxiesMaintenance => 'Maintenance';

  @override
  String get proxiesMaintHint => 'In maintenance; routing excludes this proxy';

  @override
  String get proxiesUsage => 'Usage';

  @override
  String get proxiesReason => 'Reason';

  @override
  String get proxiesDetail => 'Detail';

  @override
  String get proxiesCooldown => 'Cooldown';

  @override
  String get proxiesResetAt => 'Resets';

  @override
  String get proxiesNextProbe => 'Next probe';

  @override
  String get proxiesLastOk => 'Last OK';

  @override
  String get proxiesLastFail => 'Last error';

  @override
  String proxiesRisk(String risk) {
    return 'Risk $risk';
  }

  @override
  String proxiesSpend24h(String v) {
    return '24h $v';
  }

  @override
  String proxiesSpendWeek(String v) {
    return 'week $v';
  }

  @override
  String proxiesSpendMonth(String v) {
    return 'month $v';
  }

  @override
  String get proxiesAdd => 'Add proxy';

  @override
  String proxiesEditTitle(String name) {
    return 'Edit proxy $name';
  }

  @override
  String get proxiesNamePlaceholder => 'Name (optional, auto-normalized)';

  @override
  String get proxiesUrlPlaceholder => 'Proxy URL (http(s)://…)';

  @override
  String get proxiesKeyPlaceholder => 'Proxy API key';

  @override
  String get proxiesKeyPlaceholderKeep => 'Proxy API key (leave empty to keep)';

  @override
  String get proxiesRemarkPlaceholder => 'Remark (optional, e.g. main route)';

  @override
  String get proxiesErrUrlScheme => 'URL must start with http(s)://';

  @override
  String get proxiesErrName =>
      'Name allows lowercase letters/digits/hyphens only';

  @override
  String get proxiesErrKeyRequired => 'New proxy requires a key';

  @override
  String proxiesOpFailed(String err) {
    return 'Operation failed: $err';
  }

  @override
  String get proxiesProbeDone => 'Probe complete';

  @override
  String get proxiesAdded => 'Proxy added';

  @override
  String get proxiesSaved => 'Changes saved';

  @override
  String proxiesDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get proxiesNeedOne => 'At least one proxy is required';

  @override
  String get proxiesDeleteTitle => 'Delete proxy';

  @override
  String proxiesDeleteMessage(String name) {
    return 'Delete proxy \"$name\"?\n\nThis removes it from the runtime config; if the proxy came from env vars it will reappear after reset.';
  }

  @override
  String get proxiesEgressTitle => 'Egress IP probe';

  @override
  String get proxiesEgressSubtitle =>
      'Public egress IP and geolocation per proxy';

  @override
  String proxiesEgressFailed(String err) {
    return 'Egress probe failed: $err';
  }

  @override
  String get logsClear => 'Clear';

  @override
  String get logsSearchPlaceholder => 'Search proxy / model / type / content…';

  @override
  String get logsAll => 'All';

  @override
  String get logsRoutes => 'Routes';

  @override
  String get logsEvents => 'Events';

  @override
  String get logsSuccess => '✓ OK';

  @override
  String get logsFail => '✗ Fail';

  @override
  String get logsAllEvents => 'All events';

  @override
  String get logsAllTime => 'All time';

  @override
  String get logsLast5m => 'Last 5m';

  @override
  String get logsLast30m => 'Last 30m';

  @override
  String get logsLast1h => 'Last 1h';

  @override
  String logsCount(int count) {
    return '$count entries';
  }

  @override
  String logsRouteCount(int ok, int fail) {
    return 'routes $ok✓/$fail✗';
  }

  @override
  String logsAvgMs(int ms) {
    return 'avg ${ms}ms';
  }

  @override
  String logsUpdated(String time) {
    return 'updated $time';
  }

  @override
  String get logsInsightStatus => 'Status codes';

  @override
  String get logsInsightFailReason => 'Failure reasons';

  @override
  String get logsInsightEventType => 'Event types';

  @override
  String get logsEventStatusChange => 'Status change';

  @override
  String get logsEventFailover => 'Failover';

  @override
  String get logsEventProbeFailed => 'Probe failed';

  @override
  String get logsEventAdminAction => 'Admin action';

  @override
  String get logsEventMaintenance => 'Maintenance';

  @override
  String get logsEventSmoke => 'Smoke';

  @override
  String get logsEmpty => 'No matching logs';

  @override
  String get logsClearTitle => 'Clear logs';

  @override
  String get logsClearMessage =>
      'Clear route records and system events (ring buffer)?';

  @override
  String logsClearFailed(String err) {
    return 'Clear failed: $err';
  }

  @override
  String logsRouteTitle(String name, String result) {
    return 'route → $name $result';
  }

  @override
  String get logsRouteOk => '(OK)';

  @override
  String get logsRouteFail => '(failed)';

  @override
  String logsHttpAttempts(int status, int attempts, int ms) {
    return 'HTTP $status · $attempts attempts · ${ms}ms';
  }

  @override
  String get codeRateLimited => 'rate limited';

  @override
  String get codeBanned => 'banned';

  @override
  String get codeCountryBlocked => 'country blocked';

  @override
  String get codeOutOfCredits => 'out of credits';

  @override
  String get codeWaitingRoom => 'waiting room';

  @override
  String get codeAuthRejected => 'auth rejected';

  @override
  String get codeInvalidApiKey => 'invalid API key';

  @override
  String get codeTimeout => 'timeout';

  @override
  String get codeConnectionError => 'connection error';

  @override
  String get codeDnsError => 'DNS error';

  @override
  String get codeProbeFailed => 'probe failed';

  @override
  String get codeQuotaExhausted => 'quota exhausted';

  @override
  String get codeLocked => 'locked';

  @override
  String get codeUnknown => 'unknown';

  @override
  String get actionSaveConfig => 'save config';

  @override
  String get actionProbe => 'probe';

  @override
  String get actionClearPin => 'clear pin';

  @override
  String get actionResetConfig => 'reset config';

  @override
  String get actionClearLogs => 'clear logs';

  @override
  String smokeModelLoadFailed(String err) {
    return 'Failed to load models (you can type one): $err';
  }

  @override
  String get smokeCustomModel => 'or type a model name (e.g. freebuff-1)';

  @override
  String get smokePrompt => 'Test prompt';

  @override
  String get smokeRun => 'Send test request';

  @override
  String get smokeResult => 'Result';

  @override
  String get smokeHistory => 'History';

  @override
  String get smokeSelectModel => 'Select model';

  @override
  String get smokeLoadingModels => 'Loading models…';

  @override
  String get smokeNoModels => 'No models (you can type one)';

  @override
  String get smokeOk => 'OK';

  @override
  String get smokeFail => 'failed';

  @override
  String smokeHttpResult(
    int status,
    String result,
    String proxy,
    int attempts,
    int ms,
  ) {
    return 'HTTP $status $result · routed to $proxy · $attempts attempts · ${ms}ms';
  }

  @override
  String get settingsSectionConn => 'Connection';

  @override
  String get settingsGatewayUrl => 'Gateway URL';

  @override
  String get settingsAdminKey => 'Admin key';

  @override
  String get settingsPolling => 'Polling';

  @override
  String get settingsPollingRunning => 'every 5s';

  @override
  String get settingsPollingStopped => 'stopped';

  @override
  String get settingsEditConn => 'Edit connection';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsSectionPin => 'Pinned proxy';

  @override
  String get settingsCurrentPin => 'Current pin';

  @override
  String get settingsStickyKey => 'Sticky key';

  @override
  String get settingsPinMode => 'Pin mode';

  @override
  String get settingsClearPin => 'Clear session pin';

  @override
  String get settingsSectionRuntime => 'Runtime config';

  @override
  String get settingsCfgUnreadable =>
      'Unable to read config (check connection/key)';

  @override
  String get settingsProxyCount => 'Proxy count';

  @override
  String get settingsProbeMode => 'Probe mode';

  @override
  String get settingsSource => 'Source';

  @override
  String get settingsSourceRuntime => 'runtime config';

  @override
  String get settingsSourceMixed => 'env + runtime params';

  @override
  String get settingsSourceEnv => 'env vars';

  @override
  String get settingsClientKey => 'Client key';

  @override
  String get settingsAdminAuth => 'Admin auth';

  @override
  String get settingsReuseApiKey => 'reuse API_KEY';

  @override
  String get settingsAdminKeyMasked => 'Admin key';

  @override
  String get settingsProxyKey => 'Proxy key';

  @override
  String get settingsRuntimeErr => 'Runtime proxy error';

  @override
  String get settingsEditParams => 'Edit params';

  @override
  String get settingsResetEnv => 'Reset to env vars';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSectionBackup => 'Backup & restore';

  @override
  String get settingsExport => 'Export config (copy to clipboard)';

  @override
  String get settingsImport => 'Import config (paste JSON)';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsBackend => 'Backend';

  @override
  String get settingsApi => 'API';

  @override
  String get settingsConnUpdated => 'Connection updated';

  @override
  String get settingsParamsSaved => 'Params saved and applied';

  @override
  String get settingsResetTitle => 'Reset to env config';

  @override
  String get settingsResetMessage =>
      'Clear runtime config (proxy list & params) and restore env vars. Continue?';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get settingsResetDone => 'Restored env config';

  @override
  String get settingsPinCleared => 'Session pin cleared';

  @override
  String get settingsExportDone =>
      'Config copied to clipboard (contains plaintext keys — don\'t share)';

  @override
  String settingsExportFailed(String err) {
    return 'Export failed: $err';
  }

  @override
  String get settingsImportTitle => 'Import config';

  @override
  String get settingsImportMessage =>
      'This overwrites the proxy list and runtime params; content may include plaintext keys. Continue?';

  @override
  String settingsImportFailed(String err) {
    return 'Import failed: $err';
  }

  @override
  String get settingsImportDone => 'Imported';

  @override
  String get settingsBadJson => 'Backup must be a JSON object';

  @override
  String get settingsEditConnTitle => 'Edit connection';

  @override
  String get settingsUrlKeyEmpty => 'URL and key are required';

  @override
  String get settingsImportDesc =>
      'Paste backup JSON (with version / proxies / settings)';

  @override
  String get settingsImportPlaceholder => 'version: 1, proxies: [...]';

  @override
  String get settingsImportPasteFirst => 'Paste the backup JSON first';

  @override
  String get settingsEditParamsTitle => 'Edit runtime params';

  @override
  String get settingsPinTtl => 'Pin TTL (sec, ≥60)';

  @override
  String get settingsStateTtl => 'State TTL (sec, ≥60)';

  @override
  String get settingsDepletedProbe => 'Depleted re-probe interval (sec, ≥60)';

  @override
  String get settingsDownProbe => 'Down re-probe interval (sec, ≥30)';

  @override
  String get settingsProbeTimeout => 'Probe timeout (ms, ≥500)';

  @override
  String get settingsChatTimeout => 'Forward timeout (ms, ≥1000)';

  @override
  String get settingsMaxAttempts => 'Max attempts (1-6)';

  @override
  String get settingsInput => 'Enter value';

  @override
  String get settingsPinModeClient => 'client — pin by gateway key';

  @override
  String get settingsPinModeHeader => 'header — pin by X-Sticky-Id';

  @override
  String get settingsPinModeOff => 'off — no pinning';

  @override
  String get settingsProbeSmart => 'smart — lazy probing';

  @override
  String get settingsProbeScan => 'scan — periodic scan';

  @override
  String get settingsErrPinTtl => 'pinTtl must be ≥ 60';

  @override
  String get settingsErrStateTtl => 'stateTtl must be ≥ 60';

  @override
  String get settingsErrDepletedProbe => 'depletedProbe must be ≥ 60';

  @override
  String get settingsErrDownProbe => 'downProbe must be ≥ 30';

  @override
  String get settingsErrProbeTimeout => 'probeTimeout must be ≥ 500';

  @override
  String get settingsErrChatTimeout => 'chatTimeout must be ≥ 1000';

  @override
  String get settingsErrMaxAttempts => 'maxAttempts must be 1-6';

  @override
  String get analyticsSpendByProxy => 'Spend (per proxy)';

  @override
  String get analyticsUsage => 'Quota usage';

  @override
  String get analyticsTrend => 'Request trend';

  @override
  String get analyticsModels => 'Model availability';

  @override
  String get analyticsNoSpend => 'No spend data';

  @override
  String get analyticsNoProxies => 'No proxies';

  @override
  String get analyticsCollecting => 'Collecting data, check back soon';

  @override
  String get analyticsNoModels => 'No model data (tap refresh to retry)';

  @override
  String get analyticsSpend24h => 'Rolling 24h spend';

  @override
  String get analyticsSpendWeek => 'This week';

  @override
  String get analyticsSpendMonth => 'This month';

  @override
  String get analyticsWindow24h => '24h';

  @override
  String get analyticsWindowWeek => 'week';

  @override
  String get analyticsWindowMonth => 'month';

  @override
  String get analyticsSuccess => 'OK';

  @override
  String get analyticsFail => 'failed';

  @override
  String analyticsAvgLatency(int ms) {
    return 'avg latency $ms ms';
  }

  @override
  String get analyticsModelOk => 'ok';

  @override
  String get analyticsModelDepleted => 'depleted';

  @override
  String get analyticsModelDown => 'down';

  @override
  String get err401 => 'Key invalid or expired (401)';

  @override
  String errConnFailed(String err) {
    return 'Connection failed: $err';
  }

  @override
  String get fieldProxy => 'Proxy';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldStatusCode => 'Status code';

  @override
  String get fieldAttempts => 'Attempts';

  @override
  String get fieldLatency => 'Latency';

  @override
  String get fieldModel => 'Model';

  @override
  String get fieldResult => 'Result';

  @override
  String get fieldTime => 'Time';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldChange => 'Change';

  @override
  String get fieldErrorCode => 'Error code';

  @override
  String get fieldError => 'Error';

  @override
  String get fieldAction => 'Action';

  @override
  String get fieldRouteTo => 'Routed to';

  @override
  String get fieldEnabled => 'enabled';

  @override
  String get fieldDisabled => 'disabled';

  @override
  String get fieldKey => 'key';

  @override
  String get fieldMaintenance => 'maintenance';

  @override
  String fieldProxiesCount(String n) {
    return '$n proxies';
  }

  @override
  String fieldParamsCount(String n) {
    return '$n params';
  }

  @override
  String smokeAttempts(String n) {
    return 'attempts: $n';
  }

  @override
  String get commonRefresh => 'Refresh';
}
