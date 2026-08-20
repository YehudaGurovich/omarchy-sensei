# Sensei

Interactive, do-it-yourself tutorials for [Omarchy](https://omarchy.org).

Ask *"how do I…?"*, pick a lesson, and Sensei walks you through it on your real
desktop: it tells you exactly which keys to press, then waits until you
actually do it before moving on — like a game tutorial for your window manager.

## Why it is different

- **It reads your config, not the defaults.** Lessons resolve keybindings live
  from `hyprctl binds -j`, so Sensei always shows *your* keys — even if you
  rebound everything.
- **It verifies by results, not keypresses.** Steps complete when the real
  compositor event fires (workspace changed, window opened). Use a key, a
  menu, or the mouse — if you did the thing, you advance.
- **It degrades gracefully.** No matching keybinding, a replaced bar, an
  exotic setup — every lesson still works, down to a manual "Next" button.

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
3. Pick a lesson and follow the steps on your live desktop.
4. `Esc` goes back; `Esc` again closes.

## Lessons

Lessons are plain data in `lessons/lessons.js`. Each step declares:

- `say` — the instruction, with `{key}` replaced by your live keybinding
- `bind` — the keybinding description to resolve from your active config
- `await` — the Hyprland event that proves you did it
- `spotlight` — an optional screen region to highlight

Contributions of new lessons are welcome.

## The dojo

Sensei is a penguin master with a white beard and a red headband. Completing
lessons raises your belt rank, from white belt toward black belt. Your
training happens in a compact coach card in the corner of the screen — the
desktop keeps keyboard focus, so you perform every step for real.

## Status

Version 0.2.0 — the walkthrough engine works end to end: live key
resolution (including Lua `code:` binds via the compiled keymap),
event-driven step completion (multi-monitor aware), belts, and the coach
card. Next: spotlight highlighting, persistent progress, and more lessons.
See `PLAN.md`.

## License

MIT
