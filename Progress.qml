import Quickshell
import Quickshell.Io
import QtQuick

// Persistent lesson progress: $XDG_STATE_HOME/omarchy-sensei/progress.json
// (falls back to ~/.local/state). The points field is stored from day one so
// the planned points/ranks feature lands without a schema change.
Item {
  id: root

  property var completed: []
  property int points: 0
  signal loaded()

  property bool savePending: false

  readonly property string stateDir: {
    var state = Quickshell.env("XDG_STATE_HOME")
    var base = state && String(state).length ? String(state) : Quickshell.env("HOME") + "/.local/state"
    return base + "/omarchy-sensei"
  }
  readonly property string path: stateDir + "/progress.json"

  function save() {
    if (saveProcess.running) {
      // A save is already in flight; run again with the newest state after.
      root.savePending = true
      return
    }
    var json = JSON.stringify({ schemaVersion: 1, completed: root.completed, points: root.points }, null, 2)
    saveProcess.command = [
      "bash", "-c",
      'mkdir -p "$1" && printf "%s\\n" "$2" > "$3.tmp" && mv "$3.tmp" "$3"',
      "sensei-progress-save", root.stateDir, json, root.path
    ]
    saveProcess.running = true
  }

  FileView {
    path: root.path
    printErrors: false
    onLoaded: {
      try {
        var data = JSON.parse(text())
        // An unknown future schema is treated as empty rather than half-read.
        if (data && data.schemaVersion === 1) {
          if (Array.isArray(data.completed)) root.completed = data.completed
          if (typeof data.points === "number") root.points = data.points
        }
      } catch (e) {
        console.log("sensei: ignoring unreadable progress file")
      }
      root.loaded()
    }
    onLoadFailed: root.loaded()
  }

  Process {
    id: saveProcess
    running: false
    onExited: {
      if (root.savePending) {
        root.savePending = false
        root.save()
      }
    }
  }
}
