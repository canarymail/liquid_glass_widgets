#!/bin/bash
# Record a real press-and-hold on one simulator and build a frame contact sheet.
#   record_hold.sh <flutter|swift> <x> <y> <holdSec> <outName> [dx dy]
# Needs /tmp/lgw/sim_touch and /tmp/lgw/video_sheet (see the .swift sources).
set -e
TARGET=$1; X=$2; Y=$3; HOLD=$4; NAME=$5; shift 5
SWIFT_ID="6BC12202-1931-4614-8D15-45D4330C4F22"
FLUTTER_ID="03F92F78-8215-4980-9D92-F0F910F78573"
ID=$FLUTTER_ID; [ "$TARGET" = "swift" ] && ID=$SWIFT_ID
OUT=/tmp/lgw/$NAME
xcrun simctl io $ID recordVideo --codec h264 --force $OUT.mov >/dev/null 2>&1 &
REC=$!
sleep 1.5
/tmp/lgw/sim_touch $TARGET $X $Y $HOLD "$@"
sleep 2.0
kill -INT $REC; wait $REC 2>/dev/null || true
echo "recorded $OUT.mov"
