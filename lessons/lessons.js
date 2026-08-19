// Sensei lesson data — schema v0.
//
// Lesson:
//   id        unique slug
//   title     shown in the browser list
//   keywords  extra search terms
//   intro     one-line summary shown before the first step
//   steps     ordered list of Step
//
// Step:
//   say        instruction text; "{key}" is replaced with the user's live
//              keybinding resolved from `hyprctl binds -j` by description
//   bind       description string to look up in the user's active binds
//   await      completion signal from the Hyprland event socket:
//                { event: "workspace", data: "^2$" }
//              null means the step shows a manual Next button
//   spotlight  "bar" | null — layer surface to highlight (resolved via
//              `hyprctl layers -j`, degrades to no spotlight if absent)

var LESSONS = [
  {
    id: "switch-workspaces",
    title: "Switch between workspaces",
    keywords: ["workspace", "desktop", "navigate", "move around"],
    intro: "Workspaces are numbered desktops. You can jump to any of them directly.",
    steps: [
      {
        say: "Press {key} to jump to workspace 2.",
        bind: "Workspace 2",
        await: { event: "workspace", data: "^2$" },
        spotlight: "bar"
      },
      {
        say: "Now press {key} to come back to workspace 1.",
        bind: "Workspace 1",
        await: { event: "workspace", data: "^1$" },
        spotlight: "bar"
      },
      {
        say: "Press {key} to bounce back to the workspace you came from.",
        bind: "Former workspace",
        await: { event: "workspace", data: ".*" },
        spotlight: null
      }
    ]
  },
  {
    id: "move-window",
    title: "Move a window to another workspace",
    keywords: ["move", "window", "workspace", "send"],
    intro: "You can carry the focused window with you, or send it away silently.",
    steps: [
      {
        say: "Press {key} to move this window to workspace 3 and follow it.",
        bind: "Move window to workspace 3",
        await: { event: "workspace", data: "^3$" },
        spotlight: null
      },
      {
        say: "Bring it back: press {key} to move it to workspace 1.",
        bind: "Move window to workspace 1",
        await: { event: "workspace", data: "^1$" },
        spotlight: null
      }
    ]
  },
  {
    id: "open-terminal",
    title: "Open a terminal",
    keywords: ["terminal", "shell", "console", "app"],
    intro: "Omarchy launches your default terminal with one keybinding.",
    steps: [
      {
        say: "Press {key} to open a new terminal window.",
        bind: "Terminal",
        await: { event: "openwindow", data: ".*" },
        spotlight: null
      }
    ]
  }
]

function all() {
  return LESSONS
}

function search(query) {
  if (!query) return LESSONS
  var q = query.toLowerCase()
  return LESSONS.filter(function(lesson) {
    if (lesson.title.toLowerCase().indexOf(q) !== -1) return true
    return lesson.keywords.some(function(k) { return k.indexOf(q) !== -1 })
  })
}
