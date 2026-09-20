# RPN Calculator for Omarchy

A keyboard-first RPN calculator for the Omarchy bar. It provides an unlimited
stack, editable numeric input, mouse controls, and two visual styles: a
Classic mode inspired by scientific calculators and a theme-aware Omarchy
mode.

The calculator runs entirely inside Omarchy Shell. It has no external runtime
dependencies, does not access the network, and never evaluates expressions as
code.

## Features

- Four-level display with scrolling for deeper stacks
- Direct `+`, `-`, `*`, and `/` operations
- Square root, power, reciprocal, sign, `ARG`, `DROP`, `SWAP`, and `CLEAR`
- Keyboard navigation with arrow keys or `h`/`j`/`k`/`l`
- Stack browsing and `PICK`
- Clipboard copy and paste
- Classic and Omarchy appearances, with Classic enabled by default
- Errors preserve their operands

## Requirements

- Omarchy 4 with shell plugin support

## Installation

```bash
omarchy plugin add https://github.com/lpanebr/omarchy-rpn-calc.git --enable
```

The widget is added to the right section of the bar. Click its icon to open or
close the calculator.

During an interactive installation, Omarchy asks whether to place the widget
in the left, center, or right section. The manifest suggests right as the
default; the selected position is saved by Omarchy Shell.

For a local checkout:

```bash
omarchy plugin add "$PWD" --enable
```

## Usage

RPN operations consume the top stack levels. For example:

```text
2 Enter 3 +       → 5
2 Enter 3 + 4 *   → 20
```

An entry is committed automatically before an operation, so `2 Enter 3 +` and
`2 Enter 3 Enter +` are equivalent.

### Keyboard controls

| Keys | Action |
| --- | --- |
| `0`–`9`, `.` | Edit a number |
| `Left`, `Right` | Move the entry cursor |
| `Enter` | Push an entry, run a function, or `PICK` a stack level |
| `+`, `-`, `*`, `/` | Commit the entry and calculate |
| `_` | Change the sign |
| `Backspace` | Erase the character before the cursor |
| `Delete` | Drop the top level when not editing |
| `p` / `Ctrl+p` | Browse toward older stack levels |
| `n` / `Ctrl+n` | Browse toward the top level |
| Arrows or `h`/`j`/`k`/`l` | Navigate the function grid with wrap |
| `Ctrl+c` / `Ctrl+v` | Copy the top level / paste a new top level |
| `?` | Open keyboard help |
| `Esc` | Clear an error, cancel the current state, or close the panel |

`h`/`j`/`k`/`l` are disabled while editing a number. `ARG` restores the
operands of the last successful mathematical operation without removing its
result.

## Appearance and numeric behavior

Use the switch in the panel header to select Classic or Omarchy mode. The
choice is stored in the Omarchy Shell configuration.

Calculations use JavaScript `Number`. Large and small supported values are
shown in scientific notation. A finite mathematical result outside the
supported range reports `Result Out of Range`; division by zero reports
`Infinite Result`. Arbitrary-precision decimals are not supported.

The stack and the arguments used by `ARG` are stored in
`$XDG_STATE_HOME/omarchy-rpn-calc.json` (normally
`~/.local/state/omarchy-rpn-calc.json`). Closing the panel, restarting Omarchy
Shell, and updating the plugin preserve them. Use `CLEAR` to empty the stack.

## Update and removal

```bash
omarchy plugin update lpanebr.rpn-calc
omarchy plugin remove lpanebr.rpn-calc
```

Removing the plugin also removes it from the bar. To remove its saved stack as
well, delete `~/.local/state/omarchy-rpn-calc.json`. Its appearance preference
lives in the widget entry managed by Omarchy Shell.

## Development

The complete behavior specification is in [SPEC.md](SPEC.md).

```bash
omarchy plugin validate .
node tests/rpn-engine.test.cjs
bash tests/run-qml-tests.sh
bash tests/run-shell-smoke.sh
```

The shell smoke test starts a separate temporary Quickshell instance and
requires an active Wayland session. It does not install the plugin or change
the bar configuration.

## License

GPL-2.0-or-later
