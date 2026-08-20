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
