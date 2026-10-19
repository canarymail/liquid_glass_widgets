# iOS parity tooling

Maintainer-only tools for comparing the Flutter widgets against the native
iOS 27 (SwiftUI) behaviour. Nothing here ships in the pub.dev package
(`tool/` is in `.pubignore`). Findings and measurements live in
[PARITY_AUDIT.md](PARITY_AUDIT.md).

## What is here

| File | Purpose |
| :--- | :--- |
| `ios_reference/` | SwiftUI reference app (`build_and_run.sh` builds and installs it). Launch args: `-tab <n>`, `-editOff` (edit mode is on by default), `-expandAll` (expand the disclosure groups). |
| `capture_parity.sh` | Builds the reference app and screenshots its tabs. |
| `capture_flutter.sh` | Sends one command to the Flutter harness, then screenshots the simulator. |
| `snap.sh`, `snap_open.sh` | Screenshots around touch-and-hold gestures / of the settled menu-open state. |
| `sim_touch.swift` | Injects real mouse presses into a simulator window (press, hold, drag, scripted gestures). |
| `record_hold.sh`, `record_gesture.sh`, `record_menu.sh` | Record a press-and-hold, a scripted gesture, or a full context-menu cycle on one simulator as video. |
| `video_sheet.swift` | Builds a frame contact sheet from a recording. |
| `measure_rows.py`, `png_probe.py` | Measure card extents and divider positions / probe pixel colours in screenshots. |
| `INTERACTIVE_TEST_CHECKLIST.md` | Manual checks that screenshots cannot cover. |

The Flutter side is `example/lib/harnesses/ios_parity_harness.dart`.

## One-time setup

1. Boot two iPhone 18 Pro simulators side by side: Flutter on the left, the
   native reference on the right.
2. Put your simulator UUIDs into `SWIFT_ID` / `FLUTTER_ID` in
   `record_hold.sh` and `record_gesture.sh` (they are hardcoded).
3. Grant Accessibility permission to your terminal (needed to inject touches).
4. Compile the helpers:

   ```bash
   mkdir -p /tmp/lgw
   swiftc tool/parity/sim_touch.swift -o /tmp/lgw/sim_touch
   swiftc tool/parity/video_sheet.swift -o /tmp/lgw/video_sheet
   ```

5. Run the harness on the Flutter simulator:
   `flutter run -t example/lib/harnesses/ios_parity_harness.dart -d <flutter-uuid>`.
   It can be driven by writing commands (`tab 2`, `edit on`, ...) to
   `/tmp/lgw_parity_cmd.txt`.

## Gestures

Coordinates are iOS points (402x874 on iPhone 18 Pro).

```bash
# press-and-hold with no movement
tool/parity/record_gesture.sh swift hold1 1.0 1.5 m,358,368 d,358,368 w,1500 u
# scripted drag: m=move d=down g=glide(x,y,ms) w=wait(ms) u=up
tool/parity/record_gesture.sh flutter drag1 1.0 1.5 m,358,420 d,358,420 w,400 g,358,470,500 u
```

Note: a glide step is `g,x,y,ms` (commas only); a space in it crashes
`sim_touch`.

## Known caveats

- The first click on a simulator window only focuses it. The record scripts
  send a throwaway prime click for this; do the same if you call `sim_touch`
  directly.
- `sim_touch` calibrates the device screen inside the window for the current
  Device Hub layout. If the window chrome changes, adjust `point()`.
- Captures and `ios_reference/build/` are git-ignored.
