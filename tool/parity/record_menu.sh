#!/bin/bash
# Record a full context-menu cycle (press-and-hold -> menu -> tap outside to
# dismiss) on one simulator, using real injected touches.
#   record_menu.sh <flutter|swift> <outName> [rowY=327] [holdSec=1.6]
# Needs /tmp/lgw/sim_touch (build from sim_touch.swift).
TARGET=$1; NAME=$2; ROWY=${3:-327}; HOLD=${4:-1.6}
SWIFT_ID="6BC12202-1931-4614-8D15-45D4330C4F22"
FLUTTER_ID="03F92F78-8215-4980-9D92-F0F910F78573"
ID=$FLUTTER_ID; [ "$TARGET" = "swift" ] && ID=$SWIFT_ID
OUT=/tmp/lgw/$NAME
/tmp/lgw/sim_touch $TARGET 200 640 0.05   # prime: first click only focuses the window
sleep 0.5
xcrun simctl io $ID recordVideo --codec h264 --force $OUT.mov >/dev/null 2>&1 &
REC=$!
sleep 1.5
/tmp/lgw/sim_touch $TARGET 200 $ROWY $HOLD
sleep 1.0
/tmp/lgw/sim_touch $TARGET 200 700 0.08
sleep 2.0
kill -INT $REC; wait $REC 2>/dev/null
echo "recorded $OUT.mov"
