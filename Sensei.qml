import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
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
  property int selectedIndex: 0
  property var filteredLessons: []

  // Walkthrough state
  property var lesson: null
  property int stepIndex: 0
  property string phase: "idle" // idle | await | complete
  property var stepCaps: []
  property bool stepBindFound: true
  property string praiseText: ""
  property bool skipUsed: false
  property var completedIds: []
  // Window-local {x,y,w,h} of the region the current step highlights, or null.
  property var spotlightRect: null
  property string spotlightNs: ""
  property bool spotlightRequery: false

  // Shares the [menu] surface tokens so every Omarchy theme styles Sensei.
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
  property int cardWidth: Math.min(Style.space(440), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(420), panel.height - Style.gapsOut * 2)
  property int coachWidth: Style.space(330)
  property int smallFont: Math.max(10, Math.round(Style.font.body * 0.85))

  function findLesson(id) {
    var match = Lessons.all().filter(function(l) { return l.id === id })
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
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
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
    root.filteredLessons = Lessons.search(root.filterText)
    displayModel.clear()
    for (var i = 0; i < root.filteredLessons.length; i++) {
      displayModel.append({
        title: root.filteredLessons[i].title,
        index: i,
        mastered: root.completedIds.indexOf(root.filteredLessons[i].id) !== -1
      })
    }
    if (root.selectedIndex >= displayModel.count) root.selectedIndex = Math.max(0, displayModel.count - 1)
  }

  function setFilter(text) {
    root.filterText = text
    root.selectedIndex = 0
    root.rebuildDisplay()
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
    root.spotlightRect = null
    root.spotlightNs = ""
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

  // Spotlight anchors are layer surfaces resolved by namespace at step time;
  // a missing anchor (replaced bar, other monitor) degrades to no spotlight.
  function querySpotlight(step) {
    root.spotlightRect = null
    root.spotlightNs = ({ bar: "omarchy-bar" })[step && step.spotlight] || ""
    if (!root.spotlightNs) return
    if (spotlightProcess.running) root.spotlightRequery = true
    else spotlightProcess.running = true
  }

  function applySpotlight(output) {
    // A step change may have cleared the namespace while the query was in
    // flight; a late result must not ring a step that asked for nothing.
    if (!root.spotlightNs) return
    var parts = String(output || "").split("\n---\n")
    if (parts.length < 2) return
    var layers, monitors
    try {
      layers = JSON.parse(parts[0])
      monitors = JSON.parse(parts[1])
    } catch (e) { return }
    var screenName = coachWindow.screen ? String(coachWindow.screen.name) : ""
    var monitor = null
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) { monitor = monitors[i]; break }
    }
    var forScreen = layers[screenName]
    if (!monitor || !forScreen || !forScreen.levels) return
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
    command: ["bash", "-c", 'printf "%s\\n---\\n%s\\n" "$(hyprctl -j layers)" "$(hyprctl -j monitors)"']
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
        progress.save()
      }
      root.phase = "complete"
      root.spotlightRect = null
    } else {
      root.praiseText = "✓  " + Dojo.praise(root.stepIndex)
      praiseTimer.restart()
      root.stepIndex += 1
      root.applyStep()
    }
  }

  function endLesson() {
    root.lesson = null
    root.phase = "idle"
    root.praiseText = ""
    root.spotlightRect = null
    praiseTimer.stop()
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
    onTriggered: root.praiseText = ""
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
        completed: root.completedIds
      })
    }

    function skip(): string {
      if (!root.lesson || root.phase !== "await") return "nothing to skip"
      root.stepComplete(true)
      return "skipped"
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
    signal clicked()

    width: buttonText.implicitWidth + Style.spacing.md * 2
    height: Math.max(Style.space(26), root.smallFont + Style.spacing.controlPaddingY * 2)
    radius: root.cornerRadius
    color: buttonArea.containsMouse ? root.selectedBackground : "transparent"
    border.color: root.border
    border.width: 1

    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.label
      color: buttonArea.containsMouse ? root.selectedText : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.smallFont
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
      color: Dojo.beltFor(root.completedIds.length).color
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

  component KeyCap: Rectangle {
    property string label: ""

    width: capText.implicitWidth + Style.spacing.md * 2
    height: Math.max(Style.space(28), Style.font.body + Style.spacing.controlPaddingY * 2)
    radius: root.cornerRadius
    color: root.selectedBackground

    Text {
      id: capText
      anchors.centerIn: parent
      text: parent.label
      color: root.selectedText
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  // ---------------------------------------------------------------------
  // Modal browser — "the dojo"
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

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
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
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
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

        Row {
          width: parent.width
          height: root.headerHeight
          spacing: root.contentSpacing

          PenguinSensei {
            size: root.headerHeight
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            width: parent.width - root.headerHeight - root.contentSpacing
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText || "How do I…"
            color: root.foreground
            opacity: root.filterText ? 1 : 0.58
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            elide: Text.ElideRight
          }
        }

        Text {
          id: firstTimeHint
          width: parent.width
          visible: root.completedIds.length === 0
          text: "First time in the dojo? Start with the welcome tour."
          color: root.foreground
          opacity: 0.6
          font.family: root.fontFamily
          font.pixelSize: root.smallFont
          wrapMode: Text.WordWrap
        }

        ListView {
          id: lessonList
          width: parent.width
          height: parent.height - root.headerHeight - beltRow.height - root.contentSpacing * 2
            - (firstTimeHint.visible ? firstTimeHint.height + root.contentSpacing : 0)
          model: displayModel
          clip: true

          delegate: Rectangle {
            width: lessonList.width
            height: Math.max(Style.space(36), Style.font.body + Style.spacing.controlPaddingY * 2)
            radius: root.cornerRadius
            color: model.index === root.selectedIndex ? root.selectedBackground : "transparent"

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.md
              anchors.right: masteredMark.left
              anchors.verticalCenter: parent.verticalCenter
              text: model.title
              color: model.index === root.selectedIndex ? root.selectedText : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Text {
              id: masteredMark
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              text: model.mastered ? "✓" : ""
              color: model.index === root.selectedIndex ? root.selectedText : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            MouseArea {
              anchors.fill: parent
              onClicked: root.activateIndex(model.index)
            }
          }
        }

        BeltBadge {
          id: beltRow
          width: parent.width
          height: Math.max(Style.space(20), root.smallFont + Style.spacing.controlPaddingY)
          label: Dojo.beltFor(root.completedIds.length).name + " · "
            + root.completedIds.length + " of " + Lessons.all().length + " lessons mastered"
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

    // Spotlight: dim the monitor around the anchored region and ring it.
    // Drawn before the coach surface so the card stays on top; input is
    // masked to the card, so the dim panes never swallow clicks.
    Item {
      id: spotlightArea
      anchors.fill: parent
      visible: root.phase === "await" && !!root.spotlightRect

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
      }
    }

    BorderSurface {
      id: coachSurface
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.gapsOut
      anchors.rightMargin: Style.gapsOut
      width: root.coachWidth
      height: coachContent.implicitHeight + coachSurface.contentTopInset + coachSurface.contentBottomInset
      radius: root.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      Column {
        id: coachContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: coachSurface.contentTopInset
        anchors.leftMargin: coachSurface.contentLeftInset
        anchors.rightMargin: coachSurface.contentRightInset
        spacing: root.contentSpacing

        Row {
          width: parent.width
          spacing: root.contentSpacing

          PenguinSensei {
            size: Style.space(44)
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            width: parent.width - Style.space(44) - root.contentSpacing
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

        Text {
          width: parent.width
          visible: root.phase === "await" && !!root.praiseText
          text: root.praiseText
          color: root.foreground
          opacity: 0.8
          font.family: root.fontFamily
          font.pixelSize: root.smallFont
          wrapMode: Text.WordWrap
        }

        Text {
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
        }

        Flow {
          width: parent.width
          visible: root.phase === "await" && root.stepBindFound && root.stepCaps.length > 0
          spacing: Style.space(6)

          Repeater {
            model: root.stepCaps
            delegate: KeyCap { label: modelData }
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

          BeltBadge {
            label: "Rank: " + Dojo.beltFor(root.completedIds.length).name
          }
        }

        Row {
          width: parent.width
          visible: root.phase === "await"
          spacing: Style.space(4)

          Repeater {
            model: root.lesson ? root.lesson.steps.length : 0
            delegate: Rectangle {
              width: Style.space(8)
              height: Style.space(8)
              radius: Style.space(4)
              color: index < root.stepIndex ? root.selectedBackground : "transparent"
              border.color: root.border
              border.width: 1
            }
          }
        }

        Row {
          spacing: Style.spacing.md

          CoachButton {
            visible: root.phase === "await"
            label: {
              var step = root.currentStep()
              return step && !step.await ? "Next" : "Skip step"
            }
            onClicked: root.stepComplete(true)
          }

          CoachButton {
            visible: root.phase === "complete"
            label: "Return to dojo"
            onClicked: root.openBrowser()
          }

          CoachButton {
            label: root.phase === "complete" ? "Close" : "End lesson"
            onClicked: root.dismiss()
          }
        }
      }
    }
  }
}
