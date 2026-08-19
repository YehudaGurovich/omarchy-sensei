#!/usr/bin/env bash
# Sync the working tree into the local plugin folder and rescan the shell.
set -euo pipefail

PLUGIN_ID="io.github.yehudagurovich.sensei"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

mkdir -p "$DEST"
rsync -a --delete --exclude '.git' --exclude 'dev.sh' "$SRC/" "$DEST/"
omarchy-shell -q shell rescanPlugins
echo "Synced to $DEST and rescanned."
echo "Toggle: omarchy-shell shell toggle $PLUGIN_ID '{}'"
echo "If changes do not show: omarchy restart shell"
