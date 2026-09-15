#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
runner="$(command -v qmltestrunner || true)"
if [[ -z "$runner" ]]; then runner=/usr/lib/qt6/bin/qmltestrunner; fi
# Keep integration-test audio out of the user's speakers. Only these test
# fixtures select the temporary device explicitly; Qt need not honor PULSE_SINK.
# The system default is never changed.
test_sink="yuragi-test-$$"
module_id="$(pactl load-module module-null-sink sink_name="$test_sink" sink_properties=device.description=YuragiTest)"
trap 'pactl unload-module "$module_id"' EXIT
QT_QPA_PLATFORM=offscreen \
  "$runner" -input tests/tst_service.qml "$@"
