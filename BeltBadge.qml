import QtQuick
import qs.Commons

Row {
  id: root

  required property string label
  required property color beltColor
  required property color outlineColor
  required property color labelColor
  required property string labelFontFamily
  required property int labelFontSize

  spacing: Style.spacing.md

  Rectangle {
    width: Style.space(12)
    height: Style.space(12)
    radius: Style.space(6)
    anchors.verticalCenter: parent.verticalCenter
    color: root.beltColor
    border.color: root.outlineColor
    border.width: 1
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: root.labelColor
    opacity: 0.7
    font.family: root.labelFontFamily
    font.pixelSize: root.labelFontSize
  }
}
