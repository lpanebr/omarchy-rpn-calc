const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const engine = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../plugin/RpnEngine.js'), 'utf8'), engine);
const stack = state => Array.from(state.stack);
function values(...numbers) {
    const state = engine.createState();
    numbers.forEach(number => assert.equal(engine.paste(state, String(number)), true));
    return state;
}

test('explicit and implicit entry produce the specified RPN results', () => {
    for (const explicit of [true, false]) {
        const state = values(2);
        engine.insert(state, '3');
        if (explicit) engine.commit(state);
        assert.equal(engine.operate(state, '+'), true);
        assert.deepEqual(stack(state), [5]);
        engine.insert(state, '4');
        if (explicit) engine.commit(state);
        engine.operate(state, '*');
        assert.deepEqual(stack(state), [20]);
    }
});

test('operand order and unary functions', () => {
    for (const [op, inputs, expected] of [
        ['-', [9, 4], 5], ['/', [9, 4], 2.25], ['pow', [2, 3], 8],
        ['sqrt', [9], 3], ['reciprocal', [4], 0.25], ['1/x', [4], 0.25],
    ]) {
        const state = values(...inputs);
        assert.equal(engine.operate(state, op), true);
        assert.deepEqual(stack(state), [expected]);
    }
    const state = engine.createState();
    engine.insert(state, '9');
    engine.operate(state, 'sqrt');
    assert.deepEqual(stack(state), [3]);
    assert.equal(state.entry, '');
});

test('operation errors preserve operands after confirming entry', () => {
    const state = values(2);
    engine.insert(state, '0');
    assert.equal(engine.operate(state, '/'), false);
    assert.deepEqual(stack(state), [2, 0]);
    assert.equal(state.entry, '');
    assert.equal(state.cursor, 0);
    assert.equal(state.error.operation, '/');
    assert.equal(state.error.message, 'Infinite Result');
    for (const [op, inputs, message] of [
        ['+', [2], 'Too Few Arguments'], ['sqrt', [-1], 'Invalid Argument'],
        ['reciprocal', [0], 'Infinite Result'], ['/', [0, 0], 'Infinite Result'],
        ['pow', [-2, 0.5], 'Invalid Argument'], ['pow', [10, 1000], 'Infinite Result'],
        ['*', [1e308, 10], 'Infinite Result'],
    ]) {
        const other = values(...inputs);
        assert.equal(engine.operate(other, op), false);
        assert.deepEqual(stack(other), inputs);
        assert.equal(other.error.message, message);
    }
});

test('all operations requiring operands reject an empty stack', () => {
    for (const op of ['+', '-', '*', '/', 'pow', 'swap', 'sqrt', 'reciprocal', 'dup', 'drop', 'sign']) {
        const state = engine.createState();
        assert.equal(engine.operate(state, op), false);
        assert.equal(state.error.message, 'Too Few Arguments');
        assert.deepEqual(stack(state), []);
    }
});

test('underflow commits a valid operand, while overflowing entry stays editable', () => {
    const state = engine.createState();
    engine.insert(state, '2');
    assert.equal(engine.operate(state, '+'), false);
    assert.deepEqual(stack(state), [2]);
    assert.equal(state.entry, '');
    const huge = '9'.repeat(400);
    engine.insert(state, huge);
    assert.equal(engine.commit(state), false);
    assert.deepEqual(stack(state), [2]);
    assert.equal(state.entry, huge);
    assert.equal(state.cursor, huge.length);
});

test('cursor insertion, bounds, backspace and sign retain editing semantics', () => {
    const state = values(99);
    engine.insert(state, '123');
    engine.moveCursor(state, -1);
    engine.insert(state, '.');
    assert.equal(state.entry, '12.3');
    assert.equal(state.cursor, 3);
    engine.backspace(state);
    assert.equal(state.entry, '123');
    engine.toggleSign(state);
    assert.equal(state.entry, '-123');
    assert.equal(state.cursor, 3);
    assert.deepEqual(stack(state), [99]);
    engine.operate(state, '+/-');
    assert.equal(state.entry, '123');
    assert.equal(state.cursor, 2);
    engine.moveCursor(state, -100);
    engine.backspace(state);
    assert.equal(state.entry, '123');
    assert.equal(state.cursor, 0);
    engine.moveCursor(state, 100);
    assert.equal(state.cursor, 3);
    engine.commit(state);
    engine.backspace(state);
    assert.deepEqual(stack(state), [99, 123]);
    engine.toggleSign(state);
    assert.deepEqual(stack(state), [99, -123]);
});

test('invalid edits and incomplete entry preserve stack and buffer', () => {
    const state = values(2);
    engine.insert(state, '.');
    assert.equal(engine.operate(state, '+'), false);
    assert.equal(state.error.message, 'Invalid Input');
    assert.deepEqual(stack(state), [2]);
    assert.equal(state.entry, '.');
    for (const invalid of ['.', 'x', 'e', '1+2', ' ']) {
        assert.equal(engine.insert(state, invalid), false);
        assert.equal(state.entry, '.');
    }
    engine.insert(state, '5');
    assert.equal(state.error, null);
    engine.commit(state);
    assert.deepEqual(stack(state), [2, 0.5]);
});

test('paste accepts only finite decimal numbers and preserves pending edit/cursor', () => {
    const state = values(7);
    engine.insert(state, '123');
    engine.moveCursor(state, -1);
    for (const text of ['  -1.25e+3\n', '+.5', '2.', '1E-4'])
        assert.equal(engine.paste(state, text), true);
    assert.deepEqual(stack(state), [7, -1250, 0.5, 2, 0.0001]);
    assert.equal(state.entry, '123');
    assert.equal(state.cursor, 2);
    for (const text of ['', ' ', 'NaN', 'Infinity', '-Infinity', '1e309', '0x10', '0b10', '1,5', '1 2', '2\n3', '1+2', '1e', '--2', 'Math.PI']) {
        assert.equal(engine.paste(state, text), false, text);
        assert.deepEqual(stack(state), [7, -1250, 0.5, 2, 0.0001]);
        assert.equal(state.entry, '123');
        assert.equal(state.cursor, 2);
    }
});

test('stack operations, pending entry and error clearing', () => {
    const state = values(2, 3);
    engine.operate(state, 'dup');
    assert.deepEqual(stack(state), [2, 3, 3]);
    engine.operate(state, 'drop');
    engine.operate(state, 'swap');
    assert.deepEqual(stack(state), [3, 2]);
    engine.insert(state, '4');
    engine.operate(state, 'dup');
    assert.deepEqual(stack(state), [3, 2, 4, 4]);
    engine.insert(state, '5');
    engine.operate(state, 'clear');
    assert.deepEqual(stack(state), []);
    assert.equal(state.entry, '');
    engine.operate(state, '+');
    engine.clearError(state);
    assert.equal(state.error, null);
});

test('ARG restores the last successful operation arguments after its result', () => {
    const state = values(2, 3);
    assert.equal(engine.operate(state, '+'), true);
    assert.deepEqual(stack(state), [5]);
    assert.equal(engine.operate(state, 'arg'), true);
    assert.deepEqual(stack(state), [5, 2, 3]);
    // ARG itself does not replace the remembered arguments.
    assert.equal(engine.operate(state, 'arg'), true);
    assert.deepEqual(stack(state), [5, 2, 3, 2, 3]);

    const unary = values(9);
    engine.operate(unary, 'sqrt');
    engine.operate(unary, 'arg');
    assert.deepEqual(stack(unary), [3, 9]);

    const signed = values(4);
    engine.toggleSign(signed);
    engine.operate(signed, 'arg');
    assert.deepEqual(stack(signed), [-4, 4]);

    const empty = engine.createState();
    assert.equal(engine.operate(empty, 'arg'), false);
    assert.equal(empty.error.operation, 'ARG');
    assert.equal(empty.error.message, 'No Last Arguments');
});

test('Number precision is retained and independent states do not share arrays', () => {
    const first = values(0.1, 0.2);
    engine.operate(first, '+');
    assert.equal(first.stack[0], 0.1 + 0.2);
    const second = values(Number.MIN_VALUE, Number.MAX_VALUE);
    assert.deepEqual(stack(second), [Number.MIN_VALUE, Number.MAX_VALUE]);
    assert.deepEqual(stack(first), [0.30000000000000004]);
});
