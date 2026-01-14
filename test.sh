#!/system/bin/sh

# =================================================
# KAERU ROBLOX MULTI INSTANCE MANAGER (SIMPLIFIED)
# =================================================

MAX_INSTANCE=10
CHECK_INTERVAL=5
CACHE_INTERVAL=900  # 15 menit
RAM_THRESHOLD=500   # MB

# ---------- SIMPLE LOGGING ----------
log() {
  echo "[$(date '+%H:%M:%S')] $1"
}

# ---------- GET RAM INFO ----------
get_ram() {
  FREE=$(cat /proc/meminfo 2>/dev/null | grep MemAvailable | awk '{print int($2/1024)}' || echo 500)
  TOTAL=$(cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{print int($2/1024)}' || echo 4096)
  [ -z "$FREE" ] && FREE=500
  [ -z "$TOTAL" ] && TOTAL=4096
}

# ---------- CLEAN CACHE ----------
clean_cache() {
  log "Cleaning cache..."
  # Hanya bersihkan cache untuk package Roblox
  for pkg in $PACKAGES; do
    if [ -d "/data/data/$pkg/cache" ]; then
      rm -rf /data/data/$pkg/cache/* 2>/dev/null
      log "  Cleared cache for $pkg"
    fi
  done
  sync
}

# ---------- DETECT PACKAGES ----------
detect_packages() {
  PACKAGES=$(pm list packages 2>/dev/null | grep -i roblox | cut -d: -f2 | head -n $MAX_INSTANCE)
  COUNT=$(echo "$PACKAGES" | wc -l)
  if [ "$COUNT" -eq 0 ]; then
    log "ERROR: No Roblox packages found!"
    return 1
  fi
  return 0
}

# ---------- CHECK IF RUNNING ----------
is_running() {
  pkg=$1
  # Check using ps
  if ps -A 2>/dev/null | grep -q "$pkg"; then
    return 0
  fi
  # Check using pidof
  if pidof "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# ---------- LAUNCH APP ----------
launch_app() {
  pkg=$1
  idx=$2
  
  log "Launching $pkg (idx:$idx)..."
  
  # Coba berbagai cara untuk launch
  success=0
  
  # Cara 1: Standard launch
  am start --user 0 -a android.intent.action.MAIN \
    --activity-options '{"android.activity.windowingMode":5}' \
    -n "$pkg/$pkg.ActivitySplash" >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    success=1
  else
    # Cara 2: Coba tanpa activity specifik
    am start --user 0 -a android.intent.action.MAIN \
      --activity-options '{"android.activity.windowingMode":5}' \
      "$pkg" >/dev/null 2>&1
    [ $? -eq 0 ] && success=1
  fi
  
  if [ $success -eq 1 ]; then
    sleep 2
    # Coba resize window jika berhasil
    resize_window "$pkg" "$idx"
    return 0
  else
    log "Failed to launch $pkg"
    return 1
  fi
}

# ---------- RESIZE WINDOW ----------
resize_window() {
  pkg=$1
  idx=$2
  
  # Dapatkan task ID
  sleep 1
  task_id=$(am stack list 2>/dev/null | grep -A2 "$pkg" | grep "taskId=" | sed 's/.*taskId=//' | awk '{print $1}' | head -1)
  
  if [ -n "$task_id" ] && [ "$task_id" != "null" ]; then
    # Hitung posisi grid sederhana (2 kolom)
    if [ $idx -lt 2 ]; then
      col=$idx
      row=0
    else
      col=$((idx % 2))
      row=$((idx / 2))
    fi
    
    width=540  # Setengah layar
    height=1200
    
    x=$((col * width))
    y=$((row * height))
    
    log "Resizing $pkg to $width x $height at $x,$y"
    
    # Coba berbagai cara resize
    wm resize-task "$task_id" "$x" "$y" "$width" "$height" >/dev/null 2>&1
    sleep 0.5
    wm task position "$task_id" "$x" "$y" >/dev/null 2>&1
    sleep 0.5
    wm task resize "$task_id" "$width" "$height" >/dev/null 2>&1
  fi
}

# ---------- MAIN SCRIPT ----------
log "Starting Kaeru Roblox Manager..."

# Deteksi package pertama kali
if ! detect_packages; then
  exit 1
fi

log "Found $COUNT Roblox packages"

# Setup layar
SCREEN_SIZE=$(wm size 2>/dev/null | grep -o "[0-9]\+x[0-9]\+" || echo "1080x2400")
SCREEN_W=$(echo "$SCREEN_SIZE" | cut -dx -f1)
SCREEN_H=$(echo "$SCREEN_SIZE" | cut -dx -f2)

[ -z "$SCREEN_W" ] && SCREEN_W=1080
[ -z "$SCREEN_H" ] && SCREEN_H=2400

log "Screen size: ${SCREEN_W}x${SCREEN_H}"

# Launch semua app
idx=0
for pkg in $PACKAGES; do
  if ! is_running "$pkg"; then
    launch_app "$pkg" "$idx"
  else
    log "$pkg is already running"
  fi
  idx=$((idx + 1))
done

# Main monitoring loop
last_clean=$(date +%s)
clean_counter=0

while true; do
  # Update package list setiap 10 iterasi
  if [ $((clean_counter % 10)) -eq 0 ]; then
    detect_packages
  fi
  
  # Bersihkan UI
  clear 2>/dev/null || printf "\033c"
  
  # Header
  echo "================================================"
  echo " KAERU ROBLOX MANAGER v2.0"
  echo "================================================"
  
  # RAM info
  get_ram
  echo " RAM: ${FREE}MB / ${TOTAL}MB"
  echo " Packages: $COUNT"
  echo " Time: $(date '+%H:%M:%S')"
  echo "-----------------------------------------------"
  
  # Tampilkan status packages
  idx=0
  relaunch_count=0
  echo "NO  PACKAGE                STATUS"
  echo "--- ---------------------  -------"
  
  for pkg in $PACKAGES; do
    if is_running "$pkg"; then
      status="✓ ONLINE"
    else
      status="✗ OFFLINE"
      # Relaunch otomatis
      log "Relaunching $pkg..."
      launch_app "$pkg" "$idx"
      relaunch_count=$((relaunch_count + 1))
    fi
    
    # Tampilkan dengan nomor pendek
    num=$((idx + 1))
    if [ ${#pkg} -gt 20 ]; then
      pkg_short="${pkg:0:17}..."
    else
      pkg_short="$pkg"
    fi
    
    printf "%-3s %-22s %s\n" "$num" "$pkg_short" "$status"
    idx=$((idx + 1))
  done
  
  echo "-----------------------------------------------"
  
  if [ $relaunch_count -gt 0 ]; then
    echo " Relaunched: $relaunch_count instance(s)"
  fi
  
  # Auto clean cache setiap CACHE_INTERVAL
  current_time=$(date +%s)
  if [ $((current_time - last_clean)) -ge $CACHE_INTERVAL ]; then
    clean_cache
    last_clean=$current_time
    echo " Cache cleaned!"
  fi
  
  # Clean RAM jika rendah
  if [ $FREE -lt $RAM_THRESHOLD ]; then
    echo " RAM low! Cleaning..."
    clean_cache
    # Juga coba free pagecache
    sync
    echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
  fi
  
  clean_counter=$((clean_counter + 1))
  
  # Sleep dengan progress bar sederhana
  echo -n " Next check in: "
  for i in $(seq 1 $CHECK_INTERVAL); do
    echo -n "."
    sleep 1
  done
  echo ""
done
