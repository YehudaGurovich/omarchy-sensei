# Sensei

Interactive, do-it-yourself tutorials for [Omarchy](https://omarchy.org).

Ask *"how do I…?"*, pick a lesson, and Sensei walks you through it on your real
desktop: it tells you exactly which keys to press, then waits until you
actually do it before moving on — like a game tutorial for your window manager.

## Why it is different

- **It reads your config, not the defaults.** Keybindings resolve live from
  your real Hyprland config: a sandboxed scan of your config entry point plus
  your compiled keymap (`bin/sensei-binds`), with `hyprctl binds -j` as
  fallback. Sensei always shows *your* keys — even if you rebound everything.
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

Open Sensei:

```sh
omarchy-shell shell toggle io.github.yehudagurovich.sensei '{}'
```

Bind it to a key for quick access.

## Usage

1. Open Sensei — a search palette appears.
2. Type what you want to learn ("move window", "terminal", "workspace").
3. Pick a lesson and follow the steps on your live desktop. During a
   walkthrough the desktop keeps keyboard focus — use the coach card's
   buttons to skip a step or end the lesson.
4. In the palette, `Esc` clears the search; `Esc` again closes.

## Lessons

Lessons are plain data in `lessons/lessons.js`. Each step declares:

- `say` — the instruction; your live keybinding renders as keycaps below it
- `bind` — the keybinding description to resolve from your active config
- `await` — the Hyprland event (or alternatives) that proves you did it;
  `null` makes the step advance with a manual Next button
- `spotlight` — a screen region to highlight while the step waits
  (`"bar"` rings the Omarchy bar; missing anchors degrade silently)

Contributions of new lessons are welcome.

## The dojo

Sensei is a penguin master with a white beard and a red headband. Completing
lessons — without skipping steps — raises your belt rank, from white belt
toward black belt. Progress persists across restarts
(`~/.local/state/omarchy-sensei/progress.json`). First-time visitors are
pointed at the welcome tour, which walks the core moves in four steps. Your
training happens in a compact coach card in the corner of the screen — the
desktop keeps keyboard focus, so you perform every step for real.

## Status

Version 0.3.0 — the walkthrough engine works end to end: live key
resolution (including Lua `code:` binds via the compiled keymap),
event-driven step completion (multi-monitor aware), spotlight highlighting,
persistent progress and belts, the welcome tour, and the coach card.
Next: more lessons. See `PLAN.md`.

## License

MIT
