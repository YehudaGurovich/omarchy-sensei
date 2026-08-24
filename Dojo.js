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

// XP needed for each next belt. The ordered course needs 1, 2, 3, 4, 4, 5,
// 6, then 8 more lessons for each stage. A same-size later stage contains
// harder lessons, so every stage still needs more XP than the one before it.
var BELT_STAGE_WEIGHTS = [1, 2, 3, 5, 8, 10, 15, 24]

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

function xpForLesson(lesson) {
  return 10 * (lesson && lesson.difficulty ? lesson.difficulty : 1)
}

function totalXp(lessons) {
  if (!Array.isArray(lessons)) return 0
  return lessons.reduce(function(total, lesson) {
    return total + xpForLesson(lesson)
  }, 0)
}

function xpForCompleted(completedIds, lessons) {
  if (!Array.isArray(completedIds) || !Array.isArray(lessons)) return 0
  var mastered = {}
  for (var i = 0; i < completedIds.length; i++) mastered[completedIds[i]] = true
  return lessons.reduce(function(total, lesson) {
    return total + (mastered[lesson.id] ? xpForLesson(lesson) : 0)
  }, 0)
}

function beltXpThreshold(index, courseXp) {
  var total = Math.max(1, Number(courseXp) || 1)
  if (index <= 0) return 0
  if (index >= BELTS.length - 1) return total
  var allWeights = BELT_STAGE_WEIGHTS.reduce(function(sum, weight) { return sum + weight }, 0)
  var earnedWeights = 0
  for (var i = 0; i < index; i++) earnedWeights += BELT_STAGE_WEIGHTS[i]
  return Math.round(total * earnedWeights / allWeights)
}

function beltFor(earnedXp, courseXp) {
  var earned = Math.max(0, Number(earnedXp) || 0)
  var belt = BELTS[0]
  for (var i = 1; i < BELTS.length; i++) {
    if (earned >= beltXpThreshold(i, courseXp)) belt = BELTS[i]
  }
  return belt
}

function nextBeltFor(earnedXp, courseXp) {
  var current = beltFor(earnedXp, courseXp)
  var index = BELTS.indexOf(current)
  return index >= 0 && index + 1 < BELTS.length ? BELTS[index + 1] : null
}

function xpUntilNextBelt(earnedXp, courseXp) {
  var earned = Math.max(0, Number(earnedXp) || 0)
  var current = beltFor(earned, courseXp)
  var index = BELTS.indexOf(current)
  if (index < 0 || index + 1 >= BELTS.length) return 0
  return Math.max(0, beltXpThreshold(index + 1, courseXp) - earned)
}

function beltXpRange(earnedXp, courseXp) {
  var earned = Math.max(0, Number(earnedXp) || 0)
  var current = beltFor(earned, courseXp)
  var index = BELTS.indexOf(current)
  if (index < 0 || index + 1 >= BELTS.length) {
    return {
      earnedInStage: Math.max(0, Number(courseXp) || 0),
      requiredForStage: Math.max(0, Number(courseXp) || 0)
    }
  }
  var start = beltXpThreshold(index, courseXp)
  var end = beltXpThreshold(index + 1, courseXp)
  return {
    earnedInStage: Math.max(0, earned - start),
    requiredForStage: Math.max(1, end - start)
  }
}

function beltProgress(earnedXp, courseXp) {
  var current = beltFor(earnedXp, courseXp)
  if (BELTS.indexOf(current) === BELTS.length - 1) return 1
  var range = beltXpRange(earnedXp, courseXp)
  return Math.max(0, Math.min(1,
    range.earnedInStage / range.requiredForStage))
}

// Keep the old score field current for progress-file compatibility. Visible
// XP is recalculated from mastered lesson ids and current difficulty values.
function pointsFor(lesson) {
  return xpForLesson(lesson)
}

function praise(stepIndex) {
  return STEP_PRAISE[stepIndex % STEP_PRAISE.length]
}
