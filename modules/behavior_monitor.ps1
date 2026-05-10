# =================================================================
# BEHAVIOR MONITOR - ACTIVE FILE + DAILY BACKUP
# =================================================================

$scriptDir = $PSScriptRoot
if ($scriptDir -match 'modules$') { 
    $scriptDir = Split-Path -Parent $scriptDir 
}

$LogDir = Join-Path $scriptDir "logs"
$ArchiveDir = Join-Path $LogDir "archive\keyboard"
$RetentionDays = 30

$MainLogPath = Join-Path $LogDir "keyboard_input.log"

# ================= INIT FOLDER =================
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
}

# ================= INIT MAIN FILE =================
if (-not (Test-Path $MainLogPath)) {

    $header = "Timestamp,KeyCode,KeyName,IntervalMs,Type,Source"

    $fs = [System.IO.FileStream]::new($MainLogPath,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::Read)

    $writer = [System.IO.StreamWriter]::new($fs)
    $writer.WriteLine($header)
    $writer.Flush()
    $writer.Close()
    $fs.Close()
}

Write-Host "[MONITOR] Active log: keyboard_input.log" -ForegroundColor DarkGray

# ================= DAILY BACKUP FUNCTION =================
function Invoke-DailyBackup {
    param($PreviousDate)

    if (-not (Test-Path $MainLogPath)) { return }

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $year  = $PreviousDate.Substring(0,4)
        $month = $PreviousDate.Substring(5,2)

        $yearFolder = Join-Path $ArchiveDir $year
        if (-not (Test-Path $yearFolder)) {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }

        $zipPath    = Join-Path $yearFolder "$year-$month.zip"
        $entryName  = "keyboard_$PreviousDate.log"

        # Buka atau buat ZIP
        if (Test-Path $zipPath) {
            $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Update")
        } else {
            $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")
        }

        # Anti duplikat
        $exists = $zip.Entries | Where-Object { $_.FullName -eq $entryName }

        if (-not $exists) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $MainLogPath, $entryName
            )
        }

        $zip.Dispose()

        $fs = [System.IO.FileStream]::new(
            $MainLogPath,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::Read
        )
        $writer = [System.IO.StreamWriter]::new($fs)
        $writer.WriteLine("Timestamp,KeyCode,KeyName,IntervalMs,Type,Source")
        $writer.Flush()
        $writer.Close()
        $fs.Close()

        Write-Host "[BACKUP] $entryName → $year-$month.zip" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[BACKUP ERROR] $_" -ForegroundColor Red
    }
}

# ================= KEYBOARD POLLER =================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class KeyPoller {

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

}
"@

# ================= KEY NAME RESOLVER =================
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class KeyName {

    [DllImport("user32.dll")]
    public static extern uint MapVirtualKey(uint uCode, uint uMapType);

    [DllImport("user32.dll")]
    public static extern int GetKeyNameText(int lParam, StringBuilder lpString, int nSize);

    public static string GetKeyName(int vk) {

        uint scanCode = MapVirtualKey((uint)vk, 0);
        int lParam = (int)(scanCode << 16);

        StringBuilder sb = new StringBuilder(64);

        if (GetKeyNameText(lParam, sb, sb.Capacity) > 0)
            return sb.ToString();
        else
            return "VK_" + vk.ToString();
    }
}
"@

# ================= STATE =================
$lastTime = [DateTime]::MinValue
$keyStates = @{}

for ($vk = 8; $vk -le 255; $vk++) {
    $keyStates[$vk] = $false
}

$currentDate = Get-Date -Format "yyyy-MM-dd"

# ================= STARTUP BACKUP CHECK =================
function Invoke-StartupBackupCheck {
    if (-not (Test-Path $MainLogPath)) { return }
    
    try {
        $lines = Get-Content $MainLogPath -TotalCount 2
        if ($lines.Count -lt 2) { return }
        
        $firstDataLine = $lines[1]
        if ($firstDataLine -match "^(\d{4}-\d{2}-\d{2})") {
            $logStartDate = $Matches[1]
            
            if ($logStartDate -ne $currentDate) {
                Write-Host "[STARTUP] Detected old log from $logStartDate, backing up..." -ForegroundColor Magenta
                
                $backupName = "keyboard_$logStartDate.log"
                $backupPath = Join-Path $LogDir $backupName
                
                Copy-Item $MainLogPath $backupPath -Force
                Write-Host "[BACKUP] Saved $backupName (startup backup)" -ForegroundColor Cyan
                
                $fs = [System.IO.FileStream]::new($MainLogPath,
                    [System.IO.FileMode]::Create,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::Read)

                $writer = [System.IO.StreamWriter]::new($fs)
                $writer.WriteLine("Timestamp,KeyCode,KeyName,IntervalMs,Type,Source")
                $writer.Flush()
                $writer.Close()
                $fs.Close()
            }
        }
    }
    catch {
        Write-Host "[ERROR] Startup check failed: $_" -ForegroundColor Red
    }
}

Invoke-StartupBackupCheck

# ================= MAIN LOOP =================
while ($true) {

    $today = Get-Date -Format "yyyy-MM-dd"

    if ($today -ne $currentDate) {

        Write-Host "[NEW DAY] $currentDate -> $today" -ForegroundColor Yellow

        Invoke-DailyBackup -PreviousDate $currentDate

        $currentDate = $today
        $lastTime = [DateTime]::MinValue
    }

    for ($vk = 8; $vk -le 255; $vk++) {

        $state = [KeyPoller]::GetAsyncKeyState($vk)
        $isPressed = ($state -eq -32767)

        if ($isPressed -and -not $keyStates[$vk]) {

            $now = Get-Date

            $interval = if ($lastTime -ne [DateTime]::MinValue) {
                ($now - $lastTime).TotalMilliseconds
            } else { 0 }

            $lastTime = $now

            $keyName = [KeyName]::GetKeyName($vk)

            $line = "$($now.ToString('yyyy-MM-dd HH:mm:ss.fff')),$vk,$keyName,$([math]::Round($interval,2)),POLLING,GLOBAL"

            try {

                $fs = [System.IO.FileStream]::new($MainLogPath,
                    [System.IO.FileMode]::Append,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::Read)

                $writer = [System.IO.StreamWriter]::new($fs)
                $writer.WriteLine($line)
                $writer.Flush()
                $writer.Close()
                $fs.Close()
            }
            catch {}
        }

        $keyStates[$vk] = ($state -band 0x8000) -ne 0
    }

    Start-Sleep -Milliseconds 10
}