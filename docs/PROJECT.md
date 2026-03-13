# 项目说明

## 项目定位

这是一个个人使用的 macOS 状态栏加密货币小工具，目标是保持实现简单、结构清晰、方便 AI 代理继续接手开发。

当前阶段优先保证：

- 应用可以作为状态栏程序运行
- 结构上为后续价格能力预留扩展点
- 文档足够轻，AI 读取成本低

## 当前功能边界

当前已经支持：

- 应用启动后创建状态栏项
- 状态栏菜单显示基础说明与退出入口
- 在菜单输入框中提交非空文本后，更新状态栏标题
- 空白输入不会覆盖当前标题
- 通过 stub 服务完成应用装配与占位运行

当前还不支持：

- 真实价格拉取
- 刷新调度的业务逻辑
- 用户设置持久化
- 多币种切换
- 生产级发布流程

## 代码结构

### 应用层

- `Sources/CryptoTickerApp/App/CryptoTickerApp.swift`：SwiftUI 应用入口
- `Sources/CryptoTickerApp/App/AppDelegate.swift`：启动时装配状态栏控制器

### 功能层

- `Sources/CryptoTickerApp/Features/StatusBar/StatusBarController.swift`：状态栏项、菜单、输入框与提交行为

### 领域层

- `Sources/CryptoTickerApp/Domain/Models/AppState.swift`：状态栏标题和详情等运行时状态
- `Sources/CryptoTickerApp/Domain/Models/AppConfiguration.swift`：应用配置模型
- `Sources/CryptoTickerApp/Domain/Models/CryptoAsset.swift`：币种模型
- `Sources/CryptoTickerApp/Domain/Models/PriceSnapshot.swift`：价格快照模型

### 服务层

- `Sources/CryptoTickerApp/Services/Protocols/`：价格、配置、刷新相关协议
- `Sources/CryptoTickerApp/Services/Stubs/`：当前使用的占位实现

### 支持层

- `Sources/CryptoTickerApp/Support/AppContainer.swift`：依赖容器
- `Sources/CryptoTickerApp/Support/AppBootstrapper.swift`：应用启动装配流程
- `Sources/CryptoTickerApp/Support/AppCopy.swift`：界面文案常量

### 测试

- `Tests/CryptoTickerAppTests/AppBootstrapperTests.swift`
- `Tests/CryptoTickerAppTests/AppStateTests.swift`
- `Tests/CryptoTickerAppTests/StubServicesTests.swift`

## 当前行为约束

- `AppState.updateStatusTitle(input:)` 会先做首尾空白裁剪
- 裁剪后为空时，不更新现有标题
- 状态栏标题由 `AppState` 统一管理，`StatusBarController` 负责 UI 事件转发和订阅
- 当前默认标题为 `--`
- 当前默认详情文案为“价格服务尚未接入”

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
