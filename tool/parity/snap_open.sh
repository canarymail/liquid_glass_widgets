#!/bin/bash
# Capture the settled (menu open) state at full device resolution on one simulator.
#   snap_open.sh <flutter|swift> <outName> [rowY=327]
TARGET=$1; NAME=$2; ROWY=${3:-327}
SWIFT_ID="6BC12202-1931-4614-8D15-45D4330C4F22"
FLUTTER_ID="03F92F78-8215-4980-9D92-F0F910F78573"
ID=$FLUTTER_ID; [ "$TARGET" = "swift" ] && ID=$SWIFT_ID
/tmp/lgw/sim_touch $TARGET 200 640 0.05
sleep 0.5
xcrun simctl io $ID screenshot /tmp/lgw/${NAME}_rest.png >/dev/null 2>&1
/tmp/lgw/sim_touch $TARGET 200 $ROWY 1.6
sleep 1.5
xcrun simctl io $ID screenshot /tmp/lgw/${NAME}_open.png >/dev/null 2>&1
/tmp/lgw/sim_touch $TARGET 200 700 0.08
sleep 1.0
echo "snapped $NAME"
