import QtQuick
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
    readonly property bool classic: setting("appearance", "Classic") === "Classic"

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
            onCloseRequested: root.opened = false
            onAppearanceToggleRequested: root.toggleAppearance()
        }
    }
}
