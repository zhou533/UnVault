# unvault-core

UnVault 以太坊 HD 钱包的 Rust 密码学核心库。

## 架构概览

```
rust/src/
├── lib.rs                  # crate 入口
├── error.rs                # 统一错误类型
├── crypto/
│   ├── mnemonic.rs         # BIP-39 助记词
│   ├── key_derivation.rs   # BIP-44 HD 密钥派生
│   ├── argon2.rs           # Argon2id 密码→密钥派生
│   ├── encryption.rs       # AES-256-GCM 加解密
│   └── memory.rs           # 内存安全工具
└── models/
    └── mod.rs              # 共享类型（Address、ChainConfig）
```

## 功能模块

### 助记词 (`crypto::mnemonic`)

基于 BIP-39 标准的助记词生成、验证与种子派生。

- `generate(WordCount)` — 生成 12 或 24 个单词的助记词（使用 OsRng CSPRNG）
- `validate(&[u8])` — 验证助记词合法性（含校验和）
- `derive_seed(&[u8], &[u8])` — 从助记词 + 可选密码短语派生 64 字节种子

敏感数据通过 `SecretBox<MnemonicPhrase>` 封装，实现 `Zeroize + ZeroizeOnDrop`，无 `Debug`/`Display`。

### HD 密钥派生 (`crypto::key_derivation`)

基于 BIP-44 标准的以太坊分层确定性密钥派生。

- `derive_account(seed, index)` — 在路径 `m/44'/60'/0'/0/{index}` 派生单个账户
- `derive_accounts(seed, count)` — 批量派生（父密钥仅派生一次，效率更高）

地址计算流程：未压缩公钥 → keccak256 → 取后 20 字节 → EIP-55 校验和格式。

### Argon2id 密钥派生 (`crypto::argon2`)

将用户密码转换为 AES-256 加密密钥。

- `derive_key(password, salt, params)` — Argon2id 密钥派生
- `generate_salt()` — 生成 16 字节随机盐值
- `calibrate(target_ms)` — 根据设备性能动态校准参数

安全下限：内存 ≥ 32 MB，迭代次数 ≥ 2。参数验证在派生前强制执行。

### AES-256-GCM 加解密 (`crypto::encryption`)

对称加密保护助记词等敏感数据。

- `encrypt(key, plaintext)` — 加密，输出格式：`nonce(12) || 密文 || tag(16)`
- `decrypt(key, data)` — 解密并验证认证标签

每次加密使用 OsRng 生成随机 nonce，避免 nonce 重用风险。

### 内存安全 (`crypto::memory`)

防止敏感数据泄露到交换分区。

- `mlock_region` / `munlock_region` — 锁定/解锁内存页
- `LockedBuffer` — 自动尝试 mlock，drop 时 zeroize + munlock

在 iOS 沙箱等受限环境中，mlock 失败会优雅降级（zeroize 仍然有效）。

### 错误类型 (`error`)

通过 `thiserror` 实现的统一错误枚举 `UnvaultError`，覆盖所有加密操作的错误场景。错误信息**绝不包含**私钥、助记词等敏感数据。实现 `Send + Sync`，适配 FFI 场景。

### 共享类型 (`models`)

- 重导出 `alloy_primitives::Address`（EIP-55 校验和地址）
- `ChainConfig` — 链配置占位类型（Phase 2 多链支持）

## 安全规则

1. 所有随机数来自 `OsRng`（CSPRNG），绝不使用 `thread_rng`
2. 敏感类型全部实现 `Zeroize + ZeroizeOnDrop`，封装在 `SecretBox<T>` 中
3. 敏感类型无 `Debug` / `Display` 实现，防止意外日志泄露
4. FFI 边界仅传递 `Vec<u8>` / `&[u8]`，绝不传递 `String`
5. 错误信息不包含任何敏感数据

## 运行测试

```bash
# 全部测试（含单元测试 + 集成测试）
cargo test --all-targets

# 仅单元测试
cargo test --lib

# 仅集成测试
cargo test --test crypto_integration

# 指定模块测试
cargo test --lib crypto::mnemonic
cargo test --lib crypto::key_derivation
cargo test --lib crypto::argon2
cargo test --lib crypto::encryption
cargo test --lib crypto::memory

# 代码格式检查
cargo fmt --check

# 静态分析（零警告）
cargo clippy --all-targets -- -D warnings
```

## 运行基准测试

```bash
cargo bench
```

基准测试使用 Criterion，测量 Argon2id 在安全下限参数（32MB/2iter）和默认高参数（64MB/3iter）下的性能。

## 测试统计

| 模块 | 测试数 |
|------|--------|
| error | 12 |
| memory | 9 |
| encryption | 14（含 proptest） |
| mnemonic | 15 |
| argon2 | 14（含 proptest） |
| key_derivation | 13 |
| models | 3 |
| 集成测试 | 6 |
| **合计** | **87** (含 1 慢速 proptest) |

## 依赖说明

| 依赖 | 用途 |
|------|------|
| `coins-bip39` | BIP-39 助记词生成与验证 |
| `coins-bip32` | BIP-32/44 HD 密钥派生 |
| `alloy-primitives` | 以太坊地址（EIP-55）、keccak256 |
| `argon2` | Argon2id 密码→密钥派生 |
| `aes-gcm` | AES-256-GCM 对称加密 |
| `secrecy` | `SecretBox<T>` 敏感数据封装 |
| `zeroize` | 内存归零（drop 时自动清除） |
| `flutter_rust_bridge` | FFI 桥接（可选，feature-gated） |

## 构建要求

- Rust ≥ 1.75（edition 2021）
- 构建目标：`staticlib`（iOS）、`cdylib`（Android）、`lib`（测试）
