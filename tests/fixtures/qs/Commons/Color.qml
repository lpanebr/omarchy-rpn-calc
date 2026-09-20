pragma Singleton
import QtQuick
// Theme-only double: Quickshell registers its plugins inside its own executable.
QtObject {
    readonly property color foreground: "#dddddd"
    readonly property color background: "#202020"
    readonly property color accent: "#55aaff"
    readonly property color urgent: "#ff6655"
}
