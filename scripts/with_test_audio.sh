#!/usr/bin/env bash
# Isolated native PipeWire backend: no hardware devices or desktop defaults.
set -euo pipefail
runtime="$(mktemp -d)"
export XDG_RUNTIME_DIR="$runtime"
export XDG_STATE_HOME="$runtime/state"
export XDG_CONFIG_HOME="$runtime/config"
export PIPEWIRE_RUNTIME_DIR="$runtime"
export PIPEWIRE_REMOTE=pipewire-0
export PULSE_RUNTIME_PATH="$runtime/pulse"
export PULSE_SERVER="unix:$runtime/pulse/native"
export QT_QPA_PLATFORM=offscreen
export QT_QPA_PLATFORMTHEME=''
export QT_QUICK_BACKEND=software
export QT_AUDIO_BACKEND=pipewire
export MURMUR_PRIVATE_AUDIO=1
unset WAYLAND_DISPLAY DISPLAY
pids=()
cleanup() {
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait || true
  rm -rf "$runtime"
}
trap cleanup EXIT
mkdir -p "$XDG_CONFIG_HOME/wireplumber/wireplumber.conf.d"
cat > "$XDG_CONFIG_HOME/wireplumber/wireplumber.conf.d/no-hardware.conf" <<'CONFIG'
wireplumber.profiles = {
  main = {
    monitor.alsa = disabled
    monitor.bluez = disabled
    monitor.v4l2 = disabled
    monitor.libcamera = disabled
  }
}
CONFIG
pipewire > "$runtime/pipewire.log" 2>&1 & pids+=("$!")
for i in {1..50}; do [[ -S "$runtime/pipewire-0" ]] && break; sleep .1; done
wireplumber > "$runtime/wireplumber.log" 2>&1 & pids+=("$!")
pipewire-pulse > "$runtime/pulse.log" 2>&1 & pids+=("$!")
for i in {1..50}; do pactl info >/dev/null 2>&1 && break; sleep .1; done
if ! pactl info >/dev/null 2>&1; then
  cat "$runtime/pipewire.log" "$runtime/pulse.log" >&2
  exit 1
fi
"$@"
