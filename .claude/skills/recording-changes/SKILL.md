---
name: recording-changes
description: Use when a code generation session is finishing or after completing implementation tasks, feature additions, bug fixes, or refactoring - records what changed and why to docs/changelog/
---

# Recording Changes

## Overview

Record a structured changelog entry after each code generation session. Captures timestamp, changed modules, intent, and affected files.

**Core principle:** Every code generation session gets a changelog entry before the session ends.

## When to Use

- After completing a feature, fix, refactor, or any code generation task
- Before using finishing-a-development-branch skill
- When user says "record changes", "记录变更", "write changelog"

**Do NOT use for:**
- Documentation-only edits (README, skills, config)
- Pure conversation/planning with no code changes

## Process

### Step 1: Gather Changed Files

```bash
git diff --name-only HEAD~1
# Or if multiple commits in session:
git diff --name-only <start-sha> HEAD
```

### Step 2: Identify Modules

Infer module names from the project's directory structure. Use the **first two meaningful path segments** as the module name:

```
src/auth/login.ts        → auth/login
app/models/user.rb       → models/user
rust/src/crypto/aes.rs   → crypto/aes
lib/src/features/home/   → features/home
packages/utils/math.dart → utils/math
```

**Rules:**
- Strip common prefixes (`src/`, `lib/src/`, `rust/src/`, `app/`)
- Use directory name as module, filename (without extension) as sub-module
- Group by top-level directory when listing in changelog

### Step 3: Write Entry

**Create directory if needed:**
```bash
mkdir -p docs/changelog
```

**File name:** `docs/changelog/YYYY-MM-DD-HHMMSS-<short-desc>.md`

**Template:**

```markdown
# <type>(<scope>): <short description>

- **时间**: YYYY-MM-DD HH:MM
- **类型**: feat / fix / refactor / security / test / docs
- **模块**: <逗号分隔的模块名>

## 变更意图

<1-3句话：为什么做这个变更>

## 变更内容

- `path/to/file` — <具体改了什么>

## 备注

<可选：安全影响、破坏性变更、后续 TODO。无则删除此节>
```

**Type 参考（如项目有 Conventional Commits 规范则从之）:**

| Type | Use |
|------|-----|
| feat | New feature |
| fix | Bug fix |
| security | Security fix |
| refactor | No behavior change |
| test | Tests only |
| docs / ci / chore | Non-code |

### Step 4: Commit

```bash
git add docs/changelog/<filename>.md
git commit -m "docs(changelog): record <short-desc>"
```

## Example

**File:** `docs/changelog/2026-03-03-143022-user-auth.md`

```markdown
# feat(auth): add JWT authentication middleware

- **时间**: 2026-03-03 14:30
- **类型**: feat
- **模块**: auth/middleware, auth/token, routes/protected

## 变更意图

实现 JWT 认证中间件，保护需要登录的 API 路由。Token 过期时间设为 24h，使用 RS256 签名。

## 变更内容

- `src/auth/middleware.ts` — 新增 verifyToken 中间件，校验 Authorization header
- `src/auth/token.ts` — 新增 sign/verify 工具函数，使用 RS256
- `src/routes/protected.ts` — 对 /api/user/* 路由应用认证中间件

## 备注

- 密钥从环境变量 JWT_PRIVATE_KEY 读取，不硬编码
```

## Common Mistakes

| 错误 | 正确做法 |
|------|----------|
| 忘记创建目录 | 先 `mkdir -p docs/changelog` |
| 意图太模糊："更新了模块" | 写清楚为什么："实现 JWT 认证保护 API 路由" |
| 只列文件不说改了什么 | 每个文件附带具体变更说明 |
| 用单个文件累积记录 | 每次独立文件，避免合并冲突 |
