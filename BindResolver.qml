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

  property var luaBinds: []
  property var hyprctlBinds: []
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

  // Returns { found, caps: ["SUPER", "3"], submap }
  function resolve(description) {
    var want = String(description || "").trim().toLowerCase()

    // Last match wins: the config executes defaults first, user files after,
    // so a user override shadows the default binding.
    for (var i = root.luaBinds.length - 1; i >= 0; i--) {
      var lb = root.luaBinds[i]
      if (lb.description.toLowerCase() !== want || !lb.key) continue
      return { found: true, caps: modNames(lb.modmask).concat([displayKey(lb.key)]), submap: "" }
    }

    for (var j = 0; j < root.hyprctlBinds.length; j++) {
      var hb = root.hyprctlBinds[j]
      if (String(hb.description || "").trim().toLowerCase() !== want) continue
      var key = String(hb.key || "")
      if (!key && hb.keycode) key = "code:" + hb.keycode
      if (!key) continue
      return { found: true, caps: modNames(hb.modmask).concat([displayKey(key)]), submap: String(hb.submap || "") }
    }

    return { found: false, caps: [], submap: "" }
  }

  Process {
    id: scanProcess
    running: false
    command: ["bash", root.scanScript]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = []
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length < 3) continue
          parsed.push({ modmask: parseInt(parts[0], 10) || 0, description: parts[1], key: parts[2] })
        }
        root.luaBinds = parsed
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
        try {
          root.hyprctlBinds = JSON.parse(text)
        } catch (e) {
          root.hyprctlBinds = []
        }
        if (root.ready) root.loaded()
      }
    }
  }
}
