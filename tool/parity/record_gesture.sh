#!/bin/bash
# Record an arbitrary scripted gesture (see sim_touch.swift) on one simulator.
#   record_gesture.sh <flutter|swift> <outName> <preSec> <postSec> <step>...
TARGET=$1; NAME=$2; PRE=$3; POST=$4; shift 4
SWIFT_ID="6BC12202-1931-4614-8D15-45D4330C4F22"
FLUTTER_ID="03F92F78-8215-4980-9D92-F0F910F78573"
ID=$FLUTTER_ID; [ "$TARGET" = "swift" ] && ID=$SWIFT_ID
OUT=/tmp/lgw/$NAME
/tmp/lgw/sim_touch $TARGET 200 790 0.05   # prime: first click only focuses the window
sleep 0.5
xcrun simctl io $ID recordVideo --codec h264 --force $OUT.mov >/dev/null 2>&1 &
REC=$!
sleep $PRE
/tmp/lgw/sim_touch $TARGET -s "$@"
sleep $POST
kill -INT $REC; wait $REC 2>/dev/null
echo "recorded $OUT.mov"
