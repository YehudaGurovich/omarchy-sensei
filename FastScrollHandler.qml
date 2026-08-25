import QtQuick
import "Scroll.js" as Scroll

MouseArea {
  id: root

  required property Flickable flickable
  property real rowHeight: 1
  property real scrollDestination: 0
  readonly property int wheelDuration: 120
  property Timer inputIdle: Timer { interval: 160 }
  property NumberAnimation scrollMotion: NumberAnimation {
    target: root.flickable
    property: "contentY"
    duration: root.wheelDuration
    easing.type: Easing.OutCubic
  }
  readonly property bool inputActive: inputIdle.running

  anchors.fill: parent
  acceptedButtons: Qt.NoButton
  scrollGestureEnabled: false

  function applyInput(pixelY, angleY) {
    if (!Scroll.shouldHandleInput(pixelY)) return false
    if (!inputIdle.running) {
      root.flickable.cancelFlick()
      root.scrollMotion.stop()
      root.scrollDestination = root.flickable.contentY
    }
    inputIdle.restart()
    var delta = Scroll.contentDelta(pixelY, angleY, root.rowHeight)
    var minimum = root.flickable.originY
    var maximum = minimum + Math.max(
      0, root.flickable.contentHeight - root.flickable.height)

    if (!root.scrollMotion.running)
      root.scrollDestination = root.flickable.contentY
    root.scrollDestination = Scroll.clampContentY(
      root.scrollDestination - delta, minimum, maximum)
    root.scrollMotion.from = root.flickable.contentY
    root.scrollMotion.to = root.scrollDestination
    root.scrollMotion.restart()
    return true
  }

  onWheel: function(event) {
    event.accepted = root.applyInput(event.pixelDelta.y, event.angleDelta.y)
  }
}
