#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
shell_dir="${OMARCHY_PATH:-/usr/share/omarchy}/shell"
lint_bin="$(command -v qmllint || true)"
if [[ -z "$lint_bin" ]]; then lint_bin=/usr/lib/qt6/bin/qmllint; fi
if [[ ! -x "$lint_bin" || ! -d "$shell_dir/Ui" ]]; then
  echo 'QML checks require qt6-declarative and an installed Omarchy shell.' >&2
  exit 1
fi
# Quickshell supplies the virtual qs import at runtime. Recreate that import
# only in a temporary lint directory; installed plugins contain no symlinks.
lint_dir="$(mktemp -d)"
trap 'rm -rf "$lint_dir"' EXIT
ln -s "$shell_dir" "$lint_dir/qs"
"$lint_bin" -I "$lint_dir" -I "$shell_dir" \
  BarWidget.qml Panel.qml VolumeControl.qml Service.qml AudioChannel.qml
