# 变更记录

使用轻量日志记录已完成的实际变更。只记录已经落地到代码或文档的内容，不记录纯规划。

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
