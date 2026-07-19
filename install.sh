#!/bin/bash
# cmux-manager installer — symlinks the CLI into ~/.local/bin
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)/bin"
DEST="$HOME/.local/bin"
mkdir -p "$DEST"
for f in cmuxman cmuxman-update-worker; do
  chmod +x "$SRC/$f"
  ln -sf "$SRC/$f" "$DEST/$f"
done
# helpers: only link if not already provided by another install
for f in cmux-spawn cmux-rescue; do
  chmod +x "$SRC/$f"
  [ -e "$DEST/$f" ] || ln -sf "$SRC/$f" "$DEST/$f"
done
echo "installed: cmuxman -> $DEST (plus worker, cmux-spawn, cmux-rescue)"
echo "try: cmuxman doctor"
