# Omarchy Dojo — build plan

Target: marketplace-ready release. The Mon Aug 24, 09:00 CEST competition
listing deadline passed before this branch was ready to publish.

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
- **Day 4 round 1 — DONE (Aug 21): audit + dynamism.** Full fact-check and
  an energy pass, verified end to end on this machine (welcome tour driven
  through real compositor events via scripted dispatches).
  Audit results:
  - All 12 lesson bind descriptions resolve against the live config (both
    `bin/sensei-binds` and `hyprctl binds -j`). Layer namespaces
    omarchy-bar/menu/emojis/clipboard confirmed in the shell source.
    lua/gawk/xkbcli/hyprctl all present. Terminal class regex covers the
    terminals installed here. `omarchy plugin validate .` passes (exit 0).
  - Found: README said 1.0.0 while manifest said 1.0.1 — versions now
    aligned at 1.1.0.
  - Found: workspace-jump steps dead-ended when the user was already on
    the target workspace (switching to the current workspace emits no
    event — reproduced live). Fix: `notOnWorkspace` step field + a live
    nudge, updated from `workspace` AND `focusedmon` events (the first
    test caught the nudge going stale on a monitor-focus change).
  - Known, accepted: float/fullscreen lessons self-correct if the window
    already is in the target state (first press emits the opposite event,
    second press completes); window spotlight degrades silently when the
    focused window is on a different monitor than the coach card.
  New in 1.1.0: spotlight anchors for the focused window and the open
  menu/emojis/clipboard layers; pressed-key echo beside the praise line
  the moment the event fires; animated spotlight (fade + breathing ring);
  coach card slide-in; staggered keycap pop-in; pulsing current-step dot;
  blinking/nodding penguin with a celebration hop; belt-colored confetti
  on completion; browser card entrance and hover transitions.
- **Day 4 round 2 — DONE (Aug 21): backlog features.** Points and ranks,
  learning path, hint escalation, bigger praise pool.
  - Every lesson has a `difficulty` (1–3, sums to 150 across the pack);
    first mastery awards 10 × difficulty points, stored in the points
    field progress.json carried since day one. Points climb a rank ladder
    (Grasshopper → Sensei, thresholds in Dojo.js tuned so mastering all
    lessons reaches Sensei). Rank + points show on the completion screen
    and in the browser belt row.
  - The completion screen names the next unmastered lesson in list order
    (the list IS the learning path) with a button that starts it.
  - Hint escalation: a step waiting 30 s shows its `hint` field, or a
    generic way out. Four steps got real hints (terminal alternative,
    float toggle, fullscreen toggle, scratchpad vanish reassurance).
  - Verified live: open-terminal completed by real event → 10 points in
    progress.json, next=welcome-tour suggested, rank shown. Hint timer
    verified by review only — two 30-second live waits were both cut
    short (see gotchas below); the path shares its mechanics with the
    proven praise timer.
  - Version 1.5.0 later removed the visible rank ladder. The points
    field remains in progress schema version 1 for compatibility; the UI now
    shows one nine-belt course progression.
  - Investigated and dropped for now: a resize lesson. Quattro has no
    resize submap — resizing is direct binds ("Expand window left",
    keycodes 20/21) — and no socket2 event for resize was confirmed
    (the probe hit a fullscreen window; retry on an idle machine).
- **Day 4 round 3 — DONE (Aug 23): modern-look pass + full sweep.**
  - Visual polish, all inside the theme tokens: keycaps joined with "+"
    separators and given a subtle border; the step dots replaced by a
    full-width segmented progress bar (done segments filled, current one
    breathing); difficulty shown as three dots on every browser row;
    thin rules under both card headers; the completion screen's "Next
    lesson" is now a filled primary button.
  - dev.sh now restarts the shell after syncing. Rationale: the hot-reload
    path is the crash trigger below and leaves stale IPC handlers.
  - Crash status confirmed (Aug 22): upstream issue
    quickshell-mirror/quickshell#956 is open with the same stack and a
    root cause (EngineGeneration::destroy() clears extensions but not the
    hash; forGeneration dynamic_casts a freed pointer) — no fix merged;
    an 8-round local reload-churn repro attempt did not crash (upstream
    quotes ~2 per 30 cycles), consistent with a timing-dependent race.
  - Full end-to-end sweep: all 10 lessons, all 22 steps, driven through
    real compositor actions (dispatches + shell overlay toggles) with
    zero failures; finished at 150 points = Sensei rank, next=null.
    No sensei QML warnings in the shell log. Test state fully restored.
- **Day 4 round 4 — DONE (Aug 23): bar widget + palette refresh (1.2.0).**
  - Sensei is now also a bar widget: the penguin (compact variant, knot
    tails hidden at icon size) as a BarIconButton that toggles the dojo —
    the beginner front door, zero setup. `kinds: ["overlay",
    "bar-widget"]`, `defaultSection: "right"`. Verified rendering in the
    live bar by screenshot.
  - Placement quirk: widgets auto-place at plugin ENABLE time, so a fresh
    marketplace install gets the icon automatically, but an existing
    install needs one disable/enable cycle (or `omarchy bar put`) —
    documented in the README. `omarchy bar put` alone claimed "is on the
    bar" without adding it to shell.json's layout; the enable cycle is
    the reliable path.
  - Dojo browser is a real command palette now: search field with prompt
    glyph and blinking cursor, first-visit banner with a primary "Begin"
    button into the welcome tour, empty-search state with suggestions,
    and a mastery progress bar above the belt line.
  - Live user validation: the welcome tour and float lessons were
    completed for real through the new UI mid-round (progress.json:
    30 pts) — CTA, engine, and points all exercised by an actual run.
- **Day 4 round 5 — DONE (Aug 23): course-browser redesign (1.3.0).**
  - Replaced the narrow palette with a larger course browser. It has visible
    difficulty and mastery filters; lesson summaries with category, duration,
    and step count; and a visible scroll control plus an explicit overflow
    label. User review removed the sort row and widened the lesson accent
    gutter so the line cannot touch the text.
  - The dojo and coach cards can be dragged by their headers and stay inside
    the monitor bounds. Menu rows, chips, entry motion, spotlight motion,
    keycaps, praise, progress, and completion all use short transitions.
  - Each live step now explains why the action is useful. Each lesson has a
    skill-specific completion message, so the flow teaches a desktop habit
    and not only a shortcut. Two six-step guided circuits combine the already
    verified focus and overlay actions into longer practice workflows.
  - The mascot headband and waist sash now use the earned belt color in the
    bar, browser, and coach. The bar watches progress.json and updates after
    mastery without a shell restart.
  - Verification: `qmllint -I /usr/share/omarchy/shell` passes for all QML
    files; `omarchy plugin validate .`, `node --check`,
    `bin/sensei-validate-lessons`, and `git diff --check` pass. The live shell
    showed the centered 12-lesson browser and coach with no Sensei runtime
    warnings.
- **Day 4 round 6 — DONE (Aug 23): advanced operating-system course (1.4.0).**
  - Added 21 multi-step lessons. The 33-lesson, 136-step pack now covers
    menu and app search, keybinding references, advanced window control,
    screen-space toggles, appearance, power, plugins, Pacman packages, web
    apps, dictation, capture, OCR, recording, sharing, hardware panels, and
    reminders.
  - Event-backed actions still wait for real compositor results. Operations
    with no safe event — including resize, package choice, dictation, and
    suspend/resume — use explicit manual checkpoints with action-specific
    button labels.
  - Reversible lessons restore the starting state for layout, shell space,
    Stay Awake, focus modes, and window visuals. The plugin lessons enable,
    use, and disable the Microphone bar control across safe shell reloads.
    Destructive targets such as a package or web app remain the learner’s
    choice.
  - The dojo now recenters on every open and monitor-size change, while its
    header remains draggable for the current visit.
  - Added a `sensei dismiss` IPC action. A normal Super+W close helper can now
    close the dojo or coach without using toggle, which could reopen a closed
    overlay.
- **Day 4 round 7 — DONE (Aug 24): Omarchy Dojo progression (1.5.0).**
  - Renamed the visible product and bar widget to Omarchy Dojo. The stable
    plugin id, IPC target, state path, and source filenames stay unchanged.
  - Applied one difficulty scale to all lessons: 9 Easy, 13 Medium, and 11 Hard.
    Runtime course order is now Easy → Medium → Hard while authored topic
    groups stay readable in the lesson data file.
  - Spread nine Omarchy-titled belts across the complete course. White starts
    at zero. Version 1.6.0 made Hard lessons give more XP. Each later belt
    costs more XP and never needs fewer lessons. Black requires all 680
    course XP. The old
    points field remains for schema compatibility.
  - Replaced the custom non-interactive scroll track with the native Omarchy
    Qt Quick scrollbar and stock flick behavior. Replaced each row's
    MouseArea with pointer handlers, and prepared reusable rows outside the
    visible area. Fresh opens and filter changes now reset the list to the
    first result.
  - Added repeatable validation for difficulty counts and order, full-course
    Black belt, and the native scroll setup.
  - Version 1.6.0 added explicit fast scrolling for both touchpads and mouse
    wheels, with a repeatable scroll-speed test. Hover effects pause during
    scroll input. Mouse-wheel steps now use a short, smooth motion. Touchpad
    scrolling applies each update immediately, without animation.
  - Version 1.6.0 kept the flat mascot style and added clear Linux penguin
    traits: broad orange feet, a pear-shaped belly, tall face patches, and a
    broad two-part beak. The header uses the official Omarchy logo, and the
    bar hover text shows only the Dojo name and total XP progress.
- **Day 4 round 8 — PARTIAL (Aug 25):** refreshed `preview.png` from the live
  centered Dojo on a clean workspace. A public-URL fresh install and the
  marketplace form remain blocked while the repository is private.
- **Day 4 round 9 — DONE (Aug 25):** moved course discovery and lesson coaching
  behind `DojoBrowser.qml` and `LessonCoach.qml`; kept `Sensei.qml` as the
  lesson-state and IPC controller. The plugin ships a tested Super+W close
  wrapper and shares the Omarchy-menu event contract across lessons. On Aug 26,
  explicit touchpad handling was restored because native Flickable fallback did
  not move the lesson list.
- **Day 4 round 10 — DONE (Aug 26):** version 1.7.2 restores touchpad scrolling
  and states the plugin's purpose: make Omarchy accessible from the first login
  through visual, hands-on lessons that help anyone learn Linux with confidence.

## Dev loop

```sh
./dev.sh          # sync repo -> ~/.config/omarchy/plugins/<id> and restart the shell
omarchy-shell shell toggle io.github.yehudagurovich.sensei '{}'
```

Logs: `qs list --all` for the instance id, then `qs log -i <id>`.

Gotchas learned while testing:

- `dev.sh` refuses to write plugin files while the session is locked. File
  churn previously queued reloads that made lock recovery show surfaces before
  Quickshell held an active Wayland session lock, which caused a SIGABRT.
- Hot reload re-creates the plugin but the OLD IpcHandler keeps answering
  (`Handler was registered but will not be used` in the log). Any change to
  IPC-visible behavior needs `omarchy restart shell` before `omarchy-shell
  sensei …` reflects it.
- Scripted lesson driving uses Quattro's Lua dispatch syntax:
  `hyprctl dispatch 'hl.dsp.focus({ workspace = "2" })'`,
  `'hl.dsp.window.move({ workspace = "1" })'`,
  `'hl.dsp.exec_cmd("alacritty")'`. Classic `hyprctl dispatch workspace 2`
  fails on this build.
- The shell can SIGSEGV and auto-respawn during `omarchy restart shell`
  (known upstream issue, see Day 2) — a lesson started right before the
  crash silently ends; check `qs list --all` for a new instance id before
  blaming the plugin. Confirmed twice by coredump: the crash is
  `IpcHandler::onPostReload` → `__dynamic_cast`, and it can fire up to a
  minute AFTER a dev.sh sync (queued plugin-reload events from the rsync
  file churn). `dev.sh` now refuses locked sessions, does not request an
  additional explicit rescan, and restarts the shell after syncing. After
  syncing, wait for the instance to settle before driving lessons.
- ANY file write inside ANY local plugin's directory triggers the shell's
  `reloadPlugins()` → `unloadPanels()` → `close()` on every panel plugin —
  which ends an in-flight lesson. Plugins must never write state into
  their own plugin dir (Sensei writes to `~/.local/state`, correct), and
  scripted tests should not touch `~/.config/omarchy/plugins` mid-lesson.

## Ideas backlog

- ~~**Omarchy points / sensei ranks**~~ — built in Day 4 round 2, then replaced
  in 1.5.0 by one nine-belt Omarchy Dojo path. The old points value remains
  in progress schema version 1.
- ~~**Hint escalation**~~ — DONE (Day 4 round 2): 30 s timer, per-step
  `hint` field with a generic fallback.
- ~~**Belt path / curriculum (lite)**~~ — DONE (Day 4 round 2): list order
  is the path; completion screen suggests and can start the next
  unmastered lesson. Full multi-course curricula remain open.
- **Challenge mode:** timed replay of a mastered lesson ("do the four core
  moves in 20 seconds"), with a personal-best per lesson stored next to
  `points`. Verified by the same events, so it cannot be cheesed.
- **Practice stats:** per-lesson completion count, fastest run, and a daily
  streak — data already flows through progress.json.
- **More event-verified lessons once tight signals are confirmed:** window
  groups, moving workspaces between monitors (`moveworkspace`), resizing,
  and theme changes. These lessons now exist with manual checkpoints where
  the compositor does not expose a distinguishing result.
- **User lesson packs:** load extra lesson files from
  `~/.config/omarchy-sensei/lessons.d/` so people can ship dojo packs for
  their own setups (the engine is already data-driven).
- **First-run autostart:** offer a one-line snippet that opens the welcome
  tour on a fresh Omarchy install's first login, gated on progress.json
  being absent.
- **Multi-monitor coach placement:** put the coach card (and window
  spotlight) on the monitor the user is actually working on, following
  `focusedmon` — removes the silent cross-monitor spotlight degrade.
- **Sound cues (opt-in):** a soft "tok" on step completion and a gong on
  lesson mastery, respecting a quiet flag in the payload.
- **Sensei speaks:** praise pool grown to ten lines (Day 4 round 2).
  Still open: occasional koans keyed to lesson ids so repeats feel fresh.

## Open questions

- Exact wording drift of bind descriptions across Omarchy versions — keep an
  alias map per lesson if needed.
- Whether `openlayer` events reliably identify the omarchy menu for
  menu-related lessons.
