#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    $base = Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
    $base = $PSScriptRoot
} else {
    $base = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
Set-Location $base

# =================================================================
#  WARNA TEMA
# =================================================================
$clrBg        = [System.Drawing.Color]::FromArgb(13, 17, 23)
$clrPanel     = [System.Drawing.Color]::FromArgb(22, 27, 34)
$clrBorder    = [System.Drawing.Color]::FromArgb(48, 54, 61)
$clrCyan      = [System.Drawing.Color]::FromArgb(88, 166, 255)
$clrGreen     = [System.Drawing.Color]::FromArgb(63, 185, 80)
$clrRed       = [System.Drawing.Color]::FromArgb(248, 81, 73)
$clrYellow    = [System.Drawing.Color]::FromArgb(210, 153, 34)
$clrGray      = [System.Drawing.Color]::FromArgb(139, 148, 158)
$clrWhite     = [System.Drawing.Color]::FromArgb(230, 237, 243)
$clrDarkGreen = [System.Drawing.Color]::FromArgb(35, 134, 54)
$clrDarkRed   = [System.Drawing.Color]::FromArgb(130, 30, 30)
$clrDarkBlue  = [System.Drawing.Color]::FromArgb(20, 40, 70)
$fntMono      = New-Object System.Drawing.Font("Consolas", 9)
$fntMonoSm    = New-Object System.Drawing.Font("Consolas", 8)
$fntMonoBold  = New-Object System.Drawing.Font("Consolas", 9,  [System.Drawing.FontStyle]::Bold)
$fntTitle     = New-Object System.Drawing.Font("Consolas", 13, [System.Drawing.FontStyle]::Bold)
$fntSection   = New-Object System.Drawing.Font("Consolas", 9,  [System.Drawing.FontStyle]::Bold)

# =================================================================
#  FORM UTAMA
# =================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Zero Trust USB Security - Dashboard"
$form.Size            = New-Object System.Drawing.Size(1100, 720)
$form.MinimumSize     = New-Object System.Drawing.Size(1100, 720)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $clrBg
$form.ForeColor       = $clrWhite
$form.Font            = $fntMono

# =================================================================
#  HEADER
# =================================================================
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock      = "Top"
$pnlHeader.Height    = 55
$pnlHeader.BackColor = $clrPanel
$form.Controls.Add($pnlHeader)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "  ZERO TRUST USB SECURITY"
$lblTitle.Font      = $fntTitle
$lblTitle.ForeColor = $clrCyan
$lblTitle.AutoSize  = $true
$lblTitle.Location  = New-Object System.Drawing.Point(10, 15)
$pnlHeader.Controls.Add($lblTitle)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "● MONITORING AKTIF"
$lblStatus.Font      = $fntMonoBold
$lblStatus.ForeColor = $clrGreen
$lblStatus.AutoSize  = $true
$lblStatus.Location  = New-Object System.Drawing.Point(800, 20)
$pnlHeader.Controls.Add($lblStatus)

# =================================================================
#  LAYOUT UTAMA — KIRI + KANAN
# =================================================================
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Location = New-Object System.Drawing.Point(0, 55)
$pnlMain.Size     = New-Object System.Drawing.Size(1090, 620)
$pnlMain.Anchor   = "Top,Left,Right,Bottom"
$form.Controls.Add($pnlMain)

# --- PANEL KIRI ---
$pnlLeft = New-Object System.Windows.Forms.Panel
$pnlLeft.Location  = New-Object System.Drawing.Point(5, 5)
$pnlLeft.Size      = New-Object System.Drawing.Size(520, 610)
$pnlLeft.BackColor = $clrBg
$pnlMain.Controls.Add($pnlLeft)

# --- PANEL KANAN ---
$pnlRight = New-Object System.Windows.Forms.Panel
$pnlRight.Location  = New-Object System.Drawing.Point(535, 5)
$pnlRight.Size      = New-Object System.Drawing.Size(550, 610)
$pnlRight.BackColor = $clrBg
$pnlMain.Controls.Add($pnlRight)

# =================================================================
#  HELPER: BUAT LABEL SECTION
# =================================================================
function New-SectionLabel {
    param($Text, $X, $Y, $Parent)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Text
    $lbl.Font      = $fntSection
    $lbl.ForeColor = $clrCyan
    $lbl.AutoSize  = $true
    $lbl.Location  = New-Object System.Drawing.Point($X, $Y)
    $Parent.Controls.Add($lbl)
    return $lbl
}

# =================================================================
#  HELPER: BUAT BUTTON
# =================================================================
function New-Btn {
    param($Text, $X, $Y, $W, $H, $BgColor, $Parent)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $Text
    $btn.Location  = New-Object System.Drawing.Point($X, $Y)
    $btn.Size      = New-Object System.Drawing.Size($W, $H)
    $btn.BackColor = $BgColor
    $btn.ForeColor = $clrWhite
    $btn.Font      = $fntMonoBold
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize  = 1
    $btn.FlatAppearance.BorderColor = $clrBorder
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $Parent.Controls.Add($btn)
    return $btn
}

# =================================================================
#  KIRI ATAS — STATISTIK BEHAVIORAL
# =================================================================
New-SectionLabel "[ BEHAVIORAL ANALYSIS ]" 5 5 $pnlLeft | Out-Null

$pnlStats = New-Object System.Windows.Forms.Panel
$pnlStats.Location  = New-Object System.Drawing.Point(5, 28)
$pnlStats.Size      = New-Object System.Drawing.Size(510, 115)
$pnlStats.BackColor = $clrPanel
$pnlLeft.Controls.Add($pnlStats)

function New-StatBox {
    param($Label, $Value, $X, $Parent)
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location  = New-Object System.Drawing.Point($X, 8)
    $pnl.Size      = New-Object System.Drawing.Size(88, 70)
    $pnl.BackColor = $clrBg
    $Parent.Controls.Add($pnl)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Label
    $lbl.Font      = $fntMonoSm
    $lbl.ForeColor = $clrGray
    $lbl.AutoSize  = $false
    $lbl.Size      = New-Object System.Drawing.Size(88, 18)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.Location  = New-Object System.Drawing.Point(0, 5)
    $pnl.Controls.Add($lbl)

    $val = New-Object System.Windows.Forms.Label
    $val.Text      = $Value
    $val.Font      = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
    $val.ForeColor = $clrCyan
    $val.AutoSize  = $false
    $val.Size      = New-Object System.Drawing.Size(88, 35)
    $val.TextAlign = "MiddleCenter"
    $val.Location  = New-Object System.Drawing.Point(0, 25)
    $pnl.Controls.Add($val)

    return $val
}

$statScore = New-StatBox "SCORE"   "0"   10  $pnlStats
$statAvg   = New-StatBox "AVG(ms)" "0"   108 $pnlStats
$statCV    = New-StatBox "CV"      "0"   206 $pnlStats
$statBurst = New-StatBox "BURST"   "0"   304 $pnlStats
$statN     = New-StatBox "N"       "0"   402 $pnlStats

$lblBehaviorStatus = New-Object System.Windows.Forms.Label
$lblBehaviorStatus.Text      = "  Status : NORMAL"
$lblBehaviorStatus.Font      = $fntMonoBold
$lblBehaviorStatus.ForeColor = $clrGreen
$lblBehaviorStatus.AutoSize  = $false
$lblBehaviorStatus.Size      = New-Object System.Drawing.Size(510, 22)
$lblBehaviorStatus.Location  = New-Object System.Drawing.Point(0, 88)
$pnlStats.Controls.Add($lblBehaviorStatus)

# =================================================================
#  KIRI TENGAH — LOG BEHAVIORAL REAL-TIME
# =================================================================
New-SectionLabel "[ REAL-TIME BEHAVIOR LOG ]" 5 153 $pnlLeft | Out-Null

$txtBehavior = New-Object System.Windows.Forms.RichTextBox
$txtBehavior.Location  = New-Object System.Drawing.Point(5, 175)
$txtBehavior.Size      = New-Object System.Drawing.Size(510, 175)
$txtBehavior.BackColor = $clrPanel
$txtBehavior.ForeColor = $clrGray
$txtBehavior.Font      = $fntMonoSm
$txtBehavior.ReadOnly  = $true
$txtBehavior.ScrollBars = "Vertical"
$txtBehavior.BorderStyle = "None"
$pnlLeft.Controls.Add($txtBehavior)

# =================================================================
#  KIRI BAWAH — KONTROL DEVICE
# =================================================================
New-SectionLabel "[ DEVICE CONTROL ]" 5 360 $pnlLeft | Out-Null

$pnlControl = New-Object System.Windows.Forms.Panel
$pnlControl.Location  = New-Object System.Drawing.Point(5, 382)
$pnlControl.Size      = New-Object System.Drawing.Size(510, 100)
$pnlControl.BackColor = $clrPanel
$pnlLeft.Controls.Add($pnlControl)

$lblInputKey = New-Object System.Windows.Forms.Label
$lblInputKey.Text      = "Device Key (VID:PID) :"
$lblInputKey.ForeColor = $clrGray
$lblInputKey.Font      = $fntMonoSm
$lblInputKey.AutoSize  = $true
$lblInputKey.Location  = New-Object System.Drawing.Point(10, 12)
$pnlControl.Controls.Add($lblInputKey)

$txtDeviceKey = New-Object System.Windows.Forms.TextBox
$txtDeviceKey.Location  = New-Object System.Drawing.Point(175, 9)
$txtDeviceKey.Size      = New-Object System.Drawing.Size(110, 22)
$txtDeviceKey.BackColor = $clrBg
$txtDeviceKey.ForeColor = $clrWhite
$txtDeviceKey.Font      = $fntMono
$txtDeviceKey.BorderStyle = "FixedSingle"
$pnlControl.Controls.Add($txtDeviceKey)

$btnUnblock = New-Btn "Unblock"          10  45 110 32 $clrDarkGreen $pnlControl
$btnRemoveWL = New-Btn "Remove Whitelist" 130 45 150 32 ([System.Drawing.Color]::FromArgb(100,70,0)) $pnlControl
$btnFirstRun = New-Btn "Setup Awal"      290 45 110 32 ([System.Drawing.Color]::FromArgb(30,50,100)) $pnlControl

# =================================================================
#  KIRI BAWAH — WHITELIST & BLACKLIST
# =================================================================
New-SectionLabel "[ WHITELIST ]" 5 492 $pnlLeft | Out-Null

$lstWhitelist = New-Object System.Windows.Forms.ListBox
$lstWhitelist.Location  = New-Object System.Drawing.Point(5, 512)
$lstWhitelist.Size      = New-Object System.Drawing.Size(248, 88)
$lstWhitelist.BackColor = $clrPanel
$lstWhitelist.ForeColor = $clrGreen
$lstWhitelist.Font      = $fntMonoSm
$lstWhitelist.BorderStyle = "None"
$pnlLeft.Controls.Add($lstWhitelist)

New-SectionLabel "[ BLACKLIST ]" 262 492 $pnlLeft | Out-Null

$lstBlacklist = New-Object System.Windows.Forms.ListBox
$lstBlacklist.Location  = New-Object System.Drawing.Point(262, 512)
$lstBlacklist.Size      = New-Object System.Drawing.Size(248, 88)
$lstBlacklist.BackColor = $clrPanel
$lstBlacklist.ForeColor = $clrRed
$lstBlacklist.Font      = $fntMonoSm
$lstBlacklist.BorderStyle = "None"
$pnlLeft.Controls.Add($lstBlacklist)

# Double click whitelist → isi textbox
$lstWhitelist.Add_DoubleClick({
    if ($lstWhitelist.SelectedItem) {
        $txtDeviceKey.Text = $lstWhitelist.SelectedItem -replace '^\[OK\] ',''
    }
})
$lstBlacklist.Add_DoubleClick({
    if ($lstBlacklist.SelectedItem) {
        $txtDeviceKey.Text = $lstBlacklist.SelectedItem -replace '^\[X\]  ',''
    }
})

# =================================================================
#  KANAN — LOG USB SECURITY
# =================================================================
New-SectionLabel "[ USB SECURITY LOG ]" 5 5 $pnlRight | Out-Null

$txtUSBLog = New-Object System.Windows.Forms.RichTextBox
$txtUSBLog.Location   = New-Object System.Drawing.Point(5, 28)
$txtUSBLog.Size       = New-Object System.Drawing.Size(540, 480)
$txtUSBLog.BackColor  = $clrPanel
$txtUSBLog.ForeColor  = $clrWhite
$txtUSBLog.Font       = $fntMonoSm
$txtUSBLog.ReadOnly   = $true
$txtUSBLog.ScrollBars = "Vertical"
$txtUSBLog.BorderStyle = "None"
$pnlRight.Controls.Add($txtUSBLog)

# =================================================================
#  KANAN BAWAH — TOMBOL LOG
# =================================================================
$btnRefreshLog  = New-Btn "Refresh Log"    5   520 130 32 ([System.Drawing.Color]::FromArgb(30,50,80))  $pnlRight
$btnClearView   = New-Btn "Clear View"     145 520 120 32 ([System.Drawing.Color]::FromArgb(50,40,40))  $pnlRight
$btnOpenFolder  = New-Btn "Buka Folder"    275 520 120 32 ([System.Drawing.Color]::FromArgb(40,40,60))  $pnlRight
$btnAutoScroll  = New-Btn "Auto-Scroll ON" 405 520 135 32 ([System.Drawing.Color]::FromArgb(20,60,40))  $pnlRight

$script:AutoScroll = $true
$script:LastLogSize = 0

# =================================================================
#  FUNGSI LOAD LOG USB
# =================================================================
function Load-USBLog {
    $logPath = Join-Path $base "logs\usb_security.log"
    if (-not (Test-Path $logPath)) { return }

    try {
        $fs = [System.IO.FileStream]::new(
            $logPath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        $currentSize = $fs.Length

        if ($currentSize -le $script:LastLogSize) {
            $fs.Close()
            return
        }

        # Baca hanya bagian baru
        $fs.Seek($script:LastLogSize, [System.IO.SeekOrigin]::Begin) | Out-Null
        $reader = New-Object System.IO.StreamReader($fs)
        $newContent = $reader.ReadToEnd()
        $reader.Close()
        $fs.Close()

        $script:LastLogSize = $currentSize

        if ([string]::IsNullOrWhiteSpace($newContent)) { return }

        $newLines = $newContent -split "`n"
        foreach ($line in $newLines) {
            $line = $line.TrimEnd("`r")
            if ($line -eq "") {
                $txtUSBLog.SelectionColor = $clrWhite
                $txtUSBLog.AppendText("`n")
                continue
            }

            $color = $clrWhite
            if     ($line -match "\[BLOCK\]")   { $color = $clrRed }
            elseif ($line -match "\[ALERT\]")   { $color = [System.Drawing.Color]::FromArgb(255,140,0) }
            elseif ($line -match "\[TRUSTED\]") { $color = $clrCyan }
            elseif ($line -match "\[ALLOW\]")   { $color = $clrGreen }
            elseif ($line -match "\[INFO\]")    { $color = $clrGray }
            elseif ($line -match "^===")        { $color = $clrYellow }
            elseif ($line -match "^\s+\|")      { $color = [System.Drawing.Color]::FromArgb(170,170,170) }

            $txtUSBLog.SelectionColor = $color
            $txtUSBLog.AppendText("$line`n")
        }

        if ($script:AutoScroll) { $txtUSBLog.ScrollToCaret() }

    } catch {}
}

# =================================================================
#  FUNGSI LOAD WHITELIST & BLACKLIST
# =================================================================
function Load-Lists {
    $lstWhitelist.Items.Clear()
    $lstBlacklist.Items.Clear()

    $wlPath = Join-Path $base "whitelist.txt"
    if (Test-Path $wlPath) {
        Get-Content $wlPath | ForEach-Object {
            $parts = $_ -split '\|'
            if ($parts.Count -ge 1 -and $parts[0] -match ':') {
                $lstWhitelist.Items.Add("[OK] $($parts[0])")
            }
        }
    }

    $blPath = Join-Path $base "blacklist.txt"
    if (Test-Path $blPath) {
        Get-Content $blPath | ForEach-Object {
            $parts = $_ -split '\|'
            if ($parts.Count -ge 1 -and $parts[0] -match ':') {
                $lstBlacklist.Items.Add("[X]  $($parts[0])")
            }
        }
    }
}

# =================================================================
#  FUNGSI BACA BEHAVIORAL LOG REAL-TIME
# =================================================================
function Update-BehaviorLog {
    $logPath = Join-Path $base "logs\keyboard_input.log"
    if (-not (Test-Path $logPath)) { return }

    $cutoff = (Get-Date).AddSeconds(-3)
    $intervals = @()

    Get-Content $logPath -Tail 300 | ForEach-Object {
        if ($_ -match '^\d{4}-\d{2}-\d{2}') {
            $parts = $_ -split ','
            if ($parts.Count -ge 4) {
                try {
                    $ts = [DateTime]::Parse($parts[0])
                    $iv = [double]$parts[3]
                    if ($ts -gt $cutoff -and $iv -ge 0 -and $iv -lt 500) {
                        $intervals += $iv
                    }
                } catch {}
            }
        }
    }

    if ($intervals.Count -lt 5) {
        $statScore.Text = "0"
        $statAvg.Text   = "0"
        $statCV.Text    = "0"
        $statBurst.Text = "0"
        $statN.Text     = "0"
        $lblBehaviorStatus.Text      = "  Status : IDLE (tidak ada input)"
        $lblBehaviorStatus.ForeColor = $clrGray
        return
    }

    $avg = ($intervals | Measure-Object -Average).Average
    $std = [math]::Sqrt(($intervals | ForEach-Object { [math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average)
    $cv  = if ($avg -gt 0) { $std / $avg } else { 999 }
    $burst = ($intervals | Where-Object { $_ -lt 25 }).Count

    $score = 0
    if ($avg   -lt 50)  { $score += 1 }
    if ($avg   -lt 30)  { $score += 2 }
    if ($cv    -lt 0.5) { $score += 1 }
    if ($cv    -lt 0.2) { $score += 2 }
    if ($burst -ge 5)   { $score += 1 }
    if ($burst -ge 15)  { $score += 2 }
    $score = [math]::Min($score, 6)

    $statScore.Text = "$score"
    $statAvg.Text   = "$([math]::Round($avg,0))"
    $statCV.Text    = "$([math]::Round($cv,2))"
    $statBurst.Text = "$burst"
    $statN.Text     = "$($intervals.Count)"

    # Warna score
    if     ($score -ge 4) { $statScore.ForeColor = $clrRed }
    elseif ($score -ge 2) { $statScore.ForeColor = $clrYellow }
    else                  { $statScore.ForeColor = $clrCyan }

    $isSuspicious = $score -ge 4
    if ($isSuspicious) {
        $lblBehaviorStatus.Text      = "  !! SUSPICIOUS | Score=$score  Avg=$([math]::Round($avg,0))ms  CV=$([math]::Round($cv,2))  Burst=$burst"
        $lblBehaviorStatus.ForeColor = $clrRed
    } else {
        $lblBehaviorStatus.Text      = "  Status : NORMAL | Score=$score  Avg=$([math]::Round($avg,0))ms  CV=$([math]::Round($cv,2))  Burst=$burst"
        $lblBehaviorStatus.ForeColor = $clrGreen
    }

    # Tambah ke log behavior
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $tag   = if ($isSuspicious) { "[!!]" } else { "[ L]" }
    $color = if ($isSuspicious) { $clrRed } else { $clrGray }
    $line  = "$tag $timestamp  Score=$score  Avg=$([math]::Round($avg,0))ms  CV=$([math]::Round($cv,2))  Burst=$burst  N=$($intervals.Count)"

    $txtBehavior.SelectionColor = $color
    $txtBehavior.AppendText("$line`n")
    if ($txtBehavior.Lines.Count -gt 200) {
        $txtBehavior.Select(0, $txtBehavior.GetFirstCharIndexFromLine(50))
        $txtBehavior.SelectedText = ""
    }
    $txtBehavior.ScrollToCaret()
}

# =================================================================
#  EVENT TOMBOL
# =================================================================
$btnRefreshLog.Add_Click({
    Load-USBLog
    Load-Lists
})

$btnClearView.Add_Click({
    $txtUSBLog.Clear()
    $txtBehavior.Clear()
})

$btnOpenFolder.Add_Click({
    $logDir = Join-Path $base "logs"
    if (Test-Path $logDir) { Start-Process explorer $logDir }
})

$btnAutoScroll.Add_Click({
    $script:AutoScroll = -not $script:AutoScroll
    $btnAutoScroll.Text = if ($script:AutoScroll) { "Auto-Scroll ON" } else { "Auto-Scroll OFF" }
    $btnAutoScroll.BackColor = if ($script:AutoScroll) {
        [System.Drawing.Color]::FromArgb(20,60,40)
    } else {
        [System.Drawing.Color]::FromArgb(60,30,30)
    }
})

$btnUnblock.Add_Click({
    $key = $txtDeviceKey.Text.Trim()
    if ($key -notmatch '^[0-9A-Fa-f?]+:[0-9A-Fa-f?]+$') {
        [System.Windows.Forms.MessageBox]::Show(
            "Format salah.`nGunakan format  VID:PID`nContoh: 2341:8037", "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    # === VALIDASI: cek apakah ada di blacklist ===
    $blPath = Join-Path $base "blacklist.txt"
    $adaDiBlacklist = $false
    if (Test-Path $blPath) {
        $adaDiBlacklist = (Get-Content $blPath | Where-Object {
            ($_ -split '\|')[0].Trim() -eq $key
        }).Count -gt 0
    }

    if (-not $adaDiBlacklist) {
        [System.Windows.Forms.MessageBox]::Show(
            "Device $key tidak ditemukan di blacklist.`nTidak ada yang perlu di-unblock.", "Info",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Unblock device $key ?", "Konfirmasi",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirm -eq "Yes") {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$base\main.ps1`" -UnblockDevice `"$key`"" -Verb RunAs -Wait
        Load-USBLog
        Load-Lists
    }
})

$btnRemoveWL.Add_Click({
    $key = $txtDeviceKey.Text.Trim()
    if ($key -notmatch '^[0-9A-Fa-f?]+:[0-9A-Fa-f?]+$') {
        [System.Windows.Forms.MessageBox]::Show(
            "Format salah.`nGunakan format  VID:PID`nContoh: 3151:3020", "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    # === VALIDASI: cek apakah ada di whitelist ===
    $wlPath = Join-Path $base "whitelist.txt"
    $adaDiWhitelist = $false
    if (Test-Path $wlPath) {
        $adaDiWhitelist = (Get-Content $wlPath | Where-Object {
            ($_ -split '\|')[0].Trim() -eq $key
        }).Count -gt 0
    }

    if (-not $adaDiWhitelist) {
        [System.Windows.Forms.MessageBox]::Show(
            "Device $key tidak ditemukan di whitelist.`nTidak ada yang perlu dihapus.", "Info",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Hapus $key dari whitelist?`n`nDevice ini akan dianggap UNKNOWN saat dicolok lagi.", "Konfirmasi",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -eq "Yes") {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$base\main.ps1`" -RemoveWhitelist `"$key`"" -Verb RunAs -Wait
        Load-USBLog
        Load-Lists
    }
})

$btnFirstRun.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Jalankan Setup Awal (First Run)?`n`nJendela baru akan terbuka untuk mendaftarkan device.", "Konfirmasi",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($confirm -eq "Yes") {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$base\main.ps1`" -FirstRun" -Verb RunAs
    }
})

# =================================================================
#  TIMER — AUTO REFRESH
# =================================================================
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000  

$script:TickCount = 0
$timer.Add_Tick({
    $script:TickCount++

    Update-BehaviorLog

        Load-USBLog

    if ($script:TickCount % 10 -eq 0) {
        Load-Lists
    }

$monitorRunning = Get-Process -Id $script:MainPID -ErrorAction SilentlyContinue

    if ($monitorRunning) {
        $lblStatus.Text      = "● MONITORING AKTIF"
        $lblStatus.ForeColor = $clrGreen
    } else {
        $lblStatus.Text      = "○ MONITOR TIDAK AKTIF"
        $lblStatus.ForeColor = $clrRed
    }
})

# =================================================================
#  LOAD AWAL & JALANKAN
# =================================================================
Load-USBLog
Load-Lists

$sentinelPath = Join-Path $base "stop.signal"
Remove-Item $sentinelPath -ErrorAction SilentlyContinue

$mainScript = Join-Path $base "main.ps1"

$existing = Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -match [regex]::Escape($mainScript) -and
    $_.CommandLine -notmatch "UnblockDevice|RemoveWhitelist|FirstRun"
}

if (-not $existing) {
    $script:MainProcess = Start-Process powershell `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$mainScript`"" `
        -Verb RunAs -WindowStyle Hidden -PassThru

    $script:MainPID = $script:MainProcess.Id
    Start-Sleep 2  
} else {
    $script:MainPID = ($existing | Select-Object -First 1).ProcessId
}

$timer.Start()

$form.Add_FormClosing({
    $timer.Stop()
    $mainScript = Join-Path $base "main.ps1"
    $sentinelPath = Join-Path $base "stop.signal"
    "STOP" | Set-Content $sentinelPath

    $waited = 0
    while ($waited -lt 2000) {
        $stillRunning = Get-CimInstance Win32_Process | Where-Object {
            $_.CommandLine -match [regex]::Escape($mainScript) -and
            $_.CommandLine -notmatch "UnblockDevice|RemoveWhitelist|FirstRun"
        }
        if (-not $stillRunning) { break }
        Start-Sleep -Milliseconds 200
        $waited += 200
    }

    # Fallback kill
    Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -match [regex]::Escape($mainScript) -or
        $_.CommandLine -match "behavior_monitor\.ps1"
    } | ForEach-Object {
        try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
    }

    Remove-Item $sentinelPath -ErrorAction SilentlyContinue
})

$form.ShowDialog()
$timer.Stop()