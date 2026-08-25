// Keep continuous touchpad gestures in ListView so Qt supplies native
// momentum. Only discrete mouse-wheel input uses the larger row step.

var WHEEL_ROWS = 3

function shouldHandleInput(pixelY) {
  return !(Number(pixelY) || 0)
}

function contentDelta(pixelY, angleY, rowHeight) {
  var pixels = Number(pixelY) || 0
  if (pixels) return 0

  var angle = Number(angleY) || 0
  var height = Math.max(1, Number(rowHeight) || 1)
  return angle / 120 * height * WHEEL_ROWS
}

function clampContentY(value, minimum, maximum) {
  var min = Number(minimum) || 0
  var max = Math.max(min, Number(maximum) || min)
  return Math.max(min, Math.min(max, Number(value) || 0))
}
