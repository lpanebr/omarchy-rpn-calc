import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons
import "RpnEngine.js" as Engine

Ui.BarWidget {
    id: root
    moduleName: "lpanebr.rpn-calc"

    // Keep the model alive when the popup closes.
    property var calculatorState: Engine.createState()
    property bool opened: false
    property bool popoutSwitchClosing: false
    property bool stateLoaded: false
    property string persistedSnapshot: ""
    readonly property bool classic: setting("appearance", "Classic") === "Classic"
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME")
        || Quickshell.env("HOME") + "/.local/state"
    readonly property string statePath: stateHome + "/omarchy-rpn-calc.json"

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function open() { opened = true }
    function close() { calculator.dismiss() }
    function toggle() { opened = !opened }
    function closeForPopoutSwitch() {
        popoutSwitchClosing = true
        opened = false
        Qt.callLater(function() { root.popoutSwitchClosing = false })
    }

    function toggleAppearance() {
        var entry = { id: moduleName }
        for (var key in settings) if (key !== "id") entry[key] = settings[key]
        entry.appearance = classic ? "Omarchy" : "Classic"
        settings = entry
        if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
            bar.shell.updateEntryInline(moduleName, entry)
    }

    function stateSnapshot() {
        return JSON.stringify({
            version: 1,
            stack: calculatorState.stack,
            lastArguments: calculatorState.lastArguments || []
        })
    }

    function finiteNumberArray(value) {
        if (!Array.isArray(value)) return false
        for (var i = 0; i < value.length; i++)
            if (typeof value[i] !== "number" || !isFinite(value[i])) return false
        return true
    }

    function restoreState(raw) {
        try {
            var saved = JSON.parse(String(raw || ""))
            if (!saved || saved.version !== 1 || !finiteNumberArray(saved.stack)
                    || !finiteNumberArray(saved.lastArguments || []))
                throw new Error("invalid state")
            calculatorState.stack = saved.stack.slice()
            calculatorState.lastArguments = (saved.lastArguments || []).slice()
        } catch (error) {
            console.warn("RPN Calculator: ignoring invalid state file at " + statePath)
        }
        stateLoaded = true
        persistedSnapshot = stateSnapshot()
        Qt.callLater(function() { if (calculator) calculator.refresh() })
    }

    function persistState() {
        if (!stateLoaded) return
        var snapshot = stateSnapshot()
        if (snapshot === persistedSnapshot) return
        persistedSnapshot = snapshot
        stateFile.setText(snapshot + "\n")
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.restoreState(text())
        onLoadFailed: function(error) {
            root.stateLoaded = true
            root.persistedSnapshot = root.stateSnapshot()
        }
        onFileChanged: reload()
    }

    Ui.WidgetButton {
        id: button
        bar: root.bar
        text: "󰃬"
        tooltipText: "RPN Calculator"
        active: root.opened
        onPressed: function(mouseButton) {
            if (mouseButton === Qt.LeftButton) root.toggle()
        }
    }

    Ui.KeyboardPanel {
        id: popup
        anchorItem: button
        bar: root.bar
        owner: root
        open: root.opened
        focusTarget: calculator
        contentWidth: fittedContentWidth(calculator.implicitWidth + padding * 2)
        contentHeight: fittedContentHeight(calculator.implicitHeight)

        Panel {
            id: calculator
            anchors.fill: parent
            calculatorState: root.calculatorState
            classic: root.classic
            onStateMutated: root.persistState()
            onCloseRequested: root.opened = false
            onAppearanceToggleRequested: root.toggleAppearance()
        }
    }
}
