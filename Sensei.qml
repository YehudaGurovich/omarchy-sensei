import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "lessons/lessons.js" as Lessons
import "Dojo.js" as Dojo

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property bool opened: browser.opened

  property var lesson: null
  property int stepIndex: 0
  property string phase: "idle"
  property var stepCaps: []
  property bool stepBindFound: true
  property string praiseText: ""
  property var praiseCaps: []
  property bool skipUsed: false
  property var completedIds: []
  readonly property var learningPath: Lessons.learningPath()
  readonly property int courseXp: Dojo.totalXp(root.learningPath)
  readonly property int earnedXp: Dojo.xpForCompleted(root.completedIds, root.learningPath)
  readonly property var currentBelt: Dojo.beltFor(root.earnedXp, root.courseXp)
  readonly property var nextBelt: Dojo.nextBeltFor(root.earnedXp, root.courseXp)
  readonly property real beltFill: Dojo.beltProgress(root.earnedXp, root.courseXp)
  readonly property var beltXpRange: Dojo.beltXpRange(root.earnedXp, root.courseXp)
  property var spotlightRect: null
  property string spotlightNs: ""
  property bool spotlightWindow: false
  property bool spotlightRequery: false
  property string stepNudge: ""
  property string hintText: ""
  property var nextLessonData: null

  function nudgeFor(n) {
    return "You are already on workspace " + n
      + " — hop to any other workspace first, then come back with the keys below."
  }

  function findLesson(id) {
    var match = root.learningPath.filter(function(candidate) { return candidate.id === id })
    return match.length ? match[0] : null
  }

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) {}
    var lessonData = payload && payload.lesson ? root.findLesson(payload.lesson) : null
    if (lessonData) {
      root.startLesson(lessonData)
      return
    }
    root.openBrowser()
  }

  function openBrowser() {
    root.endLesson()
    browser.open()
  }

  function close() {
    root.endLesson()
    browser.close()
  }

  function dismiss() {
    root.endLesson()
    browser.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.yehudagurovich.sensei")
  }

  function toggle() {
    if (root.opened || root.lesson) root.dismiss()
    else root.open("{}")
  }

  function beltSummary() {
    var text = root.currentBelt.name + " · " + root.currentBelt.title + " · "
    if (root.nextBelt) {
      text += root.beltXpRange.earnedInStage + " / "
        + root.beltXpRange.requiredForStage + " XP"
    } else {
      text += root.earnedXp + " XP · Course mastered"
    }
    return text
  }

  function startLesson(lessonData) {
    browser.close()
    root.lesson = lessonData
    root.stepIndex = 0
    root.phase = "await"
    root.stepCaps = []
    root.stepBindFound = true
    root.skipUsed = false
    root.praiseText = ""
    root.praiseCaps = []
    root.spotlightRect = null
    root.spotlightNs = ""
    root.spotlightWindow = false
    root.stepNudge = ""
    root.hintText = ""
    root.nextLessonData = null
    praiseTimer.stop()
    binds.refresh()
    console.log("sensei: lesson start " + lessonData.id)
  }

  function currentStep() {
    if (!root.lesson || root.stepIndex >= root.lesson.steps.length) return null
    return root.lesson.steps[root.stepIndex]
  }

  function applyStep() {
    var step = root.currentStep()
    if (!step) return
    root.hintText = ""
    hintTimer.restart()
    if (!step.bind) {
      // The instruction itself carries the key (e.g. "press Esc").
      root.stepCaps = []
      root.stepBindFound = true
    } else {
      var r = binds.resolve(step.bind)
      root.stepCaps = r.caps
      root.stepBindFound = r.found
      if (!r.found) console.log("sensei: no binding found for \"" + step.bind + "\"")
    }
    root.querySpotlight(step)
  }

  // Spotlight anchors resolve at step time: layer surfaces by namespace
  // ("bar", and the open "menu"/"emojis"/"clipboard" layers), or the
  // focused window ("window"). A missing anchor (replaced bar, other
  // monitor, no focused window) degrades to no spotlight. The same query
  // feeds the workspace precheck (step.notOnWorkspace).
  function querySpotlight(step) {
    root.spotlightRect = null
    root.spotlightNs = ({
      bar: "omarchy-bar",
      menu: "omarchy-menu",
      emojis: "omarchy-emojis",
      clipboard: "omarchy-clipboard"
    })[step && step.spotlight] || ""
    root.spotlightWindow = !!step && step.spotlight === "window"
    root.stepNudge = ""
    var wantsPrecheck = !!step && step.notOnWorkspace !== undefined
    if (!root.spotlightNs && !root.spotlightWindow && !wantsPrecheck) return
    if (spotlightProcess.running) root.spotlightRequery = true
    else spotlightProcess.running = true
  }

  function parseJsonOr(text, fallback) {
    try { return JSON.parse(text) } catch (e) { return fallback }
  }

  function applySpotlight(output) {
    // A step change may have cleared the anchor while the query was in
    // flight; a late result must not ring a step that asked for nothing.
    var step = root.currentStep()
    if (!step || root.phase !== "await") return
    var parts = String(output || "").split("\n---\n")
    if (parts.length < 4) return
    var layers = parseJsonOr(parts[0], null)
    var monitors = parseJsonOr(parts[1], null)
    var activeWindow = parseJsonOr(parts[2], null)
    var activeWorkspace = parseJsonOr(parts[3], null)
    if (!layers || !monitors) return

    if (step.notOnWorkspace !== undefined && activeWorkspace
        && activeWorkspace.id === step.notOnWorkspace)
      root.stepNudge = root.nudgeFor(step.notOnWorkspace)

    var screenName = coach.screenName
    var monitor = null
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) { monitor = monitors[i]; break }
    }
    if (!monitor) return

    if (root.spotlightWindow) {
      if (activeWindow && activeWindow.at && activeWindow.size
          && activeWindow.monitor === monitor.id) {
        root.spotlightRect = {
          x: activeWindow.at[0] - monitor.x,
          y: activeWindow.at[1] - monitor.y,
          w: activeWindow.size[0],
          h: activeWindow.size[1]
        }
      }
      return
    }

    if (!root.spotlightNs) return
    var forScreen = layers[screenName]
    if (!forScreen || !forScreen.levels) return
    for (var level in forScreen.levels) {
      var surfaces = forScreen.levels[level]
      for (var j = 0; j < surfaces.length; j++) {
        if (surfaces[j].namespace !== root.spotlightNs) continue
        root.spotlightRect = {
          x: surfaces[j].x - monitor.x,
          y: surfaces[j].y - monitor.y,
          w: surfaces[j].w,
          h: surfaces[j].h
        }
        return
      }
    }
  }

  Process {
    id: spotlightProcess
    running: false
    command: ["bash", "-c", 'printf "%s\\n---\\n%s\\n---\\n%s\\n---\\n%s\\n" "$(hyprctl -j layers)" "$(hyprctl -j monitors)" "$(hyprctl -j activewindow)" "$(hyprctl -j activeworkspace)"']
    onExited: {
      if (root.spotlightRequery) {
        root.spotlightRequery = false
        spotlightProcess.running = true
      }
    }

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySpotlight(text)
    }
  }

  // viaButton distinguishes the manual button from a detected event. It only
  // counts as a skip when the step had a detectable event to wait for —
  // manual-only steps (await: null) advance by button by design. A skipped
  // step means the lesson is finished but not mastered: no belt credit.
  function stepComplete(viaButton) {
    if (!root.lesson || root.phase !== "await") return
    var step = root.currentStep()
    if (viaButton && step && step.await) root.skipUsed = true
    console.log("sensei: step " + (root.stepIndex + 1) + "/" + root.lesson.steps.length + " complete")
    if (root.stepIndex + 1 >= root.lesson.steps.length) {
      if (!root.skipUsed && root.completedIds.indexOf(root.lesson.id) === -1) {
        root.completedIds = root.completedIds.concat([root.lesson.id])
        progress.completed = root.completedIds
        progress.points = progress.points + Dojo.pointsFor(root.lesson)
        progress.save()
      }
      root.phase = "complete"
      root.spotlightRect = null
      root.stepNudge = ""
      root.hintText = ""
      root.nextLessonData = Lessons.nextLesson(root.lesson.id, root.completedIds)
      hintTimer.stop()
    } else {
      // Echo the keys the user actually pressed — only when the real
      // event fired, never for the skip button.
      root.praiseCaps = viaButton ? [] : root.stepCaps.slice()
      root.praiseText = "✓  " + Dojo.praise(root.stepIndex)
      praiseTimer.restart()
      coach.nod()
      root.stepIndex += 1
      root.applyStep()
    }
  }

  function endLesson() {
    root.lesson = null
    root.phase = "idle"
    root.praiseText = ""
    root.praiseCaps = []
    root.spotlightRect = null
    root.stepNudge = ""
    root.hintText = ""
    root.nextLessonData = null
    praiseTimer.stop()
    hintTimer.stop()
  }

  Progress {
    id: progress
    onLoaded: {
      root.completedIds = progress.completed
      if (root.opened) browser.refresh(false)
    }
  }

  Timer {
    id: praiseTimer
    interval: 1400
    onTriggered: {
      root.praiseText = ""
      root.praiseCaps = []
    }
  }

  // Hint escalation: a step that waits this long gets extra help — the
  // step's own hint if it has one, otherwise a generic way out.
  Timer {
    id: hintTimer
    interval: 30000
    onTriggered: {
      if (root.phase !== "await") return
      var step = root.currentStep()
      if (!step) return
      root.hintText = step.hint
        || "Stuck? Most actions also live in the Omarchy menu — or skip this step and retrain the lesson later."
    }
  }

  BindResolver {
    id: binds
    onLoaded: root.applyStep()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!root.lesson || root.phase !== "await") return
      var step = root.currentStep()
      if (!step || !step.await) return
      // A step may await alternative events: on multi-monitor setups,
      // focusing a workspace already visible on another monitor emits
      // focusedmon instead of workspace.
      var awaits = Array.isArray(step.await) ? step.await : [step.await]
      var name = String(event.name)
      var data = String(event.data === undefined || event.data === null ? "" : event.data)
      // Keep the precheck nudge live: it appears when the user lands on
      // the step's forbidden workspace and clears the moment they leave.
      // focusedmon ("MONITOR,WS") covers arriving by monitor focus.
      if (step.notOnWorkspace !== undefined
          && (name === "workspace" || name === "focusedmon")) {
        var ws = name === "workspace" ? data : data.split(",").pop()
        root.stepNudge = ws === String(step.notOnWorkspace)
          ? root.nudgeFor(step.notOnWorkspace) : ""
      }
      for (var i = 0; i < awaits.length; i++) {
        if (name !== awaits[i].event) continue
        var re
        try { re = new RegExp(awaits[i].data) } catch (e) { continue }
        if (re.test(data)) { root.stepComplete(false); return }
      }
    }
  }

  IpcHandler {
    target: "sensei"

    function start(lessonId: string): string {
      var lessonData = root.findLesson(lessonId)
      if (!lessonData) return "unknown lesson: " + lessonId
      browser.close()
      root.startLesson(lessonData)
      return "started " + lessonId
    }

    function status(): string {
      return JSON.stringify({
        opened: root.opened,
        lesson: root.lesson ? root.lesson.id : null,
        step: root.stepIndex,
        phase: root.phase,
        caps: root.stepCaps,
        bindFound: root.stepBindFound,
        skipUsed: root.skipUsed,
        spotlight: !!root.spotlightRect,
        nudge: root.stepNudge,
        hint: root.hintText,
        next: root.nextLessonData ? root.nextLessonData.id : null,
        points: progress.points,
        completed: root.completedIds
      })
    }

    function skip(): string {
      if (!root.lesson || root.phase !== "await") return "nothing to skip"
      root.stepComplete(true)
      return "skipped"
    }

    function dismiss(): string {
      if (!root.opened && !root.lesson) return "already closed"
      root.dismiss()
      return "dismissed"
    }

    function end(): string {
      root.endLesson()
      return "ended"
    }
  }

  DojoBrowser {
    id: browser
    completedIds: root.completedIds
    earnedXp: root.earnedXp
    currentBelt: root.currentBelt
    nextBelt: root.nextBelt
    beltFill: root.beltFill
    beltXpRange: root.beltXpRange
    onLessonRequested: function(lessonData) { root.startLesson(lessonData) }
    onDismissRequested: root.dismiss()
  }

  LessonCoach {
    id: coach
    lesson: root.lesson
    stepIndex: root.stepIndex
    phase: root.phase
    stepCaps: root.stepCaps
    stepBindFound: root.stepBindFound
    praiseText: root.praiseText
    praiseCaps: root.praiseCaps
    skipUsed: root.skipUsed
    currentBelt: root.currentBelt
    spotlightRect: root.spotlightRect
    stepNudge: root.stepNudge
    hintText: root.hintText
    nextLessonData: root.nextLessonData
    beltSummaryText: root.beltSummary()
    onStepRequested: function(viaButton) { root.stepComplete(viaButton) }
    onLessonRequested: function(lessonData) { root.startLesson(lessonData) }
    onDojoRequested: root.openBrowser()
    onDismissRequested: root.dismiss()
  }
}
