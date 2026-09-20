import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui as Ui
import "RpnEngine.js" as Engine

FocusScope {
    id: root
    property var calculatorState: Engine.createState()
    property bool classic: false
    property int revision: 0
    property int selectedLevel: 0
    property int selectedFunction: -1
    property bool helpOpen: false
    property bool confirmingClear: false
    readonly property string entry: { revision; return calculatorState.entry }
    readonly property int count: { revision; return calculatorState.stack.length }
    readonly property var error: { revision; return calculatorState.error }
    readonly property color ink: classic ? "#d9dcdd" : Color.foreground
    readonly property color accent: classic ? "#70ced8" : Color.accent
    readonly property color lcdInk: classic ? "#253025" : Color.foreground
    readonly property int pad: Style.space(12)
    readonly property real displayFontSize: Style.font.body * 2
    readonly property real displayRowHeight: Math.max(Style.space(40), displayFontSize * 1.4)
    readonly property var functions: [
        { name: "sqrt", label: "√x", hint: "Square root" },
        { name: "pow", label: "yˣ", hint: "Raise level 2 to level 1" },
        { name: "reciprocal", label: "1/x", hint: "Reciprocal" },
        { name: "sign", label: "+/−", hint: "Change sign" },
        { name: "arg", label: "arg", hint: "Restore last operation arguments" },
        { name: "drop", label: "drop", hint: "Remove top" },
        { name: "swap", label: "swap", hint: "Exchange top two" },
        { name: "clear", label: "clear", hint: "Clear stack (confirmation required)" }
    ]
    readonly property var operations: [
        { name: "/", label: "÷", hint: "Divide" },
        { name: "*", label: "×", hint: "Multiply" },
        { name: "-", label: "−", hint: "Subtract" },
        { name: "+", label: "+", hint: "Add" }
    ]
    readonly property var actions: functions.concat(operations)
    readonly property int gridColumns: 4
    readonly property int gridRows: Math.ceil(actions.length / gridColumns)
    signal stateMutated()
    signal closeRequested()
    signal appearanceToggleRequested()
    implicitWidth: Style.space(360)
    implicitHeight: body.implicitHeight + pad * 2
    focus: true

    function refresh() {
        revision++
        stateMutated()
        forceActiveFocus()
        Qt.callLater(function() {
            if (selectedLevel > 0) stackView.positionViewAtIndex(Math.max(4, count) - selectedLevel, ListView.Contain)
            else stackView.positionViewAtEnd()
        })
    }
    function dismiss() {
        if (helpOpen) helpOpen = false
        else closeRequested()
    }
    function handleEscape() {
        if (helpOpen) helpOpen = false
        else if (error) { Engine.clearError(calculatorState); refresh() }
        else if (confirmingClear) confirmingClear = false
        else if (selectedLevel || selectedFunction >= 0) { selectedLevel = 0; selectedFunction = -1; refresh() }
        else if (entry.length) { calculatorState.entry = ""; calculatorState.cursor = 0; refresh() }
        else closeRequested()
    }
    function run(name) {
        if (confirmingClear) return
        if (name === "clear") { confirmingClear = true; forceActiveFocus(); return }
        selectedLevel = 0
        selectedFunction = -1
        Engine.operate(calculatorState, name)
        refresh()
    }
    function clearConfirmed() {
        confirmingClear = false
        selectedLevel = 0
        selectedFunction = -1
        Engine.operate(calculatorState, "clear")
        refresh()
    }
    function browse(delta) {
        selectedFunction = -1
        if (count === 0) return
        selectedLevel = selectedLevel === 0 ? 1 : Math.max(1, Math.min(count, selectedLevel + delta))
        Engine.clearError(calculatorState)
        refresh()
    }
    function pick() {
        if (selectedLevel < 1 || selectedLevel > count) return
        calculatorState.stack.push(calculatorState.stack[count - selectedLevel])
        Engine.clearError(calculatorState)
        selectedLevel = 0
        refresh()
    }
    function arrow(key) {
        if (selectedFunction >= 0) {
            var col = selectedFunction % gridColumns
            var row = Math.floor(selectedFunction / gridColumns)
            if (key === Qt.Key_Left) col = (col + gridColumns - 1) % gridColumns
            if (key === Qt.Key_Right) col = (col + 1) % gridColumns
            if (key === Qt.Key_Up) row = (row + gridRows - 1) % gridRows
            if (key === Qt.Key_Down) row = (row + 1) % gridRows
            selectedFunction = row * gridColumns + col
        } else if (entry.length && !selectedLevel && (key === Qt.Key_Left || key === Qt.Key_Right)) {
            Engine.moveCursor(calculatorState, key === Qt.Key_Left ? -1 : 1)
        } else {
            selectedLevel = 0
            selectedFunction = key === Qt.Key_Up ? (gridRows - 1) * gridColumns
                : key === Qt.Key_Left ? gridColumns - 1 : 0
        }
        Engine.clearError(calculatorState)
        refresh()
    }
    Keys.onPressed: function(event) {
        event.accepted = true
        var key = event.key
        var ctrl = !!(event.modifiers & Qt.ControlModifier)
        if (key === Qt.Key_Escape) { handleEscape(); return }
        if (event.text === "?") { helpOpen = !helpOpen; return }
        if (helpOpen) return
        if (confirmingClear) {
            if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Y) clearConfirmed()
            else if (key === Qt.Key_N) confirmingClear = false
            return
        }
        if (ctrl && key === Qt.Key_C) {
            if (count) { clipboard.text = String(calculatorState.stack[count - 1]); clipboard.selectAll(); clipboard.copy() }
            return
        }
        if (ctrl && key === Qt.Key_V) {
            clipboard.text = ""
            clipboard.paste()
            Engine.paste(calculatorState, clipboard.text)
            refresh()
            return
        }
        if (key === Qt.Key_P && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier))) { browse(1); return }
        if (key === Qt.Key_N && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier))) { browse(-1); return }
        if (ctrl || (event.modifiers & (Qt.AltModifier | Qt.MetaModifier))) { event.accepted = false; return }
        var viKeys = { h: Qt.Key_Left, j: Qt.Key_Down, k: Qt.Key_Up, l: Qt.Key_Right }
        var editingEntry = entry.length > 0 && selectedLevel === 0 && selectedFunction < 0
        if (!editingEntry && viKeys[event.text] !== undefined) { arrow(viKeys[event.text]); return }
        if ([Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].indexOf(key) >= 0) { arrow(key); return }
        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            if (selectedFunction >= 0) run(actions[selectedFunction].name)
            else if (selectedLevel) pick()
            else { Engine.commit(calculatorState); refresh() }
            return
        }
        if (/^[0-9.]$/.test(event.text)) {
            if (selectedLevel) { calculatorState.entry = ""; calculatorState.cursor = 0 }
            selectedLevel = 0
            selectedFunction = -1
            Engine.insert(calculatorState, event.text)
            refresh()
        } else if (["+", "-", "*", "/"].indexOf(event.text) >= 0) run(event.text)
        else if (event.text === "_") { Engine.toggleSign(calculatorState); refresh() }
        else if (key === Qt.Key_Backspace) { Engine.backspace(calculatorState); refresh() }
        else if (key === Qt.Key_Delete && !entry.length) run("drop")
        else event.accepted = false
    }

    // Native Qt clipboard access; this editor never participates in focus traversal.
    TextEdit { id: clipboard; visible: false; textFormat: TextEdit.PlainText }
    Rectangle {
        anchors.fill: parent
        color: root.classic ? "#30343a" : Color.background
        radius: root.classic ? Style.space(5) : Style.cornerRadius
    }
    component KeyButton: Rectangle {
        id: button
        property string label
        property string hint: ""
        property bool selected: false
        property bool functionKey: false
        signal triggered()
        implicitHeight: Style.space(32)
        color: mouse.pressed ? (root.classic ? "#535a63" : Style.pressedFill)
             : selected || mouse.containsMouse ? (root.classic ? "#414d56" : Style.hoverFill)
             : root.classic ? "#3a3e44" : Style.normalFill
        border.width: selected ? 2 : 1
        border.color: selected ? root.accent : root.classic ? "#697078" : Style.normalBorderColor
        radius: root.classic ? Style.space(functionKey ? 8 : 2) : Style.cornerRadius
        Text {
            anchors.centerIn: parent
            text: (button.selected ? "› " : "") + (root.classic && button.functionKey ? button.label.toUpperCase() : button.label)
            color: root.ink
            font.family: Style.fontFamily
            font.pixelSize: Style.font.body
            font.bold: root.classic && button.functionKey
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.forceActiveFocus(); button.triggered() }
        }
        Controls.ToolTip.visible: mouse.containsMouse && hint.length > 0
        Controls.ToolTip.text: hint
        Controls.ToolTip.delay: 700
    }
    component HelpSection: Column {
        required property string title
        required property var shortcuts
        width: parent ? parent.width : 0
        spacing: Style.space(5)

        Text {
            text: parent.title
            textFormat: Text.PlainText
            color: Qt.darker(root.ink, 1.45)
            font.family: Style.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            font.letterSpacing: 1.2
        }
        Repeater {
            model: parent.shortcuts
            Row {
                required property var modelData
                width: parent.width
                height: Math.max(shortcutText.implicitHeight, descriptionText.implicitHeight)
                spacing: Style.space(10)
                Text {
                    id: shortcutText
                    width: Style.space(128)
                    text: modelData[0]
                    textFormat: Text.PlainText
                    color: root.accent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                }
                Text {
                    id: descriptionText
                    width: parent.width - shortcutText.width - parent.spacing
                    text: modelData[1]
                    textFormat: Text.PlainText
                    color: root.ink
                    font.family: Style.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
    Column {
        id: body
        x: root.pad; y: root.pad
        width: parent.width - root.pad * 2
        spacing: Style.space(10)
        Item {
            width: parent.width; height: Style.space(42)
            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(1)
                Text {
                    text: "RPN Calculator"; color: root.ink
                    font.family: Style.fontFamily; font.pixelSize: Style.font.body
                }
                Text {
                    text: "not for normies"
                    color: Qt.darker(root.ink, 1.55)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.italic: true
                }
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(8)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.classic ? "Classic" : "Omarchy"
                    color: root.ink
                    font.family: Style.fontFamily
                    font.pixelSize: Style.font.bodySmall
                }
                Ui.ToggleSwitch {
                    objectName: "appearanceToggle"
                    checked: root.classic
                    rounded: false
                    cursorPad: Style.space(2)
                    trackHeight: Style.space(24)
                    trackWidth: Style.space(48)
                    foreground: root.ink
                    accent: root.accent
                    onToggled: {
                        root.forceActiveFocus()
                        root.appearanceToggleRequested()
                    }
                }
            }
        }
        Rectangle {
            width: parent.width
            height: display.implicitHeight + Style.space(16)
            color: root.classic ? "#b2bda1" : Style.normalFill
            border.width: 1
            border.color: root.classic ? "#1e2327" : Style.normalBorderColor
            Column {
                id: display
                x: Style.space(8); y: Style.space(8)
                width: parent.width - Style.space(16)
                Text {
                    width: parent.width
                    height: Style.space(36)
                    text: root.error ? (root.error.operation + " Error:\n" + root.error.message) : ""
                    color: root.classic ? "#573522" : Color.urgent
                    font.family: Style.fontFamily; font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                }
                ListView {
                    id: stackView
                    objectName: "stackView"
                    width: parent.width; height: root.displayRowHeight * 4
                    clip: true
                    model: Math.max(4, root.count)
                    boundsBehavior: Flickable.StopAtBounds
                    Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }
                    Component.onCompleted: positionViewAtEnd()
                    delegate: Rectangle {
                        id: stackRow
                        required property int index
                        readonly property int level: Math.max(4, root.count) - index
                        readonly property bool selected: root.selectedLevel === level
                        width: stackView.width; height: root.displayRowHeight
                        color: selected ? (root.classic ? "#96a48a" : Style.selectedFill) : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: stackRow.level + ":"; color: root.lcdInk
                            font.family: "monospace"; font.pixelSize: Style.font.body
                        }
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: Style.space(42)
                            anchors.right: parent.right; anchors.rightMargin: Style.space(12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: { root.revision; return stackRow.level <= root.count ? String(root.calculatorState.stack[root.count - stackRow.level]) + (stackRow.selected ? " ‹" : "") : "" }
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideMiddle
                            color: root.lcdInk; font.family: "monospace"; font.pixelSize: root.displayFontSize
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.confirmingClear && stackRow.level <= root.count
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.forceActiveFocus()
                                root.selectedFunction = -1
                                if (root.selectedLevel === stackRow.level) root.pick()
                                else {
                                    root.selectedLevel = stackRow.level
                                    Engine.clearError(root.calculatorState)
                                    root.refresh()
                                }
                            }
                        }
                    }
                }
                Item {
                    width: parent.width; height: root.displayRowHeight
                    clip: true
                    FontMetrics { id: entryMetrics; font: entryText.font }
                    Text {
                        id: entryText
                        anchors.verticalCenter: parent.verticalCenter
                        // Keep the insertion marker visible even for an entry wider than the display.
                        x: {
                            root.revision
                            if (implicitWidth <= parent.width) return parent.width - implicitWidth
                            var beforeCursor = "› " + root.entry.slice(0, root.calculatorState.cursor)
                            return -Math.max(0, Math.min(implicitWidth - parent.width,
                                entryMetrics.advanceWidth(beforeCursor) - parent.width / 2))
                        }
                        text: {
                            root.revision
                            return root.entry.length ? "› " + root.entry.slice(0, root.calculatorState.cursor) + "│" + root.entry.slice(root.calculatorState.cursor) : ""
                        }
                        color: root.lcdInk; font.family: "monospace"; font.pixelSize: root.displayFontSize
                    }
                }
            }
        }
        Grid {
            width: parent.width
            enabled: !root.confirmingClear
            columns: root.gridColumns; spacing: Style.space(6)
            Repeater {
                model: root.functions
                KeyButton {
                    required property var modelData
                    required property int index
                    objectName: "function_" + modelData.name
                    functionKey: true
                    width: (body.width - Style.space(18)) / 4
                    label: modelData.label; hint: modelData.hint
                    selected: root.selectedFunction === index
                    onTriggered: root.run(modelData.name)
                }
            }
        }
        Row {
            width: parent.width
            spacing: Style.space(6)
            Repeater {
                model: root.operations
                KeyButton {
                    required property var modelData
                    required property int index
                    objectName: "operation_" + modelData.name
                    width: (body.width - Style.space(18)) / 4
                    label: modelData.label
                    hint: modelData.hint
                    functionKey: true
                    selected: root.selectedFunction === index + root.functions.length
                    onTriggered: root.run(modelData.name)
                }
            }
        }
        Row {
            visible: root.confirmingClear
            width: parent.width; spacing: Style.space(6)
            Text {
                width: parent.width - Style.space(136); height: Style.space(32)
                text: "Clear stack?"; color: root.ink
                verticalAlignment: Text.AlignVCenter
                font.family: Style.fontFamily; font.pixelSize: Style.font.body
            }
            KeyButton { width: Style.space(65); label: "Yes"; onTriggered: root.clearConfirmed() }
            KeyButton { width: Style.space(65); label: "No"; onTriggered: root.confirmingClear = false }
        }
        Item {
            width: parent.width; height: Style.space(24)
            Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: root.selectedLevel ? "Level " + root.selectedLevel + " · Enter to PICK"
                    : root.selectedFunction >= 0 ? "Function · Enter to run"
                    : root.entry.length ? "Editing · Enter to push" : "Ready · " + root.count + " values"
                color: root.ink; font.family: Style.fontFamily; font.pixelSize: Style.font.bodySmall
            }
            KeyButton {
                anchors.right: parent.right; width: Style.space(30); height: parent.height
                label: "?"; hint: "Keyboard help"
                onTriggered: root.helpOpen = true
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: root.helpOpen
        color: root.classic ? "#30343a" : Color.background
        MouseArea { anchors.fill: parent; onClicked: root.helpOpen = false }
        Flickable {
            anchors.fill: parent
            anchors.margins: root.pad
            clip: true
            contentWidth: width
            contentHeight: helpColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: helpColumn
                width: parent.width
                spacing: Style.space(16)

                Item {
                    width: parent.width
                    height: Math.max(helpTitle.implicitHeight, modeLabel.implicitHeight)
                    Text {
                        id: helpTitle
                        anchors.left: parent.left
                        text: "Keyboard help"
                        color: root.ink
                        font.family: Style.fontFamily
                        font.pixelSize: Style.font.body + 2
                        font.bold: true
                    }
                    Text {
                        id: modeLabel
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.classic ? "Classic" : "Omarchy"
                        color: root.accent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                    }
                }

                HelpSection {
                    title: "ENTRY & OPERATIONS"
                    shortcuts: [
                        ["0–9 / .", "edit number"],
                        ["← / →", "move entry cursor"],
                        ["Enter", "push entry / run selection"],
                        ["+ − × ÷", "calculate; push entry first"],
                        ["_", "change sign"],
                        ["Backspace", "erase entry character"],
                        ["Delete", "drop top when not editing"],
                        ["Ctrl+C / Ctrl+V", "copy top / paste new top"]
                    ]
                }
                HelpSection {
                    title: "STACK"
                    shortcuts: [
                        ["p / Ctrl+P", "browse older levels"],
                        ["n / Ctrl+N", "browse toward top"],
                        ["Enter", "PICK selected level"],
                        ["Click level", "select; click again to PICK"]
                    ]
                }
                HelpSection {
                    title: "FUNCTION GRID"
                    shortcuts: [
                        ["↓ / ↑", "enter at first / last row"],
                        ["Arrows / hjkl", "navigate with wrap"],
                        ["Esc", "clear error / cancel / close"]
                    ]
                }
                HelpSection {
                    title: "FUNCTIONS"
                    shortcuts: [
                        ["√x / yˣ", "square root / power"],
                        ["1/x / +/−", "reciprocal / change sign"],
                        ["ARG", "restore last arguments"],
                        ["DROP / SWAP", "remove top / exchange top two"],
                        ["CLEAR", "empty stack after confirmation"],
                        ["÷ × − +", "arithmetic operations"]
                    ]
                }
                Text {
                    width: parent.width
                    text: "Esc / ? / click outside closes help"
                    textFormat: Text.PlainText
                    color: Qt.darker(root.ink, 1.45)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.font.bodySmall
                }
            }
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
        }
    }
}
