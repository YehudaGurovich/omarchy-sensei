import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "lessons/lessons.js" as Lessons
import "Dojo.js" as Dojo

Item {
  id: root

  property var shell: null
  property var manifest: null

  // Browser (modal) state
  property bool opened: false
  property string filterText: ""
  property int difficultyFilter: 0 // 0 = all, otherwise 1–3
  property string masteryFilter: "all" // all | open | mastered
  property int selectedIndex: 0
  property var filteredLessons: []

  // Walkthrough state
  property var lesson: null
  property int stepIndex: 0
  property string phase: "idle" // idle | await | complete
  property var stepCaps: []
  property bool stepBindFound: true
  property string praiseText: ""
  // Keycaps the user just pressed, echoed next to the praise line the
  // moment the compositor event fires — live feedback, not a replay.
  property var praiseCaps: []
  property bool skipUsed: false
  property var completedIds: []
  readonly property int lessonCount: Lessons.learningPath().length
  readonly property var currentBelt: Dojo.beltFor(root.completedIds.length, root.lessonCount)
  readonly property var nextBelt: Dojo.nextBeltFor(root.completedIds.length, root.lessonCount)
  // Window-local {x,y,w,h} of the region the current step highlights, or null.
  property var spotlightRect: null
  property string spotlightNs: ""
  property bool spotlightWindow: false
  property bool spotlightRequery: false
  // Shown when a step's precondition already holds (e.g. the user is
  // already on the target workspace, so the taught key emits no event).
  property string stepNudge: ""
  // Extra help shown when a step has waited a while (hint escalation).
  property string hintText: ""
  // Suggested lesson on the completion screen (learning-path order).
  property var nextLessonData: null

  function nudgeFor(n) {
    return "You are already on workspace " + n
      + " — hop to any other workspace first, then come back with the keys below."
  }

  // Shares the [menu] surface tokens so every Omarchy theme styles the dojo.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(760), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(600), panel.height - Style.gapsOut * 2)
  property int coachWidth: Style.space(380)
  property int smallFont: Math.max(10, Math.round(Style.font.body * 0.85))

  function findLesson(id) {
    var match = Lessons.learningPath().filter(function(l) { return l.id === id })
    return match.length ? match[0] : null
  }

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) {}
    var lessonData = payload && payload.lesson ? root.findLesson(payload.lesson) : null
    if (lessonData) { root.startLesson(lessonData); return }
    root.openBrowser()
  }

  function openBrowser() {
    root.endLesson()
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.rebuildDisplay()
    Qt.callLater(function() {
      root.centerDojo()
      keyCatcher.forceActiveFocus()
    })
  }

  function centerDojo() {
    if (!panel || !card) return
    card.x = Math.max(Style.gapsOut, (panel.width - card.width) / 2)
    card.y = Math.max(Style.gapsOut, (panel.height - card.height) / 2)
  }

  // Shell overlay contract: the shell calls close() when it hides the
  // plugin, mirroring the built-in overlays.
  function close() {
    root.endLesson()
    root.opened = false
  }

  function dismiss() {
    root.endLesson()
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.yehudagurovich.sensei")
  }

  function toggle() {
    if (root.opened || root.lesson) root.dismiss()
    else root.open("{}")
  }

  function rebuildDisplay() {
    var lessons = Lessons.search(root.filterText).filter(function(lesson) {
      if (root.difficultyFilter && lesson.difficulty !== root.difficultyFilter) return false
      var mastered = root.completedIds.indexOf(lesson.id) !== -1
      if (root.masteryFilter === "open" && mastered) return false
      if (root.masteryFilter === "mastered" && !mastered) return false
      return true
    })
    root.filteredLessons = lessons
    displayModel.clear()
    for (var i = 0; i < root.filteredLessons.length; i++) {
      displayModel.append({
        title: root.filteredLessons[i].title,
        index: i,
        difficulty: root.filteredLessons[i].difficulty || 1,
        mastered: root.completedIds.indexOf(root.filteredLessons[i].id) !== -1,
        intro: root.filteredLessons[i].intro || "",
        category: root.filteredLessons[i].category || "Lesson",
        duration: root.filteredLessons[i].duration || 3,
        steps: root.filteredLessons[i].steps.length
      })
    }
    if (root.selectedIndex >= displayModel.count) root.selectedIndex = Math.max(0, displayModel.count - 1)
  }

  function setFilter(text) {
    root.filterText = text
    root.selectedIndex = 0
    root.rebuildDisplay()
  }

  function setDifficulty(value) {
    root.difficultyFilter = value
    root.selectedIndex = 0
    root.rebuildDisplay()
  }

  function setMastery(value) {
    root.masteryFilter = value
    root.selectedIndex = 0
    root.rebuildDisplay()
  }

  function difficultyName(value) {
    return (["All levels", "Easy", "Medium", "Hard"])[value] || "All levels"
  }

  function beltSummary(includeNext) {
    var text = root.currentBelt.name + " · " + root.currentBelt.title + " · "
      + root.completedIds.length + " of " + root.lessonCount + " mastered"
    if (includeNext && root.nextBelt) {
      var remaining = Dojo.lessonsUntilNextBelt(root.completedIds.length, root.lessonCount)
      text += " · " + remaining + " to " + root.nextBelt.name
    } else if (includeNext) {
      text += " · Course mastered"
    }
    return text
  }

  function select(delta) {
    if (displayModel.count === 0) return
    root.selectedIndex = (root.selectedIndex + delta + displayModel.count) % displayModel.count
    lessonList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
  }

  function activateIndex(index) {
    if (index < 0 || index >= root.filteredLessons.length) return
    root.startLesson(root.filteredLessons[index])
  }

  function startLesson(lessonData) {
    root.opened = false
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

    var screenName = coachWindow.screen ? String(coachWindow.screen.name) : ""
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
      coachPenguin.nod()
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
      if (root.opened) root.rebuildDisplay()
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
      root.opened = false
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

  ListModel { id: displayModel }

  component CoachButton: Rectangle {
    id: button
    property string label: ""
    // The primary action renders filled; secondary actions stay outlined.
    property bool primary: false
    signal clicked()

    width: buttonText.implicitWidth + Style.spacing.md * 2
    height: Math.max(Style.space(26), root.smallFont + Style.spacing.controlPaddingY * 2)
    radius: root.cornerRadius
    color: button.primary || buttonArea.containsMouse ? root.selectedBackground : "transparent"
    opacity: button.primary && buttonArea.containsMouse ? 0.88 : 1
    border.color: button.primary ? root.selectedBackground : root.border
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.label
      color: button.primary || buttonArea.containsMouse ? root.selectedText : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.smallFont
      font.bold: button.primary
    }

    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.clicked()
    }
  }

  component BeltBadge: Row {
    property string label: ""
    spacing: Style.spacing.md

    Rectangle {
      width: Style.space(12)
      height: Style.space(12)
      radius: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      color: root.currentBelt.color
      border.color: root.border
      border.width: 1
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: parent.label
      color: root.foreground
      opacity: 0.7
      font.family: root.fontFamily
      font.pixelSize: root.smallFont
    }
  }

  component FilterChip: Rectangle {
    id: chip
    property string label: ""
    property bool selected: false
    signal clicked()

    width: chipLabel.implicitWidth + Style.spacing.md * 2
    height: Math.max(Style.space(26), root.smallFont + Style.spacing.controlPaddingY * 2)
    radius: height / 2
    color: chip.selected ? root.selectedBackground
      : chipArea.containsMouse ? Qt.alpha(root.selectedBackground, 0.16) : "transparent"
    border.color: chip.selected ? root.selectedBackground : Qt.alpha(root.border, 0.75)
    border.width: 1
    scale: chipArea.pressed ? 0.97 : 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    Text {
      id: chipLabel
      anchors.centerIn: parent
      text: chip.label
      color: chip.selected ? root.selectedText : root.foreground
      opacity: chip.selected ? 1 : 0.72
      font.family: root.fontFamily
      font.pixelSize: root.smallFont
      font.bold: chip.selected
    }

    MouseArea {
      id: chipArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.clicked()
    }
  }

  component KeyCap: Rectangle {
    id: cap
    property string label: ""
    // Compact caps are the pressed-key echo beside the praise line.
    property bool compact: false
    property int appearDelay: 0

    width: capText.implicitWidth + Style.spacing.md * (cap.compact ? 1.4 : 2)
    height: cap.compact
      ? Math.max(Style.space(20), root.smallFont + Style.spacing.controlPaddingY)
      : Math.max(Style.space(28), Style.font.body + Style.spacing.controlPaddingY * 2)
    radius: root.cornerRadius
    color: root.selectedBackground
    border.width: 1
    border.color: Qt.alpha(root.selectedText, 0.3)

    opacity: 0
    Component.onCompleted: capAppear.restart()
    SequentialAnimation {
      id: capAppear
      PauseAnimation { duration: cap.appearDelay }
      ParallelAnimation {
        NumberAnimation { target: cap; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: cap; property: "scale"; from: 0.85; to: 1; duration: 220; easing.type: Easing.OutBack }
      }
    }

    Text {
      id: capText
      anchors.centerIn: parent
      text: cap.label
      color: root.selectedText
      font.family: root.fontFamily
      font.pixelSize: cap.compact ? root.smallFont : Style.font.body
      font.bold: true
    }
  }

  // ---------------------------------------------------------------------
  // Centered course browser — the Omarchy Dojo. The user can move it for the
  // current visit; every new visit and monitor-size change recenters it.
  // ---------------------------------------------------------------------
  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "sensei"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: if (visible) {
      cardEnter.restart()
      // Layer-window geometry settles one event-loop turn after visibility.
      // Centering earlier sees a zero-sized window and pins the card at 0,0.
      Qt.callLater(root.centerDojo)
    }
    onWidthChanged: if (visible) Qt.callLater(root.centerDojo)
    onHeightChanged: if (visible) Qt.callLater(root.centerDojo)

    ParallelAnimation {
      id: cardEnter
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "scale"; from: 0.94; to: 1; duration: 280; easing.type: Easing.OutBack }
    }

    Rectangle { anchors.fill: parent; color: root.scrim }
    MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      x: Math.max(Style.gapsOut, (panel.width - width) / 2)
      y: Math.max(Style.gapsOut, (panel.height - height) / 2)
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.dismiss()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateIndex(root.selectedIndex)
            event.accepted = true
          } else if (event.text && event.text.length === 1
              && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        Item {
          id: dojoHeader
          width: parent.width
          height: Style.space(58)

          MouseArea {
            anchors.fill: parent
            drag.target: card
            drag.axis: Drag.XAndYAxis
            drag.minimumX: Style.gapsOut
            drag.maximumX: Math.max(Style.gapsOut, panel.width - card.width - Style.gapsOut)
            drag.minimumY: Style.gapsOut
            drag.maximumY: Math.max(Style.gapsOut, panel.height - card.height - Style.gapsOut)
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          }

          PenguinSensei {
            id: browserPenguin
            size: parent.height
            beltColor: root.currentBelt.color
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.left: browserPenguin.right
            anchors.leftMargin: root.contentSpacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "OMARCHY DOJO"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              font.letterSpacing: Style.space(1)
            }
            Text {
              text: "Choose a skill. Perform it on your real desktop."
              color: root.foreground
              opacity: 0.58
              font.family: root.fontFamily
              font.pixelSize: root.smallFont
            }
          }

          Row {
            anchors.right: closeButton.left
            anchors.rightMargin: root.contentSpacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Rectangle { width: Style.space(18); height: 1; color: Qt.alpha(root.border, 0.7) }
            Text {
              text: "DRAG TO MOVE"
              color: root.foreground
              opacity: 0.38
              font.family: root.fontFamily
              font.pixelSize: root.smallFont
              font.letterSpacing: Style.space(0.5)
            }
          }

          Rectangle {
            id: closeButton
            width: Style.space(30); height: width
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: width / 2
            color: closeArea.containsMouse ? Qt.alpha(root.selectedBackground, 0.2) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "×"
              color: root.foreground
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
            }
            MouseArea {
              id: closeArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.dismiss()
            }
          }
        }

        // The browser owns keyboard focus, so typing anywhere updates this
        // search field. The hint makes that interaction discoverable.
        Rectangle {
          id: searchField
          width: parent.width
          height: Style.space(44)
          radius: root.cornerRadius
          color: Qt.alpha(root.border, 0.24)
          border.color: root.filterText ? root.selectedBackground : Qt.alpha(root.border, 0.85)
          border.width: root.filterText ? 2 : 1

          Text {
            id: searchPrompt
            anchors.left: parent.left
            anchors.leftMargin: Style.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            text: "⌕"
            color: root.foreground
            opacity: 0.62
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
          }

          Text {
            id: searchValue
            anchors.left: searchPrompt.right
            anchors.leftMargin: Style.space(8)
            anchors.right: searchHint.left
            anchors.rightMargin: Style.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText || "Search lessons, tools, and workflows…"
            color: root.foreground
            opacity: root.filterText ? 1 : 0.42
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            elide: Text.ElideRight
          }

          Rectangle {
            width: 2
            height: Style.font.heading
            x: Math.min(searchValue.x + searchValue.implicitWidth + Style.space(4), searchHint.x - Style.space(8))
            anchors.verticalCenter: parent.verticalCenter
            color: root.foreground
            visible: !!root.filterText
            SequentialAnimation on opacity {
              running: parent.visible
              loops: Animation.Infinite
              PauseAnimation { duration: 500 }
              NumberAnimation { to: 0; duration: 140 }
              PauseAnimation { duration: 320 }
              NumberAnimation { to: 1; duration: 140 }
            }
          }

          Text {
            id: searchHint
            anchors.right: parent.right
            anchors.rightMargin: Style.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText ? "ESC TO CLEAR" : "JUST TYPE"
            color: root.foreground
            opacity: 0.34
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
            font.letterSpacing: Style.space(0.5)
          }

          MouseArea { anchors.fill: parent; onClicked: keyCatcher.forceActiveFocus() }
          Behavior on border.color { ColorAnimation { duration: 160 } }
        }

        Rectangle {
          id: filterPanel
          width: parent.width
          height: filterContent.implicitHeight + Style.spacing.md * 2
          radius: root.cornerRadius
          color: Qt.alpha(root.border, 0.14)
          border.color: Qt.alpha(root.border, 0.48)
          border.width: 1

          Column {
            id: filterContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            spacing: Style.space(7)

            Row {
              spacing: Style.space(6)
              Text {
                width: Style.space(56)
                anchors.verticalCenter: parent.verticalCenter
                text: "LEVEL"
                color: root.foreground
                opacity: 0.42
                font.family: root.fontFamily
                font.pixelSize: root.smallFont
                font.bold: true
              }
              Repeater {
                model: [
                  { label: "All", value: 0 }, { label: "Easy", value: 1 },
                  { label: "Medium", value: 2 }, { label: "Hard", value: 3 }
                ]
                delegate: FilterChip {
                  label: modelData.label
                  selected: root.difficultyFilter === modelData.value
                  onClicked: root.setDifficulty(modelData.value)
                }
              }
              Item { width: Style.space(18); height: 1 }
              Text {
                width: Style.space(52)
                anchors.verticalCenter: parent.verticalCenter
                text: "STATUS"
                color: root.foreground
                opacity: 0.42
                font.family: root.fontFamily
                font.pixelSize: root.smallFont
                font.bold: true
              }
              Repeater {
                model: [
                  { label: "All", value: "all" }, { label: "To learn", value: "open" },
                  { label: "Mastered", value: "mastered" }
                ]
                delegate: FilterChip {
                  label: modelData.label
                  selected: root.masteryFilter === modelData.value
                  onClicked: root.setMastery(modelData.value)
                }
              }
            }

          }
        }

        Rectangle {
          id: firstTimeHint
          width: parent.width
          visible: root.completedIds.length === 0
          radius: root.cornerRadius
          color: Qt.alpha(root.selectedBackground, 0.14)
          border.color: Qt.alpha(root.selectedBackground, 0.5)
          border.width: 1
          height: ctaContent.implicitHeight + Style.spacing.md * 2

          Row {
            id: ctaContent
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Style.spacing.md
            anchors.right: parent.right
            anchors.rightMargin: Style.spacing.md
            spacing: root.contentSpacing

            Column {
              width: parent.width - ctaButton.width - root.contentSpacing
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)
              Text {
                width: parent.width
                text: "New here? Start with the five-minute field tour."
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }
              Text {
                width: parent.width
                text: "Four verified actions teach the core Omarchy rhythm on your live desktop."
                color: root.foreground
                opacity: 0.65
                font.family: root.fontFamily
                font.pixelSize: root.smallFont
                wrapMode: Text.WordWrap
              }
            }
            CoachButton {
              id: ctaButton
              primary: true
              anchors.verticalCenter: parent.verticalCenter
              label: "Begin tour"
              onClicked: {
                var tour = root.findLesson("welcome-tour")
                if (tour) root.startLesson(tour)
              }
            }
          }
        }

        Item {
          id: resultsHeader
          width: parent.width
          height: Style.space(18)
          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: displayModel.count + (displayModel.count === 1 ? " LESSON" : " LESSONS")
            color: root.foreground
            opacity: 0.44
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
            font.bold: true
            font.letterSpacing: Style.space(0.5)
          }
          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: lessonList.contentHeight > lessonList.height
            text: "↕  SCROLL FOR MORE"
            color: root.foreground
            opacity: 0.44
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
            font.bold: true
            font.letterSpacing: Style.space(0.5)
          }
        }

        Item {
          id: listFrame
          width: parent.width
          height: parent.height - dojoHeader.height - searchField.height - filterPanel.height
            - resultsHeader.height - beltRow.height - root.contentSpacing * 5
            - (firstTimeHint.visible ? firstTimeHint.height + root.contentSpacing : 0)

          ListView {
            id: lessonList
            anchors.fill: parent
            model: displayModel
            clip: true
            spacing: Style.space(7)
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height
            ScrollBar.vertical: ScrollBar {
              policy: ScrollBar.AsNeeded
              interactive: true
              width: Style.space(7)
              contentItem: Rectangle {
                implicitWidth: Style.space(5)
                radius: width / 2
                color: root.selectedBackground
              }
              background: Rectangle {
                implicitWidth: Style.space(5)
                radius: width / 2
                color: Qt.alpha(root.border, 0.4)
              }
            }

            Text {
              anchors.centerIn: parent
              width: parent.width - Style.spacing.md * 2
              visible: displayModel.count === 0
              text: "No lessons match these filters. Clear a filter or try workspace, terminal, or menu."
              color: root.foreground
              opacity: 0.55
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
              horizontalAlignment: Text.AlignHCenter
            }

            delegate: Rectangle {
              id: lessonRow
              width: lessonList.width
              height: Style.space(78)
              radius: root.cornerRadius
              readonly property int accentGutter: Style.space(18)
              readonly property bool selected: model.index === root.selectedIndex
              readonly property color rowText: selected ? root.selectedText : root.foreground
              color: selected ? root.selectedBackground
                : lessonArea.containsMouse ? Qt.alpha(root.selectedBackground, 0.14) : Qt.alpha(root.border, 0.08)
              border.color: selected ? root.selectedBackground : Qt.alpha(root.border, 0.45)
              border.width: 1

              Rectangle {
                width: Style.space(3)
                height: parent.height - Style.space(18)
                anchors.left: parent.left
                anchors.leftMargin: (lessonRow.accentGutter - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: lessonRow.selected ? root.selectedText : root.currentBelt.color
                opacity: lessonRow.selected ? 0.9 : 0.55
              }

              Column {
                anchors.left: parent.left
                anchors.leftMargin: lessonRow.accentGutter + Style.space(4)
                anchors.right: lessonMeta.left
                anchors.rightMargin: root.contentSpacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)
                Text {
                  width: parent.width
                  text: model.category.toUpperCase() + "  ·  " + model.duration + " MIN  ·  "
                    + model.steps + (model.steps === 1 ? " STEP" : " STEPS")
                  color: lessonRow.rowText
                  opacity: 0.52
                  font.family: root.fontFamily
                  font.pixelSize: root.smallFont
                  font.bold: true
                  font.letterSpacing: Style.space(0.4)
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: model.title
                  color: lessonRow.rowText
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: model.intro
                  color: lessonRow.rowText
                  opacity: 0.65
                  font.family: root.fontFamily
                  font.pixelSize: root.smallFont
                  elide: Text.ElideRight
                }
              }

              Column {
                id: lessonMeta
                width: Style.space(106)
                anchors.right: parent.right
                anchors.rightMargin: Style.spacing.md
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(7)

                Rectangle {
                  width: parent.width
                  height: Style.space(24)
                  radius: height / 2
                  color: lessonRow.selected ? Qt.alpha(root.selectedText, 0.15)
                    : Qt.alpha(root.selectedBackground, 0.13)
                  border.color: lessonRow.selected ? Qt.alpha(root.selectedText, 0.45)
                    : Qt.alpha(root.border, 0.55)
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    text: root.difficultyName(model.difficulty)
                    color: lessonRow.rowText
                    opacity: 0.8
                    font.family: root.fontFamily
                    font.pixelSize: root.smallFont
                    font.bold: true
                  }
                }
                Text {
                  width: parent.width
                  text: model.mastered ? "✓  MASTERED" : "○  TO LEARN"
                  color: lessonRow.rowText
                  opacity: model.mastered ? 0.9 : 0.48
                  horizontalAlignment: Text.AlignHCenter
                  font.family: root.fontFamily
                  font.pixelSize: root.smallFont
                  font.bold: true
                }
              }

              MouseArea {
                id: lessonArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  if (!lessonList.moving) root.selectedIndex = model.index
                }
                onClicked: root.activateIndex(model.index)
              }

              Behavior on color { ColorAnimation { duration: 140 } }
            }
          }
        }

        Column {
          id: beltRow
          width: parent.width
          spacing: Style.space(6)
          Rectangle {
            width: parent.width
            height: Style.space(5)
            radius: height / 2
            color: Qt.alpha(root.border, 0.45)
            Rectangle {
              width: root.lessonCount
                ? parent.width * root.completedIds.length / root.lessonCount : 0
              height: parent.height
              radius: parent.radius
              color: root.currentBelt.color
              border.color: Qt.alpha(root.border, 0.5)
              border.width: width > 0 ? 1 : 0
              Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
            }
          }
          BeltBadge {
            width: parent.width
            height: Math.max(Style.space(20), root.smallFont + Style.spacing.controlPaddingY)
            label: root.beltSummary(true)
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Coach card — compact corner panel shown during a walkthrough.
  // Keyboard focus stays with the desktop so the user can actually
  // perform each step; input is masked to the card only.
  // ---------------------------------------------------------------------
  PanelWindow {
    id: coachWindow
    visible: !!root.lesson
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "sensei-coach"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: coachSurface }

    onVisibleChanged: if (visible) {
      coachEnter.restart()
      Qt.callLater(function() {
        coachSurface.x = Math.max(Style.gapsOut,
          coachWindow.width - coachSurface.width - Style.gapsOut)
        coachSurface.y = Style.gapsOut
      })
    }

    ParallelAnimation {
      id: coachEnter
      NumberAnimation { target: coachSurface; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
      NumberAnimation { target: coachSlide; property: "y"; from: -Style.space(14); to: 0; duration: 240; easing.type: Easing.OutCubic }
    }

    // Spotlight: dim the monitor around the anchored region and ring it.
    // Drawn before the coach surface so the card stays on top; input is
    // masked to the card, so the dim panes never swallow clicks.
    Item {
      id: spotlightArea
      anchors.fill: parent
      opacity: root.phase === "await" && !!root.spotlightRect ? 1 : 0
      visible: opacity > 0

      Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
      }

      readonly property real pad: Style.space(4)
      readonly property real rx: root.spotlightRect ? root.spotlightRect.x - pad : 0
      readonly property real ry: root.spotlightRect ? root.spotlightRect.y - pad : 0
      readonly property real rw: root.spotlightRect ? root.spotlightRect.w + pad * 2 : 0
      readonly property real rh: root.spotlightRect ? root.spotlightRect.h + pad * 2 : 0

      Rectangle {
        x: 0; y: 0
        width: spotlightArea.width
        height: Math.max(0, spotlightArea.ry)
        color: root.scrim
        opacity: 0.5
      }
      Rectangle {
        x: 0; y: spotlightArea.ry + spotlightArea.rh
        width: spotlightArea.width
        height: Math.max(0, spotlightArea.height - spotlightArea.ry - spotlightArea.rh)
        color: root.scrim
        opacity: 0.5
      }
      Rectangle {
        x: 0; y: spotlightArea.ry
        width: Math.max(0, spotlightArea.rx)
        height: spotlightArea.rh
        color: root.scrim
        opacity: 0.5
      }
      Rectangle {
        x: spotlightArea.rx + spotlightArea.rw; y: spotlightArea.ry
        width: Math.max(0, spotlightArea.width - spotlightArea.rx - spotlightArea.rw)
        height: spotlightArea.rh
        color: root.scrim
        opacity: 0.5
      }

      Rectangle {
        x: spotlightArea.rx; y: spotlightArea.ry
        width: spotlightArea.rw; height: spotlightArea.rh
        color: "transparent"
        radius: root.cornerRadius
        border.color: root.selectedBackground
        border.width: Math.max(2, Style.space(2))

        // The ring breathes while the step waits, pulling the eye to the
        // region without hiding anything behind it.
        SequentialAnimation on opacity {
          running: spotlightArea.visible
          loops: Animation.Infinite
          alwaysRunToEnd: true
          NumberAnimation { from: 1; to: 0.45; duration: 700; easing.type: Easing.InOutQuad }
          NumberAnimation { from: 0.45; to: 1; duration: 700; easing.type: Easing.InOutQuad }
        }
      }
    }

    BorderSurface {
      id: coachSurface
      x: Math.max(Style.gapsOut, coachWindow.width - width - Style.gapsOut)
      y: Style.gapsOut
      width: root.coachWidth
      height: coachContent.implicitHeight + coachSurface.contentTopInset + coachSurface.contentBottomInset
      radius: root.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin
      transform: Translate { id: coachSlide; y: 0 }

      Column {
        id: coachContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: coachSurface.contentTopInset
        anchors.leftMargin: coachSurface.contentLeftInset
        anchors.rightMargin: coachSurface.contentRightInset
        spacing: root.contentSpacing

        Item {
          id: coachHeader
          width: parent.width
          height: Style.space(46)

          MouseArea {
            anchors.fill: parent
            drag.target: coachSurface
            drag.axis: Drag.XAndYAxis
            drag.minimumX: Style.gapsOut
            drag.maximumX: Math.max(Style.gapsOut,
              coachWindow.width - coachSurface.width - Style.gapsOut)
            drag.minimumY: Style.gapsOut
            drag.maximumY: Math.max(Style.gapsOut,
              coachWindow.height - coachSurface.height - Style.gapsOut)
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          }

          PenguinSensei {
            id: coachPenguin
            size: Style.space(44)
            beltColor: root.currentBelt.color
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            celebrating: root.phase === "complete"
          }

          Column {
            anchors.left: coachPenguin.right
            anchors.leftMargin: root.contentSpacing
            anchors.right: coachGrip.left
            anchors.rightMargin: Style.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: root.lesson ? root.lesson.title : ""
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              visible: root.phase !== "complete"
              text: root.lesson ? "Step " + (root.stepIndex + 1) + " of " + root.lesson.steps.length : ""
              color: root.foreground
              opacity: 0.6
              font.family: root.fontFamily
              font.pixelSize: root.smallFont
            }
          }

          Text {
            id: coachGrip
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "⠿"
            color: root.foreground
            opacity: 0.35
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.alpha(root.border, 0.6)
        }

        Text {
          width: parent.width
          visible: root.phase === "await" && root.stepIndex === 0 && !!root.lesson && !!root.lesson.intro
          text: root.lesson ? root.lesson.intro : ""
          color: root.foreground
          opacity: 0.6
          font.family: root.fontFamily
          font.pixelSize: root.smallFont
          wrapMode: Text.WordWrap
        }

        Column {
          id: praiseBlock
          width: parent.width
          visible: root.phase === "await" && !!root.praiseText
          spacing: Style.space(4)
          transformOrigin: Item.TopLeft

          Connections {
            target: root
            function onPraiseTextChanged() {
              if (root.praiseText) praisePop.restart()
            }
          }

          ParallelAnimation {
            id: praisePop
            NumberAnimation { target: praiseBlock; property: "opacity"; from: 0; to: 0.9; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: praiseBlock; property: "scale"; from: 0.92; to: 1; duration: 220; easing.type: Easing.OutBack }
          }

          Row {
            visible: root.praiseCaps.length > 0
            spacing: Style.space(4)

            Repeater {
              model: root.praiseCaps
              delegate: KeyCap { label: modelData; compact: true }
            }
          }

          Text {
            width: parent.width
            text: root.praiseText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
            wrapMode: Text.WordWrap
          }
        }

        Text {
          id: sayText
          width: parent.width
          visible: root.phase === "await"
          text: {
            var step = root.currentStep()
            return step ? step.say : ""
          }
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
          onTextChanged: if (sayText.text) sayIn.restart()

          NumberAnimation {
            id: sayIn
            target: sayText
            property: "opacity"
            from: 0; to: 1
            duration: 220
            easing.type: Easing.OutCubic
          }
        }

        Rectangle {
          id: whyCard
          width: parent.width
          visible: {
            var step = root.currentStep()
            return root.phase === "await" && !!step && !!step.why
          }
          height: whyContent.implicitHeight + Style.spacing.md * 2
          radius: root.cornerRadius
          color: Qt.alpha(root.selectedBackground, 0.11)
          border.color: Qt.alpha(root.selectedBackground, 0.35)
          border.width: 1

          Column {
            id: whyContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            spacing: Style.space(3)
            Text {
              width: parent.width
              text: "WHY THIS MATTERS"
              color: root.foreground
              opacity: 0.46
              font.family: root.fontFamily
              font.pixelSize: root.smallFont
              font.bold: true
              font.letterSpacing: Style.space(0.4)
            }
            Text {
              width: parent.width
              text: {
                var step = root.currentStep()
                return step && step.why ? step.why : ""
              }
              color: root.foreground
              opacity: 0.76
              font.family: root.fontFamily
              font.pixelSize: root.smallFont
              wrapMode: Text.WordWrap
            }
          }
        }

        Text {
          width: parent.width
          visible: root.phase === "await" && !!root.stepNudge
          text: root.stepNudge
          color: root.foreground
          opacity: 0.7
          font.family: root.fontFamily
          font.pixelSize: root.smallFont
          font.italic: true
          wrapMode: Text.WordWrap
        }

        Text {
          id: hintLine
          width: parent.width
          visible: root.phase === "await" && !!root.hintText
          text: root.hintText
          color: root.foreground
          opacity: 0.7
          font.family: root.fontFamily
          font.pixelSize: root.smallFont
          font.italic: true
          wrapMode: Text.WordWrap
          onVisibleChanged: if (visible) hintIn.restart()

          NumberAnimation {
            id: hintIn
            target: hintLine
            property: "opacity"
            from: 0; to: 0.7
            duration: 300
            easing.type: Easing.OutCubic
          }
        }

        Flow {
          width: parent.width
          visible: root.phase === "await" && root.stepBindFound && root.stepCaps.length > 0
          spacing: Style.space(6)

          Repeater {
            model: root.stepCaps
            delegate: Row {
              spacing: Style.space(6)

              Text {
                visible: index > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                color: root.foreground
                opacity: 0.45
                font.family: root.fontFamily
                font.pixelSize: root.smallFont
                font.bold: true
              }

              KeyCap { label: modelData; appearDelay: index * 60 }
            }
          }
        }

        Text {
          width: parent.width
          visible: root.phase === "await" && !root.stepBindFound
          text: "You have no keybinding for this action — skip the step, or add a binding and try again."
          color: root.foreground
          opacity: 0.7
          font.family: root.fontFamily
          font.pixelSize: root.smallFont
          wrapMode: Text.WordWrap
        }

        Column {
          width: parent.width
          visible: root.phase === "complete"
          spacing: Style.space(4)

          Text {
            width: parent.width
            text: root.skipUsed
              ? "Lesson finished. Skipped steps are not mastered — run it again to earn the belt."
              : "Lesson mastered. " + Dojo.praise(root.stepIndex)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            visible: !root.skipUsed && !!root.lesson && !!root.lesson.outro
            text: root.lesson && root.lesson.outro ? root.lesson.outro : ""
            color: root.foreground
            opacity: 0.72
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
            wrapMode: Text.WordWrap
          }

          BeltBadge {
            label: root.beltSummary(false)
          }

          Text {
            width: parent.width
            visible: !!root.nextLessonData
            text: root.nextLessonData ? "Next on the path: " + root.nextLessonData.title : ""
            color: root.foreground
            opacity: 0.7
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
            wrapMode: Text.WordWrap
          }
        }

        // Segmented progress bar: done segments filled, the current one
        // breathing, the rest a faint track.
        Row {
          id: progressBar
          width: parent.width
          visible: root.phase === "await"
          spacing: Style.space(4)

          readonly property int count: root.lesson ? root.lesson.steps.length : 1

          Repeater {
            model: progressBar.count
            delegate: Rectangle {
              width: (progressBar.width - Style.space(4) * (progressBar.count - 1)) / progressBar.count
              height: Style.space(5)
              radius: Style.space(2)
              color: index <= root.stepIndex ? root.selectedBackground : Qt.alpha(root.border, 0.5)

              Behavior on color { ColorAnimation { duration: 200 } }

              // The current step's segment breathes until the step is done.
              SequentialAnimation on opacity {
                running: index === root.stepIndex && root.phase === "await"
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { from: 1; to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.35; to: 1; duration: 700; easing.type: Easing.InOutQuad }
              }
            }
          }
        }

        Row {
          spacing: Style.spacing.md

          CoachButton {
            visible: root.phase === "await"
            label: {
              var step = root.currentStep()
              return step && !step.await ? (step.nextLabel || "Next") : "Skip step"
            }
            onClicked: root.stepComplete(true)
          }

          CoachButton {
            visible: root.phase === "complete" && !!root.nextLessonData
            primary: true
            label: "Next lesson"
            onClicked: root.startLesson(root.nextLessonData)
          }

          CoachButton {
            visible: root.phase === "complete"
            label: "Return to Omarchy Dojo"
            onClicked: root.openBrowser()
          }

          CoachButton {
            label: root.phase === "complete" ? "Close" : "End lesson"
            onClicked: root.dismiss()
          }
        }
      }
    }

    // Belt-colored confetti burst over the coach card when a lesson
    // completes. Trajectories are index-derived (golden angle), so the
    // burst looks scattered without any randomness at play.
    Item {
      id: celebration
      anchors.fill: coachSurface
      visible: root.phase === "complete"

      Repeater {
        model: 16

        delegate: Rectangle {
          id: particle
          readonly property real angle: modelData * 2.399 + 0.7
          readonly property real dist: Style.space(44) + (modelData % 5) * Style.space(12)
          readonly property real cx: celebration.width / 2
          readonly property real cy: Style.space(26)

          width: Style.space(modelData % 3 === 0 ? 8 : 5)
          height: width
          radius: width / 2
          color: ["#f2c14e", "#e8833a", "#57a05b", "#4a90d9", "#d94f4f", "#8f5fd7"][modelData % 6]
          opacity: 0
          x: cx; y: cy

          SequentialAnimation {
            running: celebration.visible
            PauseAnimation { duration: (modelData % 8) * 40 }
            ParallelAnimation {
              NumberAnimation {
                target: particle; property: "x"
                from: particle.cx
                to: particle.cx + Math.cos(particle.angle) * particle.dist
                duration: 800; easing.type: Easing.OutCubic
              }
              NumberAnimation {
                target: particle; property: "y"
                from: particle.cy
                to: particle.cy + Math.sin(particle.angle) * particle.dist * 0.8 + Style.space(18)
                duration: 800; easing.type: Easing.OutCubic
              }
              NumberAnimation {
                target: particle; property: "rotation"
                from: 0; to: particle.angle * 60
                duration: 800
              }
              SequentialAnimation {
                NumberAnimation { target: particle; property: "opacity"; from: 0; to: 1; duration: 120 }
                PauseAnimation { duration: 340 }
                NumberAnimation { target: particle; property: "opacity"; to: 0; duration: 340 }
              }
            }
          }
        }
      }
    }
  }
}
