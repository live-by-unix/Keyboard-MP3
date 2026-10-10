# keyboard-mp3

A small macOS/Linux terminal utility that plays an MP3 sound whenever a keyboard key is pressed.

`keyboard-mp3` provides commands to start and stop the listener, check its status, change the sound file, and display help or version information.

## Features

- Detects global keyboard key-press events with `pynput`.
- Plays MP3 audio using `pygame`.
- Runs the listener in the background.
- Lets you change the sound file from the terminal.
- Keeps configuration and logs under `~/.local/share/keyboard-mp3/`.
- Uses a Bash command-line interface.

## Requirements

- macOS/Linux
- Python 3
- A terminal shell such as zsh or Bash
- Permission for your terminal application to monitor keyboard input, if requested by macOS/Linux

## Installation

Download `install-keyboard-mp3.sh` from the repo, then run it from Terminal. If it is in your Downloads folder:

```bash
bash ~/Downloads/install-keyboard-mp3.sh
```

The installer:

1. Creates `~/bin` and `~/.local/share/keyboard-mp3`.
2. Creates a Python virtual environment and installs `pynput` and `pygame`.
3. Installs the `keyboard-mp3` command in `~/bin`.
4. Adds `~/bin` to your `~/.zshrc` or `~/.bashrc` PATH if it is not already there.

Make the command available in your current Terminal session:

```bash
export PATH="$HOME/bin:$PATH"
```

Alternatively, open a new Terminal window or run `source ~/.zshrc`.

## Quick start

Set the path to your MP3 file:

```bash
keyboard-mp3 change "$HOME/Music/keyboard.mp3"
```

Start the listener:

```bash
keyboard-mp3 on
```

Stop it when you are done:

```bash
keyboard-mp3 off
```

## Commands

| Command | Description |
| --- | --- |
| `keyboard-mp3 on` | Start the keyboard sound listener in the background. |
| `keyboard-mp3 off` | Stop the listener. |
| `keyboard-mp3 status` | Show whether the listener is running and the configured sound file. |
| `keyboard-mp3 change "/path/to/file.mp3"` | Set the sound file. If the listener is running, it will be restarted. |
| `keyboard-mp3 help` | Show command help. |
| `keyboard-mp3 -h` | Show command help. |
| `keyboard-mp3 --help` | Show command help. |
| `keyboard-mp3 -v` | Show the version. |
| `keyboard-mp3 --version` | Show the version. |

Paths containing spaces should be quoted:

```bash
keyboard-mp3 change "$HOME/Music/My Keyboard Sound.mp3"
```

The `change` command expects a path to an existing file. MP3 is the intended format.


## Files and logs

The installer creates these files:

- `~/bin/keyboard-mp3` — Bash command-line utility
- `~/.local/share/keyboard-mp3/listener.py` — Python keyboard and audio helper
- `~/.local/share/keyboard-mp3/venv/` — Python virtual environment and dependencies
- `~/.local/share/keyboard-mp3/sound-path` — Configured MP3 path
- `~/.local/share/keyboard-mp3/listener.pid` — Background process ID while running
- `~/.local/share/keyboard-mp3/listener.log` — Listener output and error log

If the listener fails to start, inspect the log:

```bash
cat ~/.local/share/keyboard-mp3/listener.log
```

## Uninstall

First stop the listener:

```bash
keyboard-mp3 off
```

Then remove the installed command and application files:

```bash
rm -f "$HOME/bin/keyboard-mp3"
rm -rf "$HOME/.local/share/keyboard-mp3"
```

If you no longer want `~/bin` in your PATH, remove the following line from `~/.zshrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

## Troubleshooting

### `keyboard-mp3: command not found`

Run:

```bash
export PATH="$HOME/bin:$PATH"
```

If needed, add that line to `~/.zshrc` and open a new Terminal window.

### No sound plays

- Confirm the configured file exists.
- Check that system output volume is audible.
- Check the listener log for errors.
- Verify macOS/Linux privacy permissions for your terminal application.

### Check the current state

```bash
keyboard-mp3 status
```

## Version

Current version: `1.0.0`

## License

BSD-3-Clause [LICENSE](LICENSE)

## Contributions
Made by live-by-unix.
Feel free to contribute.
