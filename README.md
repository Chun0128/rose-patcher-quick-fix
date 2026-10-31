# Rose Patcher Quick Fix v1.3

Windows one-click repair for **Rose LTK Patcher Outdated** and the **VRF00000008 host verification** failure, using the original signed files from **LTK Manager 1.29.1**. Includes automatic backup and restore.

**[Download v1.3 ZIP](https://github.com/Chun0128/rose-patcher-quick-fix/raw/refs/heads/main/downloads/Rose_Patcher_Quick_Fix_v1.3.zip)** · [繁體中文說明](#繁體中文)

## Quick start

Requires Windows x64, an existing Rose installation, and [7-Zip](https://www.7-zip.org/).

1. Download and **extract the whole ZIP**.
2. Finish any match, run **`FIX_NOW_EN.cmd`**, and approve the Windows administrator prompt.
3. Rose restarts automatically. Select a skin and test in **Practice Tool**.

To undo the change, run **`RESTORE_EN.cmd`**. It restores the previous files; those files may still have the original problem. Keep every file in the extracted folder together.

## 繁體中文

1. 下載 ZIP 並**全部解壓縮**，電腦需已安裝 Rose 與 [7-Zip](https://www.7-zip.org/)。
2. 結束對局後，雙擊 **`FIX_NOW.cmd`**，允許 Windows 管理員提示。
3. Rose 會自動重新開啟，再進**訓練模式**確認造型。

需要還原時雙擊 **`RESTORE.cmd`**。工具會自動備份；對局進行中會停止，檔案已正確時不會重複替換。

## What changed and what was tested

- Replaces **both** `ltk_patcher_dll.dll` and `ltk_patcher_host.exe` with the matching official **1.29.1** pair. It downloads and extracts the installer without installing or downgrading LTK Manager.
- Checks exact SHA-256 hashes, valid **Natoken LLC** signatures, and the game executable build timestamp. Original files go to `%LOCALAPPDATA%\RosePatcherFix\backups`; a failed replacement is rolled back.
- Confirmed on **one Rose 1.4.9 / zh_TW PC on 2026-10-31**, using **Blitzcrank skin 53056** in Practice Tool. Logs showed `overlay verified 2 wad(s)` and successful WAD redirects; the user confirmed the skin appeared. Other skins and systems are not all tested.
- Supports game builds through **2026-11-01 07:00 UTC / 15:00 Taiwan time**. This compares the game's build timestamp, not your current clock. A later game update may require a newer compatible official patcher.

The earlier 1.28.1 workaround was too old for the tested game build. The newer stable patcher passed the date check but rejected Rose with `VRF00000008`; switching to this verified 1.29.1 pair resolved the tested case.

[Official LTK 1.29.1 release](https://github.com/LeagueToolkit/ltk-manager/releases/tag/v1.29.1) · [File hashes and test evidence](COMPATIBILITY.json) · [Package checksum](downloads/SHA256SUMS.txt)

This is an independent community tool, not an official Rose or LTK release. This repository contains scripts and documentation; Rose, game assets, and patcher binaries are not redistributed. Upstream patcher files retain their own license.
