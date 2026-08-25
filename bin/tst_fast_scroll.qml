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
    fastScroll.scrollMotion.stop()
    fastScroll.inputIdle.stop()
    fastScroll.scrollDestination = 0
    list.positionViewAtBeginning()
    wait(0)
    compare(list.contentY, 0)
    verify(list.contentHeight > list.height)
    verify(fastScroll.parent !== null)
  }

  function test_three_rows_per_wheel_notch() {
    fastScroll.applyInput(0, -120)
    verify(list.contentY < 234)
    tryVerify(function() { return list.contentY > 0 }, 100)
    wait(30)
    verify(list.contentY < 234)
    verify(fastScroll.inputActive)

    fastScroll.applyInput(0, -120)
    verify(list.contentY < 468)
    tryCompare(list, "contentY", 468, 400)
    verify(fastScroll.inputActive)

    tryVerify(function() { return !fastScroll.inputActive }, 500)
  }

  function test_top_clamp() {
    fastScroll.applyInput(0, 120)
    compare(list.contentY, 0)
  }

  function test_continuous_touchpad_stays_native() {
    compare(fastScroll.applyInput(-8, 0), false)
    compare(list.contentY, 0)
    verify(!fastScroll.inputActive)
  }

}
