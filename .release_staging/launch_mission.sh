#!/usr/bin/env bash
# =============================================================================
# launch_mission.sh
# LunarLander3D — Smart Launcher
# Starts the live dashboard on the LEFT, then the mission on the RIGHT.
# =============================================================================
# Usage:
#   ./launch_mission.sh v1 [extra args...]
#   ./launch_mission.sh v2 --fixed
#   ./launch_mission.sh v3 --spawn -1000 -1000 1000 --orient 45 45 45
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MISSION_ID="${1:-v1}"
shift || true   # remove first arg, pass the rest to the mission

case "$MISSION_ID" in
    v1) MISSION_SCRIPT="mission_v1_classic.py"   ;;
    v2) MISSION_SCRIPT="mission_v2_direct.py"    ;;
    v3) MISSION_SCRIPT="mission_v3_trajectory.py";;
    *)  echo "Usage: $0 [v1|v2|v3] [args...]"; exit 1 ;;
esac

echo "======================================"
echo "  LunarLander3D Launcher"
echo "  Mission : $MISSION_SCRIPT"
echo "  Args    : $*"
echo "======================================"

# 1. Start live dashboard in the background
echo "[Launcher] Starting live_dashboard.py ..."
python live_dashboard.py &
DASHBOARD_PID=$!
echo "[Launcher] Dashboard PID = $DASHBOARD_PID"

# 2. Wait for dashboard window to be ready
sleep 2.5

# 3. Try to position the dashboard window to the LEFT side of screen
#    (Only works if xdotool is installed)
if command -v xdotool &>/dev/null; then
    echo "[Launcher] Positioning dashboard window (LEFT side)..."
    for attempt in 1 2 3 4 5; do
        WIN_ID=$(xdotool search --name "LunarLander3D" 2>/dev/null | head -1)
        if [ -n "$WIN_ID" ]; then
            xdotool windowmove "$WIN_ID" 20 60
            echo "[Launcher] Dashboard moved to x=20 y=60"
            break
        fi
        sleep 0.5
    done
else
    echo "[Launcher] xdotool not found. Install with: sudo apt install xdotool"
    echo "[Launcher] Please position the dashboard window manually to the LEFT."
fi

# 4. Launch the mission script
echo "[Launcher] Starting mission: $MISSION_SCRIPT ..."
python "$MISSION_SCRIPT" "$@"
EXIT_CODE=$?

# 5. When mission ends, try to move PyBullet window to the RIGHT
if command -v xdotool &>/dev/null; then
    BULL_ID=$(xdotool search --name "Bullet" 2>/dev/null | head -1)
    if [ -n "$BULL_ID" ]; then
        xdotool windowmove "$BULL_ID" 1100 60
    fi
fi

echo ""
echo "[Launcher] Mission complete (exit $EXIT_CODE)."
echo "[Launcher] Dashboard is still running (PID $DASHBOARD_PID). Press Ctrl+C to quit."
wait $DASHBOARD_PID
