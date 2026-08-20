// Sensei lesson data — schema v1.
//
// Lesson:
//   id        unique slug
//   title     shown in the browser list
//   keywords  extra search terms
//   intro     one-line summary (reserved for the lesson intro card)
//   steps     ordered list of Step
//
// Step:
//   say        plain instruction text; the resolved keycaps render below it
//   bind       keybinding description resolved from the user's live config
//              (bin/sensei-binds + hyprctl) — never a hardcoded key
//   await      completion signal from the Hyprland event socket. One object
//              or an array of alternatives (any match completes the step):
//                { event: "workspace", data: "^2$" }
//              On multi-monitor setups, focusing a workspace that is already
//              visible on another monitor emits focusedmon ("MONITOR,WS")
//              instead of workspace, so workspace steps await both.
//              Keep patterns as tight as the event data allows — a loose
//              pattern lets unrelated activity complete the step.
//              null means the step advances only with the manual Next button.
//   spotlight  "bar" | null — layer surface to highlight (Day 2)

var LESSONS = [
  {
    id: "welcome-tour",
    title: "Welcome tour — the basics",
    keywords: ["welcome", "start", "basics", "tour", "new", "first"],
    intro: "Five minutes to the core moves. The sensei waits for each one — take your time.",
    steps: [
      {
        say: "Jump to workspace 2.",
        bind: "Switch to workspace 2",
        await: [
          { event: "workspace", data: "^2$" },
          { event: "focusedmon", data: ",2$" }
        ],
        spotlight: "bar"
      },
      {
        say: "Open a terminal.",
        bind: "Terminal",
        await: {
          event: "openwindow",
          data: "^[^,]*,[^,]*,([Aa]lacritty|foot|footclient|kitty|com\\.mitchellh\\.ghostty|ghostty|org\\.wezfurlong\\.wezterm|wezterm|[Kk]onsole|[Ss]t|[Xx]term),"
        },
        spotlight: null
      },
      {
        say: "Carry that terminal to workspace 1 — you travel with it.",
        bind: "Move window to workspace 1",
        await: { event: "movewindow", data: ",1$" },
        spotlight: null
      },
      {
        // The tour flow guarantees the former workspace here is 2.
        say: "Bounce back to the workspace you came from.",
        bind: "Former workspace",
        await: [
          { event: "workspace", data: "^2$" },
          { event: "focusedmon", data: ",2$" }
        ],
        spotlight: "bar"
      }
    ]
  },
  {
    id: "switch-workspaces",
    title: "Switch between workspaces",
    keywords: ["workspace", "desktop", "navigate", "move around"],
    intro: "Workspaces are numbered desktops. You can jump to any of them directly.",
    steps: [
      {
        say: "Jump to workspace 2.",
        bind: "Switch to workspace 2",
        await: [
          { event: "workspace", data: "^2$" },
          { event: "focusedmon", data: ",2$" }
        ],
        spotlight: "bar"
      },
      {
        say: "Now come back to workspace 1.",
        bind: "Switch to workspace 1",
        await: [
          { event: "workspace", data: "^1$" },
          { event: "focusedmon", data: ",1$" }
        ],
        spotlight: "bar"
      },
      {
        // The lesson flow guarantees the former workspace here is 2.
        say: "Bounce back to the workspace you came from.",
        bind: "Former workspace",
        await: [
          { event: "workspace", data: "^2$" },
          { event: "focusedmon", data: ",2$" }
        ],
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
        // movewindow fires only when a window actually moves ("ADDRESS,WS"),
        // so merely switching workspaces cannot complete the step.
        say: "Carry this window to workspace 3 — you travel with it.",
        bind: "Move window to workspace 3",
        await: { event: "movewindow", data: ",3$" },
        spotlight: null
      },
      {
        say: "Bring it home: move it back to workspace 1.",
        bind: "Move window to workspace 1",
        await: { event: "movewindow", data: ",1$" },
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
        // openwindow data is "ADDRESS,WS,CLASS,TITLE"; match the class of
        // common terminals so an unrelated window cannot complete the step.
        say: "Open a new terminal window.",
        bind: "Terminal",
        await: {
          event: "openwindow",
          data: "^[^,]*,[^,]*,([Aa]lacritty|foot|footclient|kitty|com\\.mitchellh\\.ghostty|ghostty|org\\.wezfurlong\\.wezterm|wezterm|[Kk]onsole|[Ss]t|[Xx]term),"
        },
        spotlight: null
      }
    ]
  },
  {
    id: "float-window",
    title: "Float and tile a window",
    keywords: ["float", "floating", "tile", "tiling", "toggle"],
    intro: "Tiled windows share the screen; floating windows sit on top, free to move.",
    steps: [
      {
        say: "Pop the focused window out of the tiling grid.",
        bind: "Toggle window floating/tiling",
        await: { event: "changefloatingmode", data: ",1$" },
        spotlight: null
      },
      {
        say: "Tuck it back into the grid.",
        bind: "Toggle window floating/tiling",
        await: { event: "changefloatingmode", data: ",0$" },
        spotlight: null
      }
    ]
  },
  {
    id: "fullscreen",
    title: "Go full screen",
    keywords: ["fullscreen", "full", "screen", "maximize", "focus"],
    intro: "One keybinding fills the screen with the focused window — and brings it back.",
    steps: [
      {
        say: "Make the focused window fill the whole screen.",
        bind: "Full screen",
        await: { event: "fullscreen", data: "^1$" },
        spotlight: null
      },
      {
        say: "Now bring it back to its place in the grid.",
        bind: "Full screen",
        await: { event: "fullscreen", data: "^0$" },
        spotlight: null
      }
    ]
  },
  {
    id: "scratchpad",
    title: "Stash windows in the scratchpad",
    keywords: ["scratchpad", "stash", "special", "hide", "music", "notes"],
    intro: "The scratchpad is a hidden workspace you can summon anywhere — great for music players and notes.",
    steps: [
      {
        say: "Send the focused window to the scratchpad.",
        bind: "Move window to scratchpad",
        await: { event: "movewindow", data: ",special:scratchpad$" },
        spotlight: null
      },
      {
        say: "Summon the scratchpad to see it again.",
        bind: "Toggle scratchpad",
        await: { event: "activespecial", data: "^special:scratchpad," },
        spotlight: null
      },
      {
        say: "And tuck it away.",
        bind: "Toggle scratchpad",
        await: { event: "activespecial", data: "^," },
        spotlight: null
      }
    ]
  },
  {
    id: "omarchy-menu",
    title: "Open the Omarchy menu",
    keywords: ["menu", "omarchy", "settings", "launcher", "everything"],
    intro: "The Omarchy menu is the front door to apps, capture, themes, and system controls.",
    steps: [
      {
        say: "Open the Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null
      },
      {
        say: "Have a look around, then close it with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: null
      }
    ]
  },
  {
    id: "emojis",
    title: "Type an emoji",
    keywords: ["emoji", "emojis", "picker", "symbols"],
    intro: "A searchable emoji picker lives one keybinding away.",
    steps: [
      {
        say: "Open the emoji picker.",
        bind: "Emojis",
        await: { event: "openlayer", data: "^omarchy-emojis$" },
        spotlight: null
      },
      {
        say: "Search one and pick it with Enter — or close with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-emojis$" },
        spotlight: null
      }
    ]
  },
  {
    id: "clipboard",
    title: "Use the clipboard manager",
    keywords: ["clipboard", "copy", "paste", "history"],
    intro: "Everything you copy is kept in a searchable history.",
    steps: [
      {
        say: "Open the clipboard manager.",
        bind: "Clipboard manager",
        await: { event: "openlayer", data: "^omarchy-clipboard$" },
        spotlight: null
      },
      {
        say: "Pick an entry with Enter to paste it — or close with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-clipboard$" },
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
