# 小米10S（thyme）自编译内核 — SukiSU + KPM + SUSFS

## 这是什么

GitHub Actions 全自动编译内核，一次打进四个能力：

| 能力 | 说明 |
|---|---|
| **修崩溃** | 基于 4.19.325-CIP 稳定树（CIP 仍在维护 4.19 的 bpf 安全修复，含你崩溃的那个 use-after-free 一族） |
| **KPM** | `CONFIG_KPM=y`（KernelPatch 框架），你的 `kpm-selinux-filter.kpm` 可以复活 |
| **SukiSU** | setup.sh 源码集成（susfs-main 分支 = KSU + SUSFS 一起） |
| **SUSFS** | 内核级隐藏（`susfs4ksu` 模块从"死"变"活"） |

源码树：`HuTao77-Studio/android_kernel_xiaomi_thyme` 分支 `16.0`（A16/HyperOS3 向、2026 年还在活跃维护、含 `build.config.xiaomi.thyme`）。

## 操作步骤（你需要做的）

### ① GitHub 建一个**空**仓库
名字随意（如 `thyme-kernel-build`），**Public**（Actions 免费无限）。

### ② 推送本目录
```bash
cd "E:\新建文件夹 (2)\文件\.workbuddy\kernel_build"
git init
git add .github
git commit -m "thyme kernel builder"
git remote add origin https://github.com/<你的用户名>/thyme-kernel-build.git
git push -u origin main
```
（如果 GitHub 默认分支是 main，直接推 main；推前在本地 `git branch -M main`）

### ③ 跑 Actions
仓库页 → **Actions** 标签 → 左侧 **Build thyme kernel** → **Run workflow** →
参数保持默认（ksu_branch=`susfs-main`，enable_kpm=`true`，build_target=`auto`）→ Run。

### ④ 拿产物
跑完（约 20-50 分钟）→ 该次运行页底部 **Artifacts** → 下载 `thyme-kernel-SukiSU-KPM-SUSFS`，
里面有 `AnyKernel3-*.zip` 和裸 `Image`。

### ⑤ 刷入（先看下方⚠️）
```bash
fastboot flash boot AnyKernel3解包后的boot.img    # 或 TWRP 刷 AnyKernel3 zip
```
**回滚（任何时候）**：
```bash
fastboot flash boot "E:\新建文件夹 (2)\文件\reboot_diag_1015\boot_backup_skydev_current.img"
```

## ⚠️ 刷前必读

1. **首次编译可能失败**——正常！看 Actions 日志的红色步骤：
   - "Detect defconfig" 失败 → 日志会列出所有 defconfig 名，把对的告诉我，改 workflow 里的候选列表
   - "Build kernel" 失败 → 把日志尾部贴给我（多半是 clang 兼容小问题，好修）
2. **CONFIG_KPM 验证**：编译成功后，在 "Enable KSU/KPM" 步骤日志里确认 `CONFIG_KPM=y` 真的生效；若显示 "(no CONFIG_KPM in Kconfig)"，说明该版 SukiSU 没带 KPM，我来换集成方式
3. **兼容性**：此树是 A16 向（分支名 16.0），与你的 HyperOS 3 匹配度远高于 jishu1688；但**任何新内核都有黑屏可能**，boot 备份在手，随时 `fastboot flash boot` 回滚
4. **管理器**：刷好后用 SukiSU Ultra 管理器（v4.0.0）接管；KPM 文件放 `/data/adb/kpm/`

## 文件结构

```
.github/workflows/build.yml    # 全自动编译工作流（已含动态探测与失败回退）
```
