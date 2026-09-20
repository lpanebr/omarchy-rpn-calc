// Plain JavaScript shared by QML and the Node test harness. Stack top is last.
function createState() {
    return { stack: [], entry: "", cursor: 0, error: null };
}

function clearError(state) {
    state.error = null;
    return true;
}

function fail(state, operation, message) {
    state.error = { operation: operation, message: message };
    return false;
}

function parseNumber(text) {
    var value = String(text).trim();
    if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(value))
        return null;
    var number = Number(value);
    return isFinite(number) ? number : null;
}

function insert(state, text) {
    text = String(text);
    if (!/^[\d.]+$/.test(text))
        return fail(state, "Entry", "Invalid Input");
    var entry = state.entry.slice(0, state.cursor) + text + state.entry.slice(state.cursor);
    if (!/^-?\d*\.?\d*$/.test(entry))
        return fail(state, "Entry", "Invalid Input");
    state.entry = entry;
    state.cursor += text.length;
    return clearError(state);
}

function moveCursor(state, delta) {
    state.cursor = Math.max(0, Math.min(state.entry.length, state.cursor + delta));
    return clearError(state);
}

function backspace(state) {
    if (state.cursor > 0) {
        state.entry = state.entry.slice(0, state.cursor - 1) + state.entry.slice(state.cursor);
        state.cursor--;
    }
    return clearError(state);
}

function toggleSign(state) {
    if (state.entry !== "") {
        if (state.entry.charAt(0) === "-") {
            state.entry = state.entry.slice(1);
            state.cursor = Math.max(0, state.cursor - 1);
        } else {
            state.entry = "-" + state.entry;
            state.cursor++;
        }
        return clearError(state);
    }
    if (state.stack.length === 0)
        return fail(state, "+/-", "Too Few Arguments");
    state.stack[state.stack.length - 1] = -state.stack[state.stack.length - 1];
    return clearError(state);
}

function commit(state) {
    if (state.entry === "")
        return clearError(state);
    var value = parseNumber(state.entry);
    if (value === null)
        return fail(state, "Entry", "Invalid Input");
    state.stack.push(value);
    state.entry = "";
    state.cursor = 0;
    return clearError(state);
}

function paste(state, text) {
    var value = parseNumber(text);
    if (value === null)
        return fail(state, "Paste", "Invalid Input");
    state.stack.push(value);
    return clearError(state);
}

function operate(state, name) {
    if (name === "sign" || name === "+/-")
        return toggleSign(state);
    if (name === "1/x")
        name = "reciprocal";
    var label = name === "reciprocal" ? "1/x" : name;
    var binary = name === "+" || name === "-" || name === "*" || name === "/" || name === "pow" || name === "swap";
    var unary = name === "sqrt" || name === "reciprocal" || name === "dup" || name === "drop";
    if (!binary && !unary && name !== "clear")
        return fail(state, label, "Unknown Operation");
    // A valid pending entry remains committed even if the operation fails.
    if (!commit(state))
        return false;
    if (name === "clear") {
        state.stack.length = 0;
        return clearError(state);
    }
    var count = binary ? 2 : 1;
    var length = state.stack.length;
    if (length < count)
        return fail(state, label, "Too Few Arguments");
    var x = state.stack[length - 1];
    var y = state.stack[length - 2];
    if (name === "dup") {
        state.stack.push(x);
        return clearError(state);
    }
    if (name === "drop") {
        state.stack.pop();
        return clearError(state);
    }
    if (name === "swap") {
        state.stack[length - 1] = y;
        state.stack[length - 2] = x;
        return clearError(state);
    }
    if ((name === "/" || name === "reciprocal") && x === 0)
        return fail(state, label, "Infinite Result");
    if (name === "sqrt" && x < 0)
        return fail(state, label, "Invalid Argument");
    var result;
    switch (name) {
    case "+": result = y + x; break;
    case "-": result = y - x; break;
    case "*": result = y * x; break;
    case "/": result = y / x; break;
    case "pow": result = Math.pow(y, x); break;
    case "sqrt": result = Math.sqrt(x); break;
    case "reciprocal": result = 1 / x; break;
    }
    if (isNaN(result))
        return fail(state, label, "Invalid Argument");
    if (!isFinite(result))
        return fail(state, label, "Infinite Result");
    state.stack.splice(length - count, count, result);
    return clearError(state);
}
