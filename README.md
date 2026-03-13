# Crypto Ticker

一个使用 Swift + SwiftUI/AppKit 构建的 macOS 状态栏加密货币小工具。

当前项目仍处于轻量骨架阶段，但已经具备可运行的状态栏应用形态，并支持在菜单中输入自定义状态栏文字。

## 当前能力

- macOS 状态栏应用入口与基础生命周期
- 状态栏菜单与退出操作
- 菜单内输入自定义文字，并立即更新状态栏标题
- 面向后续价格功能的模型、协议和 stub 服务
- 最小测试 target 与基础单元测试

## 当前未实现

- 真实加密货币价格 API 接入
- 定时刷新、缓存与错误恢复
- 用户配置持久化
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
- `Sources/CryptoTickerApp/Services`：协议与 stub 服务
- `Sources/CryptoTickerApp/Support`：依赖装配与文案等支持代码
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
