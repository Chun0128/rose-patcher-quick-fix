Rose Patcher Quick Fix v1.3 — 一個 CMD 就能用 / Single CMD edition

【繁體中文】
1. 先安裝 Rose 與 7-Zip：https://www.7-zip.org/
2. 全部解壓縮，雙擊 Rose_Quick_Fix.cmd。
3. 按 1 修復，允許 Windows 管理員提示；完成後進訓練模式確認造型。
按 2 還原備份；按 3 檢查版本；按 L 切換中英文；按 0 離開。
修復前請先結束對局。還原只恢復修復前的檔案，不保證能使用造型。

【English】
1. Install Rose and 7-Zip: https://www.7-zip.org/
2. Extract the ZIP and double-click Rose_Quick_Fix.cmd.
3. Press L for English. Choose 1 to repair and approve the administrator prompt.
After Rose restarts, test your skin in Practice Tool.
2 = Restore backup; 3 = Check; L = Switch language; 0 = Exit.
Finish your match first. Restoring the previous files may restore the original problem.

只需這個 CMD，README.txt 是使用說明。執行時會自動準備並清理暫存程式。
The CMD runs independently. It prepares its built-in runtime temporarily and removes it on exit.
原檔備份與下載快取會保留 / Backups and download cache are retained:
%LOCALAPPDATA%\RosePatcherFix

使用官方 LTK 1.29.1 原始配套檔案，核對 SHA-256 與簽章，先備份再更換。
Uses the original official LTK 1.29.1 pair, verified by hashes/signatures, with backup and rollback.
遊戲執行檔建置上限：2026-11-01 07:00 UTC（台灣 15:00）。
Game executable build limit: 2026-11-01 07:00 UTC. This is not your computer's current time.
遊戲更新後可能需要新的相容補丁。Future game updates may require another compatible patcher.

非官方社群工具 / Independent community tool.
說明與原始碼 / Details and source:
https://github.com/Chun0128/rose-patcher-quick-fix

--- License ---

MIT License

Copyright (c) 2026 Chun0128

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

This license covers this tool's scripts and documentation only. Separately
downloaded third-party files remain subject to their respective licenses.
