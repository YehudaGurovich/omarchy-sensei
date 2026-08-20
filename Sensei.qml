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
  property string phase: "idle" // idle | await | flash | complete
  property var stepCaps: []
  property bool stepBindFound: true
  property var completedIds: [] // in-memory for now; persistence lands with Day 2

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

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) {}
    if (payload && payload.lesson) {
      var match = Lessons.all().filter(function(l) { return l.id === payload.lesson })
      if (match.length) { root.startLesson(match[0]); return }
    }
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
    var r = binds.resolve(step.bind)
    root.stepCaps = r.caps
    root.stepBindFound = r.found
    if (!r.found) console.log("sensei: no binding found for \"" + step.bind + "\"")
  }

  function stepComplete() {
    if (!root.lesson || root.phase !== "await") return
    console.log("sensei: step " + (root.stepIndex + 1) + "/" + root.lesson.steps.length + " complete")
    if (root.stepIndex + 1 >= root.lesson.steps.length) {
      if (root.completedIds.indexOf(root.lesson.id) === -1)
        root.completedIds = root.completedIds.concat([root.lesson.id])
      root.phase = "complete"
    } else {
      root.phase = "flash"
      flashTimer.restart()
    }
  }

  function advanceStep() {
    root.stepIndex += 1
    root.phase = "await"
    root.applyStep()
  }

  function endLesson() {
    root.lesson = null
    root.phase = "idle"
  }

  function backToDojo() {
    root.openBrowser()
  }

  Timer {
    id: flashTimer
    interval: 900
    onTriggered: root.advanceStep()
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
        if (re.test(data)) { root.stepComplete(); return }
      }
    }
  }

  IpcHandler {
    target: "sensei"

    function start(lessonId: string): string {
      var match = Lessons.all().filter(function(l) { return l.id === lessonId })
      if (!match.length) return "unknown lesson: " + lessonId
      root.opened = false
      root.startLesson(match[0])
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
        completed: root.completedIds
      })
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
          } else if (event.key === Qt.Key_Backspace) {
            root.setFilter(root.filterText.slice(0, -1))
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

        ListView {
          id: lessonList
          width: parent.width
          height: parent.height - root.headerHeight - beltRow.height - root.contentSpacing * 2
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

        Row {
          id: beltRow
          width: parent.width
          height: Math.max(Style.space(20), root.smallFont + Style.spacing.controlPaddingY)
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
            text: Dojo.beltFor(root.completedIds.length).name + " · "
              + root.completedIds.length + " of " + Lessons.all().length + " lessons mastered"
            color: root.foreground
            opacity: 0.65
            font.family: root.fontFamily
            font.pixelSize: root.smallFont
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

        Text {
          width: parent.width
          visible: root.phase === "flash"
          text: "✓  " + Dojo.praise(root.stepIndex)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Column {
          width: parent.width
          visible: root.phase === "complete"
          spacing: Style.space(4)

          Text {
            width: parent.width
            text: "Lesson mastered. " + Dojo.praise(root.stepIndex)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Row {
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
              text: "Rank: " + Dojo.beltFor(root.completedIds.length).name
              color: root.foreground
              opacity: 0.75
              font.family: root.fontFamily
              font.pixelSize: root.smallFont
            }
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
            label: "Skip step"
            onClicked: root.stepComplete()
          }

          CoachButton {
            visible: root.phase === "complete"
            label: "Return to dojo"
            onClicked: root.backToDojo()
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
