# Pi Bench WebUI

**繁體中文 | English below**

一個簡潔、漂亮的 **HTML5 + SSE** Web 介面，用來**即時串流顯示**系統測試腳本的輸出。  
介面一致，支援 **Linux（Bash）** 與 **Windows（PowerShell）**。

---

## 功能（Features）

- 🎨 現代深色 UI：玻璃卡片、柔和漸層、細緻分隔線  
- 🖱️ 執行：使用者點「執行測試」才會啟動（不自動跑）  
- 🔌 **Server-Sent Events (SSE)**：分段即時呈現（System / CPU & Memory / Disk / Network）  
- 🐧 **Linux**：測試資訊（CPU/Memory/Disk + Network Info）  
- 🪟 **Windows**：提供系統資訊（若 PATH 找到 `iperf3` 亦可使用）  
- 🌐 **i18n**：繁體中文 / English  
- 🔒 無外部 CDN、同源 CSP、無 Cookie；可純內網運作  

---

## 架構（Architecture）

```text
webui/ (Frontend + CGI)
├─ index.html              # HTML5 + 嚴格 CSP（同源）
├─ assets/
│  ├─ app.css              # 現代深色主題
│  ├─ app.js               # SSE 客戶端 + 語系切換
│  └─ i18n/
│     ├─ zh-Hant.json      # 繁體中文
│     └─ en.json           # English
└─ cgi-bin/
   ├─ bench.sse.py         # CGI：跨平台；呼叫 OS 對應腳本並以 SSE 串流輸出
   └─ pi-bench.cgi         # 舊路徑相容：302 轉址到 /
scripts/ (Benchmark Scripts)
├─ pi-bench-lite.sh        # Linux：CPU/Memory/Disk/Network 資訊
└─ pi-bench-lite.ps1       # Windows：等價系統資訊
extras/
└─ pi-webui.service        # systemd 服務範本（常駐）
```

## 功能（Features）

- 🎨 現代深色 UI：玻璃卡片、柔和漸層、細緻分隔線
- 🖱️ 執行：使用者點「執行測試」才會啟動（不自動跑）
- 🔌 **Server-Sent Events (SSE)** 串流：分段即時呈現（System / CPU & Memory / Disk / Network）
- 🐧 **Linux** 測試（CPU/Memory/Disk + Network Info）
- 🪟 **Windows** 提供系統資訊（如在 PATH 找到 iperf3 也可用）
- 🌐 **i18n**：繁體中文 / English
- 🔒 無外部 CDN、同源 CSP、無 Cookie；支援純內網模式

---

## 快速開始（Linux）
```bash
# 1) 安裝相依（可選：sysbench / iperf3）
sudo apt-get update -y
sudo apt-get install -y python3 sysbench iperf3 curl || true

# 2) 啟動內建 CGI 伺服器（9091）
cd webui
python3 -m http.server --cgi 9091

# 3) 瀏覽 http://<你的主機IP>:9091/ 並點「執行測試」
```

```bash
## 常駐服務（systemd）
sudo cp extras/pi-webui.service /etc/systemd/system/
sudo sed -i "s#YOUR_USER#$USER#g" /etc/systemd/system/pi-webui.service
sudo systemctl daemon-reload
sudo systemctl enable --now pi-webui
# 之後可用：
# sudo systemctl restart pi-webui
`````


## 快速開始（Windows 10/11）
```bash
# 1) 安裝 Python 3 並勾選 Add to PATH
（可選）下載 iperf3.exe 並加入 PATH

# 2) 使用powershell啟動：
cd webui

# 3) py -3 -m http.server --cgi 9091
# 開啟 http://localhost:9091/ 後按「Run Bench」
```

## 隱私與安全（Privacy & Security）

```text 無外部 CDN／字型／分析腳本；CSP 僅允許 'self'
 SSE 為同源路徑 /cgi-bin/bench.sse.py；前端僅以文字節點插入輸出，避免 HTML 注入
 不想對外查詢 IP/地理資訊，可於執行前設定：
```

```bash
export PIBENCH_NO_NETINFO=1
```

```text
 內建 http.server 無驗證與 TLS：建議僅在 LAN 使用，或：
 加 --bind 127.0.0.1 僅開本機 + SSH 轉發
 以 Nginx/Traefik 反代並加基本認證 / TLS
```

## 除錯（Troubleshooting）
```bash
# 必須在 webui/ 目錄啟動（確保 CGI 相對路徑正確）
cd webui && python3 -m http.server --cgi 9091

# 檢查 CGI/SSE 標頭（應為 text/event-stream）
curl -sI http://localhost:9091/cgi-bin/bench.sse.py | grep -i '^Content-Type'

# systemd 日誌
sudo journalctl -u pi-webui -f
```

# 權限/換行（ZIP 解壓後可能掉權限或帶 CRLF）
```bash
chmod 755 webui/cgi-bin/bench.sse.py webui/cgi-bin/pi-bench.cgi scripts/pi-bench-lite.sh

sed -i 's/\r$//' webui/cgi-bin/*.py scripts/*.sh

權限/換行（ZIP 解壓後可能掉執行權或有 CRLF）

chmod 755 webui/cgi-bin/bench.sse.py webui/cgi-bin/pi-bench.cgi scripts/pi-bench-lite.sh

sed -i 's/\r$//' webui/cgi-bin/*.py scripts/*.sh
```

## 授權（License）
MIT License — 可商用/修改/分發，需保留版權宣告。
