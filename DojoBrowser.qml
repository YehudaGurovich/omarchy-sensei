import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "lessons/lessons.js" as Lessons
import "Dojo.js" as Dojo

Item {
  id: root

  required property var completedIds
  required property int earnedXp
  required property var currentBelt
  required property var nextBelt
  required property real beltFill
  required property var beltXpRange

  signal lessonRequested(var lessonData)
  signal dismissRequested()

  property bool opened: false
  property string filterText: ""
  property int difficultyFilter: 0
  property string masteryFilter: "all"
  property int selectedIndex: 0
  property var filteredLessons: []

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
  property int smallFont: Math.max(10, Math.round(Style.font.body * 0.85))

  function findLesson(id) {
    var match = Lessons.learningPath().filter(function(lesson) { return lesson.id === id })
    return match.length ? match[0] : null
  }

  function open() {
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.rebuildDisplay(true)
    Qt.callLater(function() {
      root.centerDojo()
      keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.dismissRequested()
  }

  function refresh(resetView) {
    root.rebuildDisplay(resetView === true)
  }

  function centerDojo() {
    if (!panel || !card) return
    card.x = Math.max(Style.gapsOut, (panel.width - card.width) / 2)
    card.y = Math.max(Style.gapsOut, (panel.height - card.height) / 2)
  }

  function rebuildDisplay(resetView) {
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
    if (root.selectedIndex >= displayModel.count)
      root.selectedIndex = Math.max(0, displayModel.count - 1)
    Qt.callLater(function() {
      if (resetView) lessonList.positionViewAtBeginning()
      else if (displayModel.count)
        lessonList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    })
  }

  function setFilter(text) {
    root.filterText = text
    root.selectedIndex = 0
    root.rebuildDisplay(true)
  }

  function setDifficulty(value) {
    root.difficultyFilter = value
    root.selectedIndex = 0
    root.rebuildDisplay(true)
  }

  function setMastery(value) {
    root.masteryFilter = value
    root.selectedIndex = 0
    root.rebuildDisplay(true)
  }

  function difficultyName(value) {
    return (["All levels", "Easy", "Medium", "Hard"])[value] || "All levels"
  }

  function beltSummary(includeNext) {
    var text = root.currentBelt.name + " · " + root.currentBelt.title + " · "
    if (root.nextBelt) {
      text += root.beltXpRange.earnedInStage + " / "
        + root.beltXpRange.requiredForStage + " XP"
      if (includeNext) text += " · " + root.nextBelt.name + " next"
    } else {
      text += root.earnedXp + " XP · Course mastered"
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
    root.lessonRequested(lessonData)
  }

  ListModel { id: displayModel }

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

          // Square Omarchy O from the built-in Omarchy icon font.
          Text {
            anchors.right: headerGrip.left
            anchors.rightMargin: root.contentSpacing
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(30)
            height: width
            text: "\ue900"
            color: root.foreground
            opacity: 0.62
            font.family: "omarchy"
            font.pixelSize: Style.space(26)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          Row {
            id: headerGrip
            anchors.right: closeButton.left
            anchors.rightMargin: root.contentSpacing
            anchors.verticalCenter: parent.verticalCenter
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
            DojoButton {
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
          height: Math.max(0,
            parent.height - dojoHeader.height - searchField.height - filterPanel.height
              - resultsHeader.height - beltRow.height - root.contentSpacing * 5
              - (firstTimeHint.visible ? firstTimeHint.height + root.contentSpacing : 0))

          ListView {
            id: lessonList
            anchors.fill: parent
            model: displayModel
            clip: true
            spacing: Style.space(7)
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height
            reuseItems: true
            cacheBuffer: Math.max(0, height * 2)

            FastScrollHandler {
              id: fastScroll
              flickable: lessonList
              rowHeight: Style.space(78)
            }

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
              readonly property bool hovered: lessonHover.hovered
                && !fastScroll.inputActive && !lessonList.moving
              readonly property color rowText: selected ? root.selectedText : root.foreground
              color: selected ? root.selectedBackground
                : hovered ? Qt.alpha(root.selectedBackground, 0.14) : Qt.alpha(root.border, 0.08)
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

              HoverHandler {
                id: lessonHover
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                  if (hovered && !fastScroll.inputActive && !lessonList.moving)
                    root.selectedIndex = model.index
                }
              }

              TapHandler {
                onTapped: root.activateIndex(model.index)
              }

              Behavior on color {
                enabled: !fastScroll.inputActive
                ColorAnimation { duration: 140 }
              }
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
              width: parent.width * root.beltFill
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
            beltColor: root.currentBelt.color
            outlineColor: root.border
            labelColor: root.foreground
            labelFontFamily: root.fontFamily
            labelFontSize: root.smallFont
          }
        }
      }
    }
  }
}
