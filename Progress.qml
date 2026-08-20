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

  readonly property string stateDir: {
    var state = Quickshell.env("XDG_STATE_HOME")
    var base = state && String(state).length ? String(state) : Quickshell.env("HOME") + "/.local/state"
    return base + "/omarchy-sensei"
  }
  readonly property string path: stateDir + "/progress.json"

  function save() {
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
        if (data && Array.isArray(data.completed)) root.completed = data.completed
        if (data && typeof data.points === "number") root.points = data.points
      } catch (e) {
        console.log("sensei: ignoring unreadable progress file")
      }
      root.loaded()
    }
  }

  Process {
    id: saveProcess
    running: false
  }
}
