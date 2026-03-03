# Flutter 项目脚手架设计

> 日期: 2026-03-03
> 状态: 已批准（架构师 Review 通过）

## 背景

Rust 密码学核心层已完成（132 个测试），现在搭建 Flutter 侧完整项目骨架，使项目可以 `flutter run` 启动空壳 APP，并具备完整的目录结构和依赖配置。

## 方案

使用 `flutter create` 生成标准平台代码（android/ios），然后按技术规范改造 `lib/` 结构。

## 依赖版本（架构师 Review 后确定）

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
  go_router: ^14.8.0
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  drift: ^2.22.0
  drift_flutter: ^0.2.0
  flutter_secure_storage: ^9.2.0
  local_auth: ^2.3.0
  flutter_rust_bridge: ^2.7.0
  path_provider: ^2.1.0
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^3.0.0
  riverpod_lint: ^3.0.0
  custom_lint: ^0.7.0
  freezed: ^3.0.0
  json_serializable: ^6.9.0
  build_runner: ^2.4.0
  drift_dev: ^2.22.0
  mocktail: ^1.0.0
  very_good_analysis: ^7.0.0
```

注意：以上为语义化版本下限约束，`flutter pub get` 时会解析为实际可用的最新兼容版本。最终确切版本以 `pubspec.lock` 为准。

## 目录结构

```
lib/
├── main.dart
├── app.dart
└── src/
    ├── rust/                     # [自动生成] FRB 绑定
    ├── features/
    │   ├── wallet/               # domain/data/application/presentation
    │   ├── auth/                 # domain/data/application/presentation
    │   ├── backup/               # domain/application/presentation
    │   ├── transfer/             # domain/data/application/presentation
    │   ├── history/              # domain/data/presentation
    │   ├── network/              # domain/data/presentation
    │   └── settings/             # domain/data/presentation
    ├── core/
    │   ├── database/             # drift 表定义 + daos + migrations
    │   ├── providers/            # 全局 Provider
    │   ├── common_widgets/
    │   ├── constants/            # 颜色、链配置
    │   ├── exceptions/
    │   ├── utils/
    │   └── extensions/
    ├── routing/                  # go_router 路由树
    └── localization/             # ARB 国际化文件

test/
├── helpers/pump_app.dart
├── mocks/mocks.dart
├── unit/
├── widget/
└── golden/

integration_test/
```

## 配置文件

- `analysis_options.yaml` — very_good_analysis + 生成文件排除
- `build.yaml` — build_runner 配置
- `flutter_rust_bridge.yaml` — FRB 代码生成配置
- `l10n.yaml` — 国际化配置

## 架构师 Review 关键修正

1. Riverpod 2.x → 3.x（auto-dispose 默认行为、统一 Ref）
2. freezed 2.x → 3.x（sealed class、不可变集合）
3. 新增 `drift_flutter` 替代 `sqlite3_flutter_libs`
4. 新增 `riverpod_lint` + `custom_lint`
5. 使用 `very_good_analysis` 替代 `flutter_lints`
6. 新增 `l10n.yaml` 和 `analysis_options.yaml`
7. 新增测试目录骨架
8. `backup/` feature 补充 application 层
