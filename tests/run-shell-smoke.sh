#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_dir=${OMARCHY_SHELL_DIR:-/usr/share/omarchy/shell}
smoke_dir=$(mktemp -d /tmp/rpn-shell-smoke.XXXXXX)
trap 'rm -rf -- "$smoke_dir"' EXIT
cp "$repo_dir/tests/smoke/shell.qml" "$smoke_dir/shell.qml"
ln -s "$shell_dir/Commons" "$smoke_dir/Commons"
ln -s "$shell_dir/Ui" "$smoke_dir/Ui"
ln -s "$repo_dir/plugin" "$smoke_dir/plugin"

# A separate, hidden host loads real Quickshell/Omarchy components. It neither
# installs the plugin nor changes the running desktop's bar configuration.
wayland_socket=${WAYLAND_DISPLAY:-wayland-0}
if [[ $wayland_socket != /* ]]; then
    wayland_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$wayland_socket"
fi
mkdir "$smoke_dir/runtime"
mkdir "$smoke_dir/state"
chmod 700 "$smoke_dir/runtime"
XDG_RUNTIME_DIR="$smoke_dir/runtime" XDG_STATE_HOME="$smoke_dir/state" WAYLAND_DISPLAY="$wayland_socket" \
QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
    timeout 15s quickshell --no-color -p "$smoke_dir/shell.qml" >"$smoke_dir/log" 2>&1 || {
        cat "$smoke_dir/log"
        exit 1
    }
cat "$smoke_dir/log"
rg -q 'RPN_SMOKE_PASS' "$smoke_dir/log"
jq -e '.version == 1 and .stack == [42] and .lastArguments == []' \
    "$smoke_dir/state/omarchy-rpn-calc.json" >/dev/null
if rg -q '(TypeError|ReferenceError|SyntaxError|Error loading configuration|is not a type|Cannot assign|Unable to assign)' "$smoke_dir/log"; then
    exit 1
fi
RPN_SMOKE_RESTORE=1 XDG_RUNTIME_DIR="$smoke_dir/runtime" \
XDG_STATE_HOME="$smoke_dir/state" WAYLAND_DISPLAY="$wayland_socket" \
QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
    timeout 15s quickshell --no-color -p "$smoke_dir/shell.qml" >"$smoke_dir/restore-log" 2>&1 || {
        cat "$smoke_dir/restore-log"
        exit 1
    }
cat "$smoke_dir/restore-log"
rg -q 'RPN_RESTORE_PASS' "$smoke_dir/restore-log"
