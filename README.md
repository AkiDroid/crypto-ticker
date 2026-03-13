# Crypto Ticker

一个使用 Swift + SwiftUI/AppKit 构建的 macOS 状态栏加密货币小工具。

当前版本已支持 Binance USDT-M 永续合约实时价格展示、交易对管理和刷新间隔持久化。

## 当前能力

- macOS 状态栏应用入口与基础生命周期
- 状态栏菜单与退出操作
- 默认交易对：`BTCUSDT`、`ETHUSDT`、`SOLUSDT`（不可删除）
- 支持添加/删除自定义交易对（删除前确认）
- 选中交易对后从 Binance `fapi` 接口拉取最新价格
- 状态栏展示格式：币种简称 + 价格（如 `BTC 65000.12`）
- 刷新间隔可配置（1-300 秒，默认 5 秒）并持久化到本地
- 基础单元测试覆盖应用状态、协调器和启动流程

## 当前未实现

- 价格缓存与离线回退
- 更丰富的错误分类和重试策略
- 发布、签名与自动更新

## 文档约定

本仓库不再使用 OpenSpec。

后续协作统一阅读：

1. `AGENTS.md`
2. `README.md`
3. `docs/PROJECT.md`
4. `docs/CHANGELOG.md`

任何功能实现后，都要同步更新文档，至少追加 `docs/CHANGELOG.md`。

## 目录结构

- `Sources/CryptoTickerApp/App`：应用入口与生命周期
- `Sources/CryptoTickerApp/Features`：状态栏相关 UI / 交互
- `Sources/CryptoTickerApp/Domain`：领域模型与应用状态
- `Sources/CryptoTickerApp/Services`：协议、Binance 远程服务、刷新调度与配置存储
- `Sources/CryptoTickerApp/Support`：依赖装配、启动流程、业务协调器与文案
- `Tests/CryptoTickerAppTests`：基础测试
- `docs`：轻量项目文档与变更记录

## 本地验证

```bash
swift test
```

运行应用：

```bash
swift run CryptoTickerApp
```
