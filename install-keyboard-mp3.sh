#!/bin/bash
set -euo pipefail

# Install keyboard-mp3 as a Bash command on macOS/Linux.
# Usage: bash install-keyboard-mp3.sh

BIN_DIR="$HOME/bin"
APP_DIR="$HOME/.local/share/keyboard-mp3"
VENV="$APP_DIR/venv"

mkdir -p "$BIN_DIR" "$APP_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required. Install Python 3 and run this installer again." >&2
  exit 1
fi

python3 -m venv "$VENV"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install pynput pygame

cat > "$APP_DIR/listener.py" <<'PY'
import signal
import sys
import threading

import pygame
from pynput import keyboard

if len(sys.argv) != 2:
    print("Usage: listener.py /full/path/to/sound.mp3", file=sys.stderr)
    sys.exit(2)

sound_path = sys.argv[1]
pygame.mixer.init()
sound = pygame.mixer.Sound(sound_path)
shutdown = threading.Event()

def on_press(key):
    if not shutdown.is_set():
        sound.play()

def stop_listener(*_):
    shutdown.set()
    listener.stop()

signal.signal(signal.SIGTERM, stop_listener)
signal.signal(signal.SIGINT, stop_listener)

listener = keyboard.Listener(on_press=on_press)
listener.start()

try:
    shutdown.wait()
finally:
    listener.stop()
    listener.join(timeout=2)
    pygame.mixer.quit()
PY

cat > "$BIN_DIR/keyboard-mp3" <<'BASH'
#!/bin/bash
set -u

VERSION="1.0.0"
APP="$HOME/.local/share/keyboard-mp3"
PYTHON="$APP/venv/bin/python"
HELPER="$APP/listener.py"
CONFIG="$APP/sound-path"
PIDFILE="$APP/listener.pid"
LOG="$APP/listener.log"

usage() {
  cat <<EOF
keyboard-mp3 $VERSION

Usage:
  keyboard-mp3 on
  keyboard-mp3 off
  keyboard-mp3 status
  keyboard-mp3 change <full-path-to-mp3>
  keyboard-mp3 help | -h | --help
  keyboard-mp3 -v | --version

Commands:
  on       Start the background keyboard sound listener.
  off      Stop the listener.
  status   Show whether the listener is running.
  change   Set the MP3 file; restart the listener if active.
  help     Show this help.

Examples:
  keyboard-mp3 change "\$HOME/Music/keyboard.mp3"
  keyboard-mp3 on
  keyboard-mp3 off
EOF
}

is_running() {
  [[ -f "$PIDFILE" ]] || return 1
  local pid
  pid=$(cat "$PIDFILE" 2>/dev/null || true)
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

stop_listener() {
  if is_running; then
    local pid
    pid=$(cat "$PIDFILE")
    kill "$pid" 2>/dev/null || true
    for _ in {1..30}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
    echo "Keyboard sound stopped."
  else
    echo "Keyboard sound is already off."
  fi
  rm -f "$PIDFILE"
}

start_listener() {
  if is_running; then
    echo "Keyboard sound is already running (PID $(cat "$PIDFILE"))."
    return 0
  fi
  rm -f "$PIDFILE"

  if [[ ! -f "$CONFIG" ]]; then
    echo "No MP3 configured. Run:"
    echo '  keyboard-mp3 change "/full/path/to/keyboard.mp3"'
    return 1
  fi

  local sound
  sound=$(cat "$CONFIG")
  if [[ ! -f "$sound" ]]; then
    echo "MP3 not found: $sound"
    echo 'Set another file with: keyboard-mp3 change "/full/path/to/file.mp3"'
    return 1
  fi

  nohup "$PYTHON" "$HELPER" "$sound" >> "$LOG" 2>&1 </dev/null &
  local pid=$!
  echo "$pid" > "$PIDFILE"
  sleep 1

  if kill -0 "$pid" 2>/dev/null; then
    echo "Keyboard sound started."
    echo "MP3: $sound"
  else
    rm -f "$PIDFILE"
    echo "Failed to start. Check: $LOG" >&2
    return 1
  fi
}

case "${1:-help}" in
  on|start)
    start_listener
    ;;
  off|stop)
    stop_listener
    ;;
  status)
    if is_running; then
      echo "Keyboard sound is running (PID $(cat "$PIDFILE"))."
      [[ -f "$CONFIG" ]] && echo "MP3: $(cat "$CONFIG")"
    else
      rm -f "$PIDFILE"
      echo "Keyboard sound is off."
    fi
    ;;
  change)
    shift
    if [[ $# -eq 0 ]]; then
      echo "Usage: keyboard-mp3 change <full-path-to-mp3>" >&2
      exit 2
    fi
    sound="$*"
    if [[ ! -f "$sound" ]]; then
      echo "Error: file not found: $sound" >&2
      exit 1
    fi

    was_running=0
    if is_running; then
      was_running=1
      stop_listener
    fi

    printf '%s\n' "$sound" > "$CONFIG"
    echo "Sound file set to: $sound"
    if [[ "$was_running" -eq 1 ]]; then
      start_listener
    fi
    ;;
  help|-h|--help)
    usage
    ;;
  -v|--version|version)
    echo "keyboard-mp3 $VERSION"
    ;;
  *)
    echo "Unknown command: $1" >&2
    echo "Run 'keyboard-mp3 --help' for usage." >&2
    exit 2
    ;;
esac
BASH

chmod +x "$BIN_DIR/keyboard-mp3"

ZSHRC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/bin:$PATH"'
if [[ -f "$ZSHRC" ]] && grep -Fqx "$PATH_LINE" "$ZSHRC"; then
  :
else
  printf '\n%s\n' "$PATH_LINE" >> "$ZSHRC"
fi

echo
echo "Installed keyboard-mp3."
echo "Run this once in your current Terminal:"
echo '  export PATH="$HOME/bin:$PATH"'
echo
echo "Then configure and start it:"
echo '  keyboard-mp3 change "/full/path/to/keyboard.mp3"'
echo "  keyboard-mp3 on"
echo
echo "Help: keyboard-mp3 --help"
echo "Note: macOS may require Accessibility and/or Input Monitoring permission for your terminal app."
echo "Note: Linux may fail as well. Check X11/WayLand config & more."
echo
echo "By live-by-unix"
