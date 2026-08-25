import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "Dojo.js" as Dojo

Item {
  id: root

  required property var lesson
  required property int stepIndex
  required property string phase
  required property var stepCaps
  required property bool stepBindFound
  required property string praiseText
  required property var praiseCaps
  required property bool skipUsed
  required property var currentBelt
  required property var spotlightRect
  required property string stepNudge
  required property string hintText
  required property var nextLessonData
  required property string beltSummaryText

  signal stepRequested(bool viaButton)
  signal lessonRequested(var lessonData)
  signal dojoRequested()
  signal dismissRequested()

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
  property int contentSpacing: Style.spacing.md
  property int coachWidth: Style.space(380)
  property int smallFont: Math.max(10, Math.round(Style.font.body * 0.85))
  readonly property string screenName: coachWindow.screen ? String(coachWindow.screen.name) : ""

  function currentStep() {
    if (!root.lesson || root.stepIndex >= root.lesson.steps.length) return null
    return root.lesson.steps[root.stepIndex]
  }

  function nod() {
    coachPenguin.nod()
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
            label: root.beltSummaryText
            beltColor: root.currentBelt.color
            outlineColor: root.border
            labelColor: root.foreground
            labelFontFamily: root.fontFamily
            labelFontSize: root.smallFont
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

          DojoButton {
            visible: root.phase === "await"
            label: {
              var step = root.currentStep()
              return step && !step.await ? (step.nextLabel || "Next") : "Skip step"
            }
            onClicked: root.stepRequested(true)
          }

          DojoButton {
            visible: root.phase === "complete" && !!root.nextLessonData
            primary: true
            label: "Next lesson"
            onClicked: root.lessonRequested(root.nextLessonData)
          }

          DojoButton {
            visible: root.phase === "complete"
            label: "Return to Omarchy Dojo"
            onClicked: root.dojoRequested()
          }

          DojoButton {
            label: root.phase === "complete" ? "Close" : "End lesson"
            onClicked: root.dismissRequested()
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
