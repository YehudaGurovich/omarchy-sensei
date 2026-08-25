# Omarchy Dojo

Interactive, do-it-yourself tutorials for [Omarchy](https://omarchy.org).

Ask *"how do I…?"*, pick a lesson, and the Omarchy Dojo walks you through it
on your real desktop. The penguin sensei tells you which keys to press, then
waits until you perform the action before moving on.

## Why it is different

- **It reads your config, not the defaults.** Keybindings resolve live from
  your real Hyprland config: `bin/sensei-binds` runs your config entry point
  with a stubbed Hyprland API to record every binding, then resolves keycodes
  through your compiled keymap, with `hyprctl binds -j` as fallback. The dojo
  always shows *your* keys — even if you rebound everything.
- **It verifies by results, not keypresses.** Steps complete when the real
  compositor event fires (workspace changed, window moved, terminal opened).
  Use a key, a menu, or the mouse — if you did the thing, you advance.
  Skipped steps do not count: belts are earned, not clicked.
- **It degrades gracefully.** No matching keybinding or an exotic setup —
  every step still works: steps that anchor to a screen region spotlight it
  (dim + ring) and fall back silently when the anchor is missing;
  undetectable steps advance with a Next button; any step can be skipped.

## Install

```sh
omarchy plugin add https://github.com/YehudaGurovich/omarchy-sensei.git --enable
```

Once enabled, **the penguin appears in your bar** — click it and the dojo
opens. That is the whole onboarding: no keybinding, no command.

Upgrading from a pre-1.2 install? The bar widget joins the bar on the next
enable: run `omarchy plugin disable io.github.yehudagurovich.sensei &&
omarchy plugin enable io.github.yehudagurovich.sensei` once (or place it by
hand with `omarchy bar put io.github.yehudagurovich.sensei`).

Prefer a key? Any of these work:

```sh
omarchy-shell shell toggle io.github.yehudagurovich.sensei '{}'
```

or in `~/.config/hypr/bindings.lua` (pick any free chord — `SUPER + ALT + L`
is unbound on a default setup):

```lua
o.bind("SUPER + ALT + L", "Omarchy Dojo", "omarchy-shell shell toggle io.github.yehudagurovich.sensei '{}'")
```

A payload can launch a specific lesson directly — handy for binding the
welcome tour itself:

```sh
omarchy-shell shell toggle io.github.yehudagurovich.sensei '{"lesson":"welcome-tour"}'
```

### Close with Super+W

The plugin includes a close wrapper. It dismisses the dojo or coach when one
is open. Otherwise it runs Omarchy's normal close-window action. Add this to
`~/.config/hypr/bindings.lua`:

```lua
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", "~/.config/omarchy/plugins/io.github.yehudagurovich.sensei/bin/sensei-close")
```

If you already use a custom close command, give it to the wrapper as the
fallback:

```sh
~/.config/omarchy/plugins/io.github.yehudagurovich.sensei/bin/sensei-close ~/.config/hypr/scripts/my-close-command
```

The direct IPC command remains available for other integrations:

```sh
omarchy-shell sensei dismiss
```

## Requirements

Everything the Omarchy Dojo uses ships with Omarchy Quattro: `hyprctl`, `bash`,
`gawk`, `lua`, `jq`, and `xkbcli` (libxkbcommon). No extra package is needed.
The core plugin only reads your config and writes its own progress file under
`~/.local/state/omarchy-sensei/`. The optional Super+W integration above adds
one Hyprland binding. Compositor responses used for keybinding fallback and
spotlight placement have hard byte limits before QML receives them.

Remove with:

```sh
omarchy plugin remove io.github.yehudagurovich.sensei
```

Restore your old Super+W binding before removal if you enabled the optional
close integration.

## Usage

1. Click the penguin in the bar (or use your keybinding) — the dojo opens
   centered on the active screen.
   First-time users get a one-click start into the welcome tour.
2. Search by goal and filter by difficulty or mastery. Each card shows its
   topic, time, steps, and summary. The native scrollbar supports wheel,
   touchpad, and direct thumb dragging.
3. Pick a lesson and follow the steps on your live desktop. Drag the dojo
   header or the coach header to move either panel. During a walkthrough the
   desktop keeps keyboard focus — use the coach card's buttons to skip a
   step or end the lesson.
4. In the dojo, `Esc` clears the search; `Esc` again closes. If you enabled the
   packaged close wrapper, Super+W closes both the dojo and the active coach.

## Lessons

Lessons are plain data in `lessons/lessons.js`. Each step declares:

- `say` — the instruction; your live keybinding renders as keycaps below it
- `bind` — the keybinding description to resolve from your active config
- `await` — the Hyprland event (or alternatives) that proves you did it;
  `null` makes the step advance with a manual Next button
- `spotlight` — what to highlight while the step waits: `"bar"` rings the
  Omarchy bar; `"menu"`, `"emojis"`, `"clipboard"` ring those overlays once
  they are open; `"window"` rings the focused window. Missing anchors
  (replaced bar, other monitor, no focused window) degrade silently
- `notOnWorkspace` — marks a step that cannot complete while you are
  already on its target workspace (switching to the workspace you are on
  emits no event); the dojo shows a live nudge to hop elsewhere first
- `hint` — optional extra help shown when a step has waited a while;
  steps without one get a generic stuck-hint
- `why` — the workflow reason shown with each action
- `nextLabel` — an optional, specific confirmation label for a manual step
- lessons also carry `category`, `duration`, `outro`, and `difficulty`.
  The shared scale is Easy for basic actions with no required earlier lesson,
  Medium for one feature family that builds on Easy skills, and Hard for a
  workflow that combines feature families, needs setup, or has more risk

The pack has 33 lessons and 136 steps, from short verified actions to
multi-step system workflows and two guided circuits. The default path contains
9 Easy lessons, then 13 Medium lessons, then 11 Hard lessons.
Contributions of new lessons are welcome.

### Course coverage

- **Core navigation and windows:** numbered workspaces, former workspace,
  carry and silent moves, scratchpad, directional focus, swaps, resizing,
  layout modes, float/tile, full screen, full width, gaps, transparency,
  and single-window shape.
- **Menus and apps:** Super + Space command search, the Apps menu, terminal,
  live keybinding search, Herdr’s Super + Ctrl + K reference, web-app
  creation, and app launch.
- **Power and focus:** lock, suspend, wake, Stay Awake, notification
  silencing, nightlight, top-bar space, and reversible focus setups.
- **Software and plugins:** enable and disable shell plugins, choose a Pacman
  repository package, install it, and verify it with the package database.
- **Input and capture:** push-to-talk and toggled dictation, screenshots,
  keyboard region selection, OCR text capture, screen recording, audio-mode
  choice, and LocalSend sharing.
- **Desktop tools and hardware:** emoji and clipboard history, reminders,
  themes and backgrounds, plus the audio, Bluetooth, network, and power
  panels.
- **Integrated practice:** a focus sprint and a toolbelt circuit combine the
  verified actions into longer keyboard-first workflows.

## The Omarchy Dojo

Sensei keeps the flat dojo style but now has the broad orange feet, cream
belly, round body, tall face patches, and broad beak of the Linux penguin. The
headband and sash use the current belt color. The Dojo header also uses the
official Omarchy logo. Completing lessons without skipping earns 10 XP for
Easy, 20 XP for Medium, and 30 XP for Hard. There are nine belts. Each has an
Omarchy title: Fresh Install, Workspace Scout, Window Tiler, Menu Navigator,
Desktop Shaper, System Keeper, Workflow Adept, Omarchy Operator, and Omarchy
Sensei. Every belt needs more XP than the belt before it. A later belt never
needs fewer lessons. The bar shows XP inside the current belt, and Black
requires the full 680 course XP. Progress persists across restarts
(`~/.local/state/omarchy-sensei/progress.json`). Every completion screen
suggests the next unmastered lesson on the Easy-to-Hard path. Training happens
in a compact coach card while the desktop keeps keyboard focus.

## Status

Version 1.7.1 — the walkthrough engine works end to end: live key
resolution (including Lua `code:` binds via the compiled keymap),
event-driven step completion (multi-monitor aware), spotlight highlighting,
persistent progress and belts, and the coach card. Thirty-three lessons and 136
steps cover desktop navigation, power, appearance, software, plugins, input,
capture, sharing, hardware panels, and longer guided circuits. Detectable
actions use real compositor events; safe manual checkpoints cover workflows
such as Pacman installation and suspend. See `PLAN.md`.

Recent additions:

- **Bounded compositor reads.** Runtime keybinding and spotlight queries stop
  before QML receives oversized compositor-controlled responses. A rejected
  response degrades to the existing no-binding or no-spotlight fallback.
- **Omarchy Dojo progression.** The browser, bar tooltip, and completion card
  now use the Omarchy Dojo name. Nine Omarchy-titled belts span all 33 lessons,
  each later belt costs more XP, and Black requires full course mastery.
- **A consistent Easy-to-Hard path.** One difficulty scale applies to every
  lesson. The default order contains all Easy lessons first, then Medium,
  then Hard.
- **Native scrolling.** Touchpad gestures stay inside Qt's native Flickable
  path, including momentum. A real mouse wheel keeps the fast three-card step
  and short smooth motion. Hover effects pause while you scroll. Nearby rows are
  prepared and reused. A fresh open starts at the top, and filters reset the
  view to their first result.
- **Twenty-one advanced workflows.** The course now teaches Super + Space menu
  navigation, Super + Ctrl + K, silent window moves, focus and swap, resizing,
  screen-space controls, layouts, themes, Stay Awake, suspend/resume, plugins,
  Pacman, web apps, dictation, OCR, screen recording and sharing, focus modes,
  hardware panels, reminders, and visual window toggles.
- **Readable live shortcuts.** Tutorial keycaps use the latest readable active
  binding. An unresolved alternate hardware key cannot replace a clear primary
  shortcut such as Super + Space for the Omarchy menu.
- **Reliable centering.** The dojo recenters each time it opens and when its
  monitor size changes. It remains draggable during the current visit.
- **A course browser that shows its controls.** The larger dojo has explicit
  difficulty and mastery filters, rich lesson cards, and a native scrollbar.
  Both the dojo and coach can be dragged.
- **Richer teaching.** Lesson cards show category, time, step count, and a
  summary. Every live step explains why the action is useful, and every
  lesson ends with a skill-specific result. Two guided circuits combine six
  actions each into a full focus workflow and a daily-tools workout.
- **Belt-aware mascot.** The penguin's headband and sash use the earned belt
  color in the bar, dojo, and coach. Its feet, belly, eyes, and beak make it
  look like the Linux penguin. The bar updates without a shell restart.
- **More spotlight anchors.** Steps can ring the focused window and the
  open menu/emoji/clipboard overlays, not just the bar.
- **Live feedback.** The instant the compositor event fires, the keys you
  pressed echo next to the praise line, the sensei nods, and the progress
  dot fills — you see each move land in real time.
- **Motion.** The spotlight ring breathes, the coach card slides in, steps
  and keycaps animate, the current-step dot pulses, and finishing a lesson
  earns a belt-colored confetti burst from a hopping, blinking sensei.
- **Precheck nudges.** Workspace-jump steps detect when you are already on
  the target workspace (where the taught key emits no event) and coach you
  to hop elsewhere first — the nudge appears and clears live as you move.
- **Belts and a learning path.** Mastered lessons advance a nine-belt path.
  The completion screen suggests — and can start — the next unmastered lesson.
- **Hint escalation.** A step that waits ~30 seconds shows extra help: the
  step's own hint if it has one, otherwise an honest way out.
- **A penguin in your bar.** Omarchy Dojo ships a bar widget: one click opens the
  dojo, and a first-time button starts the welcome tour. Its hover text shows
  only the Dojo name and total XP progress.
- **Smaller module interfaces.** `Sensei.qml` controls lesson state and IPC.
  `DojoBrowser.qml` owns course discovery, and `LessonCoach.qml` owns the live
  walkthrough. Shared buttons and menu-event contracts live in one place.
- **Packaged close integration.** `bin/sensei-close` gives Super+W one safe
  route for the dojo, coach, and normal windows.

## Development

Validate the lesson schema, course progression, belts, scrolling setup, and
all active tutorial shortcuts:

```sh
./bin/sensei-validate-lessons
./bin/sensei-validate-ui
./bin/sensei-validate-scroll-speed
./bin/sensei-validate-close
./bin/sensei-validate-output-limits
./bin/sensei-validate-package
```

## License

MIT. The keybinding scan in `bin/sensei-binds` is derived from Omarchy's own
`omarchy-menu-keybindings` (MIT); see the notices at the end of `LICENSE`.
