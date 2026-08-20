// Dojo flavor: belt progression and the sensei's voice.

var BELTS = [
  { name: "White belt", color: "#f5f5f5" },
  { name: "Yellow belt", color: "#f2c14e" },
  { name: "Orange belt", color: "#e8833a" },
  { name: "Green belt", color: "#57a05b" },
  { name: "Blue belt", color: "#4a90d9" },
  { name: "Red belt", color: "#d94f4f" },
  { name: "Purple belt", color: "#8f5fd7" },
  { name: "Brown belt", color: "#7a5230" },
  { name: "Black belt", color: "#1a1a1a" }
]

var STEP_PRAISE = [
  "Well done, grasshopper.",
  "The waddle becomes the way.",
  "Swift as the arctic wind.",
  "Your keys, an extension of your flippers."
]

function beltFor(completedCount) {
  var i = Math.min(completedCount, BELTS.length - 1)
  return BELTS[i]
}

function praise(stepIndex) {
  return STEP_PRAISE[stepIndex % STEP_PRAISE.length]
}
