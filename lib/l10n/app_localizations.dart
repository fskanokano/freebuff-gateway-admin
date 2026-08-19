import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get commonImport;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonUnconfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get commonUnconfigured;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get commonNone;

  /// No description provided for @statusOk.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get statusOk;

  /// No description provided for @statusDepleted.
  ///
  /// In zh, this message translates to:
  /// **'额度耗尽'**
  String get statusDepleted;

  /// No description provided for @statusDown.
  ///
  /// In zh, this message translates to:
  /// **'故障'**
  String get statusDown;

  /// No description provided for @statusBadConfig.
  ///
  /// In zh, this message translates to:
  /// **'配置错误'**
  String get statusBadConfig;

  /// No description provided for @statusMaint.
  ///
  /// In zh, this message translates to:
  /// **'维护中'**
  String get statusMaint;

  /// No description provided for @relJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get relJustNow;

  /// No description provided for @relSecondsAgo.
  ///
  /// In zh, this message translates to:
  /// **'秒前'**
  String get relSecondsAgo;

  /// No description provided for @relMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'分钟前'**
  String get relMinutesAgo;

  /// No description provided for @relHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'小时前'**
  String get relHoursAgo;

  /// No description provided for @unitWan.
  ///
  /// In zh, this message translates to:
  /// **'万'**
  String get unitWan;

  /// No description provided for @unitYi.
  ///
  /// In zh, this message translates to:
  /// **'亿'**
  String get unitYi;

  /// No description provided for @unitK.
  ///
  /// In zh, this message translates to:
  /// **'K'**
  String get unitK;

  /// No description provided for @unitM.
  ///
  /// In zh, this message translates to:
  /// **'M'**
  String get unitM;

  /// No description provided for @unitB.
  ///
  /// In zh, this message translates to:
  /// **'B'**
  String get unitB;

  /// No description provided for @connectTitle.
  ///
  /// In zh, this message translates to:
  /// **'FreeBuff 网关管理'**
  String get connectTitle;

  /// No description provided for @connectSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'连接你的 freebuff-proxy-gateway 实例'**
  String get connectSubtitle;

  /// No description provided for @connectUrlPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'https://gateway.example.workers.dev'**
  String get connectUrlPlaceholder;

  /// No description provided for @connectKeyPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'ADMIN_KEY 或 API_KEY'**
  String get connectKeyPlaceholder;

  /// No description provided for @connectKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'密钥仅保存在本机，用于请求 /admin/api/* 接口'**
  String get connectKeyHint;

  /// No description provided for @connectButton.
  ///
  /// In zh, this message translates to:
  /// **'连接并验证'**
  String get connectButton;

  /// No description provided for @connectErrUrlEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请输入网关地址'**
  String get connectErrUrlEmpty;

  /// No description provided for @connectErrUrlScheme.
  ///
  /// In zh, this message translates to:
  /// **'需以 http:// 或 https:// 开头'**
  String get connectErrUrlScheme;

  /// No description provided for @connectErrKeyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请输入密钥'**
  String get connectErrKeyEmpty;

  /// No description provided for @tabDashboard.
  ///
  /// In zh, this message translates to:
  /// **'仪表盘'**
  String get tabDashboard;

  /// No description provided for @tabAnalytics.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get tabAnalytics;

  /// No description provided for @tabProxies.
  ///
  /// In zh, this message translates to:
  /// **'代理'**
  String get tabProxies;

  /// No description provided for @tabLogs.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get tabLogs;

  /// No description provided for @tabSmoke.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get tabSmoke;

  /// No description provided for @tabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// No description provided for @overviewProxyStatus.
  ///
  /// In zh, this message translates to:
  /// **'代理状态'**
  String get overviewProxyStatus;

  /// No description provided for @overviewRecentRoutes.
  ///
  /// In zh, this message translates to:
  /// **'最近路由'**
  String get overviewRecentRoutes;

  /// No description provided for @overviewProxyHealth.
  ///
  /// In zh, this message translates to:
  /// **'代理健康'**
  String get overviewProxyHealth;

  /// No description provided for @overviewWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待数据…'**
  String get overviewWaiting;

  /// No description provided for @overviewConnFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get overviewConnFailed;

  /// No description provided for @overviewUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新于 {time} · 每 5s 轮询'**
  String overviewUpdatedAt(String time);

  /// No description provided for @overviewTotalProxies.
  ///
  /// In zh, this message translates to:
  /// **'代理总数'**
  String get overviewTotalProxies;

  /// No description provided for @overviewOk.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get overviewOk;

  /// No description provided for @overviewDepleted.
  ///
  /// In zh, this message translates to:
  /// **'额度耗尽'**
  String get overviewDepleted;

  /// No description provided for @overviewDown.
  ///
  /// In zh, this message translates to:
  /// **'故障'**
  String get overviewDown;

  /// No description provided for @overviewReqOk.
  ///
  /// In zh, this message translates to:
  /// **'成功请求'**
  String get overviewReqOk;

  /// No description provided for @overviewReqFail.
  ///
  /// In zh, this message translates to:
  /// **'失败请求'**
  String get overviewReqFail;

  /// No description provided for @overviewSubConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已配置'**
  String get overviewSubConfigured;

  /// No description provided for @overviewSubAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get overviewSubAvailable;

  /// No description provided for @overviewSubWaitReset.
  ///
  /// In zh, this message translates to:
  /// **'等待重置'**
  String get overviewSubWaitReset;

  /// No description provided for @overviewSubInclBadCfg.
  ///
  /// In zh, this message translates to:
  /// **'含配置错误'**
  String get overviewSubInclBadCfg;

  /// No description provided for @overviewSubCumulative.
  ///
  /// In zh, this message translates to:
  /// **'累计'**
  String get overviewSubCumulative;

  /// No description provided for @overviewNoRoutes.
  ///
  /// In zh, this message translates to:
  /// **'暂无路由记录 — 发一条聊天请求后这里会显示路由事实。'**
  String get overviewNoRoutes;

  /// No description provided for @overviewNoProxies.
  ///
  /// In zh, this message translates to:
  /// **'暂无代理'**
  String get overviewNoProxies;

  /// No description provided for @proxiesPinned.
  ///
  /// In zh, this message translates to:
  /// **'当前常驻代理：{name}'**
  String proxiesPinned(String name);

  /// No description provided for @proxiesUnpin.
  ///
  /// In zh, this message translates to:
  /// **'解除'**
  String get proxiesUnpin;

  /// No description provided for @proxiesProbe.
  ///
  /// In zh, this message translates to:
  /// **'探测'**
  String get proxiesProbe;

  /// No description provided for @proxiesEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get proxiesEdit;

  /// No description provided for @proxiesMaintenance.
  ///
  /// In zh, this message translates to:
  /// **'维护模式'**
  String get proxiesMaintenance;

  /// No description provided for @proxiesMaintHint.
  ///
  /// In zh, this message translates to:
  /// **'维护中，路由会排除该代理'**
  String get proxiesMaintHint;

  /// No description provided for @proxiesUsage.
  ///
  /// In zh, this message translates to:
  /// **'用量'**
  String get proxiesUsage;

  /// No description provided for @proxiesReason.
  ///
  /// In zh, this message translates to:
  /// **'原因'**
  String get proxiesReason;

  /// No description provided for @proxiesDetail.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get proxiesDetail;

  /// No description provided for @proxiesCooldown.
  ///
  /// In zh, this message translates to:
  /// **'冷却至'**
  String get proxiesCooldown;

  /// No description provided for @proxiesResetAt.
  ///
  /// In zh, this message translates to:
  /// **'重置于'**
  String get proxiesResetAt;

  /// No description provided for @proxiesNextProbe.
  ///
  /// In zh, this message translates to:
  /// **'下次探测'**
  String get proxiesNextProbe;

  /// No description provided for @proxiesLastOk.
  ///
  /// In zh, this message translates to:
  /// **'上次成功'**
  String get proxiesLastOk;

  /// No description provided for @proxiesLastFail.
  ///
  /// In zh, this message translates to:
  /// **'上次失败'**
  String get proxiesLastFail;

  /// No description provided for @proxiesRisk.
  ///
  /// In zh, this message translates to:
  /// **'风险 {risk}'**
  String proxiesRisk(String risk);

  /// No description provided for @proxiesSpend24h.
  ///
  /// In zh, this message translates to:
  /// **'24h {v}'**
  String proxiesSpend24h(String v);

  /// No description provided for @proxiesSpendWeek.
  ///
  /// In zh, this message translates to:
  /// **'周 {v}'**
  String proxiesSpendWeek(String v);

  /// No description provided for @proxiesSpendMonth.
  ///
  /// In zh, this message translates to:
  /// **'月 {v}'**
  String proxiesSpendMonth(String v);

  /// No description provided for @proxiesAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加代理'**
  String get proxiesAdd;

  /// No description provided for @proxiesEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑代理 {name}'**
  String proxiesEditTitle(String name);

  /// No description provided for @proxiesNamePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'名称（可选，自动规范化）'**
  String get proxiesNamePlaceholder;

  /// No description provided for @proxiesUrlPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'代理地址（http(s)://…）'**
  String get proxiesUrlPlaceholder;

  /// No description provided for @proxiesKeyPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'代理 API Key'**
  String get proxiesKeyPlaceholder;

  /// No description provided for @proxiesKeyPlaceholderKeep.
  ///
  /// In zh, this message translates to:
  /// **'代理 API Key（留空保持原值）'**
  String get proxiesKeyPlaceholderKeep;

  /// No description provided for @proxiesRemarkPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选，如：主线路）'**
  String get proxiesRemarkPlaceholder;

  /// No description provided for @proxiesErrUrlScheme.
  ///
  /// In zh, this message translates to:
  /// **'地址需以 http(s):// 开头'**
  String get proxiesErrUrlScheme;

  /// No description provided for @proxiesErrName.
  ///
  /// In zh, this message translates to:
  /// **'名称仅允许小写字母/数字/连字符'**
  String get proxiesErrName;

  /// No description provided for @proxiesErrKeyRequired.
  ///
  /// In zh, this message translates to:
  /// **'新增代理必须填写 Key'**
  String get proxiesErrKeyRequired;

  /// No description provided for @proxiesOpFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败: {err}'**
  String proxiesOpFailed(String err);

  /// No description provided for @proxiesProbeDone.
  ///
  /// In zh, this message translates to:
  /// **'探测完成'**
  String get proxiesProbeDone;

  /// No description provided for @proxiesAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加代理'**
  String get proxiesAdded;

  /// No description provided for @proxiesSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存修改'**
  String get proxiesSaved;

  /// No description provided for @proxiesDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {name}'**
  String proxiesDeleted(String name);

  /// No description provided for @proxiesNeedOne.
  ///
  /// In zh, this message translates to:
  /// **'至少需要保留一个代理'**
  String get proxiesNeedOne;

  /// No description provided for @proxiesDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除代理'**
  String get proxiesDeleteTitle;

  /// No description provided for @proxiesDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定删除代理 \"{name}\" 吗？\n\n删除的是后台运行时配置中的代理列表；若代理来自环境变量，恢复默认会重新出现。'**
  String proxiesDeleteMessage(String name);

  /// No description provided for @proxiesEgressTitle.
  ///
  /// In zh, this message translates to:
  /// **'出口 IP 探测'**
  String get proxiesEgressTitle;

  /// No description provided for @proxiesEgressSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每个代理的公网出口 IP 与地理位置'**
  String get proxiesEgressSubtitle;

  /// No description provided for @proxiesEgressFailed.
  ///
  /// In zh, this message translates to:
  /// **'出口 IP 探测失败: {err}'**
  String proxiesEgressFailed(String err);

  /// No description provided for @logsClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get logsClear;

  /// No description provided for @logsSearchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'搜索代理名 / 模型 / 类型 / 内容…'**
  String get logsSearchPlaceholder;

  /// No description provided for @logsAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get logsAll;

  /// No description provided for @logsRoutes.
  ///
  /// In zh, this message translates to:
  /// **'路由记录'**
  String get logsRoutes;

  /// No description provided for @logsEvents.
  ///
  /// In zh, this message translates to:
  /// **'系统事件'**
  String get logsEvents;

  /// No description provided for @logsSuccess.
  ///
  /// In zh, this message translates to:
  /// **'✓ 成功'**
  String get logsSuccess;

  /// No description provided for @logsFail.
  ///
  /// In zh, this message translates to:
  /// **'✗ 失败'**
  String get logsFail;

  /// No description provided for @logsAllEvents.
  ///
  /// In zh, this message translates to:
  /// **'全部事件'**
  String get logsAllEvents;

  /// No description provided for @logsAllTime.
  ///
  /// In zh, this message translates to:
  /// **'全部时间'**
  String get logsAllTime;

  /// No description provided for @logsLast5m.
  ///
  /// In zh, this message translates to:
  /// **'近 5 分钟'**
  String get logsLast5m;

  /// No description provided for @logsLast30m.
  ///
  /// In zh, this message translates to:
  /// **'近 30 分钟'**
  String get logsLast30m;

  /// No description provided for @logsLast1h.
  ///
  /// In zh, this message translates to:
  /// **'近 1 小时'**
  String get logsLast1h;

  /// No description provided for @logsCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条'**
  String logsCount(int count);

  /// No description provided for @logsRouteCount.
  ///
  /// In zh, this message translates to:
  /// **'路由 {ok}✓/{fail}✗'**
  String logsRouteCount(int ok, int fail);

  /// No description provided for @logsAvgMs.
  ///
  /// In zh, this message translates to:
  /// **'平均 {ms}ms'**
  String logsAvgMs(int ms);

  /// No description provided for @logsUpdated.
  ///
  /// In zh, this message translates to:
  /// **'更新 {time}'**
  String logsUpdated(String time);

  /// No description provided for @logsInsightStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态码'**
  String get logsInsightStatus;

  /// No description provided for @logsInsightFailReason.
  ///
  /// In zh, this message translates to:
  /// **'失败原因'**
  String get logsInsightFailReason;

  /// No description provided for @logsInsightEventType.
  ///
  /// In zh, this message translates to:
  /// **'事件类型'**
  String get logsInsightEventType;

  /// No description provided for @logsEventStatusChange.
  ///
  /// In zh, this message translates to:
  /// **'状态变化'**
  String get logsEventStatusChange;

  /// No description provided for @logsEventFailover.
  ///
  /// In zh, this message translates to:
  /// **'故障转移'**
  String get logsEventFailover;

  /// No description provided for @logsEventProbeFailed.
  ///
  /// In zh, this message translates to:
  /// **'探测失败'**
  String get logsEventProbeFailed;

  /// No description provided for @logsEventAdminAction.
  ///
  /// In zh, this message translates to:
  /// **'后台操作'**
  String get logsEventAdminAction;

  /// No description provided for @logsEventMaintenance.
  ///
  /// In zh, this message translates to:
  /// **'维护模式'**
  String get logsEventMaintenance;

  /// No description provided for @logsEventSmoke.
  ///
  /// In zh, this message translates to:
  /// **'测试请求'**
  String get logsEventSmoke;

  /// No description provided for @logsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无匹配的日志'**
  String get logsEmpty;

  /// No description provided for @logsClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get logsClearTitle;

  /// No description provided for @logsClearMessage.
  ///
  /// In zh, this message translates to:
  /// **'将清空路由记录与系统事件（环形缓冲），确定吗？'**
  String get logsClearMessage;

  /// No description provided for @logsClearFailed.
  ///
  /// In zh, this message translates to:
  /// **'清空失败: {err}'**
  String logsClearFailed(String err);

  /// No description provided for @logsRouteTitle.
  ///
  /// In zh, this message translates to:
  /// **'路由 → {name} {result}'**
  String logsRouteTitle(String name, String result);

  /// No description provided for @logsRouteOk.
  ///
  /// In zh, this message translates to:
  /// **'(成功)'**
  String get logsRouteOk;

  /// No description provided for @logsRouteFail.
  ///
  /// In zh, this message translates to:
  /// **'(失败)'**
  String get logsRouteFail;

  /// No description provided for @logsHttpAttempts.
  ///
  /// In zh, this message translates to:
  /// **'HTTP {status} · 尝试 {attempts} 次 · {ms}ms'**
  String logsHttpAttempts(int status, int attempts, int ms);

  /// No description provided for @codeRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'限流'**
  String get codeRateLimited;

  /// No description provided for @codeBanned.
  ///
  /// In zh, this message translates to:
  /// **'账号封禁'**
  String get codeBanned;

  /// No description provided for @codeCountryBlocked.
  ///
  /// In zh, this message translates to:
  /// **'区域限制'**
  String get codeCountryBlocked;

  /// No description provided for @codeOutOfCredits.
  ///
  /// In zh, this message translates to:
  /// **'余额不足'**
  String get codeOutOfCredits;

  /// No description provided for @codeWaitingRoom.
  ///
  /// In zh, this message translates to:
  /// **'排队中'**
  String get codeWaitingRoom;

  /// No description provided for @codeAuthRejected.
  ///
  /// In zh, this message translates to:
  /// **'上游鉴权拒绝'**
  String get codeAuthRejected;

  /// No description provided for @codeInvalidApiKey.
  ///
  /// In zh, this message translates to:
  /// **'密钥无效'**
  String get codeInvalidApiKey;

  /// No description provided for @codeTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get codeTimeout;

  /// No description provided for @codeConnectionError.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get codeConnectionError;

  /// No description provided for @codeDnsError.
  ///
  /// In zh, this message translates to:
  /// **'DNS 解析失败'**
  String get codeDnsError;

  /// No description provided for @codeProbeFailed.
  ///
  /// In zh, this message translates to:
  /// **'探测失败'**
  String get codeProbeFailed;

  /// No description provided for @codeQuotaExhausted.
  ///
  /// In zh, this message translates to:
  /// **'额度耗尽'**
  String get codeQuotaExhausted;

  /// No description provided for @codeLocked.
  ///
  /// In zh, this message translates to:
  /// **'锁定'**
  String get codeLocked;

  /// No description provided for @codeUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get codeUnknown;

  /// No description provided for @actionSaveConfig.
  ///
  /// In zh, this message translates to:
  /// **'保存配置'**
  String get actionSaveConfig;

  /// No description provided for @actionProbe.
  ///
  /// In zh, this message translates to:
  /// **'立即探测'**
  String get actionProbe;

  /// No description provided for @actionClearPin.
  ///
  /// In zh, this message translates to:
  /// **'解除常驻'**
  String get actionClearPin;

  /// No description provided for @actionResetConfig.
  ///
  /// In zh, this message translates to:
  /// **'恢复环境变量'**
  String get actionResetConfig;

  /// No description provided for @actionClearLogs.
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get actionClearLogs;

  /// No description provided for @smokeModelLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'模型列表拉取失败（可手动输入模型名）: {err}'**
  String smokeModelLoadFailed(String err);

  /// No description provided for @smokeCustomModel.
  ///
  /// In zh, this message translates to:
  /// **'或手动输入模型名（如 freebuff-1）'**
  String get smokeCustomModel;

  /// No description provided for @smokePrompt.
  ///
  /// In zh, this message translates to:
  /// **'测试提示词'**
  String get smokePrompt;

  /// No description provided for @smokeRun.
  ///
  /// In zh, this message translates to:
  /// **'发送测试请求'**
  String get smokeRun;

  /// No description provided for @smokeResult.
  ///
  /// In zh, this message translates to:
  /// **'本次结果'**
  String get smokeResult;

  /// No description provided for @smokeHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get smokeHistory;

  /// No description provided for @smokeSelectModel.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get smokeSelectModel;

  /// No description provided for @smokeLoadingModels.
  ///
  /// In zh, this message translates to:
  /// **'加载模型…'**
  String get smokeLoadingModels;

  /// No description provided for @smokeNoModels.
  ///
  /// In zh, this message translates to:
  /// **'无可用模型（可手动输入）'**
  String get smokeNoModels;

  /// No description provided for @smokeOk.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get smokeOk;

  /// No description provided for @smokeFail.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get smokeFail;

  /// No description provided for @smokeHttpResult.
  ///
  /// In zh, this message translates to:
  /// **'HTTP {status} {result} · 路由到 {proxy} · 尝试 {attempts} 次 · {ms}ms'**
  String smokeHttpResult(
    int status,
    String result,
    String proxy,
    int attempts,
    int ms,
  );

  /// No description provided for @settingsSectionConn.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get settingsSectionConn;

  /// No description provided for @settingsGatewayUrl.
  ///
  /// In zh, this message translates to:
  /// **'网关地址'**
  String get settingsGatewayUrl;

  /// No description provided for @settingsAdminKey.
  ///
  /// In zh, this message translates to:
  /// **'管理员密钥'**
  String get settingsAdminKey;

  /// No description provided for @settingsPolling.
  ///
  /// In zh, this message translates to:
  /// **'轮询状态'**
  String get settingsPolling;

  /// No description provided for @settingsPollingRunning.
  ///
  /// In zh, this message translates to:
  /// **'每 5s 刷新'**
  String get settingsPollingRunning;

  /// No description provided for @settingsPollingStopped.
  ///
  /// In zh, this message translates to:
  /// **'未运行'**
  String get settingsPollingStopped;

  /// No description provided for @settingsEditConn.
  ///
  /// In zh, this message translates to:
  /// **'修改连接'**
  String get settingsEditConn;

  /// No description provided for @settingsLogout.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get settingsLogout;

  /// No description provided for @settingsSectionPin.
  ///
  /// In zh, this message translates to:
  /// **'常驻代理'**
  String get settingsSectionPin;

  /// No description provided for @settingsCurrentPin.
  ///
  /// In zh, this message translates to:
  /// **'当前常驻'**
  String get settingsCurrentPin;

  /// No description provided for @settingsStickyKey.
  ///
  /// In zh, this message translates to:
  /// **'Sticky Key'**
  String get settingsStickyKey;

  /// No description provided for @settingsPinMode.
  ///
  /// In zh, this message translates to:
  /// **'Pin 模式'**
  String get settingsPinMode;

  /// No description provided for @settingsClearPin.
  ///
  /// In zh, this message translates to:
  /// **'解除当前会话常驻'**
  String get settingsClearPin;

  /// No description provided for @settingsSectionRuntime.
  ///
  /// In zh, this message translates to:
  /// **'运行时配置'**
  String get settingsSectionRuntime;

  /// No description provided for @settingsCfgUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'无法读取配置（检查连接或密钥）'**
  String get settingsCfgUnreadable;

  /// No description provided for @settingsProxyCount.
  ///
  /// In zh, this message translates to:
  /// **'代理数量'**
  String get settingsProxyCount;

  /// No description provided for @settingsProbeMode.
  ///
  /// In zh, this message translates to:
  /// **'探测模式'**
  String get settingsProbeMode;

  /// No description provided for @settingsSource.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get settingsSource;

  /// No description provided for @settingsSourceRuntime.
  ///
  /// In zh, this message translates to:
  /// **'后台运行时配置'**
  String get settingsSourceRuntime;

  /// No description provided for @settingsSourceMixed.
  ///
  /// In zh, this message translates to:
  /// **'环境变量 + 运行时参数'**
  String get settingsSourceMixed;

  /// No description provided for @settingsSourceEnv.
  ///
  /// In zh, this message translates to:
  /// **'环境变量'**
  String get settingsSourceEnv;

  /// No description provided for @settingsClientKey.
  ///
  /// In zh, this message translates to:
  /// **'客户端 Key'**
  String get settingsClientKey;

  /// No description provided for @settingsAdminAuth.
  ///
  /// In zh, this message translates to:
  /// **'管理鉴权'**
  String get settingsAdminAuth;

  /// No description provided for @settingsReuseApiKey.
  ///
  /// In zh, this message translates to:
  /// **'复用 API_KEY'**
  String get settingsReuseApiKey;

  /// No description provided for @settingsAdminKeyMasked.
  ///
  /// In zh, this message translates to:
  /// **'管理 Key'**
  String get settingsAdminKeyMasked;

  /// No description provided for @settingsProxyKey.
  ///
  /// In zh, this message translates to:
  /// **'代理 Key'**
  String get settingsProxyKey;

  /// No description provided for @settingsRuntimeErr.
  ///
  /// In zh, this message translates to:
  /// **'运行时代理异常'**
  String get settingsRuntimeErr;

  /// No description provided for @settingsEditParams.
  ///
  /// In zh, this message translates to:
  /// **'编辑参数'**
  String get settingsEditParams;

  /// No description provided for @settingsResetEnv.
  ///
  /// In zh, this message translates to:
  /// **'恢复环境变量'**
  String get settingsResetEnv;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'亮'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'暗'**
  String get settingsThemeDark;

  /// No description provided for @settingsSectionBackup.
  ///
  /// In zh, this message translates to:
  /// **'备份与恢复'**
  String get settingsSectionBackup;

  /// No description provided for @settingsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出配置（复制到剪贴板）'**
  String get settingsExport;

  /// No description provided for @settingsImport.
  ///
  /// In zh, this message translates to:
  /// **'导入配置（粘贴 JSON）'**
  String get settingsImport;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsSectionAbout;

  /// No description provided for @settingsApp.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get settingsApp;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settingsVersion;

  /// No description provided for @settingsBackend.
  ///
  /// In zh, this message translates to:
  /// **'后端'**
  String get settingsBackend;

  /// No description provided for @settingsApi.
  ///
  /// In zh, this message translates to:
  /// **'接口'**
  String get settingsApi;

  /// No description provided for @settingsConnUpdated.
  ///
  /// In zh, this message translates to:
  /// **'连接已更新'**
  String get settingsConnUpdated;

  /// No description provided for @settingsParamsSaved.
  ///
  /// In zh, this message translates to:
  /// **'参数已保存并生效'**
  String get settingsParamsSaved;

  /// No description provided for @settingsResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复环境变量配置'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetMessage.
  ///
  /// In zh, this message translates to:
  /// **'清除后台保存的运行时配置（代理列表与参数），恢复为部署时的环境变量。确定吗？'**
  String get settingsResetMessage;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetDone.
  ///
  /// In zh, this message translates to:
  /// **'已恢复环境变量配置'**
  String get settingsResetDone;

  /// No description provided for @settingsPinCleared.
  ///
  /// In zh, this message translates to:
  /// **'已解除常驻钉住'**
  String get settingsPinCleared;

  /// No description provided for @settingsExportDone.
  ///
  /// In zh, this message translates to:
  /// **'配置已复制到剪贴板（含明文密钥，切勿外传）'**
  String get settingsExportDone;

  /// No description provided for @settingsExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {err}'**
  String settingsExportFailed(String err);

  /// No description provided for @settingsImportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入配置'**
  String get settingsImportTitle;

  /// No description provided for @settingsImportMessage.
  ///
  /// In zh, this message translates to:
  /// **'将覆盖当前代理列表与运行参数，导入内容可能包含明文密钥。确定继续吗？'**
  String get settingsImportMessage;

  /// No description provided for @settingsImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {err}'**
  String settingsImportFailed(String err);

  /// No description provided for @settingsImportDone.
  ///
  /// In zh, this message translates to:
  /// **'导入成功'**
  String get settingsImportDone;

  /// No description provided for @settingsBadJson.
  ///
  /// In zh, this message translates to:
  /// **'备份必须是 JSON 对象'**
  String get settingsBadJson;

  /// No description provided for @settingsEditConnTitle.
  ///
  /// In zh, this message translates to:
  /// **'修改连接'**
  String get settingsEditConnTitle;

  /// No description provided for @settingsUrlKeyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'地址与密钥不能为空'**
  String get settingsUrlKeyEmpty;

  /// No description provided for @settingsImportDesc.
  ///
  /// In zh, this message translates to:
  /// **'粘贴备份 JSON（含 version / proxies / settings 字段）'**
  String get settingsImportDesc;

  /// No description provided for @settingsImportPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'version: 1, proxies: [...]'**
  String get settingsImportPlaceholder;

  /// No description provided for @settingsImportPasteFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先粘贴备份 JSON'**
  String get settingsImportPasteFirst;

  /// No description provided for @settingsEditParamsTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑运行参数'**
  String get settingsEditParamsTitle;

  /// No description provided for @settingsPinTtl.
  ///
  /// In zh, this message translates to:
  /// **'Pin 有效期（秒, ≥60）'**
  String get settingsPinTtl;

  /// No description provided for @settingsStateTtl.
  ///
  /// In zh, this message translates to:
  /// **'状态 TTL（秒, ≥60）'**
  String get settingsStateTtl;

  /// No description provided for @settingsDepletedProbe.
  ///
  /// In zh, this message translates to:
  /// **'耗尽重探测间隔（秒, ≥60）'**
  String get settingsDepletedProbe;

  /// No description provided for @settingsDownProbe.
  ///
  /// In zh, this message translates to:
  /// **'故障重探测间隔（秒, ≥30）'**
  String get settingsDownProbe;

  /// No description provided for @settingsProbeTimeout.
  ///
  /// In zh, this message translates to:
  /// **'探测超时（毫秒, ≥500）'**
  String get settingsProbeTimeout;

  /// No description provided for @settingsChatTimeout.
  ///
  /// In zh, this message translates to:
  /// **'转发超时（毫秒, ≥1000）'**
  String get settingsChatTimeout;

  /// No description provided for @settingsMaxAttempts.
  ///
  /// In zh, this message translates to:
  /// **'最大尝试次数（1-6）'**
  String get settingsMaxAttempts;

  /// No description provided for @settingsInput.
  ///
  /// In zh, this message translates to:
  /// **'请输入'**
  String get settingsInput;

  /// No description provided for @settingsPinModeClient.
  ///
  /// In zh, this message translates to:
  /// **'client — 按网关 Key 钉住'**
  String get settingsPinModeClient;

  /// No description provided for @settingsPinModeHeader.
  ///
  /// In zh, this message translates to:
  /// **'header — 按 X-Sticky-Id 钉住'**
  String get settingsPinModeHeader;

  /// No description provided for @settingsPinModeOff.
  ///
  /// In zh, this message translates to:
  /// **'off — 关闭钉住'**
  String get settingsPinModeOff;

  /// No description provided for @settingsProbeSmart.
  ///
  /// In zh, this message translates to:
  /// **'smart — 智能懒探测'**
  String get settingsProbeSmart;

  /// No description provided for @settingsProbeScan.
  ///
  /// In zh, this message translates to:
  /// **'scan — 周期扫描'**
  String get settingsProbeScan;

  /// No description provided for @settingsErrPinTtl.
  ///
  /// In zh, this message translates to:
  /// **'pinTtl 必须 ≥ 60'**
  String get settingsErrPinTtl;

  /// No description provided for @settingsErrStateTtl.
  ///
  /// In zh, this message translates to:
  /// **'stateTtl 必须 ≥ 60'**
  String get settingsErrStateTtl;

  /// No description provided for @settingsErrDepletedProbe.
  ///
  /// In zh, this message translates to:
  /// **'depletedProbe 必须 ≥ 60'**
  String get settingsErrDepletedProbe;

  /// No description provided for @settingsErrDownProbe.
  ///
  /// In zh, this message translates to:
  /// **'downProbe 必须 ≥ 30'**
  String get settingsErrDownProbe;

  /// No description provided for @settingsErrProbeTimeout.
  ///
  /// In zh, this message translates to:
  /// **'probeTimeout 必须 ≥ 500'**
  String get settingsErrProbeTimeout;

  /// No description provided for @settingsErrChatTimeout.
  ///
  /// In zh, this message translates to:
  /// **'chatTimeout 必须 ≥ 1000'**
  String get settingsErrChatTimeout;

  /// No description provided for @settingsErrMaxAttempts.
  ///
  /// In zh, this message translates to:
  /// **'maxAttempts 必须在 1-6'**
  String get settingsErrMaxAttempts;

  /// No description provided for @analyticsSpendByProxy.
  ///
  /// In zh, this message translates to:
  /// **'消费（按代理）'**
  String get analyticsSpendByProxy;

  /// No description provided for @analyticsUsage.
  ///
  /// In zh, this message translates to:
  /// **'额度用量'**
  String get analyticsUsage;

  /// No description provided for @analyticsTrend.
  ///
  /// In zh, this message translates to:
  /// **'请求趋势'**
  String get analyticsTrend;

  /// No description provided for @analyticsModels.
  ///
  /// In zh, this message translates to:
  /// **'模型可用性'**
  String get analyticsModels;

  /// No description provided for @analyticsNoSpend.
  ///
  /// In zh, this message translates to:
  /// **'暂无消费数据'**
  String get analyticsNoSpend;

  /// No description provided for @analyticsNoProxies.
  ///
  /// In zh, this message translates to:
  /// **'暂无代理'**
  String get analyticsNoProxies;

  /// No description provided for @analyticsCollecting.
  ///
  /// In zh, this message translates to:
  /// **'收集数据中，稍后可见'**
  String get analyticsCollecting;

  /// No description provided for @analyticsNoModels.
  ///
  /// In zh, this message translates to:
  /// **'无模型数据（可点刷新重试）'**
  String get analyticsNoModels;

  /// No description provided for @analyticsSpend24h.
  ///
  /// In zh, this message translates to:
  /// **'滚动 24h 消费'**
  String get analyticsSpend24h;

  /// No description provided for @analyticsSpendWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周消费'**
  String get analyticsSpendWeek;

  /// No description provided for @analyticsSpendMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月消费'**
  String get analyticsSpendMonth;

  /// No description provided for @analyticsWindow24h.
  ///
  /// In zh, this message translates to:
  /// **'24h'**
  String get analyticsWindow24h;

  /// No description provided for @analyticsWindowWeek.
  ///
  /// In zh, this message translates to:
  /// **'周'**
  String get analyticsWindowWeek;

  /// No description provided for @analyticsWindowMonth.
  ///
  /// In zh, this message translates to:
  /// **'月'**
  String get analyticsWindowMonth;

  /// No description provided for @analyticsSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get analyticsSuccess;

  /// No description provided for @analyticsFail.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get analyticsFail;

  /// No description provided for @analyticsAvgLatency.
  ///
  /// In zh, this message translates to:
  /// **'平均延迟 {ms} ms'**
  String analyticsAvgLatency(int ms);

  /// No description provided for @analyticsModelOk.
  ///
  /// In zh, this message translates to:
  /// **'ok'**
  String get analyticsModelOk;

  /// No description provided for @analyticsModelDepleted.
  ///
  /// In zh, this message translates to:
  /// **'耗尽'**
  String get analyticsModelDepleted;

  /// No description provided for @analyticsModelDown.
  ///
  /// In zh, this message translates to:
  /// **'故障'**
  String get analyticsModelDown;

  /// No description provided for @err401.
  ///
  /// In zh, this message translates to:
  /// **'密钥无效或已过期（401）'**
  String get err401;

  /// No description provided for @errConnFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败: {err}'**
  String errConnFailed(String err);

  /// No description provided for @fieldProxy.
  ///
  /// In zh, this message translates to:
  /// **'代理'**
  String get fieldProxy;

  /// No description provided for @fieldStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get fieldStatus;

  /// No description provided for @fieldStatusCode.
  ///
  /// In zh, this message translates to:
  /// **'状态码'**
  String get fieldStatusCode;

  /// No description provided for @fieldAttempts.
  ///
  /// In zh, this message translates to:
  /// **'尝试次数'**
  String get fieldAttempts;

  /// No description provided for @fieldLatency.
  ///
  /// In zh, this message translates to:
  /// **'耗时'**
  String get fieldLatency;

  /// No description provided for @fieldModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get fieldModel;

  /// No description provided for @fieldResult.
  ///
  /// In zh, this message translates to:
  /// **'结果'**
  String get fieldResult;

  /// No description provided for @fieldTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get fieldTime;

  /// No description provided for @fieldType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get fieldType;

  /// No description provided for @fieldChange.
  ///
  /// In zh, this message translates to:
  /// **'变化'**
  String get fieldChange;

  /// No description provided for @fieldErrorCode.
  ///
  /// In zh, this message translates to:
  /// **'错误码'**
  String get fieldErrorCode;

  /// No description provided for @fieldError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get fieldError;

  /// No description provided for @fieldAction.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get fieldAction;

  /// No description provided for @fieldRouteTo.
  ///
  /// In zh, this message translates to:
  /// **'路由到'**
  String get fieldRouteTo;

  /// No description provided for @fieldEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get fieldEnabled;

  /// No description provided for @fieldDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get fieldDisabled;

  /// No description provided for @fieldKey.
  ///
  /// In zh, this message translates to:
  /// **'key'**
  String get fieldKey;

  /// No description provided for @fieldMaintenance.
  ///
  /// In zh, this message translates to:
  /// **'维护'**
  String get fieldMaintenance;

  /// No description provided for @fieldProxiesCount.
  ///
  /// In zh, this message translates to:
  /// **'代理 {n} 个'**
  String fieldProxiesCount(String n);

  /// No description provided for @fieldParamsCount.
  ///
  /// In zh, this message translates to:
  /// **'参数 {n}'**
  String fieldParamsCount(String n);

  /// No description provided for @smokeAttempts.
  ///
  /// In zh, this message translates to:
  /// **'尝试 {n} 次'**
  String smokeAttempts(String n);

  /// No description provided for @commonRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get commonRefresh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
