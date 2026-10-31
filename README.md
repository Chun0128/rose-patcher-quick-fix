# Rose Patcher Quick Fix v1.3 — Single CMD

Windows repair for **Rose LTK Patcher Outdated** and the tested **VRF00000008** host verification failure, using the original signed **LTK Manager 1.29.1** patcher pair.

**[Download the two-file ZIP](https://github.com/Chun0128/rose-patcher-quick-fix/raw/refs/heads/main/downloads/Rose_Patcher_Quick_Fix_v1.3.zip)**

## Only two files

- **Rose_Quick_Fix.cmd** — repair, restore, check and language selection in one file.
- **README.txt** — short bilingual guide and license.

The CMD works independently: no separate PS1 scripts or other files from this repository are required. It prepares its embedded runtime in a temporary folder and removes it on exit. Backups and the official download cache remain available for later use.

## Quick start

Requires Windows x64, an existing Rose installation and [7-Zip](https://www.7-zip.org/).

1. Extract the ZIP and double-click **Rose_Quick_Fix.cmd**.
2. Press **L** for English, then **1** to repair. Finish any match first and approve the Windows administrator prompt.
3. Rose restarts after a successful repair. Test your selected skin in **Practice Tool**.

Menu: **1 Repair · 2 Restore backup · 3 Check · L Language · 0 Exit**.

Restore returns the previous files, which may still have the original problem.

## 繁體中文

下載包只有 **Rose_Quick_Fix.cmd** 和 **README.txt** 兩個檔案。

1. 先安裝 Rose 與 [7-Zip](https://www.7-zip.org/)，將 ZIP 解壓縮。
2. 雙擊 **Rose_Quick_Fix.cmd**，按 **1** 修復，允許管理員提示。
3. 完成後 Rose 自動重新開啟，再進訓練模式確認造型。

按 **2** 還原、**3** 檢查版本、**L** 切換中英文、**0** 離開。請先結束對局。

## Repair behavior and compatibility

- Downloads the official 1.29.1 installer and extracts its matching DLL and host without installing or downgrading LTK Manager.
- Verifies exact SHA-256 hashes, valid **Natoken LLC** signatures and the game executable build timestamp.
- Backs up both original files under `%LOCALAPPDATA%\RosePatcherFix\backups`; a failed replacement rolls back.
- Refuses to modify files during a match. The single CMD keeps the same verified patcher selection and support limit.
- Supports game builds through **2026-11-01 07:00 UTC / 15:00 Taiwan time**. This is a game build limit, not a countdown based on the current clock. A later game update may require another compatible patcher.

The patcher pair was confirmed on one **Rose 1.4.9 / zh_TW PC on 2026-10-31**, using **Blitzcrank skin 53056** in Practice Tool. Other skins and systems are not all tested. The single-CMD wrapper was validated separately with standalone launch, paths containing Chinese/special characters, language switching, temporary-file cleanup, damaged-payload rejection and isolated repair/restore tests. No new in-game test was performed for this packaging change; UAC and Rose launches were simulated in fixture tests.

[Compatibility evidence](COMPATIBILITY.json) · [Test results](TEST_RESULTS.json) · [Package checksum](downloads/SHA256SUMS.txt) · [Official LTK 1.29.1 release](https://github.com/LeagueToolkit/ltk-manager/releases/tag/v1.29.1)

Independent community tool, not an official Rose or LTK release. Rose, game assets and patcher binaries are not included. The MIT notice is included inside the CMD and README.txt; upstream files retain their own licenses.

