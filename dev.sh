#!/usr/bin/env bash
# Sync the working tree into the local plugin folder and reload the shell.
#
# Default: full shell restart after the sync. Hot reload (--hot, sync only —
# the file watcher picks it up) is faster but risky on the current quickshell
# build: the reload path can use-after-free in IpcHandler::updateRegistration
# (SIGSEGV — upstream quickshell-mirror/quickshell#956, see PLAN.md gotchas)
# and leaves stale IPC handlers answering for the plugin.
set -euo pipefail

PLUGIN_ID="io.github.yehudagurovich.sensei"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

mkdir -p "$DEST"
rsync -a --delete --exclude '.git' --exclude 'dev.sh' "$SRC/" "$DEST/"

if [[ "${1:-}" == "--hot" ]]; then
  echo "Synced to $DEST. Omarchy will reload the plugin after file changes settle."
  echo "Hot reload is crash-prone and IPC changes will not apply; default (no --hot) restarts the shell."
else
  omarchy restart shell
  echo "Synced to $DEST and restarted the shell."
fi
echo "Toggle: omarchy-shell shell toggle $PLUGIN_ID '{}'"
