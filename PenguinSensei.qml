import QtQuick

// Original penguin sensei mascot, drawn entirely in QML shapes.
// Fixed palette so the character reads the same on every theme.
Item {
  id: root
  property int size: 64
  readonly property real s: size / 64

  width: size
  height: size

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

  // belly
  Rectangle {
    x: 19 * root.s; y: 26 * root.s
    width: 26 * root.s; height: 30 * root.s
    radius: 13 * root.s
    color: "#f4f0e6"
  }

  // eyes
  Rectangle {
    x: 21 * root.s; y: 16 * root.s
    width: 9 * root.s; height: 9 * root.s
    radius: 4.5 * root.s
    color: "#fafafa"
  }
  Rectangle {
    x: 34 * root.s; y: 16 * root.s
    width: 9 * root.s; height: 9 * root.s
    radius: 4.5 * root.s
    color: "#fafafa"
  }
  Rectangle {
    x: 24.5 * root.s; y: 19 * root.s
    width: 4 * root.s; height: 4 * root.s
    radius: 2 * root.s
    color: "#1d2024"
  }
  Rectangle {
    x: 37.5 * root.s; y: 19 * root.s
    width: 4 * root.s; height: 4 * root.s
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

  // headband
  Rectangle {
    x: 12 * root.s; y: 11 * root.s
    width: 40 * root.s; height: 6 * root.s
    radius: 3 * root.s
    color: "#c9403b"
  }
  Rectangle {
    x: 49 * root.s; y: 10 * root.s
    width: 11 * root.s; height: 4 * root.s
    radius: 2 * root.s
    rotation: -28
    color: "#c9403b"
  }
  Rectangle {
    x: 49 * root.s; y: 14 * root.s
    width: 9 * root.s; height: 4 * root.s
    radius: 2 * root.s
    rotation: 12
    color: "#c9403b"
  }
}
