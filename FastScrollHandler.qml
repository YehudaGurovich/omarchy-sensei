import QtQuick
import "Scroll.js" as Scroll

WheelHandler {
  id: root

  required property Flickable flickable
  property real rowHeight: 1
  property Timer inputIdle: Timer { interval: 160 }
  readonly property bool inputActive: inputIdle.running

  target: null
  orientation: Qt.Vertical
  blocking: true

  function applyInput(pixelY, angleY) {
    if (!inputIdle.running) root.flickable.cancelFlick()
    inputIdle.restart()
    var delta = Scroll.contentDelta(pixelY, angleY, root.rowHeight)
    var minimum = root.flickable.originY
    var maximum = minimum + Math.max(
      0, root.flickable.contentHeight - root.flickable.height)
    root.flickable.contentY = Scroll.clampContentY(
      root.flickable.contentY - delta, minimum, maximum)
  }

  onWheel: function(event) {
    root.applyInput(event.pixelDelta.y, event.angleDelta.y)
    event.accepted = true
  }
}
