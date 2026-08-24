// Keep the latest readable binding so user overrides win, but do not replace
// it with an alternate keycode that the current keymap cannot name.

function unresolvedKeycode(key) {
  return /^code:[0-9]+$/.test(String(key || ""))
}

function shouldReplaceBinding(currentKey, candidateKey) {
  if (!currentKey) return true
  return !unresolvedKeycode(candidateKey) || unresolvedKeycode(currentKey)
}
