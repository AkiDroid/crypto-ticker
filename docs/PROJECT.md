# 项目说明

## 项目定位

这是一个个人使用的 macOS 状态栏加密货币小工具，目标是保持实现简单、结构清晰、方便 AI 代理继续接手开发。

当前阶段优先保证：

- 应用可以作为状态栏程序运行
- 价格获取与刷新行为有明确分层
- 文档足够轻，AI 读取成本低

## 当前功能边界

当前已经支持：

- 应用启动后创建状态栏项
- 状态栏菜单显示说明、交易对管理、刷新间隔设置和退出入口
- 默认交易对 `BTCUSDT`、`ETHUSDT`、`SOLUSDT`，固定不可删除
- 自定义交易对添加与删除（交易对行内删除，并提供确认/取消）
- 选中交易对后即时拉取 Binance USDT-M 永续最新价格
- 定时刷新价格，刷新间隔仅支持菜单预设 `3/5/10/30/60` 单选并持久化
- 应用重启后恢复已选交易对、自定义交易对列表和刷新间隔
- 价格显示统一格式化为两位小数（状态栏标题和详情文案一致）

当前还不支持：

- 历史价格/缓存策略
- API 限流与自动退避重试
- 生产级发布流程

## 代码结构

### 应用层

- `Sources/CryptoTickerApp/App/CryptoTickerApp.swift`：SwiftUI 应用入口
- `Sources/CryptoTickerApp/App/AppDelegate.swift`：启动时装配状态栏控制器

### 功能层

- `Sources/CryptoTickerApp/Features/StatusBar/StatusBarController.swift`：状态栏项、菜单渲染、交易对与间隔交互

### 领域层

- `Sources/CryptoTickerApp/Domain/Models/AppState.swift`：交易对列表、选中项、刷新间隔、状态栏展示状态
- `Sources/CryptoTickerApp/Domain/Models/AppConfiguration.swift`：默认交易对、持久化配置模型
- `Sources/CryptoTickerApp/Domain/Models/PriceSnapshot.swift`：价格快照模型

### 服务层

- `Sources/CryptoTickerApp/Services/Protocols/`：价格、配置、刷新相关协议
- `Sources/CryptoTickerApp/Services/Remote/BinanceFuturesPriceProvider.swift`：Binance 永续价格 API 实现
- `Sources/CryptoTickerApp/Services/Scheduling/TimerRefreshScheduler.swift`：基于 `Timer` 的刷新调度
- `Sources/CryptoTickerApp/Services/Storage/UserDefaultsAppConfigurationProvider.swift`：本地配置持久化
- `Sources/CryptoTickerApp/Services/Stubs/`：测试用 stub 实现

### 支持层

- `Sources/CryptoTickerApp/Support/AppContainer.swift`：依赖容器
- `Sources/CryptoTickerApp/Support/AppBootstrapper.swift`：应用启动和停止调度
- `Sources/CryptoTickerApp/Support/TickerCoordinator.swift`：交易对操作、配置落盘、价格刷新协调
- `Sources/CryptoTickerApp/Support/AppCopy.swift`：界面文案常量

### 测试

- `Tests/CryptoTickerAppTests/AppBootstrapperTests.swift`
- `Tests/CryptoTickerAppTests/AppStateTests.swift`
- `Tests/CryptoTickerAppTests/TickerCoordinatorTests.swift`
- `Tests/CryptoTickerAppTests/StubServicesTests.swift`

## 当前行为约束

- 默认交易对只能选择，不能删除
- 自定义交易对输入会执行“去空格 + 大写 + 去重”规则
- 刷新间隔仅支持 `3/5/10/30/60` 菜单单选
- 启动时若读取到历史非预设刷新间隔，会就近映射到预设值并回写持久化
- 状态栏标题展示为“币种简称 + 价格”；`USDT` 后缀会被省略
- 价格文本在可解析为数值时统一显示为两位小数，不可解析时保留原始文本
- 状态栏展示状态由 `AppState` 统一管理，菜单事件由 `StatusBarController` 转发给 `TickerCoordinator`
- 持久化仅保存：已选交易对、自定义交易对、刷新间隔

## 开发约定

- 优先保持原生 Swift / SwiftUI / AppKit 方案，不额外引入重型依赖
- 新功能尽量沿用现有分层，不把业务逻辑直接堆进状态栏控制器
- 任何代码改动后，都要检查 `README.md`、`docs/PROJECT.md`、`docs/CHANGELOG.md` 是否需要同步
- 如果只是小修复，至少补一条 `docs/CHANGELOG.md` 记录

## 后续推荐协作方式

以后让 AI 实现功能时，建议直接给出：

- 目标行为
- 影响范围
- 是否需要测试
- 是否需要更新对外说明

AI 完成后必须同时交付：

- 代码改动
- 文档改动
- 验证结果
