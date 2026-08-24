import Quickshell.Io
import QtQuick
import "BindSelection.js" as BindSelection

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

  // The hyprctl fallback can surface raw XKB keycodes; map the common ones
  // so keycaps read "2", not "code:11" (same table as bin/sensei-binds).
  readonly property var keycodeSymbols: ({
    "code:10": "1", "code:11": "2", "code:12": "3", "code:13": "4",
    "code:14": "5", "code:15": "6", "code:16": "7", "code:17": "8",
    "code:18": "9", "code:19": "0", "code:20": "MINUS", "code:21": "EQUAL",
    "code:59": "COMMA", "code:60": "PERIOD", "code:61": "SLASH"
  })

  function displayKey(key) {
    var k = String(key || "")
    if (root.keycodeSymbols[k]) return root.keycodeSymbols[k]
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
        // readable lines overwrite earlier ones and a user override wins.
        // An unresolved alternate keycode cannot replace a readable binding.
        var map = {}
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length < 3 || !parts[2]) continue
          var description = parts[1].trim().toLowerCase()
          var current = map[description]
          if (current && !BindSelection.shouldReplaceBinding(current.key, parts[2]))
            continue
          map[description] = { modmask: parseInt(parts[0], 10) || 0, key: parts[2] }
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
          if (!desc) continue
          var key = String(b.key || "")
          if (!key && b.keycode) key = "code:" + b.keycode
          if (!key) continue
          var current = map[desc]
          if (current && !BindSelection.shouldReplaceBinding(current.key, key))
            continue
          map[desc] = { modmask: b.modmask, key: key }
        }
        root.hyprctlMap = map
        if (root.ready) root.loaded()
      }
    }
  }
}
