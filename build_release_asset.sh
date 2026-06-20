#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$ROOT_DIR/github_release_full"

if [[ ! -d "$RELEASE_DIR" ]]; then
  echo "[ERROR] Release source directory not found: $RELEASE_DIR" >&2
  exit 1
fi

OUT_ZIP="$ROOT_DIR/LunarLander3D-release.zip"
OUT_TAR="$ROOT_DIR/LunarLander3D-release.tar.gz"

rm -f "$OUT_ZIP" "$OUT_TAR"

echo "[INFO] Building release assets (clean & clear)..."
echo "[INFO] Source: $RELEASE_DIR"
echo "[INFO] ZIP   : $OUT_ZIP"
echo "[INFO] TAR   : $OUT_TAR"

# Create a temporary staging directory so ZIP/TAR root is exactly what you want.
STAGING="$ROOT_DIR/.release_staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copy only what should be shown on GitHub repo root page / release landing
cp "$RELEASE_DIR/README.md" "$STAGING/"
cp "$RELEASE_DIR/requirements.txt" "$STAGING/"

# launch scripts (optional but recommended)
cp "$RELEASE_DIR/launch_mission.sh" "$STAGING/" 2>/dev/null || true
cp "$RELEASE_DIR/live_dashboard.py" "$STAGING/" 2>/dev/null || true
cp "$RELEASE_DIR/osc_sender.py" "$STAGING/" 2>/dev/null || true

# missions + planner
cp "$RELEASE_DIR/mission_v1_classic.py" "$STAGING/" 2>/dev/null || true
cp "$RELEASE_DIR/mission_v2_direct.py" "$STAGING/" 2>/dev/null || true
cp "$RELEASE_DIR/mission_v3_trajectory.py" "$STAGING/" 2>/dev/null || true
cp "$RELEASE_DIR/trajectory_planner.py" "$STAGING/" 2>/dev/null || true

# package + assets
rm -rf "$STAGING/lunar_lander_3d"
cp -R "$RELEASE_DIR/lunar_lander_3d" "$STAGING/"

# reports
rm -rf "$STAGING/reports"
cp -R "$RELEASE_DIR/reports" "$STAGING/"

# Remove pycache from staging (so they won't show up in release)
find "$STAGING" -type d -name "__pycache__" -prune -exec rm -rf {} + >/dev/null 2>&1 || true

# Build archives from staging root (NO wrapping folder)
(
  cd "$STAGING"
  zip -rq "$OUT_ZIP" .
)
(
  cd "$STAGING"
  tar -czf "$OUT_TAR" .
)

# Quick sanity checks
echo "[INFO] ZIP entries (first 20):"
unzip -l "$OUT_ZIP" | awk 'NR<=24{print}'

echo "[INFO] TAR entries (first 20):"
tar -tzf "$OUT_TAR" | head -n 20

echo "[DONE] Release assets created."

rm -rf "$STAGING"

