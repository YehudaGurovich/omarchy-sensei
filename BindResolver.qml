import Quickshell.Io
import QtQuick

// Resolves lesson bind descriptions against the user's live Hyprland
// keybindings, so instructions always show the keys this machine uses.
//
// Primary source: bin/sensei-binds, which executes the user's real Lua
// config entry point in a sandbox and resolves keycodes through the
// compiled keymap (Hyprland's Lua provider hides keys for code: binds in
// `hyprctl binds`). Fallback: `hyprctl binds -j` for runtime-added binds.
Item {
  id: root

  // description (lowercased) -> { modmask, key }
  property var luaMap: ({})
  property var hyprctlMap: ({})
  property bool ready: false
  signal loaded()

  readonly property string scanScript: Qt.resolvedUrl("bin/sensei-binds").toString().replace(/^file:\/\//, "")

  function refresh() {
    root.ready = false
    if (!scanProcess.running) scanProcess.running = true
    if (!hyprctlProcess.running) hyprctlProcess.running = true
  }

  function modNames(modmask) {
    var names = []
    if (modmask & 64) names.push("SUPER")
    if (modmask & 4) names.push("CTRL")
    if (modmask & 8) names.push("ALT")
    if (modmask & 1) names.push("SHIFT")
    return names
  }

  function displayKey(key) {
    var k = String(key || "")
    if (k.length === 1) return k.toUpperCase()
    return k
  }

  // Returns { found, caps: ["SUPER", "3"] }
  function resolve(description) {
    var want = String(description || "").trim().toLowerCase()
    var entry = root.luaMap[want] || root.hyprctlMap[want]
    if (!entry) return { found: false, caps: [] }
    return { found: true, caps: modNames(entry.modmask).concat([displayKey(entry.key)]) }
  }

  Process {
    id: scanProcess
    running: false
    command: ["bash", root.scanScript]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        // The config executes defaults first and user files after, so later
        // lines overwrite earlier ones and a user override wins.
        var map = {}
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length < 3 || !parts[2]) continue
          map[parts[1].trim().toLowerCase()] = { modmask: parseInt(parts[0], 10) || 0, key: parts[2] }
        }
        root.luaMap = map
        root.ready = true
        root.loaded()
      }
    }
  }

  Process {
    id: hyprctlProcess
    running: false
    command: ["hyprctl", "binds", "-j"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var binds = []
        try {
          binds = JSON.parse(text)
        } catch (e) {
          binds = []
        }
        var map = {}
        for (var i = 0; i < binds.length; i++) {
          var b = binds[i]
          var desc = String(b.description || "").trim().toLowerCase()
          if (!desc || map[desc]) continue
          var key = String(b.key || "")
          if (!key && b.keycode) key = "code:" + b.keycode
          if (!key) continue
          map[desc] = { modmask: b.modmask, key: key }
        }
        root.hyprctlMap = map
        if (root.ready) root.loaded()
      }
    }
  }
}
