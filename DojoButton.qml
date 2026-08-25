import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property bool primary: false
  signal clicked()

  readonly property int smallFont: Math.max(10, Math.round(Style.font.body * 0.85))
  readonly property color foreground: Color.menu.text
  readonly property color borderColor: Color.menu.border
  readonly property color selectedBackground: Color.menu.selectedBackground
  readonly property color selectedText: Color.menu.selectedText

  width: buttonText.implicitWidth + Style.spacing.md * 2
  height: Math.max(Style.space(26), root.smallFont + Style.spacing.controlPaddingY * 2)
  radius: Style.cornerRadius
  color: root.primary || buttonArea.containsMouse ? root.selectedBackground : "transparent"
  opacity: root.primary && buttonArea.containsMouse ? 0.88 : 1
  border.color: root.primary ? root.selectedBackground : root.borderColor
  border.width: 1

  Behavior on color { ColorAnimation { duration: 120 } }

  Text {
    id: buttonText
    anchors.centerIn: parent
    text: root.label
    color: root.primary || buttonArea.containsMouse ? root.selectedText : root.foreground
    font.family: Style.font.menuFamily
    font.pixelSize: root.smallFont
    font.bold: root.primary
  }

  MouseArea {
    id: buttonArea
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }
}
