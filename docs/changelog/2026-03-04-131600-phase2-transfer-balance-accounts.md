# feat(phase2): implement transfer, balance, accounts, history, settings, and network management

- **时间**: 2026-03-04 13:16
- **类型**: feat
- **模块**: core/services, core/database, core/providers, features/transfer, features/wallet, features/history, features/network, features/settings, features/auth, routing, api/transaction

## 变更意图

实现 Phase 2 MVP 的 17 个任务，覆盖完整的 ETH 转账流程（Send → Confirm → Sign → Broadcast → Result）、余额显示、多钱包多账户管理、交易历史、链切换、网络管理、设置页面。Rust 层新增 `sign_transaction_with_seed` 保持私钥完全在 Rust 内部，不跨越 FFI 边界。

## 变更内容

### Core 层
- `lib/src/core/services/eth_rpc_service.dart` — 新增 Ethereum JSON-RPC 服务（getBalance, getTransactionCount, estimateGas, getEip1559Fees, sendRawTransaction, getTransactionReceipt）
- `lib/src/core/database/daos/accounts_dao.dart` — 新增 AccountsDao（getAccountsForWallet, getAccount, insertAccount, countAccountsForWallet）
- `lib/src/core/database/daos/networks_dao.dart` — 新增 NetworksDao（getAllNetworks, getByChainId, upsertNetwork, deleteNetwork, getCustomNetworks）
- `lib/src/core/database/daos/transactions_dao.dart` — 新增 TransactionsDao（getTransactionsForAddress, upsertTransaction, countForAddress）
- `lib/src/core/database/app_database.dart` — 注册 AccountsDao、NetworksDao、TransactionsDao，添加 forTesting 构造函数
- `lib/src/core/providers/app_providers.dart` — 新增 appDatabase 和 ethRpcService 全局 Provider

### Transfer 功能
- `lib/src/features/transfer/domain/send_form_state.dart` — 新增 SendFormState freezed 模型（含 GasTier 枚举）
- `lib/src/features/transfer/application/send_notifier.dart` — 新增 SendNotifier（gas 估算、验证、tier 倍数调整）
- `lib/src/features/transfer/presentation/send_screen.dart` — 实现发送页面（地址输入、金额、gas tier 选择）
- `lib/src/features/transfer/presentation/confirm_transaction_screen.dart` — 实现确认交易页面（密码验证 → 解密助记词 → Rust 签名 → 广播）
- `lib/src/features/transfer/presentation/receive_screen.dart` — 实现接收页面（QR 码 + 地址复制）
- `lib/src/features/transfer/presentation/transaction_result_screen.dart` — 实现交易结果页面（成功/哈希/返回钱包）

### Wallet 功能
- `lib/src/features/wallet/domain/balance_model.dart` — 新增 TokenBalance freezed 模型
- `lib/src/features/wallet/application/balance_notifier.dart` — 新增 accountBalances Provider（跨链余额查询）
- `lib/src/features/wallet/application/active_wallet_notifier.dart` — 新增 ActiveWallet keepAlive Notifier（跟踪 walletId + accountId）
- `lib/src/features/wallet/application/wallet_notifier.dart` — 修改：传入 accountsDao 依赖
- `lib/src/features/wallet/data/wallet_repository.dart` — 修改：创建/导入钱包时自动插入首个账户
- `lib/src/features/wallet/presentation/wallet_list_screen.dart` — 重写为 Home 主屏幕（余额、操作按钮、资产列表）
- `lib/src/features/wallet/presentation/accounts_screen.dart` — 新增多钱包多账户管理页面

### History 功能
- `lib/src/features/history/domain/transaction_model.dart` — 新增 TransactionModel 领域模型
- `lib/src/features/history/data/history_repository.dart` — 新增 HistoryRepository（封装 TransactionsDao）
- `lib/src/features/history/application/history_notifier.dart` — 新增 transactionHistory Provider
- `lib/src/features/history/presentation/history_screen.dart` — 实现历史页面（日期分组、发送/接收图标、下拉刷新）

### Network 功能
- `lib/src/features/network/application/network_notifier.dart` — 新增 ActiveNetwork keepAlive Notifier
- `lib/src/features/network/data/network_repository.dart` — 新增 NetworkRepository（seedBuiltInChains, CRUD）
- `lib/src/features/network/presentation/chain_switch_sheet.dart` — 新增链切换 BottomSheet
- `lib/src/features/network/presentation/network_management_screen.dart` — 实现网络管理页面（内置链/自定义 RPC 增删）

### Settings 功能
- `lib/src/features/settings/presentation/settings_screen.dart` — 实现设置页面（安全/通用/关于三个分组）

### Routing
- `lib/src/routing/app_router.dart` — 重构为 StatefulShellRoute.indexedStack（Wallet/History/Settings 三 Tab）
- `lib/src/routing/route_names.dart` — 新增 transactionResult、accounts 路由名
- `lib/src/routing/scaffold_with_nav_bar.dart` — 新增 NavigationBar 底部导航壳

### Auth
- `lib/src/features/auth/presentation/lock_screen.dart` — 移除硬编码 walletId，改用 ActiveWallet

### Rust 层
- `rust/src/api/transaction_api.rs` — 新增 `sign_transaction_with_seed`（从助记词派生密钥 + 签名，私钥不出 Rust）

### 依赖
- `pubspec.yaml` — 新增 `http: ^1.6.0`、`qr_flutter: ^4.1.0`

### 测试
- `test/unit/core/services/eth_rpc_service_test.dart` — 15 个 RPC 服务单元测试
- `test/unit/core/database/daos/accounts_dao_test.dart` — 11 个 AccountsDao 测试
- `test/unit/features/network/data/network_repository_test.dart` — 11 个网络仓库测试
- `test/unit/features/history/data/history_repository_test.dart` — 13 个历史仓库测试
- `test/unit/features/wallet/data/wallet_repository_test.dart` — 更新：添加 AccountsDao mock
- `integration_test/send_flow_test.dart` — 5 个完整发送流程集成测试

## 备注

- **安全**: `sign_transaction_with_seed` 在 Rust 内部完成从助记词到签名的完整流程，私钥通过 `ZeroizeOnDrop` 在使用后自动清零，永不跨越 FFI 边界
- **安全**: Confirm 页面在签名完成后立即对助记词字节清零
- **测试覆盖**: Rust 141 测试（135 单元 + 6 集成），Flutter 62 测试，clippy 和 analyze 均无警告
- **后续 TODO**: ERC-20 代币支持、生物识别解锁集成、价格源集成、ENS 解析、WalletConnect v2、自动锁定定时器、交易状态轮询
