#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# On Arch /usr/bin/qmltestrunner belongs to Qt 5; this panel requires Qt 6.
qml_runner=${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}
if [[ ! -x "$qml_runner" ]]; then
    printf 'Qt 6 qmltestrunner not found. Set QMLTESTRUNNER to its path.\n' >&2
    exit 1
fi

# Theme/switch fixtures isolate panel behavior from the Quickshell host.
# These tests do not validate shell integration or the real theme singletons.
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
    "$qml_runner" -import "$test_dir/fixtures" -input "$test_dir/tst_Panel.qml" "$@"
