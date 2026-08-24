import QtQuick
import qs.Ui
import "Dojo.js" as Dojo

// One-click dojo access from the bar: the penguin sensei as an icon
// button. Clicking toggles the lesson browser — the beginner-friendly
// front door, no keybinding or command needed.
BarWidget {
  id: root
  moduleName: "io.github.yehudagurovich.sensei"

  readonly property var belt: Dojo.beltFor(progress.completed.length)

  Progress { id: progress }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "Sensei — " + root.belt.name + " · "
      + progress.completed.length + " lessons mastered"
    iconComponent: Component {
      PenguinSensei {
        anchors.centerIn: parent
        size: parent ? Math.min(parent.width, parent.height) : 16
        compact: true
        beltColor: root.belt.color
      }
    }
    onPressed: function(b) {
      if (b === Qt.LeftButton)
        root.bar.run("omarchy-shell shell toggle io.github.yehudagurovich.sensei '{}'")
    }
  }
}
