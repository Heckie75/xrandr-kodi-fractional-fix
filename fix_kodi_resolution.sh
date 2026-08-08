#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: fix_kodi_resolution.sh [--dry-run|-n] [--help|-h]

Apply an X11 xrandr panning fix for Kodi fullscreen when fractional scaling is enabled.
EOF
}

DRY_RUN=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=1
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
 done

if ! command -v xrandr >/dev/null 2>&1; then
    echo "Error: xrandr is not installed or not available in PATH." >&2
    exit 1
fi

XRANDR_OUT=$(xrandr --current --verbose)

MONITOR=$(printf '%s\n' "$XRANDR_OUT" | grep -m1 " connected primary" | awk '{print $1}')
if [ -z "$MONITOR" ]; then
    MONITOR=$(printf '%s\n' "$XRANDR_OUT" | grep -m1 " connected" | awk '{print $1}')
fi

if [ -z "$MONITOR" ]; then
    echo "Error: No active monitor found in xrandr output. Aborting." >&2
    exit 1
fi

MONITOR_BLOCK=$(printf '%s\n' "$XRANDR_OUT" | awk -v mon="$MONITOR" '
    $0 ~ "^"mon" " {flag = 1; print; next}
    flag && /^[^[:space:]]/ && $2 ~ /(connected|disconnected)/ {flag = 0}
    flag {print}
')

NATIVE_RES=$(printf '%s\n' "$MONITOR_BLOCK" | awk '/^[[:space:]]+[0-9]+x[0-9]+/ && /[*+]/ {print $1; exit}')
if [ -z "$NATIVE_RES" ]; then
    NATIVE_RES=$(printf '%s\n' "$MONITOR_BLOCK" | awk '/^[[:space:]]+[0-9]+x[0-9]+/ {print $1; exit}')
fi

WIDTH=${NATIVE_RES%x*}
HEIGHT=${NATIVE_RES#*x}
if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
    echo "Error: Could not determine native resolution for $MONITOR. Aborting." >&2
    exit 1
fi

SCALE_X=$(printf '%s\n' "$MONITOR_BLOCK" | awk '/Transform:/ {print $2; exit}')
SCALE_Y=$(printf '%s\n' "$MONITOR_BLOCK" | awk '/Transform:/ {getline; print $2; exit}')
if [ -z "$SCALE_X" ] || [ -z "$SCALE_Y" ]; then
    echo "Error: Could not determine the transform scale factors for $MONITOR. Aborting." >&2
    exit 1
fi

SCALE_X=$(LC_NUMERIC=C printf "%.2f" "$SCALE_X")
SCALE_Y=$(LC_NUMERIC=C printf "%.2f" "$SCALE_Y")
SCALE_PARAM="${SCALE_X}x${SCALE_Y}"

printf 'Monitor:            %s\n' "$MONITOR"
printf 'Native Resolution:  %sx%s\n' "$WIDTH" "$HEIGHT"
printf 'Current Scale:      %s\n' "$SCALE_PARAM"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: xrandr --output $MONITOR --scale $SCALE_PARAM --panning ${WIDTH}x${HEIGHT}"
    exit 0
fi

xrandr --output "$MONITOR" --scale "$SCALE_PARAM" --panning "${WIDTH}x${HEIGHT}"

