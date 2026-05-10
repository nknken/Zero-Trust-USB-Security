# =================================================================
# USB DETECTOR - WITH WHITELIST CHECK (Annotated for First Run)
# =================================================================

$script:DetectedDevices = @{}
$script:USBLogFile = $null
$script:WhitelistCache = @()  

function Invoke-USBLogWeeklyBackup {
    param([string]$LogDir, [string]$LogFile)

    if (-not (Test-Path $LogFile)) { return }

    $today = Get-Date
    if ($today.DayOfWeek -ne [DayOfWeek]::Monday) { return }

    $lastMonday = $today.AddDays(-7).ToString("yyyy-MM-dd")
    $thisMonday = $today.ToString("yyyy-MM-dd")
    $rangeName  = "${lastMonday}_to_${thisMonday}"

    $archiveDir = Join-Path $LogDir "archive\usb"
    $year       = $today.ToString("yyyy")
    $yearFolder = Join-Path $archiveDir $year

    if (-not (Test-Path $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
    }

    $zipName    = "usb_security_$rangeName.zip"
    $entryName  = "usb_security_$rangeName.log"
    $zipPath    = Join-Path $yearFolder $zipName

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        if (Test-Path $zipPath) {
            $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Update")
        } else {
            $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")
        }

        # Anti duplikat
        $exists = $zip.Entries | Where-Object { $_.FullName -eq $entryName }
        if (-not $exists) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $LogFile, $entryName
            )
        }

        $zip.Dispose()

        $timestamp = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
        "=== USB Security Log Started at $timestamp ===" | Set-Content $LogFile -Encoding UTF8

        Write-Host "[BACKUP] USB log → $zipName" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[BACKUP ERROR] $_" -ForegroundColor Red
    }
}

function Initialize-USBDetector {
    param([string]$BasePath)

    $logDir = Join-Path $BasePath "logs"
    $script:USBLogFile = Join-Path $logDir "usb_security.log"

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Invoke-USBLogWeeklyBackup -LogDir $logDir -LogFile $script:USBLogFile

    $whitelistPath = Join-Path $BasePath "whitelist.txt"
    if (Test-Path $whitelistPath) {
        $script:WhitelistCache = Get-Content $whitelistPath | ForEach-Object {
            $parts = $_ -split '\|'
            if ($parts.Count -ge 1 -and $parts[0] -match ':') { $parts[0] }
        } | Where-Object { $_ }
    }

    $timestamp = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
    $today     = Get-Date -Format "yyyy-MM-dd"

    $existingContent = if (Test-Path $script:USBLogFile) {
        Get-Content $script:USBLogFile -Raw
    } else { "" }

    $lastDate = $null
    if ($existingContent -match "(\d{4}-\d{2}-\d{2}) \d{2}:\d{2}:\d{2}") {
        $lastDate = $Matches[1]
    }

    if (-not $existingContent -or $existingContent.Trim() -eq "") {
        "=== USB Security Log Started at $timestamp ===" | Add-Content $script:USBLogFile -Encoding UTF8
    } elseif ($lastDate -and $lastDate -ne $today) {
        "" | Add-Content $script:USBLogFile -Encoding UTF8
        "=== New Day: $today ===" | Add-Content $script:USBLogFile -Encoding UTF8
        "=== Session resumed at $timestamp ===" | Add-Content $script:USBLogFile -Encoding UTF8
    } else {
        "" | Add-Content $script:USBLogFile -Encoding UTF8
        "=== Session resumed at $timestamp ===" | Add-Content $script:USBLogFile -Encoding UTF8
    }

    Write-Host "[L0] USB Detector initialized" -ForegroundColor Cyan
    Write-Host "[L0] Whitelist loaded: $($script:WhitelistCache.Count) device(s)" -ForegroundColor Gray
}

function Write-USBLog {
    param([string]$Message, [string]$Level = "INFO")
    
    # --- [FIRST RUN: Logging] ---
    if (-not $script:USBLogFile) {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
        $basePath = $PSScriptRoot
    } else {
        $basePath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    }
        if ($basePath -match 'modules$') {
            $basePath = Split-Path -Parent $basePath
        }
        if (-not $basePath -or -not (Test-Path $basePath)) {
            $basePath = (Get-Location).Path
        }
        Initialize-USBDetector -BasePath $basePath
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp | [$Level] $Message"
    $logEntry | Add-Content $script:USBLogFile -Encoding UTF8
    
    $color = switch ($Level) { 
        "ALERT" { "Red" } 
        "ALLOW" { "Green" } 
        "TRUSTED" { "DarkGreen" }
        default { "White" } 
    }
    Write-Host $logEntry -ForegroundColor $color
}

function Get-VendorInfo {
    param([string]$InstanceId)
    
    # --- [FIRST RUN: Identitas Unik] ---
    $vid = if ($InstanceId -match "VID_([0-9A-F]{4})") { $matches[1] } else { "?" }
    $devicePid = if ($InstanceId -match "PID_([0-9A-F]{4})") { $matches[1] } else { "?" }
    
    return @{ 
        VID = $vid
        PID = $devicePid
        DeviceKey = "$vid`:$devicePid"
    }
}

function Get-USBHIDDevices {
    if (-not $script:USBLogFile) {
        Initialize-USBDetector -BasePath (Get-Location).Path
    }
    
    $usbDevices = @()
    $processedDevices = @{}
    $newDevicesForLog = @()
    
    # --- [FIRST RUN: Scanning Hardware] ---
    $hidDevices = Get-PnpDevice -Class HIDClass, Keyboard, Mouse -PresentOnly -ErrorAction SilentlyContinue | 
        Where-Object { $_.Status -eq "OK" }
    
    foreach ($dev in $hidDevices) {
        $instanceId = $dev.InstanceId
        $isUSBConnected = $false

        if ($instanceId -match "^USB\\VID_") { $isUSBConnected = $true }
        
        if (-not $isUSBConnected) { continue }

        $info = Get-VendorInfo -InstanceId $instanceId
        
        # --- [FIRST RUN: Cek Perangkat Baru] ---
        if (-not $processedDevices.ContainsKey($info.DeviceKey)) {
            $processedDevices[$info.DeviceKey] = @{
                Interfaces = @()
                IsNew = -not $script:DetectedDevices.ContainsKey($info.DeviceKey)
                VID = $info.VID
                PID = $info.PID
            }
            
            if ($processedDevices[$info.DeviceKey].IsNew) {
                $newDevicesForLog += $info.DeviceKey
            }
        }
        $processedDevices[$info.DeviceKey].Interfaces += $dev.FriendlyName

        $usbDevices += [PSCustomObject]@{
            FriendlyName = $dev.FriendlyName
            IsNew = $processedDevices[$info.DeviceKey].IsNew
            DeviceKey = $info.DeviceKey
        }
    }
    
    # --- [FIRST RUN: Status PENDING] ---
foreach ($deviceKey in $newDevicesForLog) {
    $dev = $processedDevices[$deviceKey]
    $interfaceList = $dev.Interfaces -join ", "
    $ifCount = $dev.Interfaces.Count

    if ($deviceKey -in $script:WhitelistCache) {
        $msg  = "USB CONNECTED  | VID:$($dev.VID)  PID:$($dev.PID)  [$ifCount interface(s)]`n"
        $msg += "               | Interfaces : $interfaceList`n"
        $msg += "               | Status     : TRUSTED"
        Write-USBLog -Message $msg -Level "TRUSTED"
    } else {
        $msg  = "USB CONNECTED  | VID:$($dev.VID)  PID:$($dev.PID)  [$ifCount interface(s)]`n"
        $msg += "               | Interfaces : $interfaceList`n"
        $msg += "               | Status     : PENDING/UNKNOWN"
        Write-USBLog -Message $msg -Level "ALERT"
    }

    $script:DetectedDevices[$deviceKey] = @{
        FirstSeen = Get-Date
        VID = $dev.VID
        PID = $dev.PID
    }
}
    return $usbDevices
}