// Dojo flavor: belt progression, point ranks, and the sensei's voice.

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

// Ranks are earned with points: 10 x lesson difficulty per first mastery.
// Keep these thresholds stable as lessons are added so existing progress never
// loses a rank. The larger course continues beyond the first Sensei rank.
var RANKS = [
  { name: "Grasshopper", points: 0 },
  { name: "Student", points: 20 },
  { name: "Disciple", points: 50 },
  { name: "Monk", points: 80 },
  { name: "Master", points: 110 },
  { name: "Sensei", points: 180 }
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

function beltFor(completedCount) {
  var i = Math.min(completedCount, BELTS.length - 1)
  return BELTS[i]
}

function rankFor(points) {
  var rank = RANKS[0]
  for (var i = 0; i < RANKS.length; i++) {
    if (points >= RANKS[i].points) rank = RANKS[i]
  }
  return rank
}

function pointsFor(lesson) {
  return 10 * (lesson && lesson.difficulty ? lesson.difficulty : 1)
}

function praise(stepIndex) {
  return STEP_PRAISE[stepIndex % STEP_PRAISE.length]
}
