// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonImport => '导入';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRetry => '重试';

  @override
  String get commonUnconfigured => '未配置';

  @override
  String get commonNone => '无';

  @override
  String get statusOk => '正常';

  @override
  String get statusDepleted => '额度耗尽';

  @override
  String get statusDown => '故障';

  @override
  String get statusBadConfig => '配置错误';

  @override
  String get statusMaint => '维护中';

  @override
  String get relJustNow => '刚刚';

  @override
  String get relSecondsAgo => '秒前';

  @override
  String get relMinutesAgo => '分钟前';

  @override
  String get relHoursAgo => '小时前';

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
  String get connectTitle => 'FreeBuff 网关管理';

  @override
  String get connectSubtitle => '连接你的 freebuff-proxy-gateway 实例';

  @override
  String get connectUrlPlaceholder => 'https://gateway.example.workers.dev';

  @override
  String get connectKeyPlaceholder => 'ADMIN_KEY 或 API_KEY';

  @override
  String get connectKeyHint => '密钥仅保存在本机，用于请求 /admin/api/* 接口';

  @override
  String get connectButton => '连接并验证';

  @override
  String get connectErrUrlEmpty => '请输入网关地址';

  @override
  String get connectErrUrlScheme => '需以 http:// 或 https:// 开头';

  @override
  String get connectErrKeyEmpty => '请输入密钥';

  @override
  String get tabDashboard => '仪表盘';

  @override
  String get tabAnalytics => '分析';

  @override
  String get tabProxies => '代理';

  @override
  String get tabLogs => '日志';

  @override
  String get tabSmoke => '测试';

  @override
  String get tabSettings => '设置';

  @override
  String get overviewProxyStatus => '代理状态';

  @override
  String get overviewRecentRoutes => '最近路由';

  @override
  String get overviewProxyHealth => '代理健康';

  @override
  String get overviewWaiting => '等待数据…';

  @override
  String get overviewConnFailed => '连接失败';

  @override
  String overviewUpdatedAt(String time) {
    return '更新于 $time · 每 5s 轮询';
  }

  @override
  String get overviewTotalProxies => '代理总数';

  @override
  String get overviewOk => '正常';

  @override
  String get overviewDepleted => '额度耗尽';

  @override
  String get overviewDown => '故障';

  @override
  String get overviewReqOk => '成功请求';

  @override
  String get overviewReqFail => '失败请求';

  @override
  String get overviewSubConfigured => '已配置';

  @override
  String get overviewSubAvailable => '可用';

  @override
  String get overviewSubWaitReset => '等待重置';

  @override
  String get overviewSubInclBadCfg => '含配置错误';

  @override
  String get overviewSubCumulative => '累计';

  @override
  String get overviewNoRoutes => '暂无路由记录 — 发一条聊天请求后这里会显示路由事实。';

  @override
  String get overviewNoProxies => '暂无代理';

  @override
  String proxiesPinned(String name) {
    return '当前常驻代理：$name';
  }

  @override
  String get proxiesUnpin => '解除';

  @override
  String get proxiesProbe => '探测';

  @override
  String get proxiesEdit => '编辑';

  @override
  String get proxiesMaintenance => '维护模式';

  @override
  String get proxiesMaintHint => '维护中，路由会排除该代理';

  @override
  String get proxiesUsage => '用量';

  @override
  String get proxiesReason => '原因';

  @override
  String get proxiesDetail => '详情';

  @override
  String get proxiesCooldown => '冷却至';

  @override
  String get proxiesResetAt => '重置于';

  @override
  String get proxiesNextProbe => '下次探测';

  @override
  String get proxiesLastOk => '上次成功';

  @override
  String get proxiesLastFail => '上次失败';

  @override
  String proxiesRisk(String risk) {
    return '风险 $risk';
  }

  @override
  String proxiesSpend24h(String v) {
    return '24h $v';
  }

  @override
  String proxiesSpendWeek(String v) {
    return '周 $v';
  }

  @override
  String proxiesSpendMonth(String v) {
    return '月 $v';
  }

  @override
  String get proxiesAdd => '添加代理';

  @override
  String proxiesEditTitle(String name) {
    return '编辑代理 $name';
  }

  @override
  String get proxiesNamePlaceholder => '名称（可选，自动规范化）';

  @override
  String get proxiesUrlPlaceholder => '代理地址（http(s)://…）';

  @override
  String get proxiesKeyPlaceholder => '代理 API Key';

  @override
  String get proxiesKeyPlaceholderKeep => '代理 API Key（留空保持原值）';

  @override
  String get proxiesRemarkPlaceholder => '备注（可选，如：主线路）';

  @override
  String get proxiesErrUrlScheme => '地址需以 http(s):// 开头';

  @override
  String get proxiesErrName => '名称仅允许小写字母/数字/连字符';

  @override
  String get proxiesErrKeyRequired => '新增代理必须填写 Key';

  @override
  String proxiesOpFailed(String err) {
    return '操作失败: $err';
  }

  @override
  String get proxiesProbeDone => '探测完成';

  @override
  String get proxiesAdded => '已添加代理';

  @override
  String get proxiesSaved => '已保存修改';

  @override
  String proxiesDeleted(String name) {
    return '已删除 $name';
  }

  @override
  String get proxiesNeedOne => '至少需要保留一个代理';

  @override
  String get proxiesDeleteTitle => '删除代理';

  @override
  String proxiesDeleteMessage(String name) {
    return '确定删除代理 \"$name\" 吗？\n\n删除的是后台运行时配置中的代理列表；若代理来自环境变量，恢复默认会重新出现。';
  }

  @override
  String get proxiesEgressTitle => '出口 IP 探测';

  @override
  String get proxiesEgressSubtitle => '每个代理的公网出口 IP 与地理位置';

  @override
  String proxiesEgressFailed(String err) {
    return '出口 IP 探测失败: $err';
  }

  @override
  String get logsClear => '清空';

  @override
  String get logsSearchPlaceholder => '搜索代理名 / 模型 / 类型 / 内容…';

  @override
  String get logsAll => '全部';

  @override
  String get logsRoutes => '路由记录';

  @override
  String get logsEvents => '系统事件';

  @override
  String get logsSuccess => '✓ 成功';

  @override
  String get logsFail => '✗ 失败';

  @override
  String get logsAllEvents => '全部事件';

  @override
  String get logsAllTime => '全部时间';

  @override
  String get logsLast5m => '近 5 分钟';

  @override
  String get logsLast30m => '近 30 分钟';

  @override
  String get logsLast1h => '近 1 小时';

  @override
  String logsCount(int count) {
    return '共 $count 条';
  }

  @override
  String logsRouteCount(int ok, int fail) {
    return '路由 $ok✓/$fail✗';
  }

  @override
  String logsAvgMs(int ms) {
    return '平均 ${ms}ms';
  }

  @override
  String logsUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get logsInsightStatus => '状态码';

  @override
  String get logsInsightFailReason => '失败原因';

  @override
  String get logsInsightEventType => '事件类型';

  @override
  String get logsEventStatusChange => '状态变化';

  @override
  String get logsEventFailover => '故障转移';

  @override
  String get logsEventProbeFailed => '探测失败';

  @override
  String get logsEventAdminAction => '后台操作';

  @override
  String get logsEventMaintenance => '维护模式';

  @override
  String get logsEventSmoke => '测试请求';

  @override
  String get logsEmpty => '暂无匹配的日志';

  @override
  String get logsClearTitle => '清空日志';

  @override
  String get logsClearMessage => '将清空路由记录与系统事件（环形缓冲），确定吗？';

  @override
  String logsClearFailed(String err) {
    return '清空失败: $err';
  }

  @override
  String logsRouteTitle(String name, String result) {
    return '路由 → $name $result';
  }

  @override
  String get logsRouteOk => '(成功)';

  @override
  String get logsRouteFail => '(失败)';

  @override
  String logsHttpAttempts(int status, int attempts, int ms) {
    return 'HTTP $status · 尝试 $attempts 次 · ${ms}ms';
  }

  @override
  String get codeRateLimited => '限流';

  @override
  String get codeBanned => '账号封禁';

  @override
  String get codeCountryBlocked => '区域限制';

  @override
  String get codeOutOfCredits => '余额不足';

  @override
  String get codeWaitingRoom => '排队中';

  @override
  String get codeAuthRejected => '上游鉴权拒绝';

  @override
  String get codeInvalidApiKey => '密钥无效';

  @override
  String get codeTimeout => '超时';

  @override
  String get codeConnectionError => '连接失败';

  @override
  String get codeDnsError => 'DNS 解析失败';

  @override
  String get codeProbeFailed => '探测失败';

  @override
  String get codeQuotaExhausted => '额度耗尽';

  @override
  String get codeLocked => '锁定';

  @override
  String get codeUnknown => '未知';

  @override
  String get actionSaveConfig => '保存配置';

  @override
  String get actionProbe => '立即探测';

  @override
  String get actionClearPin => '解除常驻';

  @override
  String get actionResetConfig => '恢复环境变量';

  @override
  String get actionClearLogs => '清空日志';

  @override
  String smokeModelLoadFailed(String err) {
    return '模型列表拉取失败（可手动输入模型名）: $err';
  }

  @override
  String get smokeCustomModel => '或手动输入模型名（如 freebuff-1）';

  @override
  String get smokePrompt => '测试提示词';

  @override
  String get smokeRun => '发送测试请求';

  @override
  String get smokeResult => '本次结果';

  @override
  String get smokeHistory => '历史记录';

  @override
  String get smokeSelectModel => '选择模型';

  @override
  String get smokeLoadingModels => '加载模型…';

  @override
  String get smokeNoModels => '无可用模型（可手动输入）';

  @override
  String get smokeOk => '成功';

  @override
  String get smokeFail => '失败';

  @override
  String smokeHttpResult(
    int status,
    String result,
    String proxy,
    int attempts,
    int ms,
  ) {
    return 'HTTP $status $result · 路由到 $proxy · 尝试 $attempts 次 · ${ms}ms';
  }

  @override
  String get settingsSectionConn => '连接';

  @override
  String get settingsGatewayUrl => '网关地址';

  @override
  String get settingsAdminKey => '管理员密钥';

  @override
  String get settingsPolling => '轮询状态';

  @override
  String get settingsPollingRunning => '每 5s 刷新';

  @override
  String get settingsPollingStopped => '未运行';

  @override
  String get settingsEditConn => '修改连接';

  @override
  String get settingsLogout => '登出';

  @override
  String get settingsSectionPin => '常驻代理';

  @override
  String get settingsCurrentPin => '当前常驻';

  @override
  String get settingsStickyKey => 'Sticky Key';

  @override
  String get settingsPinMode => 'Pin 模式';

  @override
  String get settingsClearPin => '解除当前会话常驻';

  @override
  String get settingsSectionRuntime => '运行时配置';

  @override
  String get settingsCfgUnreadable => '无法读取配置（检查连接或密钥）';

  @override
  String get settingsProxyCount => '代理数量';

  @override
  String get settingsProbeMode => '探测模式';

  @override
  String get settingsSource => '来源';

  @override
  String get settingsSourceRuntime => '后台运行时配置';

  @override
  String get settingsSourceMixed => '环境变量 + 运行时参数';

  @override
  String get settingsSourceEnv => '环境变量';

  @override
  String get settingsClientKey => '客户端 Key';

  @override
  String get settingsAdminAuth => '管理鉴权';

  @override
  String get settingsReuseApiKey => '复用 API_KEY';

  @override
  String get settingsAdminKeyMasked => '管理 Key';

  @override
  String get settingsProxyKey => '代理 Key';

  @override
  String get settingsRuntimeErr => '运行时代理异常';

  @override
  String get settingsEditParams => '编辑参数';

  @override
  String get settingsResetEnv => '恢复环境变量';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsThemeLight => '亮';

  @override
  String get settingsThemeDark => '暗';

  @override
  String get settingsSectionBackup => '备份与恢复';

  @override
  String get settingsExport => '导出配置（复制到剪贴板）';

  @override
  String get settingsImport => '导入配置（粘贴 JSON）';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsApp => '应用';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsBackend => '后端';

  @override
  String get settingsApi => '接口';

  @override
  String get settingsConnUpdated => '连接已更新';

  @override
  String get settingsParamsSaved => '参数已保存并生效';

  @override
  String get settingsResetTitle => '恢复环境变量配置';

  @override
  String get settingsResetMessage => '清除后台保存的运行时配置（代理列表与参数），恢复为部署时的环境变量。确定吗？';

  @override
  String get settingsResetConfirm => '恢复';

  @override
  String get settingsResetDone => '已恢复环境变量配置';

  @override
  String get settingsPinCleared => '已解除常驻钉住';

  @override
  String get settingsExportDone => '配置已复制到剪贴板（含明文密钥，切勿外传）';

  @override
  String settingsExportFailed(String err) {
    return '导出失败: $err';
  }

  @override
  String get settingsImportTitle => '导入配置';

  @override
  String get settingsImportMessage => '将覆盖当前代理列表与运行参数，导入内容可能包含明文密钥。确定继续吗？';

  @override
  String settingsImportFailed(String err) {
    return '导入失败: $err';
  }

  @override
  String get settingsImportDone => '导入成功';

  @override
  String get settingsBadJson => '备份必须是 JSON 对象';

  @override
  String get settingsEditConnTitle => '修改连接';

  @override
  String get settingsUrlKeyEmpty => '地址与密钥不能为空';

  @override
  String get settingsImportDesc =>
      '粘贴备份 JSON（含 version / proxies / settings 字段）';

  @override
  String get settingsImportPlaceholder => 'version: 1, proxies: [...]';

  @override
  String get settingsImportPasteFirst => '请先粘贴备份 JSON';

  @override
  String get settingsEditParamsTitle => '编辑运行参数';

  @override
  String get settingsPinTtl => 'Pin 有效期（秒, ≥60）';

  @override
  String get settingsStateTtl => '状态 TTL（秒, ≥60）';

  @override
  String get settingsDepletedProbe => '耗尽重探测间隔（秒, ≥60）';

  @override
  String get settingsDownProbe => '故障重探测间隔（秒, ≥30）';

  @override
  String get settingsProbeTimeout => '探测超时（毫秒, ≥500）';

  @override
  String get settingsChatTimeout => '转发超时（毫秒, ≥1000）';

  @override
  String get settingsMaxAttempts => '最大尝试次数（1-6）';

  @override
  String get settingsInput => '请输入';

  @override
  String get settingsPinModeClient => 'client — 按网关 Key 钉住';

  @override
  String get settingsPinModeHeader => 'header — 按 X-Sticky-Id 钉住';

  @override
  String get settingsPinModeOff => 'off — 关闭钉住';

  @override
  String get settingsProbeSmart => 'smart — 智能懒探测';

  @override
  String get settingsProbeScan => 'scan — 周期扫描';

  @override
  String get settingsErrPinTtl => 'pinTtl 必须 ≥ 60';

  @override
  String get settingsErrStateTtl => 'stateTtl 必须 ≥ 60';

  @override
  String get settingsErrDepletedProbe => 'depletedProbe 必须 ≥ 60';

  @override
  String get settingsErrDownProbe => 'downProbe 必须 ≥ 30';

  @override
  String get settingsErrProbeTimeout => 'probeTimeout 必须 ≥ 500';

  @override
  String get settingsErrChatTimeout => 'chatTimeout 必须 ≥ 1000';

  @override
  String get settingsErrMaxAttempts => 'maxAttempts 必须在 1-6';

  @override
  String get analyticsSpendByProxy => '消费（按代理）';

  @override
  String get analyticsUsage => '额度用量';

  @override
  String get analyticsTrend => '请求趋势';

  @override
  String get analyticsModels => '模型可用性';

  @override
  String get analyticsNoSpend => '暂无消费数据';

  @override
  String get analyticsNoProxies => '暂无代理';

  @override
  String get analyticsCollecting => '收集数据中，稍后可见';

  @override
  String get analyticsNoModels => '无模型数据（可点刷新重试）';

  @override
  String get analyticsSpend24h => '滚动 24h 消费';

  @override
  String get analyticsSpendWeek => '本周消费';

  @override
  String get analyticsSpendMonth => '本月消费';

  @override
  String get analyticsWindow24h => '24h';

  @override
  String get analyticsWindowWeek => '周';

  @override
  String get analyticsWindowMonth => '月';

  @override
  String get analyticsSuccess => '成功';

  @override
  String get analyticsFail => '失败';

  @override
  String analyticsAvgLatency(int ms) {
    return '平均延迟 $ms ms';
  }

  @override
  String get analyticsModelOk => 'ok';

  @override
  String get analyticsModelDepleted => '耗尽';

  @override
  String get analyticsModelDown => '故障';

  @override
  String get err401 => '密钥无效或已过期（401）';

  @override
  String errConnFailed(String err) {
    return '连接失败: $err';
  }

  @override
  String get fieldProxy => '代理';

  @override
  String get fieldStatus => '状态';

  @override
  String get fieldStatusCode => '状态码';

  @override
  String get fieldAttempts => '尝试次数';

  @override
  String get fieldLatency => '耗时';

  @override
  String get fieldModel => '模型';

  @override
  String get fieldResult => '结果';

  @override
  String get fieldTime => '时间';

  @override
  String get fieldType => '类型';

  @override
  String get fieldChange => '变化';

  @override
  String get fieldErrorCode => '错误码';

  @override
  String get fieldError => '错误';

  @override
  String get fieldAction => '操作';

  @override
  String get fieldRouteTo => '路由到';

  @override
  String get fieldEnabled => '已开启';

  @override
  String get fieldDisabled => '已关闭';

  @override
  String get fieldKey => 'key';

  @override
  String get fieldMaintenance => '维护';

  @override
  String fieldProxiesCount(String n) {
    return '代理 $n 个';
  }

  @override
  String fieldParamsCount(String n) {
    return '参数 $n';
  }

  @override
  String smokeAttempts(String n) {
    return '尝试 $n 次';
  }

  @override
  String get commonRefresh => '刷新';
}
