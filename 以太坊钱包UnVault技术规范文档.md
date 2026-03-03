# 以太坊钱包 APP 技术规范文档

## 1. 项目概述

跨平台（iOS + Android）以太坊 HD 钱包，使用 Flutter 构建 UI，Rust 处理所有密码学核心逻辑，通过 FFI 桥接实现安全隔离架构。项目以开源社区方式运营，强调安全性、可审计性和代码质量。

### 1.1 版本规划

#### V1（核心钱包）

- 钱包创建与导入（BIP-39 助记词）
- 助记词备份与验证流程
- 密码设置与生物识别解锁
- ETH 及原生代币转账与收款
- 多链（EVM）支持 + 自定义 RPC
- 多钱包与多账户管理
- 交易历史查看
- 完整安全体系（加密、内存安全、应用防护）

#### V2（生态扩展）

- WalletConnect v2（dApp 交互）
- ERC-20 / ERC-721 Token 管理
- EIP-712 类型化数据签名
- 硬件密钥绑定（Secure Enclave / StrongBox 参与密钥派生）
- Shamir 秘密分片备份（SSS）

## 2. 核心技术选型

| 模块       | 方案                                    |
| ---------- | --------------------------------------- |
| 钱包类型   | HD 钱包 (BIP-39 / BIP-44)              |
| 前端框架   | Flutter                                 |
| 核心实现   | Rust + flutter_rust_bridge v2           |
| 以太坊库   | alloy                                   |
| 状态管理   | Riverpod                                |
| 本地数据库 | drift (SQLite)                          |
| 路由       | go_router                               |
| 数据模型   | freezed（不可变模型）                   |
| 密钥派生   | Argon2id (密码 → 加密密钥)             |
| 对称加密   | AES-256-GCM                             |
| 安全存储   | iOS Keychain / Android Keystore         |
| 解锁方式   | 密码（≥8 位）+ 生物识别 (Face ID / 指纹) |
| 备份方式   | 手动抄写助记词                          |
| 网络支持   | 所有 EVM 链，支持自定义 RPC             |
| 错误处理   | thiserror (Rust) + 统一 FFI 错误码      |

## 3. 架构设计

### 3.1 分层架构

```
┌─────────────────────────────────────────┐
│            Flutter UI 层                │
├─────────────────────────────────────────┤
│        flutter_rust_bridge v2 (FFI)     │
├─────────────────────────────────────────┤
│              Rust 核心层                │
│  - 助记词生成/验证 (BIP-39)            │
│  - 私钥派生 (BIP-44)                   │
│  - 密码 → 加密密钥派生 (Argon2id)      │
│  - 助记词加密/解密 (AES-256-GCM)       │
│  - 交易签名 (alloy)                    │
├─────────────────────────────────────────┤
│       Platform Channel (存储桥接)       │
├──────────────────┬──────────────────────┤
│  iOS Keychain    │  Android Keystore    │
└──────────────────┴──────────────────────┘
```

### 3.2 架构原则

- Rust 层处理所有密码学逻辑，保证跨平台一致性
- 原生层只负责存储已加密的字节，永远不接触明文
- 双重保护：密码加密 + 原生安全存储
- 敏感数据用 zeroize 及时清除
- Flutter/Dart 层不持有任何密钥明文的 String 类型

### 3.3 项目目录结构

采用 flutter_rust_bridge v2 标准布局，Flutter 侧 feature-first 组织，Rust 侧按领域模块划分。

```
unvault/
├── .github/
│   ├── workflows/
│   │   ├── rust.yml                    # Rust 检查（fmt, clippy, test, coverage）
│   │   ├── flutter.yml                 # Flutter 检查（analyze, test, golden）
│   │   ├── build.yml                   # 跨平台构建（Android APK / iOS）
│   │   └── audit.yml                   # 安全审计（cargo deny, 依赖扫描）
│   ├── dependabot.yml                  # 自动依赖更新
│   └── PULL_REQUEST_TEMPLATE.md        # PR 模板
│
├── android/                            # Android 平台代码
├── ios/                                # iOS 平台代码
│
├── rust/                               # ===== Rust 核心层 =====
│   ├── Cargo.toml                      # Rust 依赖配置
│   ├── Cargo.lock
│   ├── rustfmt.toml                    # 格式化配置
│   ├── src/
│   │   ├── lib.rs                      # crate 根：模块声明 + pub re-exports
│   │   │
│   │   ├── api/                        # FRB 暴露给 Dart 的 API 层（薄包装）
│   │   │   ├── mod.rs
│   │   │   ├── wallet_api.rs           # 钱包创建/导入/导出
│   │   │   ├── crypto_api.rs           # 加密/解密/密钥派生
│   │   │   └── transaction_api.rs      # 交易构建/签名/Gas 估算
│   │   │
│   │   ├── crypto/                     # 密码学领域模块
│   │   │   ├── mod.rs
│   │   │   ├── mnemonic.rs             # BIP-39 助记词生成/验证
│   │   │   ├── key_derivation.rs       # BIP-44 HD 密钥派生
│   │   │   ├── argon2.rs               # Argon2id 密码→密钥派生 + 动态校准
│   │   │   ├── encryption.rs           # AES-256-GCM 加密/解密
│   │   │   └── memory.rs              # mlock/zeroize 内存安全工具
│   │   │
│   │   ├── wallet/                     # 钱包领域模块
│   │   │   ├── mod.rs
│   │   │   ├── wallet.rs               # 钱包核心结构与逻辑
│   │   │   └── account.rs              # 账户管理（BIP-44 多账户）
│   │   │
│   │   ├── transaction/                # 交易领域模块
│   │   │   ├── mod.rs
│   │   │   ├── builder.rs              # 交易构建（EIP-1559 / Legacy）
│   │   │   ├── signer.rs               # 交易签名（alloy）
│   │   │   └── gas.rs                  # Gas 估算策略
│   │   │
│   │   ├── models/                     # 共享数据类型
│   │   │   ├── mod.rs
│   │   │   ├── address.rs              # 以太坊地址（EIP-55）
│   │   │   └── network.rs              # 链配置
│   │   │
│   │   ├── error.rs                    # 统一错误类型（thiserror）
│   │   │
│   │   ├── frb_generated.rs            # [自动生成] FRB 胶水代码
│   │   └── frb_generated.io.rs         # [自动生成]
│   │
│   ├── tests/                          # 集成测试
│   │   ├── common/
│   │   │   └── mod.rs                  # 测试共享 fixtures/helpers
│   │   ├── crypto_integration.rs       # 加密全流程集成测试
│   │   ├── wallet_integration.rs       # 钱包创建→派生→签名流程
│   │   └── transaction_integration.rs  # 交易构建→签名→编码流程
│   │
│   └── benches/                        # 性能基准测试（criterion）
│       ├── argon2_bench.rs             # Argon2id 参数性能
│       └── signing_bench.rs            # 签名性能
│
├── rust_builder/                       # [自动生成] Cargokit 构建胶水，勿手动编辑
│
├── lib/                                # ===== Flutter/Dart 层 =====
│   ├── main.dart                       # 入口：ProviderScope 包装
│   ├── app.dart                        # MaterialApp.router 配置
│   │
│   └── src/
│       ├── rust/                       # [自动生成] FRB Dart 绑定
│       │   ├── frb_generated.dart
│       │   ├── frb_generated.io.dart
│       │   └── frb_generated.web.dart
│       │
│       ├── features/                   # 按业务功能组织（feature-first）
│       │   │
│       │   ├── wallet/                 # 钱包功能模块
│       │   │   ├── data/
│       │   │   │   └── wallet_repository.dart
│       │   │   ├── domain/
│       │   │   │   ├── wallet.dart              # Freezed 模型
│       │   │   │   └── wallet.freezed.dart      # [自动生成]
│       │   │   ├── application/
│       │   │   │   └── wallet_service.dart       # 业务逻辑
│       │   │   └── presentation/
│       │   │       ├── wallet_list_screen.dart
│       │   │       ├── create_wallet_screen.dart
│       │   │       ├── import_wallet_screen.dart
│       │   │       └── widgets/
│       │   │
│       │   ├── auth/                   # 认证/解锁功能模块
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   ├── application/
│       │   │   └── presentation/
│       │   │       ├── lock_screen.dart
│       │   │       ├── set_password_screen.dart
│       │   │       └── biometric_setup_screen.dart
│       │   │
│       │   ├── backup/                 # 助记词备份模块
│       │   │   └── presentation/
│       │   │       ├── show_mnemonic_screen.dart
│       │   │       └── verify_mnemonic_screen.dart
│       │   │
│       │   ├── transfer/              # 转账功能模块
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   ├── application/
│       │   │   └── presentation/
│       │   │       ├── send_screen.dart
│       │   │       ├── confirm_transaction_screen.dart
│       │   │       └── receive_screen.dart
│       │   │
│       │   ├── history/               # 交易历史模块
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   └── presentation/
│       │   │
│       │   ├── network/               # 多链/网络管理模块
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   └── presentation/
│       │   │
│       │   └── settings/              # 设置模块
│       │       ├── data/
│       │       ├── domain/
│       │       └── presentation/
│       │
│       ├── core/                       # 跨功能共享代码
│       │   ├── database/               # Drift 数据库
│       │   │   ├── app_database.dart   # @DriftDatabase 定义
│       │   │   ├── app_database.g.dart # [自动生成]
│       │   │   ├── tables/             # 表定义
│       │   │   │   ├── wallets_table.dart
│       │   │   │   ├── accounts_table.dart
│       │   │   │   ├── transactions_table.dart
│       │   │   │   └── networks_table.dart
│       │   │   ├── daos/               # 数据访问对象
│       │   │   └── migrations/         # 数据库迁移
│       │   │
│       │   ├── providers/              # 全局 Provider（数据库、主题、语言）
│       │   ├── common_widgets/         # 可复用 UI 组件
│       │   ├── constants/              # 常量（颜色、字符串、链配置）
│       │   ├── exceptions/             # 统一异常类型
│       │   ├── utils/                  # 工具函数（地址格式化、金额换算）
│       │   └── extensions/             # Dart 扩展方法
│       │
│       ├── routing/                    # go_router 路由配置
│       │   ├── app_router.dart         # 路由树定义
│       │   └── route_names.dart        # 路由名称常量
│       │
│       └── localization/               # 国际化
│           ├── app_en.arb
│           └── app_zh.arb
│
├── test/                               # ===== Flutter 测试 =====
│   ├── unit/                           # 纯 Dart 单元测试
│   │   ├── features/
│   │   │   ├── wallet/
│   │   │   └── transfer/
│   │   └── core/
│   │       └── database/
│   ├── widget/                         # Widget 测试
│   │   └── features/
│   ├── golden/                         # Golden 截图测试
│   ├── goldens/                        # Golden 基准图片
│   │   ├── ci/                         # 平台无关基准（CI 用）
│   │   └── macos/
│   ├── mocks/                          # Mock 类
│   │   ├── mock_rust_lib_api.dart      # FRB 桥接 Mock
│   │   └── mocks.dart                  # barrel file
│   ├── fixtures/                       # 测试数据/JSON
│   └── helpers/                        # 测试辅助函数
│       └── pump_app.dart               # ProviderScope + MaterialApp 包装
│
├── integration_test/                   # Flutter 集成测试（真机/模拟器）
│   ├── app_test.dart
│   └── wallet_flow_test.dart
│
├── docs/                               # 项目文档
│   ├── THREAT_MODEL.md                 # 威胁模型（安全审计用）
│   ├── CRYPTO_SPEC.md                  # 密码学方案详细说明
│   └── ARCHITECTURE.md                 # 架构决策记录
│
├── flutter_rust_bridge.yaml            # FRB 代码生成配置
├── pubspec.yaml                        # Flutter 依赖
├── analysis_options.yaml               # Dart lint 规则
├── build.yaml                          # build_runner 配置
├── CONTRIBUTING.md                     # 贡献指南
├── CHANGELOG.md                        # 变更日志
├── LICENSE                             # 开源协议
└── README.md
```

#### 结构设计原则

- **Flutter 采用 feature-first 组织**：每个功能模块内部按 `data/domain/application/presentation` 分层，模块间低耦合
- **每个 feature 内四层职责**：
  - `domain/`：Freezed 不可变数据模型（纯数据，无依赖）
  - `data/`：Repository 实现（调用 FRB 桥接、数据库、网络）
  - `application/`：业务逻辑服务（编排 repository + 状态）
  - `presentation/`：Screen、Controller（AsyncNotifier）、Widget
- **Rust 采用领域模块组织**：`crypto/` `wallet/` `transaction/` 各自独立，`api/` 层作为 FRB 暴露的薄包装
- **`api/` 层只做参数转换和错误映射**，真正的逻辑在各领域模块中实现
- **自动生成文件**一律提交到版本控制但禁止手动编辑，在 CI 中验证生成代码是否最新
- **测试目录结构镜像 `lib/src/` 结构**，方便定位对应测试

## 4. 安全规范

### 4.1 内存安全

#### Rust 侧

- 所有敏感类型（助记词、私钥、派生密钥）必须实现 `Zeroize + ZeroizeOnDrop`
- 使用 `secrecy` crate 的 `Secret<T>` 包装敏感类型，防止意外 Debug/Display 输出
- 错误路径和 panic 路径同样必须确保 zeroize 执行
- 使用 `libc::mlock` 锁定敏感内存页，防止 swap 到磁盘
  - iOS 沙盒环境对 mlock 支持有限，需运行时检测是否生效
  - 如果 mlock 失败，记录警告日志但不阻止操作（降级处理）
  - V2 将关键密钥操作委托给 Secure Enclave，减少密钥在应用内存中的暴露
- 编译时使用 `release` profile，strip symbols，关闭 debug 信息

#### Dart 侧

- 敏感数据只使用 `Uint8List`，禁止转为 `String`（String 不可变且可能被 intern）
- `Uint8List` 用完后立即手动覆写为零
- 敏感数据在 UI 展示后尽快从内存中清除

#### FFI 边界

- flutter_rust_bridge v2 传递敏感数据时优先使用 `Vec<u8>` / `Uint8List`
- 避免在 FFI 边界传递明文字符串

### 4.2 密钥派生与加密

#### Argon2id 参数

- 目标内存：64 MB，安全下限：32 MB
- 目标迭代次数：3 次，安全下限：2 次
- 并行度：2-4（利用现代手机多核，提升安全性且不增加延迟）
- 输出长度：32 字节（256 bit）
- **动态校准**：首次创建钱包时自动 benchmark，从高参数开始逐步降低，确保延迟在 1-2 秒内，但不低于安全下限
- 校准后的参数随 salt 一起持久化存储，解密时读取

#### Salt 管理

- 每个钱包创建时生成 16 字节随机 salt
- salt 与密文分开存储在 Keychain/Keystore 中
- salt 不可复用

#### 随机数安全

- 所有密码学随机数（salt、nonce 等）必须使用操作系统 CSPRNG（Rust 侧使用 `OsRng`）
- 禁止使用 `thread_rng` 或其他非密码学安全的随机数生成器处理安全相关数据

#### AES-256-GCM

- 每次加密使用随机 96-bit (12 字节) nonce（由 `OsRng` 生成）
- nonce 与密文拼接存储：`nonce (12 bytes) || ciphertext || tag (16 bytes)`
- 禁止使用计数器模式生成 nonce（移动端状态易丢失）

#### V2 规划：硬件密钥绑定

V2 将引入 Secure Enclave (iOS) / StrongBox (Android) 参与密钥派生，防止离线暴力破解：

```
密码 → Argon2id → derived_key
Secure Enclave/StrongBox → hardware_key
final_key = HKDF(derived_key || hardware_key)
final_key → AES-256-GCM → 加密助记词
```

效果：即使加密数据被提取，没有设备硬件密钥也无法解密。

### 4.3 解锁与认证

#### 密码

- 密码最少 8 位，支持任意长度，建议使用字母数字混合
- UI 提供密码强度指示器，引导用户设置高强度密码
- 暴力破解防护：失败次数限制 + 指数退避延迟（如 1s, 2s, 4s, 8s...）
- 连续失败 10 次后锁定 APP，需等待 30 分钟或更长时间
- 可选：连续失败 N 次后清除本地数据（需创建钱包时明确告知用户）

#### 生物识别

- 生物识别用于授权读取 Keychain/Keystore 中的加密密钥，不替代密码
- 首次解锁或敏感操作（导出助记词、大额转账）仍强制密码
- iOS：使用 `kSecAccessControlBiometryCurrentSet`，生物特征变更后失效
- Android：使用 `setUserAuthenticationRequired(true)`，绑定 BiometricPrompt
- `auth_key` 安全要求：
  - iOS：存储为 Keychain 中受生物识别保护的密钥引用，非明文密钥
  - Android：存储在 TEE/StrongBox 中，绑定用户认证
  - 生物识别被绕过不应直接暴露解密密钥

### 4.4 应用层安全

#### 截屏/录屏防护

- 助记词展示页面、私钥展示页面禁用截屏
- Android：设置 `FLAG_SECURE`
- iOS：监听 `UIScreen.capturedDidChangeNotification`，检测录屏时遮盖内容

#### 剪贴板安全

- 复制钱包地址后 60 秒自动清除剪贴板
- 永远禁止将私钥、助记词放入剪贴板

#### Root/越狱检测

- 启动时检测设备 root/越狱状态
- 检测到时向用户弹出安全警告
- 不强制禁止使用，但明确告知风险

#### 后台自动锁定

- APP 切换到后台时立即显示隐私遮罩（防止任务切换器截图泄露信息）
- 记录切换到后台的时间戳
- 返回前台时检查间隔，超过阈值自动锁定，要求重新认证
- 用户可配置锁定时间：立即 / 30 秒（默认）/ 1 分钟 / 5 分钟

#### 代码保护

- Flutter：启用 `--obfuscate` + `--split-debug-info`
- Rust：release 构建 strip symbols，开启 LTO
- 禁止在任何日志中输出敏感信息（私钥、助记词、密码、密钥）

#### 崩溃报告安全

- 崩溃报告中禁止包含敏感数据（内存 dump、密钥相关变量）
- 上报前对堆栈信息进行脱敏处理
- 用户可选择是否启用崩溃报告

### 4.5 网络安全

- 所有 RPC 请求强制 HTTPS
- 实施 Public Key Pinning（而非证书固定），更耐证书轮换
  - 同时 pin 当前公钥和备用公钥
  - 在 APP 内置 pin 配置版本号，通过 APP 更新刷新
  - pinning 失败时降级为标准 TLS 验证 + 用户安全警告
- 自定义 RPC 节点时警告用户非 HTTPS 连接的风险
- 禁止在 HTTP 请求的 URL 参数中携带敏感信息
- 请求/响应日志脱敏处理
- RPC 请求超时与重试策略（超时 10 秒，最多重试 3 次，指数退避）

### 4.6 交易安全

- 签名前必须在 UI 完整展示交易详情：目标地址、金额、Gas 费用、链信息
- 地址使用 EIP-55 校验和格式，展示时高亮校验
- 交易必须包含正确 chainId（EIP-155 重放保护）
- 大额交易（阈值可配置）强制密码二次确认
- 签名操作全部在 Rust 层完成，签名后的 raw transaction 才传回 Dart 层
- **地址投毒防护**：
  - 交易确认页完整展示目标地址，禁止截断
  - 地址簿功能：已保存地址匹配时高亮显示名称
  - 首次向某地址转账时弹出警告提示
  - 展示该地址的最近交互历史（如有）

### 4.7 Gas 估算策略

#### EIP-1559 链（Ethereum、Polygon、Arbitrum、Optimism、Base 等）

- 调用 `eth_feeHistory` 获取历史 gas 数据
- 提供三档选择：慢（节省费用）/ 标准 / 快（优先确认）
- 支持用户自定义 `maxFeePerGas` 和 `maxPriorityFeePerGas`

#### Legacy 链（部分 L2 或旧链）

- 调用 `eth_gasPrice` 获取当前 gas 价格
- 允许用户手动调整 `gasPrice`

#### 通用规则

- 使用 `eth_estimateGas` 估算 gas limit
- 在估算值基础上增加 10-20% buffer，防止 out of gas
- Gas 不足时明确提示用户，不静默失败
- 交易确认页展示预估费用（以当前法币价格换算）

### 4.8 助记词备份安全

- 创建钱包后强制进入备份流程
- 展示助记词后要求用户验证（随机抽取 3-4 个词填写确认）
- 未完成备份验证的钱包在首页持续提醒
- 可选高级功能：Shamir 秘密分片备份（SSS），将助记词拆分为多份

## 5. Flutter 侧技术选型

### 5.1 状态管理：Riverpod

- 类型安全、编译时检查，适合多钱包/多账户的复杂状态树
- 天然支持异步状态（RPC 调用、加密操作等）
- 社区活跃，与 Flutter 生态融合好
- 对开源项目友好，学习曲线合理

### 5.2 本地数据库：drift (SQLite)

- 类型安全的 SQL 封装，支持复杂查询和数据迁移
- 适合交易历史、网络配置等结构化数据
- 支持 schema 版本管理，配合升级迁移策略

### 5.3 路由：go_router

- 声明式路由，嵌套路由支持多 tab 页面
- Deep link 支持（V2 WalletConnect 回调需要）
- 路由守卫实现认证状态检查（未解锁时重定向到锁屏页）

### 5.4 数据模型：freezed

- 生成不可变数据类，减少状态相关 bug
- 自动生成 `copyWith`、`==`、`hashCode`、JSON 序列化
- 配合 Riverpod 使用，状态变化可追踪

### 5.5 Flutter 依赖参考

```yaml
dependencies:
  drift: ^2.22.0                  # 本地数据库 (SQLite)
  drift_flutter: ^0.2.0           # drift SQLite 连接（替代 sqlite3_flutter_libs）
  flutter_riverpod: ^3.0.0        # 状态管理 (Riverpod 3.x, auto-dispose 默认)
  flutter_rust_bridge: ^2.7.0     # Rust FFI 桥接
  flutter_secure_storage: ^9.2.0  # Keychain/Keystore 封装
  freezed_annotation: ^3.0.0      # 不可变数据模型 (freezed 3.x, sealed class)
  go_router: ^14.8.0              # 路由
  json_annotation: ^4.9.0         # JSON 序列化注解
  local_auth: ^2.3.0              # 生物识别
  path: ^1.9.0                    # 路径工具
  path_provider: ^2.1.0           # 文件路径
  riverpod_annotation: ^3.0.0     # Riverpod 代码生成注解

dev_dependencies:
  build_runner: ^2.4.0            # 构建工具
  custom_lint: ^0.7.0             # 自定义 lint 框架
  drift_dev: ^2.22.0              # drift 代码生成
  freezed: ^3.0.0                 # freezed 代码生成
  json_serializable: ^6.9.0       # JSON 序列化代码生成
  mocktail: ^1.0.0                # 测试 Mock（无需代码生成）
  riverpod_generator: ^3.0.0      # Riverpod 代码生成
  riverpod_lint: ^3.0.0           # Riverpod 专用 lint 规则
  very_good_analysis: ^7.0.0      # 严格 lint 规则集
```

## 6. 数据存储方案

### 6.1 Keychain / Keystore 中存储的数据

| Key                     | Value                          | 说明                     |
| ----------------------- | ------------------------------ | ------------------------ |
| `wallet_{id}_mnemonic`  | nonce + 密文 + tag             | Argon2id + AES-GCM 加密 |
| `wallet_{id}_salt`      | 16 bytes random salt           | Argon2id 的 salt         |
| `wallet_{id}_argon2_params` | memory, iterations, parallelism | 动态校准后的 Argon2id 参数 |
| `wallet_{id}_auth_key`  | 加密密钥（生物识别保护）       | 生物识别快速解锁用       |

### 6.2 本地数据库（明文，非敏感）

| 数据           | 说明                                   |
| -------------- | -------------------------------------- |
| 钱包元数据     | 名称、创建时间、备份状态               |
| 账户地址列表   | 公开地址（非敏感）                     |
| 自定义网络配置 | RPC URL、chainId、代币符号             |
| 交易历史缓存   | 本地缓存，可从链上重建                 |
| 用户偏好设置   | 货币单位、语言、主题                   |

## 7. 多钱包与多账户

- 每个钱包独立的助记词、salt、加密密文
- BIP-44 路径：`m/44'/60'/0'/0/{index}` 派生多账户
- 每个账户的私钥按需从助记词派生，不单独存储
- 切换钱包需重新认证（密码或生物识别）

## 8. 多链支持

### 8.1 内置链配置（优先级从高到低）

| 优先级 | 链                                    | 类型       |
| ------ | ------------------------------------- | ---------- |
| P0     | Ethereum Mainnet + Sepolia (测试网)   | EIP-1559   |
| P1     | Polygon / Arbitrum / Optimism / Base  | EIP-1559   |
| P2     | BSC / Avalanche C-Chain               | Legacy/混合 |
| P3     | 用户自定义 RPC                        | 自动检测   |

### 8.2 链配置数据结构

每条链需存储以下信息：

- `chainId`：链 ID
- `name`：链名称
- `symbol`：原生代币符号
- `decimals`：原生代币精度
- `rpcUrls`：RPC 地址列表（主 + 备用，至少 2 个）
- `explorerUrl`：区块浏览器 URL
- `gasType`：gas 类型（`eip1559` / `legacy`）
- `isTestnet`：是否为测试网

### 8.3 RPC 高可用策略

- 每条链至少配置 2 个 RPC endpoint（主 + 备用）
- 健康检查：定期调用 `eth_blockNumber`，响应超时（>5 秒）或区块高度明显落后则自动切换
- 用户自定义 RPC 优先级最高
- 连接失败时自动 failover 到备用节点，UI 提示当前连接状态

## 9. 升级与迁移策略

- 加密数据附带版本号标识（如 `v1`）
- 未来升级加密方案时，通过版本号判断并执行迁移
- 迁移流程：旧方案解密 → 新方案加密 → 更新版本号
- 迁移过程中确保原数据不丢失（先写新数据，验证后再删旧数据）

## 10. Rust Crate 依赖（参考）

```toml
[dependencies]
# FFI 桥接
flutter_rust_bridge = "2"

# 以太坊
alloy = { version = "0.12", features = ["full"] }  # 锁定具体版本，定期审查更新

# 密码学
argon2 = "0.5"
aes-gcm = "0.10"
rand = "0.8"          # 必须使用 OsRng (CSPRNG)，禁止 thread_rng

# BIP 标准
bip39 = "2"            # 确认多语言助记词支持

# 内存安全
zeroize = { version = "1", features = ["derive"] }
secrecy = "0.8"        # Secret<T> 包装，防止 Debug/Display 泄露敏感数据

# 内存锁定
libc = "0.2"           # 直接使用 libc::mlock/munlock，减少间接依赖

# 错误处理
thiserror = "1"        # 统一错误类型，清晰的 FFI 错误传递
```

## 11. 测试方案

分三层测试策略：Rust 独立测试 → Flutter 独立测试（Mock Rust）→ 集成测试（真机）。

### 11.1 Rust 层测试

#### 单元测试（内联 `#[cfg(test)]`）

每个模块文件底部包含自己的单元测试，这是 Rust 惯用做法。单元测试可以访问私有函数。

```rust
// rust/src/crypto/encryption.rs

pub fn encrypt(key: &[u8], plaintext: &[u8]) -> Result<Vec<u8>, CryptoError> {
    // ... 实现
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let key = [0u8; 32];
        let plaintext = b"hello world";
        let ciphertext = encrypt(&key, plaintext).unwrap();
        let decrypted = decrypt(&key, &ciphertext).unwrap();
        assert_eq!(plaintext.to_vec(), decrypted);
    }

    #[test]
    fn test_encrypt_invalid_key_length() {
        let short_key = [0u8; 16];
        let result = encrypt(&short_key, b"data");
        assert!(result.is_err());
    }
}
```

运行命令：`cargo test`（在 `rust/` 目录下）

#### 集成测试（`rust/tests/` 目录）

每个文件编译为独立 crate，只能访问公开 API，验证跨模块完整流程：

```
rust/tests/
├── common/
│   └── mod.rs                  # 共享 fixtures（测试助记词、测试密码等）
├── crypto_integration.rs       # 完整加密流程：密码→Argon2id→AES-GCM→解密→比对
├── wallet_integration.rs       # 助记词→创建钱包→派生账户→验证地址
└── transaction_integration.rs  # 构建交易→签名→验证签名→编码
```

```rust
// rust/tests/crypto_integration.rs
use unvault_core::crypto::{argon2, encryption, mnemonic};

mod common;

#[test]
fn test_full_wallet_encryption_flow() {
    // 1. 生成助记词
    let mnemonic = mnemonic::generate(12).unwrap();
    // 2. 用密码派生加密密钥
    let salt = common::random_salt();
    let key = argon2::derive_key(b"test_password", &salt, &common::test_params()).unwrap();
    // 3. 加密助记词
    let ciphertext = encryption::encrypt(&key, mnemonic.as_bytes()).unwrap();
    // 4. 解密并验证
    let decrypted = encryption::decrypt(&key, &ciphertext).unwrap();
    assert_eq!(mnemonic.as_bytes(), decrypted.as_slice());
}
```

#### 属性测试（proptest）

对密码学函数使用属性测试验证不变量，发现边界情况：

```rust
// 在单元测试或集成测试中使用
use proptest::prelude::*;

proptest! {
    #[test]
    fn encryption_roundtrip_any_input(plaintext in proptest::collection::vec(any::<u8>(), 0..1024)) {
        let key = test_key();
        let ciphertext = encrypt(&key, &plaintext).unwrap();
        let decrypted = decrypt(&key, &ciphertext).unwrap();
        prop_assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn key_derivation_deterministic(password in ".{8,64}") {
        let salt = [0u8; 16];
        let params = test_params();
        let key1 = derive_key(password.as_bytes(), &salt, &params).unwrap();
        let key2 = derive_key(password.as_bytes(), &salt, &params).unwrap();
        prop_assert_eq!(key1, key2);
    }
}
```

#### 性能基准测试（criterion）

验证密码学操作性能在可接受范围内：

```
rust/benches/
├── argon2_bench.rs     # 不同参数组合下的 Argon2id 耗时
└── signing_bench.rs    # 交易签名耗时
```

运行命令：`cargo bench`

#### Rust 测试依赖

```toml
# rust/Cargo.toml
[dev-dependencies]
proptest = "1.4"                    # 属性测试
criterion = { version = "0.5", features = ["html_reports"] }  # 性能基准
tokio = { version = "1", features = ["rt", "macros"] }       # 异步测试

[[bench]]
name = "argon2_bench"
harness = false

[[bench]]
name = "signing_bench"
harness = false
```

#### Rust 覆盖率目标

| 模块 | 覆盖率目标 | 说明 |
|------|-----------|------|
| `crypto/` | ≥ 90% | 核心密码学逻辑，必须高覆盖 |
| `wallet/` | ≥ 85% | 钱包管理逻辑 |
| `transaction/` | ≥ 85% | 交易构建与签名 |
| `api/` | ≥ 70% | 薄包装层，主要靠集成测试覆盖 |
| **整体** | **≥ 80%** | |

覆盖率工具：`cargo tarpaulin`（CI 中自动运行并上报）

### 11.2 Flutter 层测试

#### 单元测试（`test/unit/`）

测试纯 Dart 逻辑（Service、Repository、工具函数），Mock 掉 Rust 层：

```dart
// test/mocks/mock_rust_lib_api.dart
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/rust/frb_generated.dart';

class MockRustLibApi extends Mock implements RustLibApi {}
```

```dart
// test/unit/features/wallet/wallet_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../mocks/mock_rust_lib_api.dart';

void main() {
  late MockRustLibApi mockRustApi;

  setUp(() {
    mockRustApi = MockRustLibApi();
    // 注入 mock 到 FRB
    RustLib.init(api: mockRustApi);
  });

  group('WalletService', () {
    test('创建钱包返回正确结构', () async {
      when(() => mockRustApi.generateMnemonic(wordCount: 12))
          .thenAnswer((_) async => testMnemonicBytes);

      final wallet = await walletService.createWallet(name: 'Test');
      expect(wallet.name, equals('Test'));
      verify(() => mockRustApi.generateMnemonic(wordCount: 12)).called(1);
    });

    test('密码不足8位时抛出异常', () {
      expect(
        () => walletService.setPassword('short'),
        throwsA(isA<PasswordTooShortException>()),
      );
    });
  });
}
```

#### Widget 测试（`test/widget/`）

测试 UI 组件的渲染和交互，使用 `ProviderScope` 覆写依赖：

```dart
// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: widget),
      ),
    );
  }
}
```

```dart
// test/widget/features/auth/lock_screen_test.dart
void main() {
  testWidgets('输入正确密码后解锁', (tester) async {
    await tester.pumpApp(
      const LockScreen(),
      overrides: [authProvider.overrideWith(() => MockAuthNotifier())],
    );

    await tester.enterText(find.byType(TextField), 'correct_password');
    await tester.tap(find.text('解锁'));
    await tester.pumpAndSettle();

    expect(find.byType(LockScreen), findsNothing);
  });
}
```

#### Golden 截图测试（`test/golden/`）

验证 UI 视觉一致性，防止意外样式变更：

```dart
// test/golden/wallet_card_golden_test.dart
void main() {
  testWidgets('WalletCard golden', (tester) async {
    await tester.pumpApp(
      WalletCard(wallet: testWallet, balance: '1.5 ETH'),
    );
    await expectLater(
      find.byType(WalletCard),
      matchesGoldenFile('goldens/ci/wallet_card.png'),
    );
  });
}
```

更新基准图片：`flutter test --update-goldens`

#### Flutter 测试依赖

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0           # Mock（无需代码生成，比 mockito 简洁）
  flutter_riverpod: ^2.x     # ProviderScope 测试覆写
```

### 11.3 集成测试（跨层）

#### FFI 桥接验证

在真机/模拟器上运行，验证 Dart ↔ Rust 实际调用链路：

```dart
// integration_test/ffi_bridge_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unvault/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();  // 初始化真实 Rust 库
  });

  testWidgets('Rust 助记词生成返回12个词', (tester) async {
    final mnemonicBytes = await generateMnemonic(wordCount: 12);
    final words = String.fromCharCodes(mnemonicBytes).split(' ');
    expect(words.length, equals(12));
  });

  testWidgets('加密解密 round-trip', (tester) async {
    final plaintext = Uint8List.fromList(utf8.encode('test data'));
    final password = Uint8List.fromList(utf8.encode('test_password_123'));
    final encrypted = await encryptData(password: password, data: plaintext);
    final decrypted = await decryptData(password: password, data: encrypted);
    expect(decrypted, equals(plaintext));
  });
}
```

运行命令：`flutter test integration_test/`（需连接设备或模拟器）

#### 端到端流程测试

```dart
// integration_test/wallet_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整钱包创建流程', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. 点击创建钱包
    await tester.tap(find.text('创建钱包'));
    await tester.pumpAndSettle();

    // 2. 设置密码
    await tester.enterText(find.byKey(Key('password')), 'MyPassword123');
    await tester.enterText(find.byKey(Key('confirm')), 'MyPassword123');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // 3. 验证助记词页面出现
    expect(find.text('请妥善保管助记词'), findsOneWidget);
  });
}
```

### 11.4 测试层次总结

```
┌─────────────────────────────────────────────────────┐
│  集成测试（integration_test/）                      │
│  真机运行，验证完整用户流程                         │
│  运行频率：每次 Release 前 + 核心功能变更时         │
├─────────────────────────────────────────────────────┤
│  FFI 桥接测试（integration_test/）                  │
│  真机运行，验证 Dart ↔ Rust 调用链路               │
│  运行频率：FFI 接口变更时                           │
├─────────────────────────────────────────────────────┤
│  Flutter Widget 测试 + Golden 测试（test/widget/）  │
│  无需设备，验证 UI 渲染和交互                       │
│  运行频率：每次 PR                                  │
├─────────────────────────────────────────────────────┤
│  Flutter 单元测试（test/unit/）                     │
│  无需设备，Mock Rust 层，验证 Dart 业务逻辑         │
│  运行频率：每次 PR                                  │
├─────────────────────────────────────────────────────┤
│  Rust 集成测试（rust/tests/）                       │
│  验证跨模块完整流程                                 │
│  运行频率：每次 PR                                  │
├─────────────────────────────────────────────────────┤
│  Rust 单元测试（内联 #[cfg(test)]）                 │
│  验证单个函数/模块的正确性                          │
│  运行频率：每次 PR                                  │
└─────────────────────────────────────────────────────┘
```

### 11.5 安全专项测试

| 测试类别 | 内容 | 工具/方法 |
|---------|------|----------|
| 加密 round-trip | 加密→解密→比对，任意输入 | proptest |
| 密钥唯一性 | 不同 salt 生成不同密钥 | 单元测试 |
| zeroize 验证 | 敏感变量 drop 后内存归零 | 单元测试 + unsafe 检查 |
| 错误路径 zeroize | 加密失败时密钥仍被清除 | 单元测试 |
| BIP-39 向量 | 官方测试向量验证助记词正确性 | 集成测试 |
| BIP-44 向量 | 官方测试向量验证密钥派生正确性 | 集成测试 |
| EIP-155 签名 | 已知交易的签名比对 | 集成测试 |
| CSPRNG 审查 | 确认所有随机数来源为 OsRng | clippy lint + 代码审查 |

## 12. 代码审查规范

### 12.1 PR 流程

```
feature 分支 → 提交 PR → 自动化检查通过 → 人工 Review → Approve → Squash Merge → 删除分支
```

#### 分支策略

- `main`：稳定分支，只接受 PR 合入，永远可构建
- `feature/*`：功能开发分支，从 `main` 切出
- `fix/*`：Bug 修复分支
- `security/*`：安全修复分支（优先级最高）
- 合并方式：Squash Merge（保持 main 历史线性清晰）

#### PR 要求

- **标题**：遵循 Conventional Commits 格式（`feat: 添加多链切换功能`）
- **描述**：说明改了什么、为什么改、如何测试
- **检查清单**（PR 模板强制）：

```markdown
## PR 检查清单

### 必选
- [ ] 代码已通过本地 `cargo test` 和 `flutter test`
- [ ] 新增代码有对应测试
- [ ] 无编译警告（Rust clippy + Flutter analyze 均通过）
- [ ] 自动生成代码已更新（`flutter_rust_bridge_codegen generate`）

### 安全相关（涉及密码学/密钥/敏感数据时必选）
- [ ] 敏感类型实现 Zeroize + ZeroizeOnDrop
- [ ] FFI 边界无明文字符串传递
- [ ] 无日志输出敏感信息
- [ ] 随机数使用 OsRng

### 可选
- [ ] 更新了相关文档
- [ ] 涉及 UI 变更时附截图
```

### 12.2 Review 标准

#### 通用标准

- 代码可读性：命名清晰、逻辑简洁、无不必要的复杂度
- 测试充分性：新功能有测试、bug 修复有回归测试
- 错误处理：不 unwrap 生产代码、错误信息有意义
- 无性能退化：避免不必要的内存分配、克隆

#### Rust 专项 Review 重点

| 检查项 | 要求 |
|--------|------|
| 内存安全 | 敏感数据使用 `Secret<T>` 包装，实现 `Zeroize` |
| 错误处理 | 使用 `thiserror` 自定义错误，禁止在库代码中 `unwrap()`/`expect()` |
| 随机数 | 密码学场景全部使用 `OsRng`，禁止 `thread_rng` |
| 可见性 | 最小化 `pub` 暴露，优先 `pub(crate)` |
| 依赖安全 | 新增 crate 需评估维护状况和 `cargo audit` 结果 |
| unsafe | 禁止无注释的 `unsafe` 块，每个 unsafe 必须说明安全不变量 |

#### Flutter 专项 Review 重点

| 检查项 | 要求 |
|--------|------|
| 敏感数据 | 只用 `Uint8List`，禁止转为 `String` |
| 状态管理 | Provider 声明位置正确，不在 Widget 中直接操作 Repository |
| Widget 粒度 | 避免超过 200 行的 build 方法，合理拆分 |
| 资源释放 | dispose 中释放 controller、subscription |
| 硬编码 | 字符串走 localization，颜色走 theme |

### 12.3 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

| Type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `security` | 安全修复（触发优先级最高的 review） |
| `refactor` | 重构（无功能变化） |
| `test` | 测试相关 |
| `docs` | 文档 |
| `ci` | CI/CD 配置 |
| `chore` | 构建/工具/依赖 |

Scope 示例：`feat(wallet): 添加多账户派生功能`、`fix(crypto): 修复 Argon2id 参数校准边界问题`

## 13. CI/CD 方案

### 13.1 Workflow 总览

```
.github/workflows/
├── rust.yml        # Rust 检查（每次 PR + push main）
├── flutter.yml     # Flutter 检查（每次 PR + push main）
├── build.yml       # 跨平台构建（push main + tag）
└── audit.yml       # 安全审计（每日定时 + 依赖文件变更）
```

### 13.2 Rust CI（`.github/workflows/rust.yml`）

触发条件：PR 到 main + push 到 main

```yaml
name: Rust CI

on:
  push:
    branches: [main]
    paths: ['rust/**']
  pull_request:
    branches: [main]
    paths: ['rust/**']

env:
  CARGO_TERM_COLOR: always

defaults:
  run:
    working-directory: rust

jobs:
  fmt:
    name: 格式检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --check

  clippy:
    name: Lint 检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - uses: Swatinem/rust-cache@v2
        with:
          workspaces: rust
      - run: cargo clippy --all-targets --all-features -- -D warnings

  test:
    name: 测试
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
        with:
          workspaces: rust
      - run: cargo test --all-features --all-targets

  coverage:
    name: 覆盖率
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
        with:
          workspaces: rust
      - uses: taiki-e/install-action@cargo-tarpaulin
      - run: cargo tarpaulin --out xml --output-dir coverage
      - uses: codecov/codecov-action@v4
        with:
          files: rust/coverage/cobertura.xml
          flags: rust
```

### 13.3 Flutter CI（`.github/workflows/flutter.yml`）

触发条件：PR 到 main + push 到 main

```yaml
name: Flutter CI

on:
  push:
    branches: [main]
    paths-ignore: ['rust/**', 'docs/**']
  pull_request:
    branches: [main]
    paths-ignore: ['rust/**', 'docs/**']

jobs:
  analyze:
    name: 分析与格式检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart format --set-exit-if-changed lib/ test/
      - run: flutter analyze --fatal-infos

  test:
    name: 单元测试 + Widget 测试
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          flags: flutter

  golden:
    name: Golden 截图测试
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter test test/golden/

  codegen-check:
    name: 生成代码一致性检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: dtolnay/rust-toolchain@stable
      - run: flutter pub get
      - run: flutter_rust_bridge_codegen generate
      - run: dart run build_runner build --delete-conflicting-outputs
      - name: 检查生成代码是否最新
        run: git diff --exit-code
```

### 13.4 跨平台构建（`.github/workflows/build.yml`）

触发条件：push 到 main + 创建 tag（`v*`）

```yaml
name: Build

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build-android:
    name: 构建 Android APK
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: dtolnay/rust-toolchain@stable
        with:
          targets: aarch64-linux-android,armv7-linux-androideabi,x86_64-linux-android
      - uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: 17
      - name: 安装 cargo-ndk
        run: cargo install cargo-ndk
      - run: flutter pub get
      - run: flutter build apk --release --obfuscate --split-debug-info=build/debug-info
      - uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    name: 构建 iOS
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: dtolnay/rust-toolchain@stable
        with:
          targets: aarch64-apple-ios
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/debug-info
```

### 13.5 安全审计（`.github/workflows/audit.yml`）

触发条件：每日定时 + 依赖文件变更

```yaml
name: Security Audit

on:
  schedule:
    - cron: '0 8 * * *'    # 每日 UTC 8:00
  push:
    paths:
      - 'rust/Cargo.toml'
      - 'rust/Cargo.lock'
      - 'pubspec.yaml'
      - 'pubspec.lock'

jobs:
  rust-audit:
    name: Rust 依赖安全审计
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: taiki-e/install-action@cargo-deny
      - run: cargo deny check advisories
        working-directory: rust

  flutter-audit:
    name: Flutter 依赖检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter pub outdated
```

### 13.6 CI 检查总览

| 检查项 | 工具 | 触发时机 | 阻塞合入 |
|--------|------|---------|---------|
| Rust 格式 | `cargo fmt --check` | 每次 PR | 是 |
| Rust Lint | `cargo clippy -- -D warnings` | 每次 PR | 是 |
| Rust 测试 | `cargo test --all-features` | 每次 PR | 是 |
| Rust 覆盖率 | `cargo tarpaulin` → Codecov | 每次 PR | 否（仅报告） |
| Rust 安全审计 | `cargo deny check advisories` | 每日 + 依赖变更 | 是（PR 中） |
| Dart 格式 | `dart format --set-exit-if-changed` | 每次 PR | 是 |
| Flutter 分析 | `flutter analyze --fatal-infos` | 每次 PR | 是 |
| Flutter 测试 | `flutter test --coverage` | 每次 PR | 是 |
| Golden 测试 | `flutter test test/golden/` | 每次 PR | 是 |
| 生成代码一致性 | codegen + `git diff --exit-code` | 每次 PR | 是 |
| Android 构建 | `flutter build apk --release` | push main / tag | 否 |
| iOS 构建 | `flutter build ios --no-codesign` | push main / tag | 否 |

### 13.7 Dependabot 配置

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: cargo
    directory: /rust
    schedule:
      interval: weekly
    reviewers:
      - "unvault-security-team"

  - package-ecosystem: pub
    directory: /
    schedule:
      interval: weekly

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: monthly
```

## 14. 开源项目规范

### 14.1 代码架构

- Rust 核心层作为独立 crate（如 `unvault-core`）发布，方便社区独立审计
- 关键密码学逻辑添加详细注释和参考标准文档链接（如 BIP-39 RFC、NIST SP 800-63B 等）
- 提供 Threat Model 文档，明确安全假设和信任边界

### 14.2 代码质量

- Rust：`clippy`（deny warnings）+ `rustfmt` 强制格式化
- Flutter：`flutter analyze` + 自定义 lint 规则（`analysis_options.yaml`）
- 提交规范：Conventional Commits（`feat:`, `fix:`, `security:`, `docs:` 等）
- 代码覆盖率追踪（Codecov 集成，PR 中自动注释覆盖率变化）

### 14.3 文档

- 安全架构文档（`docs/THREAT_MODEL.md`，给审计者和安全研究者）
- 密码学方案详细说明（`docs/CRYPTO_SPEC.md`，给社区 review，包含参考标准和选型理由）
- 架构决策记录（`docs/ARCHITECTURE.md`）
- 贡献指南（`CONTRIBUTING.md`）
- CHANGELOG（跟随 Conventional Commits 自动生成）

## 15. 版本路线图

### V1 - 核心钱包

| 模块 | 功能 |
|------|------|
| 钱包管理 | 创建/导入钱包、助记词备份与验证、多钱包切换 |
| 账户管理 | BIP-44 多账户派生、地址展示与二维码 |
| 交易 | ETH/原生代币转账、交易确认与签名、交易历史 |
| 多链 | 内置主流 EVM 链配置、自定义 RPC、链切换 |
| 安全 | 密码加密、生物识别、内存安全、应用防护全套 |

### V2 - 生态扩展

| 模块 | 功能 |
|------|------|
| dApp 交互 | WalletConnect v2、EIP-712 类型化签名 |
| Token | ERC-20 余额与转账、ERC-721/1155 NFT 展示 |
| 硬件安全 | Secure Enclave / StrongBox 密钥绑定 |
| 高级备份 | Shamir 秘密分片备份（SSS） |

### 未来展望

- 多签钱包支持
- 硬件钱包集成（Ledger、Trezor）
- 链上治理参与（投票、委托）
- 跨链桥集成

## 16. 开发检查清单

### V1 核心功能

#### Rust 核心层
- [ ] 助记词生成/验证 (BIP-39)
- [ ] HD 密钥派生 (BIP-44)
- [ ] Argon2id 密钥派生 + 动态参数校准
- [ ] AES-256-GCM 加密/解密
- [ ] 交易构建与签名 (alloy)
- [ ] Gas 估算逻辑（EIP-1559 / Legacy）
- [ ] 统一错误类型 (thiserror)

#### FFI 桥接
- [ ] flutter_rust_bridge v2 集成
- [ ] FFI 边界敏感数据传递验证（仅 Vec<u8> / Uint8List）

#### 平台层
- [ ] iOS Keychain 读写（含 Argon2id 参数存储）
- [ ] Android Keystore 读写
- [ ] 生物识别认证集成（auth_key 安全设计）

#### Flutter UI
- [ ] 钱包创建/导入流程
- [ ] 助记词备份与验证流程
- [ ] 密码设置与解锁（≥8 位 + 强度指示器）
- [ ] 交易发送与确认（含 Gas 三档选择）
- [ ] 多链/多账户管理
- [ ] 地址簿功能
- [ ] 交易历史页面
- [ ] 设置页面（锁定时间、货币单位、语言、网络管理）

#### 安全
- [ ] 内存 zeroize 全路径覆盖 + secrecy 包装
- [ ] mlock 内存锁定（含 iOS 降级处理）
- [ ] 截屏/录屏防护
- [ ] 剪贴板自动清除
- [ ] 密码暴力破解防护（指数退避 + 锁定）
- [ ] Root/越狱检测
- [ ] Public Key Pinning（含备用公钥）
- [ ] 后台自动锁定 + 隐私遮罩
- [ ] 地址投毒防护（完整展示 + 首次转账警告）
- [ ] 代码混淆与 symbol strip
- [ ] 日志脱敏审查
- [ ] CSPRNG 使用审查（全部使用 OsRng）

#### 开源与工程
- [ ] CI/CD 搭建（GitHub Actions）
- [ ] cargo audit + clippy + rustfmt 集成
- [ ] flutter analyze + lint 规则配置
- [ ] Conventional Commits 规范
- [ ] Rust 核心层独立 crate 发布
- [ ] Threat Model 安全文档
- [ ] CONTRIBUTING.md 贡献指南

#### 测试
- [ ] Rust 核心层单元测试（覆盖率 ≥ 80%）
- [ ] 加密/解密 round-trip 测试
- [ ] Argon2id 参数校准测试
- [ ] FFI 边界集成测试
- [ ] 多设备/多平台兼容性测试

### V2 扩展功能

- [ ] WalletConnect v2 集成
- [ ] EIP-712 类型化数据签名
- [ ] ERC-20 Token 管理（检测、余额、转账）
- [ ] ERC-721/1155 NFT 展示
- [ ] Secure Enclave / StrongBox 硬件密钥绑定
- [ ] Shamir 秘密分片备份（SSS）

## Changelog

### 2026-03-03

- **[Section 5.5]** 更新 Flutter 依赖版本（架构师 Review 后确认）：
  - Riverpod `^2.x` → `^3.0.0`（3.x 默认 auto-dispose，统一 Ref API）
  - freezed `^2.x` → `^3.0.0`（3.x 使用 sealed class，集合自动不可变）
  - 新增 `drift_flutter: ^0.2.0`（替代 `sqlite3_flutter_libs`，drift 官方推荐）
  - 新增 `riverpod_annotation: ^3.0.0` + `riverpod_generator: ^3.0.0`（代码生成方式）
  - 新增 `riverpod_lint: ^3.0.0` + `custom_lint: ^0.7.0`（Riverpod 专用 lint）
  - 新增 `very_good_analysis: ^7.0.0`（替代 `flutter_lints`，更严格的 lint 规则）
  - 新增 `json_annotation` / `json_serializable`（freezed 3.x 依赖）
  - 新增 `flutter_rust_bridge: ^2.7.0`（明确 FFI 桥接版本）
  - 新增 `path_provider` / `path`（文件路径工具）
  - 新增 `mocktail: ^1.0.0`（测试 Mock 框架）
