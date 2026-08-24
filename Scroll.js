// Fast, predictable lesson-list scrolling for both touchpads and
// discrete mouse wheels.

var TOUCHPAD_GAIN = 2
var WHEEL_ROWS = 3

function contentDelta(pixelY, angleY, rowHeight) {
  var pixels = Number(pixelY) || 0
  if (pixels) return pixels * TOUCHPAD_GAIN

  var angle = Number(angleY) || 0
  var height = Math.max(1, Number(rowHeight) || 1)
  return angle / 120 * height * WHEEL_ROWS
}

function clampContentY(value, minimum, maximum) {
  var min = Number(minimum) || 0
  var max = Math.max(min, Number(maximum) || min)
  return Math.max(min, Math.min(max, Number(value) || 0))
}
