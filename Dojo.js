// Omarchy Dojo belt progression and the sensei's voice.

var BELTS = [
  { name: "White belt", title: "Fresh Install", color: "#f5f5f5" },
  { name: "Yellow belt", title: "Workspace Scout", color: "#f2c14e" },
  { name: "Orange belt", title: "Window Tiler", color: "#e8833a" },
  { name: "Green belt", title: "Menu Navigator", color: "#57a05b" },
  { name: "Blue belt", title: "Desktop Shaper", color: "#4a90d9" },
  { name: "Red belt", title: "System Keeper", color: "#d94f4f" },
  { name: "Purple belt", title: "Workflow Adept", color: "#8f5fd7" },
  { name: "Brown belt", title: "Omarchy Operator", color: "#7a5230" },
  { name: "Black belt", title: "Omarchy Sensei", color: "#1a1a1a" }
]

var STEP_PRAISE = [
  "Well done, grasshopper.",
  "The waddle becomes the way.",
  "Swift as the arctic wind.",
  "Your keys, an extension of your flippers.",
  "The ice does not ask twice.",
  "A tidy desktop, a tidy mind.",
  "Balance, little penguin. Balance.",
  "The shortcut you master today frees your tomorrow.",
  "Even the glacier moves — one keypress at a time.",
  "You begin to see the workspaces behind the workspaces."
]

// Eight even training stages lead to Black belt. Black is reserved for full
// course mastery, so a larger course cannot make the final belt arrive early.
function beltThreshold(index, totalLessons) {
  var total = Math.max(1, Number(totalLessons) || 1)
  if (index >= BELTS.length - 1) return total
  return Math.ceil(index * (total - 1) / (BELTS.length - 1))
}

function beltFor(completedCount, totalLessons) {
  var completed = Math.max(0, Number(completedCount) || 0)
  var belt = BELTS[0]
  for (var i = 1; i < BELTS.length; i++) {
    if (completed >= beltThreshold(i, totalLessons)) belt = BELTS[i]
  }
  return belt
}

function nextBeltFor(completedCount, totalLessons) {
  var current = beltFor(completedCount, totalLessons)
  var index = BELTS.indexOf(current)
  return index >= 0 && index + 1 < BELTS.length ? BELTS[index + 1] : null
}

function lessonsUntilNextBelt(completedCount, totalLessons) {
  var current = beltFor(completedCount, totalLessons)
  var index = BELTS.indexOf(current)
  if (index < 0 || index + 1 >= BELTS.length) return 0
  return Math.max(0, beltThreshold(index + 1, totalLessons) - completedCount)
}

// Keep the legacy score current for progress-file compatibility. Belt
// progression uses mastered lesson count, not points.
function pointsFor(lesson) {
  return 10 * (lesson && lesson.difficulty ? lesson.difficulty : 1)
}

function praise(stepIndex) {
  return STEP_PRAISE[stepIndex % STEP_PRAISE.length]
}
