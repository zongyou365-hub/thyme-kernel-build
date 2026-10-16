# ============================================================
# KPM verify script (Xiaomi 10S / SukiSU M13 kernel)
# Usage: run in PowerShell. Output ends with a RESULT line.
# ============================================================

$adb = "D:\AndroidWatch_ADB_ToolBox\adb\adb.exe"

function Sh([string]$cmd) {
    & $adb shell "su -c '$cmd'" 2>&1 | Out-String
}

Write-Output "==================================================="
Write-Output " [0] device and kernel"
Write-Output "==================================================="
& $adb devices 2>&1 | Out-String
Write-Output "--- kernel version ---"
& $adb shell uname -r 2>&1 | Out-String

Write-Output "==================================================="
Write-Output " [1] kernel KPM symbols"
Write-Output "==================================================="
Sh "grep -E 'sukisu_kpm|do_kpm' /proc/kallsyms | head -8"
$symCount = (Sh "grep -c 'sukisu_kpm' /proc/kallsyms").Trim()
Write-Output "sukisu_kpm symbol count: $symCount"

Write-Output "==================================================="
Write-Output " [2] kpmmgr tool check"
Write-Output "==================================================="
Sh "ls -la /data/adb/ksu/bin/kpmmgr /data/adb/ksud 2>/dev/null"

Write-Output "==================================================="
Write-Output " [3] KPM version probe (KEY)"
Write-Output "==================================================="
$ver = (Sh "/data/adb/ksu/bin/kpmmgr version 2>&1").Trim()
Write-Output $ver

Write-Output "==================================================="
Write-Output " [4] loaded KPM list"
Write-Output "==================================================="
$list = (Sh "/data/adb/ksu/bin/kpmmgr list 2>&1").Trim()
Write-Output $list

Write-Output "==================================================="
Write-Output " [5] KPM files on device"
Write-Output "==================================================="
Sh "ls -la /data/adb/kpm/ 2>/dev/null"

Write-Output "==================================================="
Write-Output " [6] dmesg KPM records"
Write-Output "==================================================="
Sh "dmesg | grep -iE 'kpm|kpatch' | head -10"

Write-Output ""
Write-Output "================ RESULT ================"
if ($ver -match "(?i)version\s*[:=]?\s*\d" -or $ver -match "^\d+(\.\d+)*$") {
    Write-Output "RESULT: KPM=OK kpmmgr=$ver"
} elseif ($ver -match "(?i)not found|no such|denied|error|invalid|unknown") {
    Write-Output "RESULT: KPM=FAIL kpmmgr=$ver"
} else {
    Write-Output "RESULT: MANUAL-CHECK kpmmgr=$ver"
}
Write-Output "========================================="
