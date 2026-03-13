# 变更记录

使用轻量日志记录已完成的实际变更。只记录已经落地到代码或文档的内容，不记录纯规划。

## 2026-03-13 - 修复 Publish Release 阶段缺少仓库上下文的问题

### 背景 / 目的

Release 工作流的 `publish` job 只下载构建产物，没有执行 `actions/checkout`。在这种情况下，`gh release view/create/upload` 会尝试从本地 `.git` 推断目标仓库，最终报出 `fatal: not a git repository`，导致发布阶段失败。

### 代码改动点

- 更新 `.github/workflows/release.yml`
  - 在 `publish` job 中显式注入 `GH_REPO=${{ github.repository }}`
  - 让 `gh` 命令直接使用 GitHub Actions 提供的仓库上下文，不再依赖本地 git 工作区

### 文档同步情况

- 本条 `docs/CHANGELOG.md` 记录本次 workflow 修复事实

### 验证情况

- 已完成工作流配置修正
- 需在 GitHub Actions 中重新触发 Release workflow 验证

## 2026-03-13 - Release 工作流改为仅构建 arm64，并修复异步测试时序问题

### 背景 / 目的

GitHub Actions 在 `x86_64` runner 上执行测试时，`TickerCoordinatorTests.startTriggersImmediateRefreshAndScheduler()` 对异步刷新完成时机的假设不稳定，导致 workflow 失败。当前需求也明确为仅构建 Apple Silicon 版本，因此将发布工作流收敛为只产出 `arm64`。

### 代码改动点

- 更新 `.github/workflows/release.yml`
  - 移除 `macos-15-intel` / `macos-x64` 构建矩阵
  - Release 工作流改为仅在 `macos-15` 构建 `macos-arm64`
- 更新 `Tests/CryptoTickerAppTests/TickerCoordinatorTests.swift`
  - 将启动即刷新测试从固定 `Task.yield()` 改为限时轮询等待
  - 降低不同 runner 调度时序差异带来的偶发失败

### 文档同步情况

- 已更新 `README.md`：同步 Release 当前仅发布 `arm64` 产物
- 已更新 `docs/PROJECT.md`：同步发布能力边界与协作约束
- 本条 `docs/CHANGELOG.md` 记录本次修正事实

### 验证情况

- 已执行 `swift test`

## 2026-03-13 - 新增开机自动启动菜单开关

### 背景 / 目的

状态栏工具目前只能手动启动。需要在菜单栏中直接提供“开机自动启动”开关，并使用 checkbox 明确展示当前状态，减少重复手动打开应用的成本。

### 代码改动点

- 新增 `LaunchAtLoginManaging` 协议和 `SMAppServiceLaunchAtLoginManager`
  - 基于 macOS `ServiceManagement.SMAppService.mainApp` 注册/取消注册系统登录项
  - 支持识别 `requiresApproval` 状态，并将其映射为界面可见的已开启态
- 更新 `AppState` / `TickerCoordinator`
  - 新增 `launchAtLoginEnabled` 状态
  - 增加开机自动启动开关处理、提示文案和配置落盘
- 更新 `StatusBarController`
  - 在菜单中新增“启动设置”分组
  - 使用 checkbox 菜单项控制“开机自动启动”
- 更新测试桩与测试
  - 新增 `StubLaunchAtLoginManager`
  - 增加开机自动启动成功、需审批、失败三类协调器测试

### 文档同步情况

- 已更新 `README.md`：补充菜单 checkbox 开机自动启动能力与使用限制
- 已更新 `docs/PROJECT.md`：补充系统登录项服务、当前能力边界和行为约束
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`

## 2026-03-13 - GitHub Actions Release runner 标签与 action 版本修正

### 背景 / 目的

首次执行 Release 工作流时，`macos-13` runner 在当前 GitHub Actions 环境中报出 `The configuration 'macos-13-us-default' is not supported`，同时 `actions/checkout@v4` 触发了 Node.js 20 弃用警告。需要调整到当前仍受支持的 runner 和官方 action 版本。

### 代码改动点

- 更新 `.github/workflows/release.yml`：
  - 将 `x64` 构建 runner 从 `macos-13` 调整为 `macos-15-intel`
  - 将 `arm64` 构建 runner 从 `macos-14` 调整为 `macos-15`
  - 将 `actions/checkout` 升级到 `v5`
  - 将 `actions/upload-artifact` / `actions/download-artifact` 升级到 `v6`

### 文档同步情况

- 已更新 `README.md`：同步当前 Release 使用的 runner 标签
- 本条 `docs/CHANGELOG.md` 记录本次修正事实

### 验证情况

- 已基于 GitHub 官方文档与 action release 说明完成配置修正
- 变更需在 GitHub Actions 上重新触发工作流验证

## 2026-03-13 - 新增 GitHub Release 打包与发布流程

### 背景 / 目的

项目当前只有本地 `swift run` / `swift test` 开发方式，缺少可复用的 release 打包流程，也无法在 GitHub 上按版本上传构建产物。需要补齐最小可用的发布链路，方便后续基于 tag 发版。

### 代码改动点

- 新增 `scripts/build_release_app.sh`：
  - 通过 `swift build -c release` 构建 release 可执行文件
  - 组装 macOS `.app` 目录结构
  - 生成 `Info.plist`
  - 执行 ad-hoc / 指定证书签名
  - 输出 zip 与 `sha256` 校验文件到 `dist/`
- 新增 `packaging/Info.plist.template`：
  - 统一维护 App Bundle 的基础元数据模板
- 新增 `.github/workflows/release.yml`：
  - 支持 tag 推送或手动触发发布
  - 在 `macos-13` / `macos-14` 分别构建 `x64` / `arm64` 产物
  - 自动创建或更新对应 GitHub Release 并上传产物
- 更新 `.gitignore`：
  - 忽略本地产生的 `dist/` 发布目录

### 文档同步情况

- 已更新 `README.md`：补充本地打包命令、GitHub Release 发布步骤和当前签名边界
- 已更新 `docs/PROJECT.md`：补充打包/发布目录结构、能力边界和协作约束
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`
- 已执行 `./scripts/build_release_app.sh macos-arm64`

## 2026-03-13 - 连续三次请求失败时显示状态栏错误图标

### 背景 / 目的

当前请求失败只会更新菜单详情文案，状态栏顶部没有明显提示。需要在连续三次请求失败后，给状态栏增加一个轻量错误提示，方便快速感知异常状态。

### 代码改动点

- 更新 `AppState`：
  - 新增连续失败计数与 `showsErrorIndicator` 状态
  - 连续三次价格请求失败后开启错误图标标记
  - 成功刷新价格或切换当前交易对后重置失败计数并清除错误标记
- 更新 `StatusBarController`：
  - 订阅错误图标状态
  - 在状态栏按钮标题左侧展示 `exclamationmark.circle.fill` SF Symbol
- 更新 `StubPriceProvider` 与测试：
  - 支持按顺序返回成功/失败结果，便于模拟连续请求失败
  - 新增应用状态与协调器测试，覆盖“三次失败触发图标”和“成功后清除图标”行为

### 文档同步情况

- 已更新 `README.md`：补充连续三次请求失败后的状态栏错误图标行为
- 已更新 `docs/PROJECT.md`：补充失败计数归属和图标显示/重置约束
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 移除菜单内全部交易对价格展示

### 背景 / 目的

菜单打开态下展示全部交易对价格带来了额外的刷新链路和布局复杂度，实际交互效果不稳定。当前决定移除这项能力，回到只在状态栏顶部展示已选交易对价格的实现。

### 代码改动点

- 更新 `StatusBarController`：
  - 移除菜单行右侧价格列
  - 移除菜单打开/关闭时的批量价格刷新联动
  - 恢复为只渲染交易对名称和自定义删除操作的菜单行
- 更新 `TickerCoordinator` / `AppContainer` / `AppDelegate`：
  - 删除菜单批量价格刷新调度器与相关生命周期逻辑
- 更新 `PriceProviding` / `BinanceFuturesPriceProvider` / `StubPriceProvider`：
  - 删除批量价格接口与对应实现
- 更新 `AppState`：
  - 删除菜单行价格缓存与相关状态更新方法
- 更新测试：
  - 删除菜单批量价格相关测试与测试桩适配代码

### 文档同步情况

- 已更新 `README.md`：移除菜单内整表行情预览描述
- 已更新 `docs/PROJECT.md`：移除菜单批量价格能力、状态职责和行为约束说明
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 菜单打开态价格不显示问题修复（debug）

### 背景 / 目的

实际使用中发现“打开菜单后没有展示所有交易对价格”。需要排查菜单打开态的渲染与刷新链路，修复行内价格不稳定/不显示的问题。

### 代码改动点

- 更新 `StatusBarController`：
  - 将状态栏标题更新与菜单重建解耦，仅在 `statusTitle` 变化时更新状态栏按钮标题
  - 菜单重建仅监听交易对/刷新间隔/菜单价格相关状态，避免无关状态导致打开态菜单频繁重建
  - `menuDidClose` 增加高亮态保护，避免菜单仍处于打开交互阶段时误触发关闭链路
- 更新 `SymbolRowView`：
  - 重构交易对行右侧价格与删除操作区域约束，消除默认行（不可删）与自定义行（可删）的布局歧义
  - 强化价格标签宽度与压缩优先级，确保右侧价格文本可见

### 文档同步情况

- 本条 `docs/CHANGELOG.md` 记录本次 debug 修复事实

### 验证情况

- 已执行 `swift test`，通过

## 2026-03-13 - 菜单打开态价格不实时刷新的问题修复（debug）

### 背景 / 目的

修复“打开菜单后首次不更新，必须关闭再打开才能看到最新价格”的问题，确保菜单保持打开时价格可实时刷新。

### 代码改动点

- 更新 `StatusBarController`：
  - 将 `menuSymbolPrices` 变化从“重建菜单”改为“直接更新当前已渲染交易对行的价格文本”
  - 新增 `refreshVisibleSymbolRowPrices()`，遍历可见 `SymbolRowView` 并原地更新右侧价格
  - 保持菜单结构变化（交易对列表/选中态/刷新间隔）与价格文本变化分离，避免打开态刷新不生效
- 更新 `SymbolRowView`：
  - 暴露交易对标识供控制器定位对应行
  - 新增 `updatePriceText(_:)` 用于打开态原地刷新价格标签

### 文档同步情况

- 本条 `docs/CHANGELOG.md` 记录本次 debug 修复事实

### 验证情况

- 已执行 `swift test`，通过

## 2026-03-13 - 菜单打开期间定时刷新与价格列对齐修复（debug）

### 背景 / 目的

继续修复“菜单打开期间价格仍不实时刷新”的问题，并解决交易对价格列呈阶梯状、首行右侧留白过大的布局问题。

### 代码改动点

- 更新 `TimerRefreshScheduler`：
  - 定时器改为显式加入主线程 `RunLoop.common` 模式
  - 避免菜单打开进入 AppKit tracking 模式后，默认模式下的 `Timer` 无法继续触发
- 更新 `StatusBarController` / `SymbolRowView`：
  - 菜单价格列改为固定宽度，保证所有交易对价格右侧对齐
  - 打开态更新价格文本时显式触发布局与重绘，减少菜单视图缓存导致的显示滞后
- 更新 `TickerCoordinatorTests`：
  - 新增菜单打开后由调度器触发第二次批量刷新的断言，覆盖持续刷新行为

### 文档同步情况

- 本条 `docs/CHANGELOG.md` 记录本次 debug 修复事实

### 验证情况

- 已执行 `swift test`，通过

## 2026-03-13 - 菜单打开态批量刷新全部交易对价格

### 背景 / 目的

打开菜单时只能看到交易对名称，看不到当前整表行情；若逐个请求又会造成过多 API 调用。需要在菜单打开后立刻展示默认和自定义交易对的价格，并在菜单关闭后停止该类请求。

### 代码改动点

- 更新 `PriceProviding` 协议，新增批量价格获取接口
- 更新 `BinanceFuturesPriceProvider`：
  - 保留单交易对查询接口供状态栏主价格使用
  - 新增通过 Binance `fapi/v1/ticker/price` 全量响应过滤所需交易对的批量获取逻辑，减少菜单打开态下的请求次数
- 更新 `TickerCoordinator`：
  - 新增菜单打开/关闭事件处理
  - 为菜单整表行情增加独立刷新调度与异步任务
  - 菜单打开时立即请求全部交易对价格，菜单关闭时停止调度并取消请求
- 更新 `AppState`：
  - 新增菜单交易对价格缓存
  - 支持为菜单行设置占位值、应用批量价格结果以及关闭菜单时清空缓存
- 更新 `StatusBarController`：
  - 接入 `NSMenuDelegate`，把菜单打开/关闭事件转发给协调器
  - 交易对行新增右侧价格展示，并订阅菜单行价格变化
- 更新测试与 stub：
  - `StubPriceProvider` 支持批量价格返回
  - `TickerCoordinatorTests` 增加菜单打开即批量刷新、菜单关闭即停止并清空价格的断言
  - `AppBootstrapperTests` 同步协议新增方法

### 文档同步情况

- 已更新 `README.md`：补充菜单打开态整表价格预览与关闭即停的能力说明
- 已更新 `docs/PROJECT.md`：同步功能边界、状态约束和 `AppState` 的菜单价格职责
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 自定义交易对输入改为弹窗模式

### 背景 / 目的

菜单内嵌输入框在打开态菜单中存在较多焦点与交互问题，影响稳定性。将“添加自定义交易对”改为弹窗输入，降低菜单重建与输入焦点耦合带来的 bug 风险。

### 代码改动点

- 更新 `StatusBarController`：
  - 移除菜单内嵌输入框与按钮视图
  - 新增“添加自定义交易对...”菜单项，点击后通过 `NSAlert + NSTextField` 弹窗输入
  - 删除与旧输入框相关的焦点处理、菜单打开时自动聚焦逻辑，以及 `HoverCursorTextField` 实现
- 更新 `AppCopy`：
  - 调整“添加自定义交易对”入口文案
  - 新增弹窗标题、提示文案、确认/取消按钮文案

### 文档同步情况

- 已更新 `README.md`：自定义交易对添加方式改为弹窗输入
- 已更新 `docs/PROJECT.md`：同步自定义交易对添加入口约束
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 交易对菜单保持打开与自定义行交互修复

### 背景 / 目的

修复交易对菜单中的三个交互问题：删除自定义交易对未在当前打开态菜单中即时生效、点击交易对会立刻收起菜单、自定义交易对输入框点击后无明显光标反馈；并统一默认/自定义交易对行的视觉对齐与颜色。

### 代码改动点

- 更新 `StatusBarController`：
  - 默认交易对从 `NSMenuItem` 切换为与自定义交易对一致的行视图渲染，保证对齐与文字颜色一致
  - 交易对行点击后不关闭菜单，在打开态菜单中立即刷新对号（选中态）显示
  - 自定义交易对删除确认后立即原地刷新当前菜单，修复“需重开菜单才消失”的问题
  - 自定义交易对输入框增加显式焦点与插入光标处理（点击输入区可见闪动光标）
- 调整交易对行布局常量，使默认/自定义交易对行的左内边距和宽度一致

### 文档同步情况

- 已更新 `README.md`：补充菜单保持展开、默认/自定义交易对样式一致的行为说明
- 已更新 `docs/PROJECT.md`：补充交易对菜单打开态行为约束与统一行样式事实
- 本条 `docs/CHANGELOG.md` 记录本次修复事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 自定义交易对即时刷新与行内删除交互重构

### 背景 / 目的

修复“添加自定义交易对后需要关闭重开菜单才显示”的交互缺陷；移除自定义刷新间隔输入，统一为固定预设；并将删除操作改为交易对行内 hover 触发的确认/取消流程，提升菜单操作连贯性。

### 代码改动点

- 更新 `StatusBarController`：
  - 保持单一 `NSMenu` 实例并原地刷新菜单项，添加成功后立即重建菜单，确保打开态即时显示新增交易对
  - 刷新间隔移除自定义输入，仅保留 `3/5/10/30/60` 预设项
  - 删除“删除自定义交易对”分组，改为自定义交易对行内 hover 显示“删除”，点击后切换为“删除/取消”确认操作
  - 新增输入区鼠标形态：输入框为 I 型，按钮为手型
  - `menuWillOpen` 中设置输入框焦点与选区，修复首次点击输入框不显示闪动光标
- 更新 `AppState`：
  - 启动时将历史非预设刷新间隔就近映射到预设值（等距取较小值）
  - 刷新间隔更新仅接受 `3/5/10/30/60`
- 更新 `TickerCoordinator`：
  - 启动时若检测到刷新间隔被归一化，自动持久化回写一次
- 更新 `AppConfiguration`：
  - 新增刷新间隔预设常量，供状态与菜单共享
- 更新测试：
  - `AppStateTests`：刷新间隔仅预设值可用 + 启动归一化断言
  - `TickerCoordinatorTests`：启动后会持久化归一化后的刷新间隔

### 文档同步情况

- 已更新 `README.md`：刷新间隔改为仅预设，删除改为行内确认
- 已更新 `docs/PROJECT.md`：同步行为约束与启动归一化规则
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 状态栏菜单交互与布局问题修复

### 背景 / 目的

修复输入控件宽度和左侧对齐不佳、首次焦点异常、自定义交易对添加后菜单不即时刷新，以及刷新间隔下拉交互不稳定导致菜单消失的问题；同时精简菜单文案。

### 代码改动点

- 更新 `StatusBarController`：
  - 改为持有单一 `NSMenu` 实例并在刷新时原地重建菜单项，避免菜单打开时新增自定义交易对不立即显示
  - 移除顶部状态行，仅保留标题和业务分组
  - 输入控件统一调整为更窄宽度并增加左侧缩进，与菜单文字起始位对齐
  - 刷新间隔改为“预设单选项（`3/5/10/30/60`）+ 自定义输入（`1-300`）”
  - 增加 `menuWillOpen` 首次焦点处理，首次打开菜单时可直接看到输入光标
- 更新 `AppCopy`：
  - 默认交易对分组标题改为“默认交易对”
  - 调整刷新间隔输入提示并恢复自定义输入的“应用”按钮文案

### 文档同步情况

- 已更新 `README.md`：刷新间隔交互描述改为菜单预设单选 + 自定义输入
- 已更新 `docs/PROJECT.md`：同步刷新间隔交互事实
- 本条 `docs/CHANGELOG.md` 记录本次修复事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 刷新间隔预设下拉与价格两位小数统一

### 背景 / 目的

修复状态栏菜单输入控件左侧贴边导致的视觉问题，并将刷新间隔改为更易用的预设选择（保留自定义输入）；同时统一价格展示精度，避免小数位不一致。

### 代码改动点

- 更新 `StatusBarController`：
  - 刷新间隔从“文本输入 + 应用按钮”改为“可输入 `NSComboBox`”
  - 预置 `3/5/10/30/60`，选择或回车后立即应用
  - 为自定义交易对输入区和刷新间隔输入区增加左右内边距与最小宽度约束，修复左侧溢出/贴边问题
- 更新 `PriceSnapshot`：
  - `formattedPrice` 改为统一两位小数输出
  - 当价格文本不可解析为数值时回退原文本
- 更新测试：
  - `AppStateTests` 增加自定义刷新间隔值（如 `7`）断言
  - `StubServicesTests` 增加两位小数格式化与异常文本回退断言

### 文档同步情况

- 已更新 `README.md`：刷新间隔交互改为“预设 + 自定义输入”，并注明价格统一两位小数
- 已更新 `docs/PROJECT.md`：同步功能边界与行为约束
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，测试通过

## 2026-03-13 - 状态栏交易对管理与 Binance 实时价格

### 背景 / 目的

移除之前用于测试的“输入文字更新状态栏”能力，改为可实际使用的交易对选择与实时价格展示，并支持刷新间隔持久化。

### 代码改动点

- 重构 `StatusBarController` 菜单结构，新增：
  - 默认交易对选择（`BTCUSDT`/`ETHUSDT`/`SOLUSDT`）
  - 自定义交易对添加与删除（删除前确认）
  - 刷新间隔输入与应用（1-300 秒）
- 重写 `AppState`，新增并管理：
  - `selectedSymbol`
  - `builtinSymbols`
  - `customSymbols`
  - `refreshInterval`
  - 价格展示与输入校验逻辑
- 新增 `TickerCoordinator` 统一处理：
  - 交易对切换后的即时拉取
  - 定时刷新调度
  - 用户配置持久化保存
- 新增真实服务实现：
  - `BinanceFuturesPriceProvider`（`/fapi/v1/ticker/price`）
  - `TimerRefreshScheduler`
  - `UserDefaultsAppConfigurationProvider`
- 更新协议：
  - `PriceProviding` 改为异步价格接口
  - `RefreshScheduling` 支持按间隔启动
  - `AppConfigurationProviding` 增加保存配置方法
- 删除 `CryptoAsset` 旧模型及相关旧调用链。

### 文档同步情况

- 已更新 `README.md`：改为当前真实能力说明（交易对管理、Binance 实时价格、间隔持久化）
- 已更新 `docs/PROJECT.md`：同步功能边界、结构分层、行为约束、测试清单
- 本条 `docs/CHANGELOG.md` 记录本次实现事实

### 验证情况

- 已执行 `swift test`，当前测试通过
- 新增/更新测试：
  - `AppStateTests`
  - `TickerCoordinatorTests`
  - `AppBootstrapperTests`
  - `StubServicesTests`

## 2026-03-13 - 初始化 macOS 状态栏应用骨架

### 背景 / 目的

创建一个可运行、可扩展、可测试的 macOS 状态栏应用骨架，为后续接入加密货币价格能力预留结构。

### 代码改动

- 建立 Swift Package 形式的 macOS 可执行应用
- 初始化应用入口、状态栏控制器、领域模型、协议与 stub 服务
- 建立依赖装配代码和基础测试 target

### 文档同步

- 更新 `README.md` 说明当前阶段仅提供骨架能力
- 采用轻量文档后，本条记录从原有 OpenSpec 历史整理而来

### 验证情况

- 仓库包含 `swift test` 基础测试入口

## 2026-03-13 - 状态栏支持自定义文字输入

### 背景 / 目的

允许用户直接在状态栏菜单中输入自定义文字，无需打开额外窗口。

### 代码改动

- 在 `StatusBarController` 中加入菜单输入框和应用按钮
- 在 `AppState` 中加入 `updateStatusTitle(input:)`，统一处理裁剪和空白输入规则
- 在 `AppCopy` 中补充输入相关文案
- 新增 `AppStateTests` 覆盖非空输入更新和空白输入忽略行为

### 文档同步

- 本条记录保留该功能的实现事实，替代原先分散在 OpenSpec 中的 proposal / design / tasks / spec
- `README.md` 与 `docs/PROJECT.md` 已同步到当前行为

### 验证情况

- 已补充对应单元测试

## 2026-03-13 - 从 OpenSpec 迁移到轻量 AI 协作文档

### 背景 / 目的

项目是个人开发小工具，OpenSpec 维护成本偏高。需要改成更适合 Codex 等 AI 工具快速读取、实现和持续同步的文档结构。

### 代码改动

- 无功能代码变更

### 文档改动

- 新增 `AGENTS.md`，定义 AI 协作入口和“改代码后必须改文档”的规则
- 新增 `docs/PROJECT.md`，集中记录项目事实、结构和约束
- 新增 `docs/CHANGELOG.md`，作为唯一持续维护的变更记录
- 重写 `README.md`，改为轻量入口说明
- 删除 `openspec/` 历史文档和仓库内 `openspec-*` 本地 skills，避免继续使用旧流程

### 验证情况

- 已通过全文搜索确认仓库内不再依赖 OpenSpec 工作流
