#!/usr/bin/env bash
# Sync the working tree into the local plugin folder and restart the shell.
set -euo pipefail

PLUGIN_ID="io.github.yehudagurovich.sensei"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

if omarchy-hyprland-session-locked; then
  echo "Refusing to sync Omarchy Dojo while the session is locked. Unlock and try again." >&2
  exit 1
fi

mkdir -p "$DEST"
rsync -a --delete --exclude '.git' "$SRC/" "$DEST/"

omarchy restart shell
echo "Synced to $DEST and restarted the shell."
echo "Toggle: omarchy-shell shell toggle $PLUGIN_ID '{}'"
