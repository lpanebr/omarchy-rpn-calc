import QtQuick
import QtTest
import "../plugin" as Calculator
import "../plugin/RpnEngine.js" as Engine

Item {
    width: 420
    height: 620
    Calculator.Panel {
        id: panel
        width: implicitWidth
        height: implicitHeight
    }
    SignalSpy { id: closed; target: panel; signalName: "closeRequested" }
    SignalSpy { id: toggled; target: panel; signalName: "appearanceToggleRequested" }
    TestCase {
        name: "PanelKeyboard"
        when: windowShown

        function init() {
            panel.calculatorState = Engine.createState()
            panel.selectedLevel = 0
            panel.selectedFunction = -1
            panel.helpOpen = false
            panel.confirmingClear = false
            panel.refresh()
            closed.clear()
            toggled.clear()
            panel.forceActiveFocus()
            tryCompare(panel, "activeFocus", true)
        }
        function stack(expected) {
            compare(JSON.stringify(panel.calculatorState.stack), JSON.stringify(expected))
        }
        function enter(value) { keySequence(value); keyClick(Qt.Key_Return) }
        function keySequence(value) {
            for (var i = 0; i < value.length; i++) keyClick(value.charAt(i))
        }
        function test_implicitCommitErrorAndEscape() {
            enter("2")
            keyClick("0")
            keyClick("/")
            stack([2, 0])
            compare(panel.entry, "")
            verify(panel.error !== null)
            keyClick(Qt.Key_Escape)
            compare(panel.error, null)
            compare(closed.count, 0)
            keyClick(Qt.Key_Escape)
            compare(closed.count, 1)
        }
        function test_cursorAndGridWrap() {
            keySequence("13")
            keyClick(Qt.Key_Left)
            keyClick("2")
            compare(panel.entry, "123")
            compare(panel.calculatorState.cursor, 2)
            keyClick(Qt.Key_Down)
            compare(panel.selectedFunction, 0)
            keyClick(Qt.Key_Left)
            compare(panel.selectedFunction, 3)
            keyClick(Qt.Key_Up)
            compare(panel.selectedFunction, 11)
            keyClick(Qt.Key_Right)
            compare(panel.selectedFunction, 8)
            keyClick(Qt.Key_Down)
            compare(panel.selectedFunction, 0)
            keyClick(Qt.Key_Escape)
            compare(panel.selectedFunction, -1)
            compare(panel.entry, "123")
            compare(panel.calculatorState.cursor, 2)
            keyClick(Qt.Key_Backspace)
            compare(panel.entry, "13")
        }
        function test_idleArrowDestinations_data() {
            return [ {tag: "left", key: Qt.Key_Left, cell: 3},
                     {tag: "right", key: Qt.Key_Right, cell: 0},
                     {tag: "up", key: Qt.Key_Up, cell: 8},
                     {tag: "down", key: Qt.Key_Down, cell: 0} ]
        }
        function test_idleArrowDestinations(data) {
            keyClick(data.key)
            compare(panel.selectedFunction, data.cell)
        }
        function test_sqrtCommitsEntry() {
            keyClick("9")
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            stack([3])
            compare(panel.entry, "")
            compare(panel.selectedFunction, -1)
        }
        function test_mouseFunctionAndAppearanceToggle() {
            keyClick("9")
            var sqrtButton = findChild(panel, "function_sqrt")
            verify(sqrtButton !== null)
            mouseClick(sqrtButton, sqrtButton.width / 2, sqrtButton.height / 2)
            stack([3])
            compare(panel.entry, "")
            var toggle = findChild(panel, "appearanceToggle")
            verify(toggle !== null)
            mouseClick(toggle, toggle.width / 2, toggle.height / 2)
            compare(toggled.count, 1)
            verify(panel.activeFocus)
        }
        function test_argAndMouseOperationButtons() {
            enter("2")
            enter("3")
            var addButton = findChild(panel, "operation_+")
            verify(addButton !== null)
            mouseClick(addButton, addButton.width / 2, addButton.height / 2)
            stack([5])
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Down)
            compare(panel.selectedFunction, 4)
            keyClick(Qt.Key_Return)
            stack([5, 2, 3])
        }
        function test_browseEscapeAndPickPreserveBuffer() {
            enter("10"); enter("25"); enter("2"); enter("3")
            keySequence("78")
            keyClick(Qt.Key_Left)
            keyClick("p")
            keyClick("p")
            compare(panel.selectedLevel, 2)
            keyClick(Qt.Key_Escape)
            compare(panel.selectedLevel, 0)
            compare(panel.entry, "78")
            compare(panel.calculatorState.cursor, 1)
            keyClick("p"); keyClick("p"); keyClick("p")
            keyClick(Qt.Key_Return)
            stack([10, 25, 2, 3, 25])
            compare(panel.entry, "78")
            compare(panel.calculatorState.cursor, 1)
        }
        function test_helpPreservesInteraction() {
            keySequence("12")
            keyClick(Qt.Key_Down)
            keyClick("?")
            verify(panel.helpOpen)
            keyClick("9")
            compare(panel.entry, "12")
            keyClick(Qt.Key_Escape)
            verify(!panel.helpOpen)
            compare(panel.selectedFunction, 0)
            compare(closed.count, 0)
        }
        function test_browseBeyondFourLevelsAndReturnToTop() {
            for (var i = 1; i <= 8; i++) enter(String(i))
            var view = findChild(panel, "stackView")
            verify(view !== null)
            tryVerify(function() { return view.atYEnd })
            for (var j = 0; j < 8; j++) keyClick(Qt.Key_P, Qt.ControlModifier)
            compare(panel.selectedLevel, 8)
            tryVerify(function() { return view.atYBeginning })
            keyClick(Qt.Key_N, Qt.ControlModifier)
            compare(panel.selectedLevel, 7)
            keyClick(Qt.Key_Escape)
            compare(panel.selectedLevel, 0)
            tryVerify(function() { return view.atYEnd })
            stack([1, 2, 3, 4, 5, 6, 7, 8])
        }
        function selectClear() {
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_Down)
            compare(panel.selectedFunction, 7)
            keyClick(Qt.Key_Return)
            verify(panel.confirmingClear)
        }
        function test_clearCancelAndConfirm() {
            enter("5")
            keySequence("12")
            selectClear()
            keyClick(Qt.Key_Escape)
            verify(!panel.confirmingClear)
            stack([5])
            compare(panel.entry, "12")
            // Cancellation preserves the current function selection too.
            keyClick(Qt.Key_Return)
            verify(panel.confirmingClear)
            keyClick(Qt.Key_Return)
            stack([])
            compare(panel.entry, "")
        }
        function test_clipboardPreservesBuffer() {
            enter("42")
            keySequence("19")
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_C, Qt.ControlModifier)
            keyClick(Qt.Key_V, Qt.ControlModifier)
            stack([42, 42])
            compare(panel.entry, "19")
            compare(panel.calculatorState.cursor, 1)
        }
        function test_backspaceDoesNotDrop() {
            enter("7")
            keyClick(Qt.Key_Backspace)
            stack([7])
            keyClick(Qt.Key_Delete)
            stack([])
        }
    }
}
