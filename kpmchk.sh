#!/system/bin/sh
# KPM verify script - runs ON the phone (via su)
echo "=== [kernel] ==="
uname -r
echo "=== [1] KPM symbols in /proc/kallsyms ==="
grep -c sukisu_kpm /proc/kallsyms
grep -e sukisu_kpm -e do_kpm /proc/kallsyms | head -8
echo "=== [2] tools ==="
ls -la /data/adb/ksu/bin/kpmmgr /data/adb/ksud 2>/dev/null
echo "=== [3] KPM version probe (KEY) ==="
/data/adb/ksu/bin/kpmmgr version 2>&1
echo "=== [4] loaded KPM list ==="
/data/adb/ksu/bin/kpmmgr list 2>&1
echo "=== [5] KPM files ==="
ls -la /data/adb/kpm/ 2>/dev/null
echo "=== [6] dmesg KPM records ==="
dmesg 2>/dev/null | grep -i -e kpm -e kpatch | head -10
echo "=== [7] ksud env (KSU variant) ==="
/data/adb/ksud debug 2>&1 | head -20
echo "=== END ==="
