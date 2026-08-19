# FreeBuff 网关管理 (gateway_admin)

[freebuff-proxy-gateway](https://github.com/fskanokano/freebuff-proxy-gateway) 的原生管理后台应用。
**Android + Windows 一套 Flutter 代码**，产物由 GitHub Actions 构建（目前仅 Android）。

## 功能

| 模块 | 说明 | 对应接口 |
|---|---|---|
| 连接 | 网关地址 + ADMIN_KEY（或 API_KEY），Bearer 鉴权，密钥加密存储 | `GET /admin/api/overview` |
| 仪表盘 | 统计卡（总数/正常/耗尽/故障/请求）、最近路由、代理健康，5s 轮询 + 失败退避 | `GET /admin/api/overview` `GET /admin/api/pin` |
| 分析 | 消费柱状图（24h/周/月）、额度用量、请求趋势（客户端环形缓冲）、模型可用性矩阵 | `GET /admin/api/overview` `GET /admin/api/models` |
| 代理 | 状态卡片（用量/配额/退避时间）、维护开关、立即探测、增删改 | `POST /admin/api/probe` `POST /admin/api/maintenance` `POST /admin/api/config` |
| 日志 | 路由记录 + 系统事件，chips 筛选，可清空 | `GET /admin/api/overview` `POST /admin/api/logs/clear` |
| 测试 | smoke 全链路测试：模型下拉 + 提示词 + 结果展示 | `POST /admin/api/smoke` `GET /admin/api/models` |
| 设置 | 修改连接、运行参数编辑/恢复环境变量、配置备份/恢复、常驻 pin 解除、主题、版本、登出 | `GET/POST /admin/api/config` `POST /admin/api/config/reset` `POST /admin/api/pin` |

## 开发

```bash
flutter pub get
flutter analyze
flutter test
```

本地开发闭环：写代码 → `flutter analyze` + `flutter test` 验证 → push → Actions 出 APK。

## 构建产物（GitHub Actions）

`.github/workflows/build-android.yml`：

- **workflow_dispatch** 手动触发 → 出 3 个 ABI 的 release APK（armeabi-v7a / arm64-v8a / x86_64），见 Actions 页 Artifacts
- **push tag `v*`** → 自动发布到 GitHub Release
- `main` push 自动跑 analyze + test（不构建）

下载后在「连接」页填入网关地址与管理密钥即可使用。

## 技术要点

- 依赖精简：`http` + `shared_preferences` + `flutter_secure_storage` + `fl_chart`，无状态管理框架（`ChangeNotifier` 够用）
- 密钥仅存本机安全存储（Android Keystore / iOS Keychain / Windows DPAPI），旧版明文一次性迁移后即清除；设置页脱敏显示、点按临时显隐
- 手机端底部导航 / 宽屏（≥840px，桌面）自动切 NavigationRail
- 轮询 5s + 失败指数退避（上限 60s）+ 前后台自动暂停/恢复
- 维护开关、探测、增删改均乐观操作 + 失败 SnackBar 提示

## 隐私说明

管理员密钥与代理密钥仅在本机加密存储，绝不上传；网关侧鉴权 `Authorization: Bearer <ADMIN_KEY|API_KEY>`。
「导出配置」会把明文代理密钥复制到剪贴板，请勿外传、用完即清。
