import QtQuick

MouseArea {
    property int scrollAccumulatedY: 0
    property int scrollAccumulatedX: 0

    function onWheel(event: WheelEvent): void {
    }

    onWheel: event => {
        let triggered = false;

        // Update accumulated vertical scroll
        if (event.angleDelta.y !== 0) {
            if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY))
                scrollAccumulatedY = 0;
            scrollAccumulatedY += event.angleDelta.y;

            // Trigger handler and reset if above threshold
            if (Math.abs(scrollAccumulatedY) >= 120) {
                onWheel(event);
                scrollAccumulatedY = 0;
                scrollAccumulatedX = 0;
                triggered = true;
            }
        }

        // Update accumulated horizontal scroll
        if (!triggered && event.angleDelta.x !== 0) {
            if (Math.sign(event.angleDelta.x) !== Math.sign(scrollAccumulatedX))
                scrollAccumulatedX = 0;
            scrollAccumulatedX += event.angleDelta.x;

            if (Math.abs(scrollAccumulatedX) >= 120) {
                onWheel(event);
                scrollAccumulatedX = 0;
                scrollAccumulatedY = 0;
            }
        }
    }
}

