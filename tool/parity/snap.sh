#!/bin/bash
# Snapshot tool for simulator touch-and-hold gestures
DELAY=${1:-2}
TARGET=${2:-"all"}

SWIFT_ID="6BC12202-1931-4614-8D15-45D4330C4F22"
FLUTTER_ID="03F92F78-8215-4980-9D92-F0F910F78573"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "⏳ Get ready! Press and hold your gesture on the simulator..."
for (( i=$DELAY; i>0; i-- )); do
    echo "   📸 Snapping in $i..."
    sleep 1
done

echo "📸 SNAP!"

if [ "$TARGET" = "swift" ] || [ "$TARGET" = "all" ]; then
    xcrun simctl io $SWIFT_ID screenshot ~/Desktop/swift_snap_${TIMESTAMP}.png 2>/dev/null
    echo " Saved Swift screenshot to: ~/Desktop/swift_snap_${TIMESTAMP}.png"
fi

if [ "$TARGET" = "flutter" ] || [ "$TARGET" = "all" ]; then
    xcrun simctl io $FLUTTER_ID screenshot ~/Desktop/flutter_snap_${TIMESTAMP}.png 2>/dev/null
    echo " Saved Flutter screenshot to: ~/Desktop/flutter_snap_${TIMESTAMP}.png"
fi
