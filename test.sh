#!/system/bin/sh

# ==============================================
# KAERU ROBLOX WINDOW ARRANGER (RESIZE ONLY)
# ==============================================

# ---------- CONFIG ----------
MAX_INSTANCE=10
GRID_COLS=2           # 2 kolom
GRID_ROWS=5           # maks 5 baris (untuk 10 instance)
MARGIN=5              # margin antar window
TITLEBAR_HEIGHT=80    # tinggi title bar

# ---------- FUNCTIONS ----------
log() {
  echo "[$(date '+%H:%M:%S')] $1"
}

get_screen_size() {
  SCREEN_INFO=$(wm size 2>/dev/null | grep -o "[0-9]\+x[0-9]\+")
  if [ -n "$SCREEN_INFO" ]; then
    SCREEN_W=$(echo "$SCREEN_INFO" | cut -dx -f1)
    SCREEN_H=$(echo "$SCREEN_INFO" | cut -dx -f2)
  else
    # Default untuk layar 1080x2400
    SCREEN_W=1080
    SCREEN_H=2400
  fi
  log "Screen: ${SCREEN_W}x${SCREEN_H}"
}

get_roblox_packages() {
  PACKAGES=$(pm list packages 2>/dev/null | grep -i roblox | cut -d: -f2 | head -n $MAX_INSTANCE)
  COUNT=$(echo "$PACKAGES" | wc -l)
  
  if [ "$COUNT" -eq 0 ]; then
    log "No Roblox packages found!"
    exit 1
  fi
  
  log "Found $COUNT Roblox packages"
  echo "$PACKAGES" | while read pkg; do
    log "  - $pkg"
  done
}

get_task_info() {
  PKG=$1
  # Cari task ID dari package
  TASK_INFO=$(am stack list 2>/dev/null | grep -B2 -A2 "$PKG")
  
  # Extract task ID
  TASK_ID=$(echo "$TASK_INFO" | grep "taskId=" | sed 's/.*taskId=//g' | awk '{print $1}' | head -1)
  
  # Extract window bounds jika ada
  BOUNDS=$(echo "$TASK_INFO" | grep "bounds=" | sed 's/.*bounds=\[//g;s/\].*//g')
  
  echo "$TASK_ID $BOUNDS"
}

arrange_windows() {
  log "Starting window arrangement..."
  
  # Hitung ukuran window
  TOTAL_MARGIN_W=$(( (GRID_COLS + 1) * MARGIN ))
  TOTAL_MARGIN_H=$(( (GRID_ROWS + 1) * MARGIN + (GRID_ROWS * TITLEBAR_HEIGHT) ))
  
  WINDOW_W=$(( (SCREEN_W - TOTAL_MARGIN_W) / GRID_COLS ))
  WINDOW_H=$(( (SCREEN_H - TOTAL_MARGIN_H) / GRID_ROWS ))
  
  log "Window size: ${WINDOW_W}x${WINDOW_H}"
  
  # Atur semua window
  INDEX=0
  for PKG in $PACKAGES; do
    log "Processing $PKG..."
    
    # Dapatkan task info
    TASK_INFO=$(get_task_info "$PKG")
    TASK_ID=$(echo "$TASK_INFO" | awk '{print $1}')
    
    if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "null" ] || [ "$TASK_ID" = "0" ]; then
      log "  No active task found, skipping..."
      continue
    fi
    
    log "  Task ID: $TASK_ID"
    
    # Hitung posisi grid
    ROW=$((INDEX / GRID_COLS))
    COL=$((INDEX % GRID_COLS))
    
    POS_X=$(( (COL * (WINDOW_W + MARGIN)) + MARGIN ))
    POS_Y=$(( (ROW * (WINDOW_H + MARGIN + TITLEBAR_HEIGHT)) + MARGIN ))
    
    log "  Position: Grid [${ROW},${COL}] -> ${POS_X},${POS_Y}"
    
    # 1. Pastikan dalam mode freeform
    wm task windowing-mode $TASK_ID 5 >/dev/null 2>&1
    sleep 0.1
    
    # 2. Set posisi
    wm task position $TASK_ID $POS_X $POS_Y >/dev/null 2>&1
    sleep 0.1
    
    # 3. Set ukuran
    wm task resize $TASK_ID $WINDOW_W $WINDOW_H >/dev/null 2>&1
    sleep 0.1
    
    # 4. Juga coba dengan resize-task (metode alternatif)
    wm resize-task $TASK_ID $POS_X $POS_Y $WINDOW_W $WINDOW_H >/dev/null 2>&1
    sleep 0.1
    
    # 5. Bawa ke depan
    am task lock $TASK_ID >/dev/null 2>&1
    sleep 0.1
    
    INDEX=$((INDEX + 1))
    
    # Delay antar window
    sleep 0.3
  done
  
  log "Arranged $INDEX windows"
}

arrange_cascade() {
  log "Arranging windows in cascade style..."
  
  CASCADE_OFFSET=60
  BASE_W=$((SCREEN_W * 70 / 100))
  BASE_H=$((SCREEN_H * 70 / 100))
  
  INDEX=0
  for PKG in $PACKAGES; do
    TASK_INFO=$(get_task_info "$PKG")
    TASK_ID=$(echo "$TASK_INFO" | awk '{print $1}')
    
    if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "null" ]; then
      continue
    fi
    
    POS_X=$((INDEX * CASCADE_OFFSET))
    POS_Y=$((INDEX * CASCADE_OFFSET))
    
    # Jika keluar dari layar, reset posisi
    if [ $((POS_X + BASE_W)) -gt $SCREEN_W ] || [ $((POS_Y + BASE_H)) -gt $SCREEN_H ]; then
      POS_X=0
      POS_Y=0
    fi
    
    log "Cascade $PKG to $POS_X,$POS_Y"
    
    wm task windowing-mode $TASK_ID 5 >/dev/null 2>&1
    sleep 0.1
    wm task position $TASK_ID $POS_X $POS_Y >/dev/null 2>&1
    sleep 0.1
    wm task resize $TASK_ID $BASE_W $BASE_H >/dev/null 2>&1
    sleep 0.1
    
    INDEX=$((INDEX + 1))
    sleep 0.3
  done
}

arrange_horizontal() {
  log "Arranging windows horizontally..."
  
  WINDOW_W=$((SCREEN_W / COUNT))
  WINDOW_H=$((SCREEN_H * 80 / 100))
  
  INDEX=0
  for PKG in $PACKAGES; do
    TASK_INFO=$(get_task_info "$PKG")
    TASK_ID=$(echo "$TASK_INFO" | awk '{print $1}')
    
    if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "null" ]; then
      continue
    fi
    
    POS_X=$((INDEX * WINDOW_W))
    POS_Y=0
    
    log "Horizontal $PKG to $POS_X,0"
    
    wm task windowing-mode $TASK_ID 5 >/dev/null 2>&1
    sleep 0.1
    wm task position $TASK_ID $POS_X $POS_Y >/dev/null 2>&1
    sleep 0.1
    wm task resize $TASK_ID $WINDOW_W $WINDOW_H >/dev/null 2>&1
    sleep 0.1
    
    INDEX=$((INDEX + 1))
    sleep 0.3
  done
}

show_menu() {
  clear 2>/dev/null || printf "\033c"
  echo "========================================"
  echo "   KAERU ROBLOX WINDOW ARRANGER"
  echo "========================================"
  get_screen_size
  get_roblox_packages
  echo "----------------------------------------"
  echo "  [1] Grid Layout (${GRID_COLS}x)"
  echo "  [2] Cascade Layout"
  echo "  [3] Horizontal Layout"
  echo "  [4] Custom Layout Setup"
  echo "  [5] Refresh Package List"
  echo "  [0] Exit"
  echo "----------------------------------------"
  echo -n " Select: "
}

custom_setup() {
  clear
  echo "=== Custom Layout Setup ==="
  echo ""
  echo -n "Grid Columns (default $GRID_COLS): "
  read cols
  [ -n "$cols" ] && GRID_COLS=$cols
  
  echo -n "Grid Rows (default $GRID_ROWS): "
  read rows
  [ -n "$rows" ] && GRID_ROWS=$rows
  
  echo -n "Margin (default $MARGIN): "
  read margin
  [ -n "$margin" ] && MARGIN=$margin
  
  echo -n "Titlebar Height (default $TITLEBAR_HEIGHT): "
  read titlebar
  [ -n "$titlebar" ] && TITLEBAR_HEIGHT=$titlebar
  
  echo "Settings updated!"
  echo "Press Enter to continue..."
  read
}

# ---------- MAIN ----------
main() {
  # Dapatkan info layar
  get_screen_size
  
  # Dapatkan packages
  get_roblox_packages
  
  while true; do
    show_menu
    read choice
    
    case $choice in
      1)
        arrange_windows
        echo "Grid layout applied!"
        sleep 2
        ;;
      2)
        arrange_cascade
        echo "Cascade layout applied!"
        sleep 2
        ;;
      3)
        arrange_horizontal
        echo "Horizontal layout applied!"
        sleep 2
        ;;
      4)
        custom_setup
        ;;
      5)
        get_roblox_packages
        echo "Package list refreshed!"
        sleep 2
        ;;
      0)
        log "Exiting..."
        exit 0
        ;;
      *)
        echo "Invalid choice!"
        sleep 1
        ;;
    esac
  done
}

# ---------- QUICK ARRANGE MODE ----------
# Jika dijalankan dengan parameter, langsung arrange
if [ "$1" = "grid" ]; then
  get_screen_size
  get_roblox_packages
  arrange_windows
  exit 0
elif [ "$1" = "cascade" ]; then
  get_screen_size
  get_roblox_packages
  arrange_cascade
  exit 0
elif [ "$1" = "horizontal" ]; then
  get_screen_size
  get_roblox_packages
  arrange_horizontal
  exit 0
fi

# Jalankan main menu
main
