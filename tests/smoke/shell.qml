import QtQuick
import Quickshell
import "plugin" as Calculator

ShellRoot {
    property int phase: 0
    property int restoreAttempts: 0
    readonly property bool restoring: Quickshell.env("RPN_SMOKE_RESTORE") === "1"
    PanelWindow {
        id: window
        visible: false
        implicitWidth: 400
        implicitHeight: 450
        Calculator.BarWidget { id: widget }
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            if (restoring) {
                if (widget.calculatorState.stack.length === 1
                        && widget.calculatorState.stack[0] === 42) {
                    console.log("RPN_RESTORE_PASS")
                    Qt.quit()
                    return
                }
                restoreAttempts++
                if (restoreAttempts > 10)
                    throw new Error("Saved stack was not restored")
                return
            }
            if (phase === 1) {
                widget.close()
                if (widget.opened || widget.calculatorState.stack[0] !== 42)
                    throw new Error("Closing the panel lost its state")
                phase = 2
                return
            }
            if (phase === 2) {
                console.log("RPN_SMOKE_PASS")
                Qt.quit()
                return
            }
            if (widget.calculatorState.stack.length !== 0)
                throw new Error("Unexpected initial stack")
            widget.calculatorState.stack.push(42)
            widget.persistState()
            if (!widget.classic) throw new Error("Classic is not the default appearance")
            widget.toggleAppearance()
            if (widget.classic) throw new Error("Appearance did not toggle")
            widget.toggleAppearance()
            if (!widget.classic) throw new Error("Appearance did not restore")
            widget.open()
            if (!widget.opened) throw new Error("Panel did not open")
            phase = 1
        }
    }
}
