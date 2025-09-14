# Pi Bench • LITE (Windows PowerShell) — info + optional iperf3 if present
$ErrorActionPreference = "Stop"

function Write-Bar { "`u2500" * 60 | ForEach-Object {[char]0x2500} | Out-String -NoNewline }
function Title($t){ "■ $t" }
function KV($k,$v){ "  {0,-22} {1}" -f $k, $v }
function Bullet($t){ "• $t" }

Write-Output (Write-Bar); Write-Output (Title "System"); Write-Output (Write-Bar)
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cs  = Get-CimInstance Win32_ComputerSystem
KV "Model 型號"     ($cs.Model) | Write-Output
KV "Cores 核心數"   ($cpu.NumberOfLogicalProcessors) | Write-Output
KV "OS 系統"        ($os.Caption + " " + $os.Version) | Write-Output
KV "Arch 架構"      ($env:PROCESSOR_ARCHITECTURE) | Write-Output
$upt = (Get-Date) - $os.LastBootUpTime
KV "Uptime 開機時間" ("{0:%d} days, {0:%h} hours, {0:%m} minutes" -f $upt) | Write-Output

Write-Output (Write-Bar); Write-Output (Title "CPU / Memory"); Write-Output (Write-Bar)
$curMHz = $cpu.CurrentClockSpeed; $maxMHz = $cpu.MaxClockSpeed
if ($curMHz) { KV "CPU 時脈（目前）" ("{0:N2} GHz" -f ($curMHz/1000)) | Write-Output }
if ($maxMHz) { KV "CPU 時脈（Max）"  ("{0:N2} GHz" -f ($maxMHz/1000)) | Write-Output }
$mt = [math]::Round($os.TotalVisibleMemorySize/1MB,2)
$ma = [math]::Round($os.FreePhysicalMemory/1MB,2)
$mu = [math]::Round($mt - $ma,2)
$pp = [math]::Round(($mu/$mt)*100,1)
KV "記憶體總量（Total）" ("{0:N2} GiB" -f $mt) | Write-Output
KV "已用記憶體（Used）"  ("{0:N2} GiB ({1}%)" -f $mu,$pp) | Write-Output

Write-Output (Write-Bar); Write-Output (Title "Disk"); Write-Output (Write-Bar)
$sysDrive = (Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Root -eq (Get-Location).Drive.Root} | Select-Object -First 1)
KV "System Drive" $sysDrive.Root | Write-Output

Write-Output (Write-Bar); Write-Output (Title "Network Info"); Write-Output (Write-Bar)
# Heuristic AES (search CPU name for "AES")
$hasAES = "$($cpu.Name)" -match "AES"
KV "AES 加速 (AES/NI)" ($(if($hasAES){"Enabled"}else{"Unknown"})) | Write-Output

# Public IP JSON
$ipv4 = "Offline"
try {
  $resp = Invoke-RestMethod -Uri "https://ipinfo.io/json" -TimeoutSec 4
  if ($resp) {
    $ipv4 = "Online"
    KV "IPv4 狀態" $ipv4 | Write-Output
    if ($resp.ip)    { KV "IP 位址 (Address)" $resp.ip | Write-Output }
    if ($resp.region -or $resp.country) { KV "區域 (Region)" ("{0}{1}{2}" -f $resp.region, $(if($resp.region -and $resp.country){" / "}), $resp.country) | Write-Output }
    if ($resp.org)   { KV "組織 (Organization)" $resp.org | Write-Output }
    if ($resp.city -or $resp.region -or $resp.country) { KV "位置 (Location)" ("{0}{1}{2}{3}{4}" -f $resp.country, $(if($resp.region){" / " + $resp.region}), $(if($resp.city){" / " + $resp.city})) | Write-Output }
  }
} catch {}
if ($ipv4 -eq "Offline") { KV "IPv4 狀態" $ipv4 | Write-Output }

try {
  $six = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -Uri "https://ifconfig.co" -Headers @{"Accept"="text/plain"}).Content
  KV "IPv6 狀態" ("Online") | Write-Output
} catch { KV "IPv6 狀態" ("Offline") | Write-Output }

Write-Output (Write-Bar); Write-Output "✓ Done"; Write-Output (Write-Bar)
