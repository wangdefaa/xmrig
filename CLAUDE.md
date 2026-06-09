# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

xxxig 是 [XMRig](https://github.com/xmrig/xmrig) 矿工的改造版，做了四件事：① **彻底移除开发者捐献（dev-fee）**；② 移植 [XMRigCC](https://github.com/Bendr0id/xmrigCC) 的**指挥控制（C&C）**能力；③ 用零依赖原生 `index.html` 重写 **Web 控制台**；④ 文档中文化。它是高性能 RandomX / KawPow / CryptoNight / GhostRider 的 CPU/GPU 矿工。

## 构建

本仓库可产出三个可执行文件：`xxxig`（矿工）、`xxxigServer`（C&C 服务器）、`xxxigDaemon`（矿工进程看护）。C&C 相关选项**默认全部 OFF**，只构建矿工。

```bash
mkdir build && cd build
# 仅矿工：
cmake .. -DCMAKE_BUILD_TYPE=Release
# 矿工 + C&C 全套：
cmake .. -DWITH_CC_CLIENT=ON -DWITH_CC_SERVER=ON -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

C&C 相关 CMake 选项：

| 选项 | 作用 |
|---|---|
| `WITH_CC_CLIENT` | 矿工内嵌 CC 客户端（定义 `XMRIG_FEATURE_CC_CLIENT`） |
| `WITH_CC_SERVER` | 构建 `xxxigServer` 与 `xxxigDaemon` |
| `WITH_CC_CLIENT_SHELL_EXECUTE` | 允许 C&C 下发 shell 命令（REBOOT/EXECUTE）——**不安全，默认 OFF** |

- 依赖（libuv / hwloc / OpenSSL 等）可用 `scripts/build.*.sh`、`scripts/build_deps.sh` 自行编译。
- 挖矿后端：CPU（默认）、OpenCL（AMD）、CUDA（NVIDIA，需外部 [xmrig-cuda](https://github.com/xmrig/xmrig-cuda) 插件）。
- 无单元测试框架；内置 RandomX benchmark/stress（`WITH_BENCHMARK`）。无 CI。
- 运行：`./xxxig -c config.json`，`./xxxig --help` 查看全部选项。`doc/` 为上游英文文档。

## 架构（big picture）

### 矿工核心
`src/xmrig.cpp` → `App` → `core/Controller`（持有 `Config`、`Miner`、`Network`）。
- `base/kernel/Base`：配置加载、文件监听与热重载，**同时是 CC Client 的宿主**（`Base.cpp` 中 `new CCClient(this)`，仅 `WITH_CC_CLIENT`）。
- `core/Miner`：挖矿调度，驱动 `backend/`（CPU / OpenCL / CUDA）。
- `net/Network`：连接矿池（`net/strategies`），分发 Job、提交结果。
- `crypto/`：算法实现（randomx、cn 系列、argon2、ghostrider、kawpow）。

### C&C 三件套（`src/cc/`，移植自 XMRigCC）
- **CC Client**（嵌入矿工）：由 `base/kernel/Base` 创建，周期向服务器上报 `ClientStatus`，并拉取/执行 `ControlCommand`——其中 `UPDATE_CONFIG` 触发配置热重载（见 `cc/CCClient.cpp`），`REBOOT`/`EXECUTE` 需 `WITH_CC_CLIENT_SHELL_EXECUTE`。配置类型 `cc/CCClientConfig`，命令行 `--cc-*` 经 `base/kernel/config/BaseTransform.cpp` 写入 `BaseConfig::kCCClient`。
- **xxxigServer**（入口 `cc/XMRigCC.cpp` → `cc/CCServer` + `cc/Service`）：基于 cpp-httplib 的 HTTP 服务；`Service.cpp` 路由 `/admin/*`（如 `getClientStatistics` 持久算力统计）。命令行用 cxxopts。
- **xxxigDaemon**（`cc/XMRigd.cpp`）：拉起并看护矿工进程。
- C&C 状态监听接口在 `base/cc/interfaces/`。

### Web 控制台
顶层 `index.html`（零依赖原生重写）由 `xxxigServer` 通过 `--custom-dashboard`（默认 `index.html`）提供，对接 `/admin/getClientStatistics` 等 API，并用 `UPDATE_CONFIG` 命令把编辑后的配置下发到矿机热重载。

### 配置系统（改动需多处同步）
新增/修改一个命令行配置项时，需同步改动：`base/kernel/interfaces/IConfig.h`（`Keys` 枚举）、`core/config/Config_platform.h`（`option` 表）、`base/kernel/config/BaseTransform.cpp`（命令行→JSON）、`core/config/usage.h`（`--help`）、`src/config.json`（默认）。矿池配置在 `base/net/stratum/Pools`。

## 改造版约定

- **去捐献**：已删除 `src/donate.h`、`net/strategies/DonateStrategy.*`，并移除 `donate-level` / `donate-over-proxy` 配置、命令行及 API 的 `donate_level` 字段。**新增功能时不要重新引入任何 donate 逻辑或字段。**
- **安全收敛**：`WITH_CC_CLIENT_SHELL_EXECUTE` 默认 OFF（避免控制端下发任意命令）；远程自更新（下发并替换二进制）已禁用——改动 C&C 时不要恢复这两项默认。
- 控制台 `index.html` 与中文 `README.md` 为本仓库自维护内容。

## 代码风格

- 沿用 XMRig 风格：文件头 GPL 注释、`xmrig` 命名空间、成员变量 `m_` 前缀、不可拷贝类用 `XMRIG_DISABLE_COPY_MOVE_DEFAULT` 宏。
- C&C 模块（`src/cc/`）使用 cpp-httplib 与 cxxopts；矿工与 C&C 通过编译期宏 `XMRIG_FEATURE_CC_CLIENT` / `XMRIG_FEATURE_CC_SERVER` 隔离，新增 C&C 代码注意用宏守卫，避免影响默认（无 C&C）构建。
