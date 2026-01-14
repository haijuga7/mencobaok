#!/system/bin/sh

# ==============================================
# KAERU ROBLOX WINDOW ARRANGER (ROOT VERSION)
# Menggunakan tsu untuk akses root
# ==============================================

# ---------- CONFIG ----------
MAX_INSTANCE=10
GRID_COLS=2           # 2 kolom
GRID_ROWS=5           # maks 5 baris
MARGIN=10             # margin antar window
TITLEBAR_HEIGHT=50    # tinggi title bar

# ---------- FUNCTIONS ----------
log() {
  echo "[$(date '+%H:%M:%S')] $1"
}

check_root() {
  if [ "$(whoami)" != "root" ]; then
    log "Script perlu dijalankan sebagai root!"
    log "Gunakan: tsu atau su terlebih dahulu"
    exit 1
  fi
}

get_screen_size() {
  SCREEN_INFO=$(wm size 2>/dev/null | grep -o "[0-9]\+x[0-9]\+")
  if [ -n "$SCREEN_INFO" ]; then
    SCREEN_W=$(echo "$SCREEN_INFO" | cut -dx -f1)
    SCREEN_H=$(echo "$SCREEN_INFO" | cut -dx -f2)
  else
    # Gunakan dumpsys untuk mendapatkan resolusi layar
    SCREEN_INFO=$(dumpsys window displays | grep "init=" | head -1)
    SCREEN_W=$(echo "$SCREEN_INFO" | grep -o "init=[0-9]\+x[0-9]\+" | cut -dx -f1 | cut -d= -f2)
    SCREEN_H=$(echo "$SCREEN_INFO" | grep -o "init=[0-9]\+x[0-9]\+" | cut -dx -f2)
    
    if [ -z "$SCREEN_W" ]; then
      SCREEN_W=1080
      SCREEN_H=2400
    fi
  fi
  log "Screen: ${SCREEN_W}x${SCREEN_H}"
}

get_roblox_tasks() {
  log "Scanning for Roblox tasks..."
  
  # Gunakan dumpsys untuk mendapatkan informasi window yang lebih detail
  ROOT_WINDOWS=$(dumpsys window windows | grep -E "Window #|mBounds=|mTitle=|package=")
  
  # Cari semua window Roblox
  ROBLOX_TASKS=""
  CURRENT_TASK=""
  CURRENT_PACKAGE=""
  
  echo "$ROOT_WINDOWS" | while IFS= read -r line; do
    # Cari package Roblox
    if echo "$line" | grep -q "package=com.roblox"; then
      CURRENT_PACKAGE=$(echo "$line" | grep -o "package=[^ ]*" | cut -d= -f2)
    fi
    
    # Cari task/window ID
    if echo "$line" | grep -q "Window #"; then
      if [ -n "$CURRENT_TASK" ] && [ -n "$CURRENT_PACKAGE" ]; then
        # Simpan task sebelumnya
        ROBLOX_TASKS="${ROBLOX_TASKS}${CURRENT_TASK}|${CURRENT_PACKAGE}\n"
      fi
      CURRENT_TASK=$(echo "$line" | grep -o "Window #[0-9a-f]*" | cut -d# -f2)
      CURRENT_PACKAGE=""
    fi
    
    # Tangkap bounds/window position
    if echo "$line" | grep -q "mBounds=\[" && [ -n "$CURRENT_TASK" ] && [ -n "$CURRENT_PACKAGE" ]; then
      BOUNDS=$(echo "$line" | grep -o "\[[0-9]*,[0-9]*\]" | tr -d '[]' | tr ',' ' ')
      echo "Found window: $CURRENT_TASK - $CURRENT_PACKAGE - $BOUNDS"
    fi
  done
  
  # Juga cari dengan am stack list
  AM_TASKS=$(am stack list 2>/dev/null | grep -E "taskId=|.*roblox.*")
  
  # Ekstrak task ID untuk Roblox
  echo "$AM_TASKS" | while IFS= read -r line; do
    if echo "$line" | grep -q "com.roblox"; then
      TASK_ID=$(echo "$line" | grep -o "taskId=[0-9]*" | cut -d= -f2)
      PACKAGE=$(echo "$line" | grep -o "com.roblox[^ /]*")
      if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "null" ] && [ "$TASK_ID" != "0" ]; then
        log "Task found via am: $TASK_ID - $PACKAGE"
        echo "${TASK_ID}|${PACKAGE}"
      fi
    fi
  done
}

arrange_windows_root() {
  log "ARRANGING WINDOWS WITH ROOT ACCESS..."
  
  # Hitung ukuran window
  WINDOW_W=$(( (SCREEN_W - (MARGIN * (GRID_COLS + 1))) / GRID_COLS ))
  WINDOW_H=$(( (SCREEN_H - (MARGIN * (GRID_ROWS + 1)) - (TITLEBAR_HEIGHT * GRID_ROWS)) / GRID_ROWS ))
  
  log "Window size: ${WINDOW_W}x${WINDOW_H}"
  
  # Dapatkan semua task Roblox
  TASKS=$(get_roblox_tasks)
  
  if [ -z "$TASKS" ]; then
    log "No Roblox tasks found! Make sure Roblox windows are open."
    return 1
  fi
  
  # Hitung jumlah task
  TASK_COUNT=$(echo "$TASKS" | wc -l)
  log "Found $TASK_COUNT Roblox tasks"
  
  # Atur setiap window
  INDEX=0
  echo "$TASKS" | while IFS= read -r TASK_INFO; do
    [ -z "$TASK_INFO" ] && continue
    
    TASK_ID=$(echo "$TASK_INFO" | cut -d'|' -f1)
    PACKAGE=$(echo "$TASK_INFO" | cut -d'|' -f2)
    
    log "Arranging task $TASK_ID ($PACKAGE)..."
    
    # Hitung posisi grid
    ROW=$((INDEX / GRID_COLS))
    COL=$((INDEX % GRID_COLS))
    
    POS_X=$(( (COL * (WINDOW_W + MARGIN)) + MARGIN ))
    POS_Y=$(( (ROW * (WINDOW_H + MARGIN + TITLEBAR_HEIGHT)) + MARGIN ))
    
    log "  Position: [${ROW},${COL}] -> ${POS_X},${POS_Y}"
    
    # ===== METODE 1: Menggunakan wm command dengan root =====
    # Set windowing mode ke freeform (5)
    wm task windowing-mode $TASK_ID 5
    sleep 0.05
    
    # Set position
    wm task position $TASK_ID $POS_X $POS_Y
    sleep 0.05
    
    # Set size
    wm task resize $TASK_ID $WINDOW_W $WINDOW_H
    sleep 0.05
    
    # ===== METODE 2: Menggunakan service call dengan root =====
    # Alternatif jika wm tidak bekerja
    service call activity 1599295570 i32 $TASK_ID i32 5
    sleep 0.05
    
    # ===== METODE 3: Menggunakan input tap untuk memastikan =====
    # Bawa window ke depan dengan input tap
    input tap $((POS_X + 10)) $((POS_Y + 10))
    sleep 0.05
    
    INDEX=$((INDEX + 1))
    
    if [ $INDEX -ge $MAX_INSTANCE ]; then
      break
    fi
  done
  
  log "Arranged $INDEX windows"
}

arrange_windows_direct() {
  log "USING DIRECT WINDOW MANAGEMENT..."
  
  # Cari semua surface/window Roblox secara langsung
  SURFACE_LIST=$(dumpsys SurfaceFlinger --list 2>/dev/null | grep -i roblox)
  
  if [ -n "$SURFACE_LIST" ]; then
    echo "$SURFACE_LIST" | while IFS= read -r SURFACE; do
      log "Found surface: $SURFACE"
      # Anda bisa mencoba memanipulasi surface langsung di sini
    done
  fi
  
  # Gunakan alternative method dengan dumpsys window
  log "Setting window positions via dumpsys..."
  
  # Dapatkan semua window Roblox
  WINDOW_LIST=$(dumpsys window windows | grep -B5 -A5 "com.roblox" | grep "Window #")
  
  INDEX=0
  echo "$WINDOW_LIST" | while IFS= read -r WINDOW_LINE; do
    WINDOW_HASH=$(echo "$WINDOW_LINE" | grep -o "#[0-9a-f]*" | cut -d# -f2)
    
    if [ -n "$WINDOW_HASH" ]; then
      # Hitung posisi
      ROW=$((INDEX / GRID_COLS))
      COL=$((INDEX % GRID_COLS))
      
      WINDOW_W=$((SCREEN_W / GRID_COLS - 20))
      WINDOW_H=$((SCREEN_H / GRID_ROWS - 100))
      
      POS_X=$((COL * WINDOW_W + 10))
      POS_Y=$((ROW * WINDOW_H + 50))
      
      log "Window $WINDOW_HASH -> ${POS_X},${POS_Y} ${WINDOW_W}x${WINDOW_H}"
      
      # Coba atur window melalui service call
      service call window 18 i32 0 i32 $WINDOW_HASH i32 $POS_X i32 $POS_Y i32 $WINDOW_W i32 $WINDOW_H
      sleep 0.1
      
      INDEX=$((INDEX + 1))
    fi
  done
}

quick_arrange() {
  log "QUICK ARRANGE MODE"
  
  # Layout sederhana: setengah layar untuk 2 window
  if [ "$1" = "2" ]; then
    log "2-window layout"
    # Window kiri
    wm task position 1 0 0
    wm task resize 1 $((SCREEN_W/2)) $SCREEN_H
    # Window kanan
    wm task position 2 $((SCREEN_W/2)) 0
    wm task resize 2 $((SCREEN_W/2)) $SCREEN_H
    
  # 4 window grid
  elif [ "$1" = "4" ]; then
    log "4-window grid"
    HALF_W=$((SCREEN_W/2))
    HALF_H=$((SCREEN_H/2))
    
    wm task position 1 0 0
    wm task resize 1 $HALF_W $HALF_H
    
    wm task position 2 $HALF_W 0
    wm task resize 2 $HALF_W $HALF_H
    
    wm task position 3 0 $HALF_H
    wm task resize 3 $HALF_W $HALF_H
    
    wm task position 4 $HALF_W $HALF_H
    wm task resize 4 $HALF_W $HALF_H
    
  else
    # Default: arrange semua window
    arrange_windows_root
  fi
}

show_menu() {
  clear 2>/dev/null || printf "\033c"
  echo "========================================"
  echo "   KAERU ROBLOX ROOT WINDOW ARRANGER"
  echo "========================================"
  echo " Root access: $(whoami)"
  get_screen_size
  echo "----------------------------------------"
  echo "  [1] Arrange All Windows (Grid)"
  echo "  [2] Quick Arrange - 2 Windows"
  echo "  [3] Quick Arrange - 4 Windows"
  echo "  [4] Direct Window Management"
  echo "  [5] Refresh Window List"
  echo "  [6] Test Root Commands"
  echo "  [0] Exit"
  echo "----------------------------------------"
  echo -n " Select: "
}

test_root_commands() {
  log "Testing root commands..."
  echo ""
  echo "1. Testing wm command:"
  wm size
  echo ""
  echo "2. Testing am command:"
  am stack list | head -5
  echo ""
  echo "3. Testing dumpsys window:"
  dumpsys window | grep "init=" | head -1
  echo ""
  echo "4. Checking Roblox processes:"
  ps -A | grep roblox | head -5
  echo ""
  echo "Press Enter to continue..."
  read
}

# ---------- MAIN ----------
main() {
  # Cek root access
  check_root
  
  # Dapatkan info layar
  get_screen_size
  
  while true; do
    show_menu
    read choice
    
    case $choice in
      1)
        arrange_windows_root
        echo "Windows arranged!"
        sleep 2
        ;;
      2)
        quick_arrange 2
        echo "2-window layout applied!"
        sleep 1
        ;;
      3)
        quick_arrange 4
        echo "4-window layout applied!"
        sleep 1
        ;;
      4)
        arrange_windows_direct
        echo "Direct window management done!"
        sleep 2
        ;;
      5)
        get_roblox_tasks
        echo "Window list refreshed!"
        sleep 2
        ;;
      6)
        test_root_commands
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

# ---------- AUTO-RUN ----------
# Jika ada parameter, langsung jalankan
if [ "$1" = "auto" ]; then
  check_root
  get_screen_size
  arrange_windows_root
  exit 0
elif [ "$1" = "quick2" ]; then
  check_root
  get_screen_size
  quick_arrange 2
  exit 0
elif [ "$1" = "quick4" ]; then
  check_root
  get_screen_size
  quick_arrange 4
  exit 0
fi

# Jalankan main menu
main
