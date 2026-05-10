#Requires -RunAsAdministrator

param(
    [switch]$FirstRun,
    [int]$ScanInterval = 0,
    [string]$UnblockDevice,
    [string]$RemoveWhitelist
)

Clear-Host

if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    $base = Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
    $base = $PSScriptRoot
} else {
    # Fallback untuk .exe — ambil dari lokasi executable itu sendiri
    $base = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
Set-Location $base

# =================================================================
#  GLOBAL STATE - EMERGENCY STOP
# =================================================================
$Global:EmergencyStop = $false
$Global:BlockedDevices = @()
$Global:LastBlockTime = $null

# =================================================================
#  HELPER FUNCTIONS - DISPLAY
# =================================================================
function Write-Header {
    param([string]$Title, [string]$Subtitle = "", [ConsoleColor]$Color = "Cyan")
    $w = 58
    $border = "+" + ("=" * $w) + "+"
    Write-Host ""
    Write-Host "  $border" -ForegroundColor $Color
    $pad = [math]::Floor(($w - $Title.Length) / 2)
    $titleLine = " " * $pad + $Title + " " * ($w - $pad - $Title.Length)
    Write-Host "  |$titleLine|" -ForegroundColor $Color
    if ($Subtitle -ne "") {
        $pad2 = [math]::Floor(($w - $Subtitle.Length) / 2)
        $subLine = " " * $pad2 + $Subtitle + " " * ($w - $pad2 - $Subtitle.Length)
        Write-Host "  |$subLine|" -ForegroundColor DarkCyan
    }
    Write-Host "  $border" -ForegroundColor $Color
    Write-Host ""
}

function Write-Section {
    param([string]$Text, [ConsoleColor]$Color = "White")
    Write-Host "  +-- $Text" -ForegroundColor $Color
}

function Write-SectionEnd {
    $line = "  +" + ("-" * 56)
    Write-Host $line -ForegroundColor DarkGray
}

function Write-Info {
    param([string]$Label, $Value, [ConsoleColor]$ValueColor = "White")
    $labelPad = $Label.PadRight(14)
    Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$labelPad : " -NoNewline -ForegroundColor Gray
    Write-Host "$Value" -ForegroundColor $ValueColor
}

function Write-Divider {
    param([ConsoleColor]$Color = "DarkGray")
    $line = "  " + ("-" * 56)
    Write-Host $line -ForegroundColor $Color
}

# =================================================================
#  Import module
# =================================================================
$usbDetectorPath = Join-Path $base "modules\usb_detector.ps1"
if (Test-Path $usbDetectorPath) {
    . $usbDetectorPath
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "USB Detector module loaded" -ForegroundColor DarkGray
} else {
    Write-Host "  [ERR] " -NoNewline -ForegroundColor Red
    Write-Host "Module not found: $usbDetectorPath" -ForegroundColor Red
    exit 1
}

# =================================================================
#  SETUP AWAL (FIRST RUN) - REAL-TIME DETECTION
# =================================================================
if ($FirstRun) {
    Write-Header -Title "ZERO TRUST USB SECURITY" -Subtitle "MODE : SETUP AWAL" -Color Cyan

    Write-Host "  Instruksi:" -ForegroundColor White
    Write-Divider
    Write-Host "    1.  Colokkan USB keyboard / mouse Anda" -ForegroundColor Green
    Write-Host "    2.  Ketik [S] lalu Enter untuk selesai" -ForegroundColor Yellow
    Write-Host ""

    $registeredDeviceKeys = @()
    $shownDeviceKeys       = @()
    if (Test-Path ".\whitelist.txt") {
        Get-Content ".\whitelist.txt" | ForEach-Object {
            $parts = $_ -split '\|'
            if ($parts.Count -ge 1 -and $parts[0] -match ':') {
                $registeredDeviceKeys += $parts[0]
            }
        }
    }
    $finish                = $false
    $scanCount             = 0

    while (-not $finish) {
        $allDevices     = Get-USBHIDDevices
        $groupedDevices = $allDevices | Group-Object DeviceKey

        foreach ($group in $groupedDevices) {
            $deviceKey = $group.Name
            if ($deviceKey -in $registeredDeviceKeys) { continue }
            if ($deviceKey -in $shownDeviceKeys)       { continue }

            $shownDeviceKeys += $deviceKey
            $firstDevice      = $group.Group[0]
            $interfaceCount   = $group.Count
            $interfaceNames   = ($group.Group | ForEach-Object { $_.FriendlyName }) -join ", "

            Write-Host ""
            Write-Section "USB DEVICE BARU TERDETEKSI" -Color Green
            Write-Info "VID:PID"    $deviceKey     Yellow
            Write-Info "Interfaces" $interfaceCount Cyan
            Write-Info "Details"    $interfaceNames Gray
            Write-SectionEnd
            Write-Host ""

            $choice = Read-Host "    Daftarkan sebagai trusted? [Y/n/s]"

            if ($choice -eq "s") {
                $finish = $true
                break
            }
            elseif ($choice -ne "n") {
                $date = Get-Date -Format 'yyyy-MM-dd'
                "$deviceKey|$date|$($firstDevice.FriendlyName)|$interfaceCount" | Add-Content ".\whitelist.txt"
                $registeredDeviceKeys += $deviceKey
                Write-Host ""
                Write-Host "  [OK] Ditambahkan ke whitelist : " -NoNewline -ForegroundColor Green
                Write-Host $deviceKey -ForegroundColor Yellow
                Write-USBLog -Message "USB REGISTERED | VID:$($firstDevice.DeviceKey.Split(':')[0])  PID:$($firstDevice.DeviceKey.Split(':')[1])  [$interfaceCount interface(s)]`n               | Status     : REGISTERED/TRUSTED" -Level "ALLOW"
            }
            else {
                Write-Host "  [--] Dilewati : " -NoNewline -ForegroundColor DarkGray
                Write-Host $deviceKey -ForegroundColor Gray
            }
            Write-Host ""
        }

        $scanCount++
        if ($scanCount % 250 -eq 0) { Write-Host "." -NoNewline -ForegroundColor DarkGray }
        if ($scanCount % 1250 -eq 0) { Write-Host "" }

        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::S) {
                $finish = $true
                Write-Host ""
                Write-Host "  Menyelesaikan setup..." -ForegroundColor Yellow
            }
        }

        Start-Sleep -Milliseconds 200
    }

    Write-Host ""
    Write-Section "SETUP SELESAI" -Color Green
    Write-Info "Total terdaftar" $registeredDeviceKeys.Count Green
    if ($registeredDeviceKeys.Count -gt 0) {
        Write-Host "  |" -ForegroundColor DarkGray
        Write-Host "  |  Whitelist:" -ForegroundColor Gray
        $registeredDeviceKeys | ForEach-Object {
            Write-Host "  |    - $_" -ForegroundColor DarkGray
        }
    }
    Write-SectionEnd
    Write-Host ""
    exit
}

# =========================
# FUNCTION unblock
# =========================
function Unblock-USBDevice {
    param([string]$DeviceKey)

    $vid = $DeviceKey.Split(':')[0]
    $devicePid = $DeviceKey.Split(':')[1]

    Write-Host ""
    Write-Host "  [UNBLOCK] Mengaktifkan kembali $DeviceKey..." -ForegroundColor Cyan

    $devices = Get-PnpDevice | Where-Object {
        $_.InstanceId -match "VID_$vid" -and
        $_.InstanceId -match "PID_$devicePid"
    }

    foreach ($dev in $devices) {
        try {
            Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            pnputil /enable-device "$($dev.InstanceId)" | Out-Null

            Write-Host "    [OK] Enabled : $($dev.FriendlyName)" -ForegroundColor Green
        } catch {
            Write-Host "    [!] Failed  : $($dev.FriendlyName)" -ForegroundColor Yellow
        }
    }

        if (Test-Path ".\blacklist.txt") {
            $DeviceKeyClean = $DeviceKey.Trim()
            $lines = Get-Content ".\blacklist.txt" | ForEach-Object { $_.Trim() }
            $lines | Where-Object {
                ($_.Split('|')[0].Trim()) -ne $DeviceKeyClean
            } | Set-Content ".\blacklist.txt"

            Write-Host "  [OK] Dihapus dari blacklist" -ForegroundColor Green
        }
        Write-USBLog -Message "USB UNBLOCKED  | VID:$vid  PID:$devicePid`n               | Status     : RESTORED" -Level "ALLOW"
}

if ($UnblockDevice) {
    Write-Header -Title "ZERO TRUST USB SECURITY" -Subtitle "MODE : UNBLOCK DEVICE" -Color Cyan

    Unblock-USBDevice -DeviceKey $UnblockDevice
    exit
}

# =========================
# FUNCTION remove whitelist
# =========================
function Remove-WhitelistDevice {
    param([string]$DeviceKey)

    $vid = $DeviceKey.Split(':')[0]
    $devicePid = $DeviceKey.Split(':')[1]

    Write-Host ""
    Write-Host "  [REMOVE] Menghapus dari whitelist: $DeviceKey..." -ForegroundColor Yellow

    if (Test-Path ".\whitelist.txt") {

        $DeviceKeyClean = $DeviceKey.Trim()

        $lines = Get-Content ".\whitelist.txt" | ForEach-Object { $_.Trim() }

        $filtered = $lines | Where-Object {
            ($_.Split('|')[0].Trim()) -ne $DeviceKeyClean
        }

        $filtered | Set-Content ".\whitelist.txt"

        Write-Host "  [OK] Device dihapus dari whitelist" -ForegroundColor Green
    }
    else {
        Write-Host "  [!] File whitelist tidak ditemukan" -ForegroundColor Yellow
    }
    Write-USBLog -Message "WHITELIST REMOVE| VID:$vid  PID:$devicePid`n               | Status     : REMOVED FROM WHITELIST" -Level "INFO"
}
if ($RemoveWhitelist) {
    Write-Header -Title "ZERO TRUST USB SECURITY" -Subtitle "MODE : REMOVE WHITELIST" -Color Yellow
    Remove-WhitelistDevice -DeviceKey $RemoveWhitelist
    exit
}

# =================================================================
#  FUNGSI BEHAVIORAL ANALYSIS
# =================================================================
function Get-BehavioralStats {
    param([int]$Seconds = 2)

    $logPath = Join-Path $base "logs\keyboard_input.log"

    if (-not (Test-Path $logPath)) {
        return @{ Score = 0; AvgInterval = 0; CV = 0; Burst = 0; Count = 0; IsSuspicious = $false }
    }

    $cutoff = (Get-Date).AddSeconds(-$Seconds)

    $intervals = @()
    Get-Content $logPath -Tail 300 | ForEach-Object {
        if ($_ -match '^\d{4}-\d{2}-\d{2}') {
            $parts = $_ -split ','
            if ($parts.Count -ge 4) {
                try {
                    $ts = [DateTime]::Parse($parts[0])
                    $interval = [double]$parts[3]
                    if ($ts -gt $cutoff -and $interval -ge 0 -and $interval -lt 500) {
                        $intervals += $interval
                    }
                } catch {}
            }
        }
    }

    if ($intervals.Count -lt 5) {
        return @{ Score = 0; AvgInterval = 0; CV = 0; Burst = 0; Count = 0; IsSuspicious = $false }
    }

    $avg = ($intervals | Measure-Object -Average).Average
    $std = [math]::Sqrt(
        ($intervals | ForEach-Object {
            [math]::Pow($_ - $avg, 2)
        } | Measure-Object -Average).Average
    )
    $cv = if ($avg -gt 0) { $std / $avg } else { 999 }
    $burst = ($intervals | Where-Object { $_ -lt 25 }).Count

    # SCORING 
    $score = 0
    
    # Kecepatan ketikan (Avg)
    if ($avg -lt 50)   { $score += 1 }
    if ($avg -lt 30)   { $score += 2 }  
    
    # Konsistensi pola ketikan (CV) 
    if ($cv -lt 0.5)   { $score += 1 }   
    if ($cv -lt 0.2)   { $score += 2 }   
    
    # Burst jumlah input cepat
    if ($burst -ge 5)  { $score += 1 }
    if ($burst -ge 15) { $score += 2 }

    return @{
        Score        = [math]::Min($score, 6)
        AvgInterval  = [math]::Round($avg, 0)
        CV           = [math]::Round($cv, 2)
        Burst        = $burst
        Count        = $intervals.Count
        IsSuspicious = $score -ge 4
    }
}

# =================================================================
#  MITIGATION - FREEZE KEYBOARD
# =================================================================
function Freeze-Keyboard-Specific {

    param([string]$DeviceKey)

    $vid = $DeviceKey.Split(':')[0]
    $devicePid = $DeviceKey.Split(':')[1]

    $devices = Get-PnpDevice | Where-Object {
        $_.Class -eq "Keyboard" -and
        $_.InstanceId -match "VID_$vid" -and
        $_.InstanceId -match "PID_$devicePid"
    }

    foreach ($d in $devices) {
        try {
            Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 100
            Enable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue

        } catch {}
    }
}

# =================================================================
#  BLOCK DEVICE - IMPROVED
# =================================================================
function Block-USBDevice {

    param(
        [string]$DeviceKey,
        [switch]$Emergency = $false
    )

    $vid       = $DeviceKey.Split(':')[0]
    $devicePid = $DeviceKey.Split(':')[1]

    Write-Host "  [BLOCK] Blocking $DeviceKey..." -ForegroundColor DarkRed

    $Global:EmergencyStop = $true
    $Global:LastBlockTime = Get-Date

    if (-not ($Global:BlockedDevices -contains $DeviceKey)) {
        $Global:BlockedDevices += $DeviceKey
    }

    if ($Emergency) {
        $recentShells = Get-Process | Where-Object {
            ($_.Name -match "powershell|pwsh|cmd") -and
            $_.StartTime -and 
            ((Get-Date) - $_.StartTime).TotalSeconds -lt 15  
        }

        foreach ($proc in $recentShells) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "    [X] Killed shell: $($proc.Name) (PID: $($proc.Id))" -ForegroundColor Red
            } catch {
                Write-Host "    [!] Failed kill: $($proc.Name)" -ForegroundColor Yellow
            }
        }
    }

    $devices = Get-PnpDevice | Where-Object {
        $_.InstanceId -match "VID_$vid" -and
        $_.InstanceId -match "PID_$devicePid"
    }

    $blockedCount = 0

    foreach ($dev in $devices) {
        try {
            Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            $dev | Remove-PnpDevice -Confirm:$false -ErrorAction Stop

            Write-Host "    [X] Removed : $($dev.FriendlyName)" -ForegroundColor Red
            $blockedCount++

        } catch {
            Write-Host "    [!] Failed  : $($dev.FriendlyName)" -ForegroundColor Yellow
        }
    }

    $date = Get-Date -Format 'yyyy-MM-dd'
    $existing = @()
    if (Test-Path ".\blacklist.txt") {
        $existing = Get-Content ".\blacklist.txt" | ForEach-Object {
            ($_ -split '\|')[0]
        }
    }

    if ($DeviceKey -notin $existing) {
        "$DeviceKey|$date|BLOCKED|EMERGENCY=$Emergency" | Add-Content ".\blacklist.txt"
    }

    Write-Host "  [BLOCK] Total diblokir : $blockedCount device(s)" -ForegroundColor Red

    Start-Sleep -Milliseconds 500
    $Global:EmergencyStop = $false

    $msg  = "USB BLOCKED    | VID:$vid  PID:$devicePid`n"
    $msg += "               | Emergency  : $Emergency"
    Write-USBLog -Message $msg -Level "BLOCK"
}

# =================================================================
#  MODE MONITORING
# =================================================================
Write-Header -Title "ZERO TRUST USB SECURITY" -Subtitle "MODE : MONITORING AKTIF" -Color Cyan

# Load whitelist
$whitelist = @{}
if (Test-Path ".\whitelist.txt") {
    Get-Content ".\whitelist.txt" | ForEach-Object {
        $parts = $_ -split '\|'
        if ($parts.Count -ge 1 -and $parts[0] -match ':') {
            $whitelist[$parts[0]] = @{
                Date           = $parts[1]
                Name           = $parts[2]
                InterfaceCount = $parts[3]
            }
        }
    }
}

# Load blacklist
$blacklist = @()
if (Test-Path ".\blacklist.txt") {
    $blacklist = Get-Content ".\blacklist.txt" | ForEach-Object {
        $parts = $_ -split '\|'
        if ($parts.Count -ge 1) { $parts[0] }
    } | Where-Object { $_ }
}

if ($whitelist.Count -eq 0) {
    Write-Host "  [!] Belum ada perangkat terdaftar di whitelist!" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Section "Trusted Devices  ($($whitelist.Count))" -Color Green
    $whitelist.Keys | ForEach-Object {
        Write-Host "  |  [OK] $_" -ForegroundColor DarkGreen
    }
    Write-SectionEnd
    Write-Host ""
}

if ($blacklist.Count -gt 0) {
    Write-Section "Blacklisted Devices  ($($blacklist.Count))" -Color Red
    $blacklist | ForEach-Object {
        Write-Host "  |  [X]  $_" -ForegroundColor DarkRed
    }
    Write-SectionEnd
    Write-Host ""
}

# Start behavior monitor
$monitor = Start-Process powershell -WindowStyle Hidden -ArgumentList "-File `"$base\modules\behavior_monitor.ps1`"" -PassThru
Start-Sleep 2

# State tracking
$deviceState       = @{ }
$alertedDevices    = @()
$pendingDevices    = @{ }
$lastBehaviorCheck = Get-Date
$consecutiveAlerts = 0
$attackInProgress  = $false

$BehaviorWindow = 2
$CheckInterval  = 0.2

Write-Host "  [OK] Monitoring aktif" -ForegroundColor Green
Write-Divider
Write-Host "    L1  Real-time  : AKTIF  " -ForegroundColor Cyan
Write-Host "    L2  Auto-block : ON     " -ForegroundColor Cyan
Write-Host "    L3  Emergency  : ON     " -ForegroundColor Cyan
Write-Divider
Write-Host ""

try {
    while ($true) {
        if (Test-Path (Join-Path $base "stop.signal")) {
            Write-Host "  [--] Stop signal diterima dari GUI." -ForegroundColor Yellow
            break
        }

        if ($Global:EmergencyStop) {
            Start-Sleep -Milliseconds 100
            continue
        }

        # -- REAL-TIME BEHAVIORAL MONITORING --
        $elapsed = (Get-Date) - $lastBehaviorCheck
        if ($elapsed.TotalSeconds -ge $CheckInterval) {

            $stats = Get-BehavioralStats -Seconds $BehaviorWindow

            if ($stats.Count -gt 0) {
                $timestamp = Get-Date -Format "HH:mm:ss.fff"
                $tag   = if ($stats.IsSuspicious) { "[!!]" } else { "[ L]" }
                $color = if ($stats.IsSuspicious) { "Red" } else { "DarkGray" }

                $line = "{0} {1}  Score={2,-2}  Avg={3,5}ms  CV={4,5}  Burst={5,3}  N={6}" -f `
                    $tag, $timestamp, $stats.Score, $stats.AvgInterval, $stats.CV, $stats.Burst, $stats.Count
                Write-Host "  $line" -ForegroundColor $color
                # ===============================
                # ⚡ REAL-TIME CHAOS (INSTANT)
                # ===============================
                if ($stats.IsSuspicious) {
                    Add-Type -AssemblyName System.Windows.Forms

                    for ($i=0; $i -lt 10; $i++) {
                        [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
                        [System.Windows.Forms.SendKeys]::SendWait("#")
                        [System.Windows.Forms.SendKeys]::SendWait("###BLOCKED###")
                    }
                }

                # DETEKSI SERANGAN - LANGSUNG EMERGENCY BLOCK
                if ($stats.IsSuspicious -and -not $attackInProgress) {
                    $attackInProgress = $true
                    # ===============================
                    # STEP 0: IDENTIFIKASI DEVICE
                    # ===============================
                    $attackingDevice = $null
                    foreach ($devKey in $pendingDevices.Keys) {
                        $attackingDevice = $devKey
                        break
                    }

                    Write-Host ""
                    Write-Host "  +=============================================+" -ForegroundColor Red
                    Write-Host "  |    !!! REAL-TIME ATTACK DETECTED !!!        |" -ForegroundColor Red
                    $attackLine = "  |  Avg: {0}ms   CV: {1}   Burst: {2}" -f $stats.AvgInterval, $stats.CV, $stats.Burst
                    Write-Host $attackLine -ForegroundColor Yellow
                    Write-Host "  +=============================================+" -ForegroundColor Red
                    Write-Host ""

                    if ($attackingDevice) {

                        # ===============================
                        # STEP 1: CHAOS (RUSAK PAYLOAD)
                        # ===============================
                        Add-Type -AssemblyName System.Windows.Forms

                        $chars = "ABCDEFG12345!@#"
                        for ($i=0; $i -lt 80; $i++) {
                            $c = $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
                            [System.Windows.Forms.SendKeys]::SendWait($c)
                            Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 40)
                        }
                        [System.Windows.Forms.SendKeys]::SendWait("###BLOCKED###")

                        # ===============================
                        # STEP 2: DELAY (BIAR MASUK DULU)
                        # ===============================
                        Start-Sleep -Milliseconds 150

                        # ===============================
                        # STEP 3: FREEZE DEVICE
                        # ===============================
                        Freeze-Keyboard-Specific -DeviceKey $attackingDevice
                        Start-Sleep -Milliseconds 50

                        # ===============================
                        # STEP 4: KILL PAYLOAD
                        # ===============================
                        $targets = "powershell","pwsh","cmd","wscript","cscript"

                        Get-Process | Where-Object {
                            $targets -contains $_.Name -and
                            $_.StartTime -and
                            ((Get-Date) - $_.StartTime).TotalSeconds -lt 10
                        } | ForEach-Object {
                            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                        }

                        # ===============================
                        # STEP 5: BLOCK DEVICE
                        # ===============================
                        Block-USBDevice -DeviceKey $attackingDevice -Emergency

                        $pendingDevices.Remove($attackingDevice)
                        $deviceState[$attackingDevice] = "BLOCKED_EMERGENCY"

                        Write-Host "  [OK] Serangan dihentikan!" -ForegroundColor Green
                    }
                    else {
                        $unknownDevices = Get-USBHIDDevices | Where-Object {
                            $_.Status -eq "OK" -and
                            -not ($whitelist.ContainsKey($_.DeviceKey)) -and
                            $_.DeviceKey -notin $blacklist
                        }

                        if ($unknownDevices) {
                            Write-Host "  [EMERGENCY] Blokir semua unknown device!" -ForegroundColor Red
                            $unknownDevices | Group-Object DeviceKey | ForEach-Object {
                                Block-USBDevice -DeviceKey $_.Name -Emergency
                            }
                        }
                    }

                    Start-Sleep 2
                    $attackInProgress = $false
                    $consecutiveAlerts = 0

                    $msg  = "ATTACK DETECTED| Score=$($stats.Score)  Avg=$($stats.AvgInterval)ms  CV=$($stats.CV)  Burst=$($stats.Burst)`n"
                    $msg += "               | Device     : $attackingDevice"
                    Write-USBLog -Message $msg -Level "ALERT"                }
                elseif (-not $stats.IsSuspicious) {
                    $consecutiveAlerts = 0
                }
            }

            $lastBehaviorCheck = Get-Date
        }

        # -- USB DEVICE SCAN --
        $devices = Get-USBHIDDevices
        $grouped = $devices | Group-Object DeviceKey

        foreach ($group in $grouped) {
            $deviceKey = $group.Name
            $firstDev  = $group.Group[0]
            $count     = $group.Count

            if ($deviceState[$deviceKey]) { continue }

            # BLACKLIST: Auto-block
            if ($deviceKey -in $blacklist) {
                Write-Host ("  [BL] BLACKLISTED {0,-20} (ignored)" -f $deviceKey) -ForegroundColor DarkRed
                $deviceState[$deviceKey] = "BLACKLISTED"
                continue

            }

            # WHITELIST: Trusted
            if ($whitelist.ContainsKey($deviceKey)) {
                Write-Host ("  [OK] TRUSTED   {0,-20}  ({1} interfaces)" -f $deviceKey, $count) -ForegroundColor DarkGreen
                $deviceState[$deviceKey] = "TRUSTED"
                continue
            }

            # DEVICE BARU: Auto-ignore dan pantau
            if ($firstDev.IsNew -and $deviceKey -notin $alertedDevices) {
                $alertedDevices += $deviceKey
                $pendingDevices[$deviceKey] = @{
                    FirstSeen = Get-Date
                    Device    = $firstDev
                    Count     = $count
                    Group     = $group
                }
                $deviceState[$deviceKey] = "PENDING_MONITOR"

                $names = ($group.Group.FriendlyName -join ', ')
                if ($names.Length -gt 44) { $names = $names.Substring(0, 44) + "..." }

                Write-Host ""
                Write-Host "  +====================================================+" -ForegroundColor Yellow
                Write-Host "  |        [!] NEW USB DEVICE DETECTED [!]             |" -ForegroundColor Yellow
                Write-Host "  +----------------------------------------------------+" -ForegroundColor DarkYellow
                Write-Host ("  |  Device     : {0,-38}|" -f $deviceKey) -ForegroundColor White
                Write-Host ("  |  Interfaces : {0,-38}|" -f $count)     -ForegroundColor White
                Write-Host ("  |  Names      : {0,-38}|" -f $names)     -ForegroundColor Gray
                Write-Host "  +----------------------------------------------------+" -ForegroundColor DarkYellow
                Write-Host "  |  Status     : AUTO-IGNORED (dipantau)              |" -ForegroundColor Cyan
                Write-Host "  |  Warning    : Jika mencurigakan -> EMERGENCY BLOCK |" -ForegroundColor Cyan
                Write-Host "  +====================================================+" -ForegroundColor Yellow
                Write-Host ""
            }
        }

        # ===============================
        # CLEANUP DEVICE YANG SUDAH DICABUT
        # ===============================

        $currentDeviceKeys = $grouped.Name

        foreach ($key in @($pendingDevices.Keys)) {
            if ($key -notin $currentDeviceKeys) {
                Write-Host "  [CLEAN] Removed (pending) : $key" -ForegroundColor DarkGray
                $pendingDevices.Remove($key)
            }
        }
        foreach ($key in @($deviceState.Keys)) {
            if ($key -notin $currentDeviceKeys) {
                $vid = $key.Split(':')[0]
                $devicePid = $key.Split(':')[1]
                Write-Host "  [CLEAN] Removed (state)   : $key" -ForegroundColor DarkGray
                $msg  = "USB REMOVED    | VID:$vid  PID:$devicePid`n"
                $msg += "               | Status     : $($deviceState[$key])"
                Write-USBLog -Message $msg -Level "INFO"                $deviceState.Remove($key)
                $script:DetectedDevices.Remove($key)
                $alertedDevices = $alertedDevices | Where-Object { $_ -ne $key }
            }
        }

        $now          = Get-Date
        $keysToRemove = @()
        foreach ($devKey in $pendingDevices.Keys) {
            $pending        = $pendingDevices[$devKey]
            $elapsedPending = ($now - $pending.FirstSeen).TotalMinutes

            if ($elapsedPending -gt 5) {
                Write-Host "  [OK] Aman (5 menit) : $devKey" -ForegroundColor Green
                $keysToRemove        += $devKey
                $deviceState[$devKey] = "MONITORED_SAFE"
            }
        }
        foreach ($key in $keysToRemove) { $pendingDevices.Remove($key) }

        Start-Sleep -Milliseconds 300
    }
}
catch {
    Write-Host ""
    Write-Host "  [ERR] $_" -ForegroundColor Red
}
finally {
    if ($monitor -and -not $monitor.HasExited) {
        Stop-Process -Id $monitor.Id -Force -ErrorAction SilentlyContinue
    }
    Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -match "behavior_monitor\.ps1"
    } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Write-Host ""
    Write-Divider
    Write-Host "  [--] Monitoring dihentikan." -ForegroundColor Yellow
    Write-Host ""
}