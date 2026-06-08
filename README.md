# XXXig（C&C 集成 · 无捐献 改造版）

[![License: GPL v3](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)

本项目基于 [XMRig](https://github.com/xmrig/xmrig) 改造，做了两件事：

1. **集成 XMRigCC 的指挥控制（C&C）能力**——把 [XMRigCC](https://github.com/Bendr0id/xmrigCC) 的远程管理三件套移植进原版 XMRig。
2. **彻底移除内置开发者捐献（dev-fee）**——原版默认抽取 1% 算力捐给作者矿池，本版已从源码层面删除，矿工 **100% 为你自己的矿池挖矿**。

XXXig 是一款高性能、开源、跨平台的 RandomX、KawPow、CryptoNight 与 [GhostRider](src/crypto/ghostrider/README.md) 统一 CPU/GPU 矿工。

## 本改造版特性

- **C&C 三件套**
  - `xxxig`：矿工，内嵌 CC Client，周期性向控制端上报状态、拉取指令。
  - `xxxigDaemon`：守护进程，负责拉起并看护矿工。
  - `xxxigServer`：控制端，集中管理多台矿机。
- **零捐献**：删除 `DonateStrategy`、`donate-level`/`donate-over-proxy` 配置、API 的 `donate_level` 字段及所有相关分支。挖矿核心不受影响。
- **安全收敛**
  - CC Client 的 **Shell 执行能力默认关闭**（`WITH_CC_CLIENT_SHELL_EXECUTE=OFF`），避免控制端下发任意命令。
  - **自更新（远程下发并替换二进制）已禁用**，因其等同于远程代码执行。

## 挖矿后端

- **CPU**（x86/x64/ARMv7/ARMv8/RISC-V）
- **OpenCL**：AMD GPU
- **CUDA**：NVIDIA GPU，经由外部 [CUDA 插件](https://github.com/xmrig/xmrig-cuda)

## 编译

```bash
mkdir build && cd build
cmake .. -DWITH_CC_CLIENT=ON -DWITH_CC_SERVER=ON -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

C&C 相关 CMake 选项（均默认 **OFF**，按需开启）：

| 选项 | 说明 |
|---|---|
| `WITH_CC_CLIENT` | 在矿工中编译 CC Client（状态上报 / 远程配置） |
| `WITH_CC_SERVER` | 编译 `xxxigServer` 控制端 |
| `WITH_CC_CLIENT_SHELL_EXECUTE` | 允许控制端下发 Shell 命令（**有安全风险，谨慎开启**） |

原版编译说明见 [XMRig 官方文档](https://xmrig.com/docs/miner/build)。

## 使用

推荐用 [JSON 配置文件](https://xmrig.com/docs/miner/config) 配置矿工，比命令行更灵活。重要选项可在运行时通过编辑配置文件或调用 [API](https://xmrig.com/docs/miner/api) 热更新，无需重启。

CC 相关命令行选项（如 `--cc-url`、`--cc-access-token`、`--cc-worker-id` 等）可通过 `./xmrig --help` 查看。

## 关于捐献

本改造版已彻底移除原版内置的 1% 开发者捐献。XMRig 与 XMRigCC 都是优秀的开源项目，在此向上游作者致谢；如你愿意支持上游开发，请访问其各自的官方仓库。

## 上游与许可

- 基础项目：[XMRig](https://github.com/xmrig)（作者 [xmrig](https://github.com/xmrig)、[sech1](https://github.com/SChernykh)）
- C&C 功能来源：[XMRigCC](https://github.com/Bendr0id/xmrigCC)
- 许可证：[GPL-3.0](LICENSE)
