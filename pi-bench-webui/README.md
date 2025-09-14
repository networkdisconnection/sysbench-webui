# Pi Bench WebUI

A minimal, pretty, **HTML5 + SSE** web UI that streams the output of a system benchmark script.
Works on **Linux** (Bash) and **Windows** (PowerShell) with the same UI.

## Features
- Modern dark UI (glass cards, subtle gradients).
- One-click run (does **not** auto-run).
- SSE streaming; shows sections as they appear.
- Linux script keeps your original measurement spirit (CPU/Memory/Disk + Network info).
- Windows script provides comparable system info; `iperf3` is optional if present in PATH.

## Quick Start (Linux)
```bash
# 1) Install deps (optional: sysbench / iperf3)
sudo apt-get update -y
sudo apt-get install -y python3 sysbench iperf3 curl || true

# 2) Start server (port 9091)
cd webui
python3 -m http.server --cgi 9091
# Open: http://<host>:9091/
```

### As a service (systemd)
Edit the user and path as needed, then:
```bash
sudo cp extras/pi-webui.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pi-webui
```

## Quick Start (Windows 10/11)
1. Install **Python 3** (add to PATH).
2. Optional: download `iperf3.exe` and put it in PATH.
3. Start:
```bat
cd webui
py -3 -m http.server --cgi 9091
```
Open `http://localhost:9091/` in your browser.

## Notes
- CGI endpoint: `webui/cgi-bin/bench.sse.py` (cross-platform). It calls:
  - Linux: `scripts/pi-bench-lite.sh`
  - Windows: `scripts/pi-bench-lite.ps1`
- Old path `cgi-bin/pi-bench.cgi` redirects to `/`.
- Security: same-origin only; CSP in HTML; output written as text nodes (no HTML injection).
