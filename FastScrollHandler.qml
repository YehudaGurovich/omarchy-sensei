import QtQuick
import "Scroll.js" as Scroll

WheelHandler {
  id: root

  required property Flickable flickable
  property real rowHeight: 1
  property real scrollDestination: 0
  property Timer inputIdle: Timer { interval: 160 }
  property NumberAnimation scrollMotion: NumberAnimation {
    target: root.flickable
    property: "contentY"
    duration: 120
    easing.type: Easing.OutCubic
  }
  readonly property bool inputActive: inputIdle.running

  target: null
  orientation: Qt.Vertical
  blocking: true

  function applyInput(pixelY, angleY) {
    var isTouchpad = !!(Number(pixelY) || 0)
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
    root.scrollMotion.duration = isTouchpad ? 55 : 120
    root.scrollMotion.from = root.flickable.contentY
    root.scrollMotion.to = root.scrollDestination
    root.scrollMotion.restart()
  }

  onWheel: function(event) {
    root.applyInput(event.pixelDelta.y, event.angleDelta.y)
    event.accepted = true
  }
}
