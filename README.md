# Crypto Ticker

这是一个 macOS 状态栏加密货币价格应用的初始化骨架工程。

当前阶段只完成以下内容：

- 原生 Swift + SwiftUI/AppKit 的应用入口
- 状态栏项与基础菜单
- 面向后续价格功能的模型、协议和 stub 服务
- 最小测试 target 与骨架测试

当前阶段不包含以下内容：

- 真实加密货币价格 API 接入
- 定时刷新、缓存与错误恢复
- 用户配置持久化
- 发布、签名与自动更新

## 目录结构

- `Sources/CryptoTickerApp/App`: 应用入口与生命周期
- `Sources/CryptoTickerApp/Features`: 状态栏等功能壳
- `Sources/CryptoTickerApp/Domain`: 领域模型与应用状态
- `Sources/CryptoTickerApp/Services`: 协议与占位服务
- `Sources/CryptoTickerApp/Support`: 依赖装配与基础支持代码
- `Tests/CryptoTickerAppTests`: 骨架测试

## 本地验证

```bash
swift test
```

如需继续实现真实价格能力，请基于现有协议和 stub 替换具体实现。
