# Sensei — build plan

Target: listed on the marketplace before Mon Aug 24, 09:00 CEST.

## Architecture decisions

1. **Keybinding resolution by description.** Omarchy Quattro routes all binds
   through the Lua dispatcher (`__lua`), so dispatcher/arg is opaque. Every
   default bind carries a human `description` (235/238 on a customized
   machine). Lessons reference descriptions ("Move window to workspace 3");
   Sensei resolves the actual key from `hyprctl binds -j` at lesson start and
   renders modmask+key as e.g. `SUPER + 3`.
2. **Step completion via Hyprland IPC socket2 events** (`workspace`,
   `openwindow`, `submap`, `fullscreen`, `openlayer`, …). Compositor facts,
   independent of how the user triggered them.
3. **Spotlight via layer geometry.** Bar located through `hyprctl layers -j`
   namespace `omarchy-bar`. Missing anchor → step runs without spotlight.
4. **Degradation ladder:** spotlight + auto-detect → detect only → manual
   Next. Unresolvable bind → lesson says "you have no binding for this".
5. **Lessons are data** (`lessons/lessons.js`), engine is generic. Loaded as a
   relative JS import to avoid runtime path resolution issues.

## Day plan

- **Day 1 — DONE (Aug 20):** walkthrough engine — bind resolver, Hyprland
  event listener, step state machine, coach card UI, dojo theming (penguin
  mascot, belts, praise lines), IPC routes (`sensei start/status/skip/end` —
  skip mirrors the coach card button and drives scripted testing).
  Verified end to end against the live compositor.
  Findings that changed the design:
  - Hyprland's Lua config provider hides keys for `code:` binds in
    `hyprctl binds -j` (59 binds affected). Fix: `bin/sensei-binds` executes
    the user's real config entry point with a stubbed `hl` API (not a
    sandbox — the config runs its full stdlib, as it already does inside
    Hyprland) and resolves keycodes through the compiled keymap (approach
    mirrors Omarchy's own omarchy-menu-keybindings). hyprctl stays as
    fallback. Known upstream-shared limitation: keycode symbols come from
    the environment's default layout, not Hyprland's kb_layout.
  - Multi-monitor: focusing a workspace already visible on another monitor
    emits `focusedmon`, not `workspace`. Steps now await alternative events.
  - Untested so far: the move-window lesson (same await mechanism, but not
    yet exercised end to end).
  - Post-review cleanup: praise now shows transiently while the next step is
    already live (no gated flash phase, no stale timer); skipping a step
    finishes the lesson without belt credit; awaits tightened (movewindow
    only for moves, terminal class match for openwindow, deterministic
    former-workspace target); resolver merged into one map lookup with
    user-override-wins semantics.
- **Day 2 — DONE (Aug 20, issues #1–#3):** spotlight overlay (dim panes +
  ring from layer geometry, window-local via monitor offset, silent
  degradation), persistent progress (`progress.json` with a points field,
  atomic writes), welcome tour lesson + first-time hint. Verified end to end
  including a real window move and a restart-survival check; spotlight
  confirmed visually by screenshot.
  Known upstream issue: quickshell can SIGSEGV on shell reload in
  `IpcHandler::onPostReload` (`__dynamic_cast`) — crash is in Quickshell C++,
  auto-respawns, not plugin-caused; report upstream separately.
- **Day 3 — DONE (Aug 20, issue #4):** content pack — 10 lessons total:
  welcome tour, workspaces, move window, terminal, float/tile, fullscreen,
  scratchpad, Omarchy menu, emojis, clipboard. Every await verified against
  captured socket2 events (changefloatingmode, fullscreen, activespecial,
  movewindow, openlayer/closelayer by namespace); all lessons exercised end
  to end on this machine. Steps whose key is in the instruction (e.g. Esc to
  close a menu) use bind: null — keycaps hidden, event still verified.
  Dropped from the candidate list: themes (no distinguishable event — the
  theme menu shares the omarchy-menu namespace), lock/idle (locks the
  session mid-lesson), resize submap and window groups (no reliably tight
  events confirmed yet).
- **Day 4 (Sun Aug 24 morning is the deadline — finish Sat night):** polish,
  preview.png, README pass, validate, fresh-install test, submit form.

## Dev loop

```sh
./dev.sh          # sync repo -> ~/.config/omarchy/plugins/<id> and restart the shell
omarchy-shell shell toggle io.github.yehudagurovich.sensei '{}'
```

The sync refuses to run while the session is locked. Writing plugin files
during a lock can reload the shell into an invalid session-lock state.

Logs: `qs log` workflow.

## Ideas backlog

- **Omarchy points / sensei ranks:** award points per completed lesson,
  weighted by difficulty (each lesson gets a difficulty field). Points feed a
  rank progression from grasshopper to sensei alongside the belt colors, so
  advanced lessons (submaps, window groups, scripting) are worth more than
  basics. Local-only. Design the Day 2 progress.json with a points field so
  this can land without a schema change.

## Open questions

- Exact wording drift of bind descriptions across Omarchy versions — keep an
  alias map per lesson if needed.
- Whether `openlayer` events reliably identify the omarchy menu for
  menu-related lessons.
