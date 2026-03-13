# Crypto Ticker

一个使用 Swift + SwiftUI/AppKit 构建的 macOS 状态栏加密货币小工具。

当前版本已支持 Binance USDT-M 永续合约实时价格展示、交易对管理、刷新间隔持久化、开机自动启动设置，以及通过 GitHub Actions 打包并发布到 GitHub Release（当前仅构建 macOS arm64 版本）。

## 当前能力

- macOS 状态栏应用入口与基础生命周期
- 状态栏菜单与退出操作
- 默认交易对：`BTCUSDT`、`ETHUSDT`、`SOLUSDT`（不可删除）
- 支持添加/删除自定义交易对（通过“添加自定义交易对...”弹窗输入，列表行内删除并二次确认）
- 点击交易对后菜单保持展开，并立即切换选中对号显示
- 选中交易对后从 Binance `fapi` 接口拉取最新价格
- 状态栏展示格式：币种简称 + 价格，价格统一保留两位小数（如 `BTC 65000.10`）
- 连续三次价格请求失败后，状态栏标题左侧显示一个错误图标；成功请求后自动清除
- 刷新间隔仅支持菜单预设 `3/5/10/30/60` 单选，默认 `5`；历史非预设值会自动就近映射并持久化
- 支持在状态栏菜单中通过 checkbox 开关“开机自动启动”，并同步系统登录项状态
- 提供 `scripts/build_release_app.sh`，可在本地生成 `.app` 和 zip 发布包
- 提供 `.github/workflows/release.yml`，支持按 tag 构建 macOS `arm64` 包并上传到 GitHub Release
- 基础单元测试覆盖应用状态、协调器和启动流程

## 当前未实现

- 价格缓存与离线回退
- 更丰富的错误分类和重试策略
- Developer ID 签名、公证和自动更新

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
- `Sources/CryptoTickerApp/Services/System`：系统登录项等平台能力封装
- `Sources/CryptoTickerApp/Support`：依赖装配、启动流程、业务协调器与文案
- `Tests/CryptoTickerAppTests`：基础测试
- `scripts/build_release_app.sh`：本地 release 打包脚本
- `.github/workflows/release.yml`：GitHub Release 构建与上传流程
- `packaging`：`.app` 打包所需模板
- `docs`：轻量项目文档与变更记录

## 本地验证

```bash
swift test
```

运行应用：

```bash
swift run CryptoTickerApp
```

说明：

- “开机自动启动”依赖 macOS `SMAppService.mainApp`
- 该能力应在打包后的 `.app` 中使用；直接 `swift run` 运行时，系统可能拒绝注册登录项

本地打包：

```bash
./scripts/build_release_app.sh macos-arm64
```

打包产物会输出到 `dist/` 目录，包括：

- `CryptoTicker.app`
- `CryptoTicker-macos-arm64.zip`
- 对应的 `sha256` 校验文件

## GitHub Release 发布步骤

1. 确认默认分支已经包含本仓库最新代码和 `.github/workflows/release.yml`
2. 在 GitHub 仓库设置中允许 Actions 具备 `Read and write permissions`
3. 本地先执行一次验证：

```bash
swift test
./scripts/build_release_app.sh macos-arm64
```

4. 提交并推送代码后，创建版本 tag：

```bash
git tag v0.1.0
git push origin v0.1.0
```

5. GitHub Actions 会自动：
   - 在 `macos-15` 构建 `arm64` 包
   - 创建或更新对应 tag 的 GitHub Release
   - 上传 zip 和 `sha256` 文件

6. 在 GitHub 的 Release 页面检查产物是否齐全，再补充发行说明

当前工作流默认使用 ad-hoc 签名，适合先把产物发布出去；如果后续要避免 Gatekeeper 告警，还需要再补 Developer ID 签名和 Apple notarization。
