import QtQuick
import QtTest
import ".."

TestCase {
  id: testCase
  name: "FastScrollHandler"
  width: 320
  height: 240
  when: windowShown

  ListView {
    id: list
    width: 300
    height: 156
    model: 20
    delegate: Rectangle {
      required property int index
      width: ListView.view.width
      height: 78
      color: index % 2 ? "#222222" : "#333333"
    }

    FastScrollHandler {
      id: fastScroll
      flickable: list
      rowHeight: 78
    }
  }

  function init() {
    list.positionViewAtBeginning()
    wait(0)
    compare(list.contentY, 0)
    verify(list.contentHeight > list.height)
    verify(fastScroll.parent !== null)
  }

  function test_three_rows_per_wheel_notch() {
    fastScroll.applyInput(0, -120)
    compare(list.contentY, 234)
    verify(fastScroll.inputActive)

    fastScroll.applyInput(0, -120)
    compare(list.contentY, 468)
    verify(fastScroll.inputActive)

    tryVerify(function() { return !fastScroll.inputActive }, 500)
  }

  function test_top_clamp() {
    fastScroll.applyInput(0, 120)
    compare(list.contentY, 0)
  }
}
