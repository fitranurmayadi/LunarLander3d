#!/usr/bin/env bash
# =============================================================================
# launch_mission.sh
# LunarLander3D — Smart Launcher
# =============================================================================
# Usage:
#   ./launch_mission.sh v1 [extra args...]
#   ./launch_mission.sh v2 --fixed
#   ./launch_mission.sh v3 --spawn -1000 -1000 1000 --orient 45 45 45
#   ./launch_mission.sh v1 --no-dashboard   # run without live dashboard
# =============================================================================

# Parse optional flag
NO_DASHBOARD=0
# Collect all args; support --no-dashboard anywhere
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--no-dashboard" ]]; then
    NO_DASHBOARD=1
  else
    ARGS+=("$arg")
  fi
done

# Reassign positional parameters without the flag
set -- "${ARGS[@]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MISSION_ID="${1:-v1}"
shift || true   # remove first arg, pass the rest to the mission

case "$MISSION_ID" in
    v1) MISSION_SCRIPT="mission_v1_classic.py"   ;;
    v2) MISSION_SCRIPT="mission_v2_direct.py"    ;;
    v3) MISSION_SCRIPT="mission_v3_trajectory.py";;
    *)  echo "Usage: $0 [v1|v2|v3] [--no-dashboard] [args...]"; exit 1 ;;
esac

echo "======================================"
echo "  LunarLander3D Launcher"
echo "  Mission : $MISSION_SCRIPT"
echo "  Args    : $*"
echo "======================================"

# 1. Start live dashboard in the background unless disabled
if [[ $NO_DASHBOARD -eq 0 ]]; then
  echo "[Launcher] Starting live_dashboard.py ..."
  python live_dashboard.py &
  DASHBOARD_PID=$!
  echo "[Launcher] Dashboard PID = $DASHBOARD_PID"
  # 2. Wait for dashboard window to be ready
  sleep 4.0
  # 3. Position the dashboard window on the RIGHT side of screen
  if command -v xdotool &>/dev/null; then
    for attempt in 1 2 3 4 5; do
      WIN_ID=$(xdotool search --name "LunarLander3D Dashboard" 2>/dev/null | head -1)
      if [ -n "$WIN_ID" ]; then
        xdotool windowmove "$WIN_ID" 1100 60
        echo "[Launcher] Dashboard moved to x=1100 y=60"
        break
      fi
      sleep 0.5
    done
  else
    echo "[Launcher] xdotool not found. Install with: sudo apt install xdotool"
    echo "[Launcher] Please position the dashboard window manually to the RIGHT."
  fi
fi

# 4. Launch the mission script in background
echo "[Launcher] Starting mission: $MISSION_SCRIPT ..."
python "$MISSION_SCRIPT" "$@" &
MISSION_PID=$!
# Give PyBullet a moment to create its window
sleep 4.0
# 5. Move PyBullet (Physics Server) window to the LEFT side
if command -v xdotool &>/dev/null; then
  echo "[Launcher] Positioning PyBullet window (LEFT side)..."
  for attempt in 1 2 3 4 5; do
    BULL_ID=$(xdotool search --name "Physics Server" "Bullet" 2>/dev/null | head -1)
    if [ -z "$BULL_ID" ]; then BULL_ID=$(xdotool search --name "Bullet" 2>/dev/null | head -1); fi
    if [ -n "$BULL_ID" ]; then
      xdotool windowmove "$BULL_ID" 20 60
      echo "[Launcher] PyBullet moved to x=20 y=60"
      break
    fi
    sleep 0.5
  done
else
  echo "[Launcher] xdotool not found. Install with: sudo apt install xdotool"
  echo "[Launcher] Please position the PyBullet window manually to the LEFT."
fi

# Wait for mission to finish
wait $MISSION_PID
EXIT_CODE=$?

echo ""
echo "[Launcher] Mission complete (exit $EXIT_CODE)."
if [[ $NO_DASHBOARD -eq 0 ]]; then
  echo "[Launcher] Dashboard is still running (PID $DASHBOARD_PID). Press Ctrl+C to quit."
  wait $DASHBOARD_PID
fi
