// Sensei lesson data — schema v1.
//
// Lesson:
//   id         unique slug
//   title      shown in the browser list
//   keywords   extra search terms
//   intro      one-line summary shown on a lesson's first step
//   category   short browser grouping label
//   duration   estimated minutes for a first run
//   outro      lesson-specific mastery message
//   difficulty 1–3, using one course-wide scale:
//              1 Easy — basic, low-risk actions with no prior lesson needed
//              2 Medium — one feature family, based on the Easy skills
//              3 Hard — combines feature families, needs setup, or has risk
//   steps      ordered list of Step
//
// Step:
//   say        plain instruction text; the resolved keycaps render below it.
//              When bind is null the key belongs in the instruction (e.g.
//              "close with Esc") and the step still verifies by event.
//   bind       keybinding description resolved from the user's live config
//              (bin/sensei-binds + hyprctl) — never a hardcoded key
//   await      completion signal from the Hyprland event socket. One object
//              or an array of alternatives (any match completes the step).
//              Keep patterns as tight as the event data allows — a loose
//              pattern lets unrelated activity complete the step.
//              null means the step advances only with the manual Next button.
//   spotlight  what to highlight while the step waits, or null:
//              "bar" | "menu" | "emojis" | "clipboard" — layer surface by
//              namespace (menus only exist while open, so anchor them on
//              the step AFTER the one that opens them); "window" — the
//              focused window at step start. Missing anchors degrade
//              silently to no spotlight.
//   notOnWorkspace  N — the step cannot complete while the user is already
//              on workspace N (switching to the workspace you are on emits
//              no event). The dojo shows a nudge to hop elsewhere first.
//   hint       optional extra help shown when the step has waited a while;
//              omitted steps fall back to a generic stuck-hint.
//   why        one short reason shown with the action so the tutorial teaches
//              the workflow, not only the keys.
//   nextLabel  optional label for a manual step's confirmation button.

// openwindow data is "ADDRESS,WS,CLASS,TITLE"; match the class of common
// terminals so an unrelated window cannot complete a terminal step.
var TERMINAL_OPENWINDOW = {
  event: "openwindow",
  data: "^[^,]*,[^,]*,([Aa]lacritty|foot|footclient|kitty|com\\.mitchellh\\.ghostty|ghostty|org\\.wezfurlong\\.wezterm|wezterm|[Kk]onsole|[Ss]t|[Xx]term),"
}

// Reaching workspace N is verified by result, not by keypress. Two events
// can prove it: `workspace` (a monitor switched to N) and `focusedmon`
// ("MONITOR,N" — focus moved to a monitor already showing N). The second is
// deliberate: on multi-monitor setups, focusing the other monitor IS a valid
// way to arrive at its workspace, and pressing the taught key emits only
// focusedmon when N is already visible there.
function workspaceAwait(n) {
  return [
    { event: "workspace", data: "^" + n + "$" },
    { event: "focusedmon", data: "," + n + "$" }
  ]
}

var LESSONS = [
  {
    id: "welcome-tour",
    title: "Welcome tour — the basics",
    keywords: ["welcome", "start", "basics", "tour", "new", "first"],
    category: "Getting started",
    duration: 5,
    difficulty: 1,
    intro: "Five minutes to the core moves. The sensei waits for each one — take your time.",
    outro: "You can now move between spaces, open your command center, and carry work with you.",
    steps: [
      {
        say: "Jump to workspace 2.",
        bind: "Switch to workspace 2",
        await: workspaceAwait(2),
        spotlight: "bar",
        notOnWorkspace: 2,
        why: "Workspaces separate tasks without making you minimize or rearrange windows."
      },
      {
        say: "Open a terminal.",
        bind: "Terminal",
        await: TERMINAL_OPENWINDOW,
        spotlight: null,
        hint: "Any terminal counts — the Omarchy menu can launch one too, under Apps.",
        why: "The terminal is the quickest route to files, tools, and system commands."
      },
      {
        say: "Carry that terminal to workspace 1 — you travel with it.",
        bind: "Move window to workspace 1",
        await: { event: "movewindow", data: ",1$" },
        spotlight: "window",
        why: "Moving with a window keeps your attention on it while the rest of the desktop stays clean."
      },
      {
        // The tour's expected return target is 2 (the flow passes through
        // it); a user who wanders to 2 mid-step completes it early, which
        // is acceptable — they are where the step wanted them.
        say: "Bounce back to the workspace you came from.",
        bind: "Former workspace",
        await: workspaceAwait(2),
        spotlight: "bar",
        why: "Former workspace is the fast two-context switch: code and browser, notes and call, or any pair."
      }
    ]
  },
  {
    id: "switch-workspaces",
    title: "Switch between workspaces",
    keywords: ["workspace", "desktop", "navigate", "move around"],
    category: "Navigation",
    duration: 4,
    difficulty: 1,
    intro: "Workspaces are numbered desktops. You can jump to any of them directly.",
    outro: "Your desktop is now a set of destinations, not one crowded surface.",
    steps: [
      {
        say: "Jump to workspace 2.",
        bind: "Switch to workspace 2",
        await: workspaceAwait(2),
        spotlight: "bar",
        notOnWorkspace: 2,
        why: "Direct jumps are faster and more predictable than cycling through every workspace."
      },
      {
        say: "Now come back to workspace 1.",
        bind: "Switch to workspace 1",
        await: workspaceAwait(1),
        spotlight: "bar",
        why: "Numbered homes build muscle memory: you always know where each kind of work lives."
      },
      {
        // The lesson flow makes 2 the expected return target.
        say: "Bounce back to the workspace you came from.",
        bind: "Former workspace",
        await: workspaceAwait(2),
        spotlight: null,
        why: "The former-workspace shortcut turns repeated comparison into one quick toggle."
      }
    ]
  },
  {
    id: "move-window",
    title: "Move a window to another workspace",
    keywords: ["move", "window", "workspace", "send"],
    category: "Windows",
    duration: 4,
    difficulty: 1,
    intro: "You can carry the focused window with you, or send it away silently.",
    outro: "You can now reorganize the desktop without dragging, dropping, or losing focus.",
    steps: [
      {
        // movewindow fires only when a window actually moves ("ADDRESS,WS"),
        // so merely switching workspaces cannot complete the step.
        say: "Carry this window to workspace 3 — you travel with it.",
        bind: "Move window to workspace 3",
        await: { event: "movewindow", data: ",3$" },
        spotlight: "window",
        notOnWorkspace: 3,
        why: "Carry mode moves the window and your viewpoint together, so you can continue immediately."
      },
      {
        say: "Bring it home: move it back to workspace 1.",
        bind: "Move window to workspace 1",
        await: { event: "movewindow", data: ",1$" },
        spotlight: "window",
        why: "A known home workspace makes a displaced window easy to find again."
      }
    ]
  },
  {
    id: "open-terminal",
    title: "Open a terminal",
    keywords: ["terminal", "shell", "console", "app"],
    category: "Apps",
    duration: 2,
    difficulty: 1,
    intro: "Omarchy launches your default terminal with one keybinding.",
    outro: "Your command center is now one gesture away, wherever you are.",
    steps: [
      {
        say: "Open a new terminal window.",
        bind: "Terminal",
        await: TERMINAL_OPENWINDOW,
        spotlight: null,
        why: "A global launcher removes the need to leave your current workspace or reach for a menu."
      }
    ]
  },
  {
    id: "float-window",
    title: "Float and tile a window",
    keywords: ["float", "floating", "tile", "tiling", "toggle"],
    category: "Windows",
    duration: 3,
    difficulty: 1,
    intro: "Tiled windows share the screen; floating windows sit on top, free to move.",
    outro: "You can choose structure for normal work and free placement for temporary tools.",
    steps: [
      {
        say: "Pop the focused window out of the tiling grid.",
        bind: "Toggle window floating/tiling",
        await: { event: "changefloatingmode", data: ",1$" },
        spotlight: "window",
        hint: "If nothing moved, this window may already float — the keys toggle, so press twice and watch it.",
        why: "Floating fits calculators, media controls, and short-lived tools that should sit above the grid."
      },
      {
        say: "Tuck it back into the grid.",
        bind: "Toggle window floating/tiling",
        await: { event: "changefloatingmode", data: ",0$" },
        spotlight: "window",
        why: "Returning to the grid lets Hyprland restore balanced, automatic placement."
      }
    ]
  },
  {
    id: "fullscreen",
    title: "Go full screen",
    keywords: ["fullscreen", "full", "screen", "maximize", "focus"],
    category: "Windows",
    duration: 3,
    difficulty: 1,
    intro: "One keybinding fills the screen with the focused window — and brings it back.",
    outro: "You can now remove every distraction for focused work, then restore the layout.",
    steps: [
      {
        say: "Make the focused window fill the whole screen.",
        bind: "Full screen",
        await: { event: "fullscreen", data: "^1$" },
        spotlight: "window",
        why: "Full screen gives one task the whole display without changing the permanent layout."
      },
      {
        say: "Now bring it back to its place in the grid.",
        bind: "Full screen",
        await: { event: "fullscreen", data: "^0$" },
        spotlight: null,
        hint: "Same keys again — full screen is a toggle.",
        why: "The same toggle returns every neighboring window exactly where it was."
      }
    ]
  },
  {
    id: "scratchpad",
    title: "Stash windows in the scratchpad",
    keywords: ["scratchpad", "stash", "special", "hide", "music", "notes"],
    category: "Windows",
    duration: 5,
    difficulty: 2,
    intro: "The scratchpad is a hidden workspace you can summon anywhere — great for music players and notes.",
    outro: "You now have a portable drawer for any window you need often but do not want in the layout.",
    steps: [
      {
        say: "Send the focused window to the scratchpad.",
        bind: "Move window to scratchpad",
        await: { event: "movewindow", data: ",special:scratchpad$" },
        spotlight: "window",
        hint: "The window will vanish — that is the point. The next step summons it back.",
        why: "The scratchpad keeps a useful window alive without letting it occupy a normal workspace."
      },
      {
        say: "Summon the scratchpad to see it again.",
        bind: "Toggle scratchpad",
        await: { event: "activespecial", data: "^special:scratchpad," },
        spotlight: null,
        why: "The stored window can appear above whichever workspace you are using now."
      },
      {
        say: "And tuck it away.",
        bind: "Toggle scratchpad",
        await: { event: "activespecial", data: "^," },
        spotlight: null,
        why: "One toggle hides the drawer without closing its apps or losing their state."
      }
    ]
  },
  {
    id: "omarchy-menu",
    title: "Open the Omarchy menu",
    keywords: ["menu", "omarchy", "settings", "launcher", "everything"],
    category: "Essentials",
    duration: 3,
    difficulty: 1,
    intro: "The Omarchy menu is the front door to apps, capture, themes, and system controls.",
    outro: "You know where to discover commands before you decide which ones deserve muscle memory.",
    steps: [
      {
        say: "Open the Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The menu is the reliable fallback when you know the goal but not its shortcut."
      },
      {
        say: "Have a look around, then close it with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "Escape closes overlays consistently and returns keyboard control to your work."
      }
    ]
  },
  {
    id: "emojis",
    title: "Type an emoji",
    keywords: ["emoji", "emojis", "picker", "symbols"],
    category: "Tools",
    duration: 3,
    difficulty: 1,
    intro: "A searchable emoji picker lives one keybinding away.",
    outro: "Symbols are now searchable from any text field, with no browser detour.",
    steps: [
      {
        say: "Open the emoji picker.",
        bind: "Emojis",
        await: { event: "openlayer", data: "^omarchy-emojis$" },
        spotlight: null,
        why: "The picker works over every app, so you do not need to copy symbols from the web."
      },
      {
        say: "Search one and pick it with Enter — or close with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-emojis$" },
        spotlight: "emojis",
        why: "Typing a name is faster than scanning categories, and Enter inserts the selected result."
      }
    ]
  },
  {
    id: "clipboard",
    title: "Use the clipboard manager",
    keywords: ["clipboard", "copy", "paste", "history"],
    category: "Tools",
    duration: 3,
    difficulty: 1,
    intro: "Everything you copy is kept in a searchable history.",
    outro: "Your clipboard is now a searchable history instead of one fragile temporary slot.",
    steps: [
      {
        say: "Open the clipboard manager.",
        bind: "Clipboard manager",
        await: { event: "openlayer", data: "^omarchy-clipboard$" },
        spotlight: null,
        why: "History lets you recover older snippets without switching back to their source."
      },
      {
        say: "Pick an entry with Enter to paste it — or close with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-clipboard$" },
        spotlight: "clipboard",
        why: "Search narrows a long history quickly; Enter restores the chosen item to your workflow."
      }
    ]
  },
  {
    id: "menu-navigation",
    title: "Drive the Omarchy menu from the keyboard",
    keywords: ["menu", "super space", "search", "keyboard", "apps", "launcher"],
    category: "Essentials",
    duration: 6,
    difficulty: 2,
    intro: "Search the full Omarchy command tree, then launch an app without reaching for the mouse.",
    outro: "You can now treat the Omarchy menu as a searchable command center, not a tree you must memorize.",
    steps: [
      {
        say: "Open the full Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The full menu exposes apps, settings, installs, capture tools, and power controls from one place."
      },
      {
        say: "Type install, move with the arrow keys, open a submenu with Enter, then press Esc until the menu closes.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        hint: "Typing filters the visible choices. Enter opens the selected row; Esc backs out or closes the menu.",
        why: "Search is faster than remembering where every command sits in the hierarchy."
      },
      {
        say: "Open the focused Apps menu.",
        bind: "Apps menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The Apps route removes every system command when you only want to launch software."
      },
      {
        say: "Type the name of a harmless app, press Enter to launch it, and wait for the menu to close.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "A name and Enter are enough to launch any desktop app from any workspace."
      }
    ]
  },
  {
    id: "keybinding-finder",
    title: "Find shortcuts with Super K and Super Ctrl K",
    keywords: ["keybindings", "shortcut", "super k", "ctrl k", "herdr", "search"],
    category: "Essentials",
    duration: 6,
    difficulty: 2,
    intro: "Search the live desktop bindings, then open the separate Herdr shortcut reference.",
    outro: "You can now answer “what is the shortcut?” from the keyboard, including inside Herdr.",
    steps: [
      {
        say: "Open the main keybinding finder.",
        bind: "Keybindings",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "This list is built from your active configuration, so it includes your overrides."
      },
      {
        say: "Type workspace, inspect the matches, then close the finder with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "Searching by the result you want is easier than searching by a key you do not know."
      },
      {
        say: "Open the Herdr keybinding finder — this is the Super + Ctrl + K shortcut.",
        bind: "Herdr keybindings",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "Herdr has its own command layer, so Omarchy gives it a separate searchable reference."
      },
      {
        say: "Search for navigate, inspect the results, then close the finder with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "Keeping application-specific bindings separate prevents the global list from becoming noise."
      }
    ]
  },
  {
    id: "silent-window-move",
    title: "Send a window away without following it",
    keywords: ["window", "workspace", "silent", "send", "organize", "background"],
    category: "Windows",
    duration: 5,
    difficulty: 2,
    intro: "Move a window to another workspace while your view stays put, then go and collect it.",
    outro: "You can now file windows into other workspaces without interrupting the task in front of you.",
    steps: [
      {
        say: "Send the focused window silently to workspace 4.",
        bind: "Move window silently to workspace 4",
        await: { event: "movewindow", data: ",4$" },
        spotlight: "window",
        notOnWorkspace: 4,
        why: "Silent moves organize background work without moving your eyes or keyboard focus to its destination."
      },
      {
        say: "Jump to workspace 4 to find the window.",
        bind: "Switch to workspace 4",
        await: workspaceAwait(4),
        spotlight: "bar",
        why: "A direct jump makes the destination predictable even after the window disappears from view."
      },
      {
        say: "Carry that window home to workspace 1.",
        bind: "Move window to workspace 1",
        await: { event: "movewindow", data: ",1$" },
        spotlight: "window",
        why: "Carry mode is useful when the window becomes the next thing you want to work on."
      }
    ]
  },
  {
    id: "focus-and-swap",
    title: "Focus and rearrange tiled windows",
    keywords: ["focus", "swap", "windows", "arrows", "tile", "rearrange"],
    category: "Windows",
    duration: 7,
    difficulty: 2,
    intro: "Create a second tile, move focus by direction, swap positions, and clean up the practice window.",
    outro: "You can now move your attention and the layout independently, without clicking title bars.",
    steps: [
      {
        say: "Open a second terminal so the workspace has at least two tiles.",
        bind: "Terminal",
        await: TERMINAL_OPENWINDOW,
        spotlight: null,
        why: "Directional focus and swaps need neighboring tiles, so this creates a safe practice layout."
      },
      {
        say: "Move focus to the window on the left.",
        bind: "Focus on left window",
        await: { event: "activewindow", data: ".+" },
        spotlight: "window",
        hint: "If there is no tile on the left, use the right-focus shortcut instead, then try this step again.",
        why: "Directional focus follows the visible layout, so it stays intuitive when window order changes."
      },
      {
        say: "Swap the focused tile with the tile on its right.",
        bind: "Swap window to the right",
        await: null,
        spotlight: "window",
        nextLabel: "Swapped",
        why: "A swap changes the layout while focus stays with the window you are moving."
      },
      {
        say: "Move focus to the window on the right.",
        bind: "Focus on right window",
        await: { event: "activewindow", data: ".+" },
        spotlight: "window",
        why: "Focus shortcuts move attention only; they do not disturb the new arrangement."
      },
      {
        say: "Close the practice terminal you just focused.",
        bind: "Close window",
        await: { event: "closewindow", data: ".+" },
        spotlight: "window",
        why: "Closing the temporary tile leaves the workspace as clean as it was before practice."
      }
    ]
  },
  {
    id: "resize-window",
    title: "Resize a tiled window in small and large steps",
    keywords: ["resize", "window", "bigger", "smaller", "space", "minus", "equal"],
    category: "Windows",
    duration: 6,
    difficulty: 2,
    intro: "Push a tile boundary in both directions and learn the modifier that makes a large adjustment.",
    outro: "You can now tune how much room each tile receives without leaving the keyboard.",
    steps: [
      {
        say: "Expand the focused window toward the left.",
        bind: "Expand window left",
        await: null,
        spotlight: "window",
        nextLabel: "Expanded",
        why: "Standard resize steps are large enough to shape a normal two-window layout quickly."
      },
      {
        say: "Shrink it from the left to return the boundary.",
        bind: "Shrink window left",
        await: null,
        spotlight: "window",
        nextLabel: "Restored",
        why: "The opposite action makes keyboard resizing reversible and easy to correct."
      },
      {
        say: "Expand the window left by a large step.",
        bind: "Expand window left a lot",
        await: null,
        spotlight: "window",
        nextLabel: "Expanded a lot",
        why: "The large-step modifier is useful when a preview, editor, or browser needs most of the display."
      },
      {
        say: "Shrink it left by a large step to restore the layout.",
        bind: "Shrink window left a lot",
        await: null,
        spotlight: "window",
        nextLabel: "Layout restored",
        why: "Paired large moves let you borrow screen space for a task and give it back afterward."
      }
    ]
  },
  {
    id: "make-screen-space",
    title: "Create more working space, then restore it",
    keywords: ["space", "bar", "gaps", "full width", "toggle", "room", "focus"],
    category: "Windows",
    duration: 7,
    difficulty: 3,
    intro: "Temporarily remove desktop chrome and widen one tile, then return to the original layout.",
    outro: "You can now create a large work surface for a focused task and undo every temporary change.",
    steps: [
      {
        say: "Note whether the top bar and window gaps are visible now.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "State noted",
        why: "Remembering the starting state makes any toggle sequence safe to reverse."
      },
      {
        say: "Toggle the top bar to free its edge of the display.",
        bind: "Toggle top bar",
        await: null,
        spotlight: "bar",
        nextLabel: "Bar toggled",
        why: "Hiding the bar creates a little more vertical or horizontal room without stopping the shell."
      },
      {
        say: "Toggle window gaps to reclaim the space between tiles.",
        bind: "Toggle window gaps",
        await: null,
        spotlight: "window",
        nextLabel: "Gaps toggled",
        why: "Gapless tiles use every pixel when content density matters more than visual separation."
      },
      {
        say: "Give the focused tile the full available width.",
        bind: "Full width",
        await: null,
        spotlight: "window",
        nextLabel: "Full width",
        why: "Full width borrows the row without entering distraction-free full screen."
      },
      {
        say: "Use the same Full width shortcut again to restore the tile.",
        bind: "Full width",
        await: null,
        spotlight: "window",
        nextLabel: "Width restored",
        why: "The same toggle returns the window to the tiling layout."
      },
      {
        say: "Toggle window gaps again to restore their starting state.",
        bind: "Toggle window gaps",
        await: null,
        spotlight: "window",
        nextLabel: "Gaps restored",
        why: "A second toggle restores the exact setting you started with."
      },
      {
        say: "Toggle the top bar again to restore its starting state.",
        bind: "Toggle top bar",
        await: null,
        spotlight: "bar",
        nextLabel: "Bar restored",
        why: "The exercise ends without leaving a permanent shell change behind."
      }
    ]
  },
  {
    id: "workspace-layout",
    title: "Switch workspace layout modes",
    keywords: ["layout", "workspace", "scrolling", "dwindle", "tiles", "toggle"],
    category: "Windows",
    duration: 4,
    difficulty: 2,
    intro: "Toggle the current workspace between its two tiling layout modes and compare how windows behave.",
    outro: "You can now choose the layout that fits the current workspace and switch back at any time.",
    steps: [
      {
        say: "Look at the current order and sizes of the windows on this workspace.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Layout noted",
        why: "A clear before view makes the layout change easy to recognize."
      },
      {
        say: "Toggle the workspace layout and watch the tiles reorganize.",
        bind: "Toggle workspace layout",
        await: null,
        spotlight: "window",
        nextLabel: "Layout changed",
        why: "Dwindle divides the screen recursively; scrolling layout gives a horizontal stream of windows."
      },
      {
        say: "Toggle the layout again to return to the starting mode.",
        bind: "Toggle workspace layout",
        await: null,
        spotlight: "window",
        nextLabel: "Layout restored",
        why: "Layout is per workspace, so one experiment does not have to change the rest of the desktop."
      }
    ]
  },
  {
    id: "theme-and-background",
    title: "Change the theme and its background",
    keywords: ["theme", "background", "wallpaper", "style", "appearance", "colors"],
    category: "Appearance",
    duration: 7,
    difficulty: 2,
    intro: "Choose a system-wide theme, then pick a background that belongs to it.",
    outro: "You can now restyle the desktop and choose a matching background without editing a config file.",
    steps: [
      {
        say: "Open the theme switcher.",
        bind: "Theme menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The switcher previews the installed themes from a focused list."
      },
      {
        say: "Choose a theme with the arrows and press Enter; wait for the switcher to close.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        hint: "The selection changes application colors, terminal colors, borders, and shell surfaces together.",
        why: "One coordinated theme prevents different desktop parts from drifting into unrelated color schemes."
      },
      {
        say: "Open the background switcher for the active theme.",
        bind: "Background switcher",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "Themes can provide several matching backgrounds without duplicating the rest of the style."
      },
      {
        say: "Choose a background and press Enter; wait for the switcher to close.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "The selected background persists, so the next login keeps the same visual setup."
      }
    ]
  },
  {
    id: "stay-awake",
    title: "Toggle Stay Awake and restore idle mode",
    keywords: ["awake", "sleep", "idle", "lock", "screensaver", "presentation", "toggle"],
    category: "Power",
    duration: 6,
    difficulty: 2,
    intro: "Change the idle policy for a presentation or download, read its indicator, then restore the prior state.",
    outro: "You can now stop automatic idle temporarily and return the machine to normal locking behavior.",
    steps: [
      {
        say: "Look at the bar and note whether the Stay Awake indicator is active.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "State noted",
        why: "Stay Awake is a persistent toggle, so the indicator tells you which state you are changing from."
      },
      {
        say: "Open the Toggle menu.",
        bind: "Toggle menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The Toggle menu groups reversible system features in one short list."
      },
      {
        say: "Choose Stay Awake and press Enter; wait for the menu to close.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "The command switches between normal idle and a mode that keeps the screen and session awake."
      },
      {
        say: "Check that the Stay Awake indicator changed state.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "Indicator changed",
        why: "The bar confirms the policy without making you reopen a settings page."
      },
      {
        say: "Open the Toggle menu again.",
        bind: "Toggle menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "Repeating the same route makes the reversible pattern easy to remember."
      },
      {
        say: "Choose Stay Awake once more and press Enter to restore the state you started with.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "Returning the toggle avoids an accidental unlocked screen or an interrupted long task later."
      }
    ]
  },
  {
    id: "lock-suspend-resume",
    title: "Lock, suspend, and wake safely",
    keywords: ["lock", "sleep", "suspend", "wake", "resume", "power", "system"],
    category: "Power",
    duration: 8,
    difficulty: 3,
    intro: "Practice the difference between locking the session and suspending the whole machine.",
    outro: "You can now secure a short absence or put the machine to sleep, then return safely.",
    steps: [
      {
        say: "Save any important work before the power-state practice.",
        bind: null,
        await: null,
        spotlight: null,
        nextLabel: "Work saved",
        why: "Suspend is normally safe, but saving first is the right habit before any power transition."
      },
      {
        say: "Open the System menu.",
        bind: "System menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The focused System route gives direct access to lock, suspend, logout, reboot, and shutdown."
      },
      {
        say: "Choose Lock, unlock with your password, then confirm here.",
        bind: null,
        await: null,
        spotlight: "menu",
        nextLabel: "I’m unlocked",
        hint: "Lock keeps programs running and turns off the display; it does not suspend the computer.",
        why: "Lock is the fast choice when you leave the desk but background work must continue."
      },
      {
        say: "Open the System menu again.",
        bind: "System menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The same route keeps every power action discoverable even if you forget a direct shortcut."
      },
      {
        say: "Choose Suspend. Wake the machine, unlock it, then confirm here.",
        bind: null,
        await: null,
        spotlight: "menu",
        nextLabel: "I’m awake",
        hint: "If Suspend is hidden, it was disabled with the suspend toggle. Re-enable it before this lesson.",
        why: "Suspend saves much more power than lock while keeping the current session ready to resume."
      }
    ]
  },
  {
    id: "enable-microphone-plugin",
    title: "Enable the Microphone plugin",
    keywords: ["plugin", "plugins", "enable", "microphone", "shell", "bar"],
    category: "System",
    duration: 4,
    difficulty: 3,
    intro: "Add Omarchy’s Microphone control to the bar. The shell reload happens only after the final step.",
    outro: "The Microphone plugin is active. Reopen Omarchy Dojo to use it and remove it in the next lesson.",
    steps: [
      {
        say: "Open the Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "Plugin management lives under Setup because it changes which shell modules are active."
      },
      {
        say: "Open Setup → Plugins → Enable Plugin, choose Microphone, and press Enter. Omarchy Dojo will close while the shell reloads; reopen it for the next lesson.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        hint: "If Microphone is not listed, it is already enabled. Close the menu, skip this step, and continue with the next lesson.",
        why: "A plugin toggle changes shell configuration. Making it the last step lets Omarchy Dojo save completion before the panels reload."
      }
    ]
  },
  {
    id: "use-disable-microphone-plugin",
    title: "Use and disable the Microphone plugin",
    keywords: ["plugin", "plugins", "use", "disable", "toggle", "microphone", "mute", "bar"],
    category: "System",
    duration: 5,
    difficulty: 3,
    intro: "Try the Microphone bar control, restore its starting state, then remove the control from the bar.",
    outro: "You used a bar plugin and removed it without deleting its files.",
    steps: [
      {
        say: "Find the Microphone icon in the bar. Click it once and note whether the microphone becomes muted or live.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "Microphone toggled",
        hint: "If this computer has no microphone source, the icon can be hidden. Continue to the disable step.",
        why: "The plugin gives direct feedback and control without opening the full audio panel."
      },
      {
        say: "Click the Microphone icon again to restore its starting mute state.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "State restored",
        hint: "If the icon is hidden, continue without changing audio state.",
        why: "Restoring the state keeps this practice task from changing your recording setup."
      },
      {
        say: "Open the Omarchy menu again.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The disable flow uses the same Setup → Plugins route as enable."
      },
      {
        say: "Open Setup → Plugins → Disable Plugin and choose Microphone. Omarchy Dojo will close while the shell reloads.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        hint: "Choose Microphone, not Omarchy Dojo. Disabling the dojo would remove the tutorial from the bar.",
        why: "Disabling a bar plugin removes its layout entry but keeps the plugin installed."
      }
    ]
  },
  {
    id: "install-pacman-package",
    title: "Install a package through the Omarchy menu",
    keywords: ["pacman", "package", "install", "download", "software", "arch", "fzf"],
    category: "System",
    duration: 10,
    difficulty: 3,
    intro: "Open Omarchy’s package picker, inspect a package, install it with Pacman, and verify the result.",
    outro: "You can now discover and install repository packages without memorizing a Pacman command.",
    steps: [
      {
        say: "Open the Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The Install section provides a guided entry point to Arch packages and optional software."
      },
      {
        say: "Choose Install → Package and wait for the package terminal to open.",
        bind: null,
        await: TERMINAL_OPENWINDOW,
        spotlight: "menu",
        hint: "The first package index load can take a moment. The terminal contains a searchable fzf list.",
        why: "The package picker searches the configured repositories and shows Pacman package details before installation."
      },
      {
        say: "Type a package name, inspect its description, and use Tab if you want to select more than one.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Package selected",
        why: "Previewing the repository and description reduces the chance of installing a similarly named package."
      },
      {
        say: "Press Enter, approve the password prompt, and wait for Pacman to finish.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Install finished",
        hint: "Press Esc instead if you do not want to install anything during practice.",
        why: "Pacman verifies package signatures, resolves dependencies, and records the installed files."
      },
      {
        say: "Open a terminal for a verification check.",
        bind: "Terminal",
        await: TERMINAL_OPENWINDOW,
        spotlight: null,
        why: "A fresh terminal gives you a clean place to inspect the package database."
      },
      {
        say: "Run pacman -Qi followed by the package name and confirm that Installed Size is shown.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Verified",
        why: "Pacman’s local query proves which version is installed and where its metadata came from."
      }
    ]
  },
  {
    id: "create-web-app",
    title: "Create and launch a web app",
    keywords: ["web app", "webapp", "website", "launcher", "desktop", "install", "url"],
    category: "Apps",
    duration: 10,
    difficulty: 3,
    intro: "Turn a website into a standalone desktop launcher, then find it in the Apps menu.",
    outro: "You can now give any useful site its own app window and launcher entry.",
    steps: [
      {
        say: "Open the Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "Web App lives under Install because it creates a persistent desktop launcher."
      },
      {
        say: "Choose Install → Web App and wait for the setup terminal.",
        bind: null,
        await: TERMINAL_OPENWINDOW,
        spotlight: "menu",
        why: "The setup asks only for a display name and URL, then creates the desktop entry for you."
      },
      {
        say: "Enter a short app name, such as Wikipedia, and press Enter.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Name entered",
        why: "The name becomes the searchable label in the application launcher."
      },
      {
        say: "Enter the full site URL and press Enter.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "URL entered",
        hint: "A missing https:// prefix is added automatically.",
        why: "The URL becomes the isolated browser-app destination."
      },
      {
        say: "Wait for the icon lookup. If it fails, enter an icon URL or installed icon name.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Web app created",
        why: "A local icon makes the new launcher easy to recognize beside native applications."
      },
      {
        say: "Open the Apps menu.",
        bind: "Apps menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "New desktop entries become available through the normal app launcher."
      },
      {
        say: "Type the new app name and press Enter to launch it.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        hint: "You can remove it later from Omarchy menu → Remove → Web App.",
        why: "The site now opens in a focused app window without normal browser tabs or controls."
      }
    ]
  },
  {
    id: "dictation",
    title: "Dictate short and long text",
    keywords: ["dictation", "voice", "microphone", "speech", "voxtype", "push to talk"],
    category: "Input",
    duration: 8,
    difficulty: 3,
    intro: "Use push-to-talk for one sentence, then use the dictation toggle for a longer passage.",
    outro: "You can now choose between quick hold-to-speak dictation and a hands-free recording toggle.",
    steps: [
      {
        say: "Focus a non-sensitive text field where you can review the result.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Text field ready",
        hint: "If no dictation keys appear on the next step, install Dictation from Omarchy menu → Install → AI, then reopen Omarchy Dojo after setup restarts the shell.",
        why: "Dictation types into the focused field, so cursor placement decides where the transcript goes."
      },
      {
        say: "Hold the push-to-talk dictation key, speak one sentence, then release it.",
        bind: "Start dictation (push-to-talk)",
        await: null,
        spotlight: "window",
        nextLabel: "Sentence dictated",
        why: "Push-to-talk is ideal for short inserts because recording stops as soon as you release the key."
      },
      {
        say: "Read the inserted sentence and correct any names or punctuation.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Text reviewed",
        why: "Speech recognition is fast, but a short review prevents a plausible wrong word from surviving."
      },
      {
        say: "Start toggle dictation and speak two or three sentences without holding the keys.",
        bind: "Toggle dictation",
        await: null,
        spotlight: "bar",
        nextLabel: "Recording",
        why: "Toggle mode frees both hands during longer notes and shows an active dictation indicator in the bar."
      },
      {
        say: "Use the same dictation toggle again to stop and insert the transcript.",
        bind: "Toggle dictation",
        await: null,
        spotlight: "window",
        nextLabel: "Transcript inserted",
        why: "Stopping explicitly marks the end of the passage before the transcription is typed."
      },
      {
        say: "Proofread the longer transcript before you send or save it.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Proofread",
        why: "A final review is important for messages, commands, and any text with private or exact details."
      }
    ]
  },
  {
    id: "screenshot-and-ocr",
    title: "Capture a screenshot and extract text with OCR",
    keywords: ["screenshot", "capture", "ocr", "text", "clipboard", "print screen"],
    category: "Capture",
    duration: 9,
    difficulty: 3,
    intro: "Capture a window with the keyboard region picker, then copy visible text from the screen.",
    outro: "You can now save visual evidence and turn unselectable screen text into editable clipboard text.",
    steps: [
      {
        say: "Start a screenshot.",
        bind: "Screenshot",
        await: { event: "openlayer", data: "^selection$" },
        spotlight: null,
        why: "The smart picker can capture a region, a highlighted window, or the full screen."
      },
      {
        say: "Use Tab or the arrows to highlight a window, then press Enter to capture it.",
        bind: null,
        await: { event: "closelayer", data: "^selection$" },
        spotlight: null,
        hint: "You can also drag a free region with the mouse or press Ctrl + Enter for the full screen.",
        why: "Keyboard selection makes exact window captures fast and repeatable."
      },
      {
        say: "Review the capture in the editor; annotate or save it, then close the editor.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Capture saved",
        why: "Cropping and annotation before sharing keeps the image focused and removes irrelevant details."
      },
      {
        say: "Start screen-text extraction with OCR.",
        bind: "Extract text (OCR) from screenshot",
        await: { event: "openlayer", data: "^selection$" },
        spotlight: null,
        why: "OCR recovers text from images, videos, remote desktops, and interfaces that block selection."
      },
      {
        say: "Drag around a visible line of text and release to copy its recognized text.",
        bind: null,
        await: { event: "closelayer", data: "^selection$" },
        spotlight: null,
        why: "A tight region reduces unrelated characters and improves recognition accuracy."
      },
      {
        say: "Paste the extracted text into a safe text field and check it for OCR mistakes.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Text checked",
        why: "OCR output is editable, but similar glyphs such as O and 0 still need a quick review."
      }
    ]
  },
  {
    id: "screenrecord-and-share",
    title: "Record the screen and share the result",
    keywords: ["screenrecord", "record", "video", "audio", "share", "localsend", "capture"],
    category: "Capture",
    duration: 10,
    difficulty: 3,
    intro: "Choose a recording mode, capture a short region, stop cleanly, and send the saved file.",
    outro: "You can now record a focused demonstration with the right audio and share the saved result.",
    steps: [
      {
        say: "Open the screen-recording controls.",
        bind: "Screenrecording",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The first press opens recording choices when no recording is active."
      },
      {
        say: "Choose no audio, desktop audio, microphone, or webcam; wait for the region picker.",
        bind: null,
        await: { event: "openlayer", data: "^selection$" },
        spotlight: "menu",
        hint: "Use no audio for this practice unless you need to test a microphone or desktop sound.",
        why: "Choosing the minimum needed inputs protects privacy and keeps the recording file smaller."
      },
      {
        say: "Drag a small region to start recording.",
        bind: null,
        await: { event: "closelayer", data: "^selection$" },
        spotlight: null,
        why: "A focused region keeps the viewer’s attention on the workflow and hides unrelated screen content."
      },
      {
        say: "Perform one short, non-sensitive action inside the recorded region.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "Action recorded",
        why: "A short practice clip is enough to verify framing, audio choice, and recording quality."
      },
      {
        say: "Stop the active recording with the same shortcut.",
        bind: "Screenrecording",
        await: null,
        spotlight: "bar",
        nextLabel: "Recording stopped",
        why: "When recording is active, the shortcut stops it directly and saves the video to your Videos folder."
      },
      {
        say: "Open the Share menu.",
        bind: "Share",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "Omarchy uses LocalSend to transfer files to nearby devices without uploading them to a cloud service."
      },
      {
        say: "Choose File, select the recording from Videos, then finish or cancel the LocalSend transfer.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "Selecting the saved file completes the path from capture to a nearby phone or computer."
      }
    ]
  },
  {
    id: "focus-modes",
    title: "Quiet notifications and warm the screen",
    keywords: ["focus", "notifications", "do not disturb", "nightlight", "night", "toggle"],
    category: "Focus",
    duration: 6,
    difficulty: 2,
    intro: "Toggle notification silencing and nightlight, read their bar indicators, then restore both settings.",
    outro: "You can now create a quieter evening workspace and return both features to their prior state.",
    steps: [
      {
        say: "Note whether the notification-silencing and nightlight indicators are active in the bar.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "States noted",
        why: "Both features are persistent toggles, so reading the indicators prevents an accidental state change."
      },
      {
        say: "Toggle notification silencing.",
        bind: "Toggle silencing notifications",
        await: null,
        spotlight: "bar",
        nextLabel: "Notifications toggled",
        why: "Silencing suppresses notification interruptions without disabling the notification system."
      },
      {
        say: "Toggle nightlight and watch the display temperature change.",
        bind: "Toggle nightlight",
        await: null,
        spotlight: "bar",
        nextLabel: "Nightlight toggled",
        why: "Nightlight reduces cool screen light for a more comfortable evening display."
      },
      {
        say: "Toggle nightlight again to restore its starting state.",
        bind: "Toggle nightlight",
        await: null,
        spotlight: "bar",
        nextLabel: "Nightlight restored",
        why: "A second use of the same shortcut restores the original display temperature policy."
      },
      {
        say: "Toggle notification silencing again to restore its starting state.",
        bind: "Toggle silencing notifications",
        await: null,
        spotlight: "bar",
        nextLabel: "Notifications restored",
        why: "The exercise ends without leaving notifications unexpectedly muted."
      }
    ]
  },
  {
    id: "quick-settings-panels",
    title: "Use the audio, Bluetooth, network, and power panels",
    keywords: ["audio", "bluetooth", "network", "wifi", "power", "battery", "panel", "settings"],
    category: "Hardware",
    duration: 8,
    difficulty: 2,
    intro: "Open each main hardware panel, learn what it controls, and close it with the same shortcut.",
    outro: "You can now reach the four daily hardware panels directly, without searching through settings.",
    steps: [
      {
        say: "Open Audio, inspect output, input, and volume, then use the same shortcut to close it.",
        bind: "Audio",
        await: null,
        spotlight: "bar",
        nextLabel: "Audio inspected",
        why: "The Audio panel can move active sound to another device and control microphones in one place."
      },
      {
        say: "Open Bluetooth, inspect power and paired devices, then close it with the same shortcut.",
        bind: "Bluetooth",
        await: null,
        spotlight: "bar",
        nextLabel: "Bluetooth inspected",
        why: "The Bluetooth panel shows connection state before you pair, connect, disconnect, or forget a device."
      },
      {
        say: "Open Network, inspect the active connection, then close it with the same shortcut.",
        bind: "Network",
        await: null,
        spotlight: "bar",
        nextLabel: "Network inspected",
        why: "The Network panel gives quick Wi-Fi control and connection details without opening a separate settings app."
      },
      {
        say: "Open Power, inspect battery use and power mode, then close it with the same shortcut.",
        bind: "Power",
        await: null,
        spotlight: "bar",
        nextLabel: "Power inspected",
        why: "The Power panel explains charge, discharge, and performance state before you change a power mode."
      }
    ]
  },
  {
    id: "set-reminder",
    title: "Set and verify a desktop reminder",
    keywords: ["reminder", "timer", "notification", "later", "alert", "schedule"],
    category: "Tools",
    duration: 5,
    difficulty: 2,
    intro: "Create a one-minute reminder, inspect the active reminder list, and wait for the notification.",
    outro: "You can now turn a thought into a timed desktop notification without opening a calendar.",
    steps: [
      {
        say: "Open the reminder prompt.",
        bind: "Set reminder",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The direct prompt removes the need to navigate through the main menu for a common timed action."
      },
      {
        say: "Set it for 1 minute, enter Practice complete as the message, and submit the prompt.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "A short timer lets you verify the complete reminder path during this lesson."
      },
      {
        say: "Show the active reminders and confirm that Practice complete is listed.",
        bind: "Show reminders",
        await: null,
        spotlight: "bar",
        nextLabel: "Reminder listed",
        why: "The list confirms the reminder was scheduled before you rely on it."
      },
      {
        say: "Continue working until the Practice complete notification appears.",
        bind: null,
        await: null,
        spotlight: "bar",
        nextLabel: "Notification received",
        hint: "The timer starts when you submit it. Wait the remaining minute, then confirm here.",
        why: "Seeing the notification proves the reminder service survives after its prompt closes."
      }
    ]
  },
  {
    id: "window-visual-toggles",
    title: "Toggle transparency and single-window shape",
    keywords: ["transparency", "opacity", "square", "aspect", "window", "toggle", "visual"],
    category: "Windows",
    duration: 6,
    difficulty: 2,
    intro: "Change two focused-window presentation modes, observe them, then restore both starting states.",
    outro: "You can now make one window transparent or constrain a lone tile without making a permanent layout edit.",
    steps: [
      {
        say: "Note the focused window’s opacity and shape.",
        bind: null,
        await: null,
        spotlight: "window",
        nextLabel: "State noted",
        why: "These are toggles, so the before view tells you what the second press must restore."
      },
      {
        say: "Toggle transparency for the focused window.",
        bind: "Toggle window transparency",
        await: null,
        spotlight: "window",
        nextLabel: "Transparency toggled",
        why: "Temporary transparency can expose reference content behind the active window."
      },
      {
        say: "Toggle the single-window square aspect setting.",
        bind: "Toggle single-window square aspect",
        await: null,
        spotlight: "window",
        nextLabel: "Shape toggled",
        why: "A centered square keeps one-window work from stretching across a very wide monitor."
      },
      {
        say: "Toggle the square aspect again to restore its starting state.",
        bind: "Toggle single-window square aspect",
        await: null,
        spotlight: "window",
        nextLabel: "Shape restored",
        why: "The second press removes the temporary single-window constraint."
      },
      {
        say: "Toggle transparency again to restore the original opacity.",
        bind: "Toggle window transparency",
        await: null,
        spotlight: "window",
        nextLabel: "Opacity restored",
        why: "The exercise finishes without leaving the active window hard to read."
      }
    ]
  },
  {
    id: "focus-sprint",
    title: "Focus sprint — put the moves together",
    keywords: ["challenge", "practice", "workout", "flow", "focus", "sprint"],
    category: "Challenge",
    duration: 7,
    difficulty: 3,
    intro: "A six-action desktop run: travel, launch, focus, restore, carry, and return.",
    outro: "You completed a full keyboard-first workflow without breaking attention or rearranging the desktop by hand.",
    steps: [
      {
        say: "Begin the run on workspace 2.",
        bind: "Switch to workspace 2",
        await: workspaceAwait(2),
        spotlight: "bar",
        notOnWorkspace: 2,
        why: "A deliberate starting workspace makes the rest of the workflow predictable."
      },
      {
        say: "Launch a terminal for the task.",
        bind: "Terminal",
        await: TERMINAL_OPENWINDOW,
        spotlight: null,
        why: "Launching in place keeps the task inside its workspace instead of pulling you to an app list."
      },
      {
        say: "Give the terminal the whole screen.",
        bind: "Full screen",
        await: { event: "fullscreen", data: "^1$" },
        spotlight: "window",
        why: "Temporary full screen creates a clean focus phase without changing the saved layout."
      },
      {
        say: "Restore the tiled layout.",
        bind: "Full screen",
        await: { event: "fullscreen", data: "^0$" },
        spotlight: null,
        why: "Restoring with the same toggle returns every window to its previous place."
      },
      {
        say: "Carry the terminal home to workspace 1.",
        bind: "Move window to workspace 1",
        await: { event: "movewindow", data: ",1$" },
        spotlight: "window",
        why: "Carry mode moves the active result and your viewpoint as one action."
      },
      {
        say: "Finish by bouncing back to workspace 2.",
        bind: "Former workspace",
        await: workspaceAwait(2),
        spotlight: "bar",
        why: "The former-workspace toggle closes the loop without making you remember where you came from."
      }
    ]
  },
  {
    id: "toolbelt-circuit",
    title: "Toolbelt circuit — menus at speed",
    keywords: ["challenge", "practice", "menu", "emoji", "clipboard", "tools"],
    category: "Challenge",
    duration: 6,
    difficulty: 3,
    intro: "Open, inspect, and dismiss the three overlays you will use every day.",
    outro: "The Omarchy menu, emoji picker, and clipboard history are now one consistent open-search-close pattern.",
    steps: [
      {
        say: "Open the Omarchy menu.",
        bind: "Omarchy menu",
        await: { event: "openlayer", data: "^omarchy-menu$" },
        spotlight: null,
        why: "The main menu is where you discover actions before their shortcuts become habit."
      },
      {
        say: "Close the menu with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-menu$" },
        spotlight: "menu",
        why: "Escape is the shared exit for Omarchy overlays, so you always know how to return."
      },
      {
        say: "Open the emoji picker.",
        bind: "Emojis",
        await: { event: "openlayer", data: "^omarchy-emojis$" },
        spotlight: null,
        why: "A global picker makes symbols available in every text field."
      },
      {
        say: "Pick an emoji or close the picker with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-emojis$" },
        spotlight: "emojis",
        why: "Search, Enter, and Escape use the same fast keyboard rhythm as the main menu."
      },
      {
        say: "Open clipboard history.",
        bind: "Clipboard manager",
        await: { event: "openlayer", data: "^omarchy-clipboard$" },
        spotlight: null,
        why: "Clipboard history turns several recent copies into a reusable toolbelt."
      },
      {
        say: "Pick an entry or close the history with Esc.",
        bind: null,
        await: { event: "closelayer", data: "^omarchy-clipboard$" },
        spotlight: "clipboard",
        why: "The final overlay uses the same open-search-close pattern, which makes the whole set easy to remember."
      }
    ]
  }
]

// The authored blocks stay grouped by topic. The course shown to learners is
// grouped by difficulty, with authored order kept inside each level. This
// makes the default path progress from Easy to Medium to Hard.
var COURSE = LESSONS.map(function(lesson, index) {
  return { lesson: lesson, index: index }
}).sort(function(left, right) {
  return left.lesson.difficulty - right.lesson.difficulty || left.index - right.index
}).map(function(entry) {
  return entry.lesson
})

function learningPath() {
  return COURSE
}

// Course order is the learning path: the suggested next lesson is the
// first unmastered one that is not the lesson just finished.
function nextLesson(currentId, completedIds) {
  for (var i = 0; i < COURSE.length; i++) {
    if (COURSE[i].id === currentId) continue
    if (completedIds.indexOf(COURSE[i].id) !== -1) continue
    return COURSE[i]
  }
  return null
}

function search(query) {
  if (!query) return COURSE
  var q = query.toLowerCase()
  return COURSE.filter(function(lesson) {
    if (lesson.title.toLowerCase().indexOf(q) !== -1) return true
    if (lesson.intro.toLowerCase().indexOf(q) !== -1) return true
    if (lesson.category.toLowerCase().indexOf(q) !== -1) return true
    return lesson.keywords.some(function(k) { return k.indexOf(q) !== -1 })
  })
}
