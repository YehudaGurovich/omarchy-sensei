import QtQuick

// Original Linux penguin sensei mascot, drawn entirely in QML shapes.
// Fixed palette so the character reads the same on every theme.
// The penguin blinks on its own; nod() bows once (step praise) and
// celebrating loops a little hop (lesson complete).
Item {
  id: root
  property int size: 64
  property bool celebrating: false
  // Earned belt color. It drives both the headband and the waist sash so
  // the mascot remains readable at compact bar-widget sizes.
  property color beltColor: "#f5f5f5"
  // Compact drops the headband knot tails — at bar-icon sizes they read
  // as a stray red streak rather than a knot.
  property bool compact: false
  readonly property real s: size / 64

  // 1 = eyes open; animated toward 0.15 for a blink.
  property real eyeScale: 1

  function nod() { nodAnim.restart() }

  width: size
  height: size

  transform: [
    Translate { id: hop; y: 0 },
    Rotation {
      id: tilt
      origin.x: root.width / 2
      origin.y: root.height * 0.75
      angle: 0
    }
  ]

  SequentialAnimation {
    running: root.visible
    loops: Animation.Infinite
    PauseAnimation { duration: 2600 }
    NumberAnimation { target: root; property: "eyeScale"; to: 0.15; duration: 70 }
    NumberAnimation { target: root; property: "eyeScale"; to: 1; duration: 110 }
    PauseAnimation { duration: 4300 }
    NumberAnimation { target: root; property: "eyeScale"; to: 0.15; duration: 70 }
    NumberAnimation { target: root; property: "eyeScale"; to: 1; duration: 110 }
  }

  // Wide orange feet make the mascot look more like the Linux penguin.
  Rectangle {
    x: 7 * root.s; y: 53 * root.s
    width: 21 * root.s; height: 9 * root.s
    radius: 4.5 * root.s
    rotation: -7
    color: "#f2a33c"
    border.color: "#55000000"
    border.width: Math.max(1, root.s)
  }
  Rectangle {
    x: 36 * root.s; y: 53 * root.s
    width: 21 * root.s; height: 9 * root.s
    radius: 4.5 * root.s
    rotation: 7
    color: "#f2a33c"
    border.color: "#55000000"
    border.width: Math.max(1, root.s)
  }

  SequentialAnimation {
    id: nodAnim
    NumberAnimation { target: tilt; property: "angle"; to: 9; duration: 130; easing.type: Easing.OutCubic }
    NumberAnimation { target: tilt; property: "angle"; to: 0; duration: 180; easing.type: Easing.OutBack }
  }

  SequentialAnimation {
    running: root.celebrating && root.visible
    loops: Animation.Infinite
    alwaysRunToEnd: true
    ParallelAnimation {
      NumberAnimation { target: hop; property: "y"; to: -3 * root.s; duration: 260; easing.type: Easing.OutQuad }
      NumberAnimation { target: tilt; property: "angle"; to: -5; duration: 260 }
    }
    ParallelAnimation {
      NumberAnimation { target: hop; property: "y"; to: 0; duration: 260; easing.type: Easing.InQuad }
      NumberAnimation { target: tilt; property: "angle"; to: 5; duration: 260 }
    }
    NumberAnimation { target: tilt; property: "angle"; to: 0; duration: 180 }
  }

  // flippers
  Rectangle {
    x: 5 * root.s; y: 27 * root.s
    width: 9 * root.s; height: 20 * root.s
    radius: 4.5 * root.s
    rotation: -18
    color: "#1d2024"
  }
  Rectangle {
    x: 50 * root.s; y: 27 * root.s
    width: 9 * root.s; height: 20 * root.s
    radius: 4.5 * root.s
    rotation: 18
    color: "#1d2024"
  }

  // body
  Rectangle {
    x: 10 * root.s; y: 6 * root.s
    width: 44 * root.s; height: 54 * root.s
    radius: 22 * root.s
    color: "#1d2024"
    border.color: "#00000040"
    border.width: Math.max(1, 1 * root.s)
  }

  // Pear-shaped cream front: a small chest over the broad Linux penguin belly.
  Rectangle {
    x: 16 * root.s; y: 34 * root.s
    width: 32 * root.s; height: 24 * root.s
    radius: 16 * root.s
    color: "#f4f0e6"
  }
  Rectangle {
    x: 20 * root.s; y: 26 * root.s
    width: 24 * root.s; height: 22 * root.s
    radius: 12 * root.s
    color: "#f4f0e6"
  }

  // eyes — height follows eyeScale around a fixed center, so blinks squash
  Rectangle {
    x: 20 * root.s; y: (15 + 5.5 * (1 - root.eyeScale)) * root.s
    width: 11 * root.s; height: 11 * root.s * root.eyeScale
    radius: 5.5 * root.s
    color: "#fafafa"
  }
  Rectangle {
    x: 33 * root.s; y: (15 + 5.5 * (1 - root.eyeScale)) * root.s
    width: 11 * root.s; height: 11 * root.s * root.eyeScale
    radius: 5.5 * root.s
    color: "#fafafa"
  }
  Rectangle {
    x: 25 * root.s; y: (19 + 2 * (1 - root.eyeScale)) * root.s
    width: 4 * root.s; height: 4 * root.s * root.eyeScale
    radius: 2 * root.s
    color: "#1d2024"
  }
  Rectangle {
    x: 38 * root.s; y: (19 + 2 * (1 - root.eyeScale)) * root.s
    width: 4 * root.s; height: 4 * root.s * root.eyeScale
    radius: 2 * root.s
    color: "#1d2024"
  }

  // white sensei beard, under the beak
  Rectangle {
    x: 24 * root.s; y: 29 * root.s
    width: 16 * root.s; height: 13 * root.s
    radius: 7 * root.s
    color: "#fafafa"
  }

  // beak
  Rectangle {
    x: 28 * root.s; y: 24 * root.s
    width: 8 * root.s; height: 8 * root.s
    radius: 2 * root.s
    rotation: 45
    color: "#f2a33c"
  }
  Rectangle {
    x: 29.5 * root.s; y: 29 * root.s
    width: 7 * root.s; height: 4 * root.s
    radius: 2 * root.s
    color: "#d9822b"
  }

  // headband
  Rectangle {
    x: 12 * root.s; y: 11 * root.s
    width: 40 * root.s; height: 6 * root.s
    radius: 3 * root.s
    color: root.beltColor
    border.color: "#80ffffff"
    border.width: Math.max(1, root.s)
  }
  Rectangle {
    visible: !root.compact
    x: 49 * root.s; y: 10 * root.s
    width: 11 * root.s; height: 4 * root.s
    radius: 2 * root.s
    rotation: -28
    color: root.beltColor
  }
  Rectangle {
    visible: !root.compact
    x: 49 * root.s; y: 14 * root.s
    width: 9 * root.s; height: 4 * root.s
    radius: 2 * root.s
    rotation: 12
    color: root.beltColor
  }

  // Belt sash. The outline keeps white and black belts visible against the
  // fixed penguin palette, and makes progression clear in the bar symbol.
  Rectangle {
    x: 17 * root.s; y: 43 * root.s
    width: 30 * root.s; height: 5 * root.s
    radius: 1.5 * root.s
    color: root.beltColor
    border.color: "#66000000"
    border.width: Math.max(1, root.s)
  }
  Rectangle {
    x: 29.5 * root.s; y: 42 * root.s
    width: 6 * root.s; height: 7 * root.s
    radius: 1.5 * root.s
    color: root.beltColor
    border.color: "#66000000"
    border.width: Math.max(1, root.s)
  }
}
