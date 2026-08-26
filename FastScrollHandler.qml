import QtQuick
import "Scroll.js" as Scroll

WheelHandler {
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

  target: null
  orientation: Qt.Vertical
  acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
  blocking: true

  function applyInput(pixelY, angleY) {
    var useImmediateScroll = !!(Number(pixelY) || 0)
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

    if (useImmediateScroll) {
      root.scrollMotion.stop()
      root.scrollDestination = Scroll.clampContentY(
        root.flickable.contentY - delta, minimum, maximum)
      root.flickable.contentY = root.scrollDestination
      return true
    }

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
