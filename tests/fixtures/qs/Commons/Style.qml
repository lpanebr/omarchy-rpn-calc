pragma Singleton
import QtQuick
QtObject {
    function space(value) { return value }
    readonly property int cornerRadius: 0
    readonly property string fontFamily: "sans-serif"
    readonly property var font: ({ body: 14, bodySmall: 12 })
    readonly property color normalFill: "#303030"
    readonly property color pressedFill: "#505050"
    readonly property color hoverFill: "#404040"
    readonly property color selectedFill: "#405060"
    readonly property color normalBorderColor: "#777777"
}
