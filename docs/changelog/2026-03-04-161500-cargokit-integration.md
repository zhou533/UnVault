# chore(bridge): integrate cargokit for iOS/macOS Rust cross-compilation

- **时间**: 2026-03-04 16:15
- **类型**: chore
- **模块**: rust_builder, ios, macos, rust/Cargo

## 变更意图

App 在 iOS 模拟器上启动白屏，因为 `RustLib.init()` 找不到 Rust native library。FRB v2 codegen 只生成了 Dart 绑定，但缺少将 Rust 交叉编译为 iOS/macOS 静态库并链接到 Xcode 项目的构建步骤。通过集成 cargokit（FRB v2 官方推荐方案），在 `flutter build` 时自动编译 Rust → iOS/macOS。

## 变更内容

- `rust_builder/` — 新增 FRB cargokit 构建插件包（通过 `flutter_rust_bridge_codegen integrate` 生成）
- `rust_builder/pubspec.yaml` — Flutter FFI 插件声明，包名改为 `unvault_core`（Dart 不允许连字符）
- `rust_builder/ios/unvault_core.podspec` — iOS 构建脚本，调用 cargokit 交叉编译 Rust 并 force_load 静态库
- `rust_builder/macos/unvault_core.podspec` — macOS 构建脚本，同上
- `rust_builder/cargokit/` — cargokit 构建工具（vendor 方式引入，处理 cargo build + lipo 合并架构）
- `pubspec.yaml` — 添加 `unvault_core: path: rust_builder` 依赖
- `rust/Cargo.toml` — 包名从 `unvault-core` 改为 `unvault_core`，解决 cargokit 产物文件名不匹配问题（Cargo 自动将连字符转下划线，但 cargokit 按原名查找）
- `rust/Cargo.lock` — 随包名变更自动更新
- `ios/Flutter/Debug.xcconfig` / `Release.xcconfig` — 添加 Generated.xcconfig include
- `ios/Runner.xcodeproj/project.pbxproj` — Xcode 项目配置更新，注册 unvault_core pod
- `ios/Runner.xcworkspace/contents.xcworkspacedata` — 工作区引用更新
- `macos/Flutter/Flutter-Debug.xcconfig` / `Flutter-Release.xcconfig` — macOS 同上
- `lib/main.dart` — 恢复为原始版本（integrate 命令曾覆盖为 demo 模板）

## 备注

- Rust crate 更名 `unvault-core` → `unvault_core` 是破坏性变更，但项目尚未发布，无外部依赖者
- 138 个 Rust 测试在更名后全部通过
- 首次 `flutter run -d iPhone` 构建较慢（需交叉编译整个 Rust crate），后续有缓存
- `rust_builder/android/` 和 `rust_builder/windows/` 等平台文件由 integrate 命令生成，暂未测试
