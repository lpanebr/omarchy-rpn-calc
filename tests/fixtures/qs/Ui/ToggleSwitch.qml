import QtQuick

// Host-free signal contract only. run-shell-smoke.sh loads the native switch.
Item {
    property bool checked: false
    property bool rounded: false
    property int cursorPad: 2
    property int trackHeight: 24
    property int trackWidth: 48
    property color foreground: "white"
    property color accent: "white"
    signal toggled()
    implicitWidth: trackWidth + cursorPad * 2
    implicitHeight: trackHeight + cursorPad * 2
    MouseArea { anchors.fill: parent; onClicked: parent.toggled() }
}
