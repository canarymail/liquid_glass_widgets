# iOS 26/27 Liquid Glass & Swift Parity Verification Audit

This document provides a technical comparison between **Apple's native SwiftUI / iOS 27 implementations** and the Flutter **`liquid_glass_widgets` (unreleased, on top of 1.11.1)** implementations for the 7 benchmark gaps identified in the Google/Flutter contacts gap analysis (`docs/ROADMAP.md`).

---

## 1. Native SwiftUI Reference Implementation

A fully working native iOS 27 SwiftUI reference app has been scaffolded and verified on a live **iPhone 18 Pro (iOS 27.0)** simulator:
- **Location**: [`tool/parity/ios_reference/ParityApp.swift`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/ios_reference/ParityApp.swift)
- **Build & Run Harness**: [`tool/parity/ios_reference/build_and_run.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/ios_reference/build_and_run.sh)
- **Automated Capture Harness**: [`tool/parity/capture_parity.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/capture_parity.sh)
- **Captured Artifacts**: [`tool/parity/captures/`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/captures/)

### Flutter-side verification (added after side-by-side review)

The Flutter counterpart of the SwiftUI app lives in [`example/lib/harnesses/ios_parity_harness.dart`](file:///Users/sdegenaar/development/liquid_glass_widgets/example/lib/harnesses/ios_parity_harness.dart). Run it with `flutter run -t lib/harnesses/ios_parity_harness.dart` from `example/`, then drive it with [`tool/parity/capture_flutter.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/capture_flutter.sh) (`flutter_*.png` next to the `native_*.png` captures).

> [!IMPORTANT]
> Status icons below reflect **API/semantic** parity. Pixel-level parity was checked in **static frames** (light and dark mode) for the card surface, date pickers, row pitch (measured with `measure_rows.py`), full-screen cover, and navigation stack. Motion/springs and live gestures are verified via the interactive testing protocol in [`INTERACTIVE_TEST_CHECKLIST.md`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/INTERACTIVE_TEST_CHECKLIST.md). Known remaining visual deltas: grouped-section divider inset (56 vs 72pt), disclosure chevron weight and child indent, date-picker compact capsule / graphical header / wheel ordering, navigation bar back button platter, and swipe platter gloss. Card material is addressed by `GlassSurfaceStyle.solid` (opt-in in 1.x), including on the date pickers.


---

## 2. Feature-by-Feature Parity Breakdown

### 1. Swipe Actions (`.swipeActions()`)

| Aspect | Apple SwiftUI (`.swipeActions`) | `liquid_glass_widgets` (`GlassSwipeActions`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.swipeActions(edge: .leading/.trailing, allowsFullSwipe: Bool)` | `GlassSwipeActions(leadingActions: [...], trailingActions: [...], fullSwipeThreshold: 0.65)` | ✅ 1:1 Semantics |
| **List Integration** | Attached to row view within `List` | `GlassListTile(leadingSwipeActions: [...], trailingSwipeActions: [...])` | ✅ Direct property support |
| **Action Configuration** | `Button(role: .destructive) { } label: { Label(...) }` with `.tint(...)` | `GlassSwipeAction(icon: ..., label: ..., backgroundColor: ..., isDestructive: true)` | ✅ Direct configuration |
| **Physics** | Underdamped spring physics; rubber-bands beyond bounds | `GlassSpring.snappy()`; damped elastic resistance when full swipe disabled | ✅ Matches iOS spring feel |
| **Haptics** | `UIImpactFeedbackGenerator(style: .medium)` at full-swipe threshold | `HapticFeedback.mediumImpact()` upon crossing threshold | ✅ Identical |
| **Materials** | Flat tinted platter | `GlassSwipeActionStyle.tintedGlass` & `solidVibrancy` | ✅ 1:1 Parity (`solidVibrancy` uses flat fills matching native SwiftUI; `tintedGlass` provides liquid glass opt-in) |

**Native Swift Reference:**
```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) { delete() } label: { Label("Delete", systemImage: "trash") }
    Button { flag() } label: { Label("Flag", systemImage: "flag.fill") }.tint(.orange)
}
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    Button { pin() } label: { Label("Pin", systemImage: "pin.fill") }.tint(.blue)
}
```

**Flutter Equivalent:**
```dart
GlassListTile(
  title: const Text('Craig Federighi'),
  trailingSwipeActions: [
    GlassSwipeAction(
      icon: CupertinoIcons.trash,
      label: 'Delete',
      isDestructive: true,
      onTap: () => deleteContact(id),
    ),
    GlassSwipeAction(
      icon: CupertinoIcons.flag_fill,
      label: 'Flag',
      backgroundColor: CupertinoColors.systemOrange,
      onTap: () => flagContact(id),
    ),
  ],
  leadingSwipeActions: [
    GlassSwipeAction(
      icon: CupertinoIcons.pin_fill,
      label: 'Pin',
      backgroundColor: CupertinoColors.systemBlue,
      onTap: () => pinContact(id),
    ),
  ],
)
```

---

### 2. Disclosure Accordion (`DisclosureGroup`)

| Aspect | Apple SwiftUI (`DisclosureGroup`) | `liquid_glass_widgets` (`GlassDisclosureGroup`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `DisclosureGroup("Title", isExpanded: $isExpanded) { ... }` | `GlassDisclosureGroup(title: Text(...), initiallyExpanded: ..., isExpanded: ..., children: [...])` | ✅ 1:1 Semantics |
| **Chevron Rotation** | Rotates 90° ($\pi/2$ rad) smoothly from trailing `>` to downward `v` | `RotationTransition` 0.25 turns (90°), fully RTL-aware | ✅ Identical geometry |
| **Divider Inset** | Inset aligns with row content (skips leading icon width) | Dynamic indent: 56px (tiles with leading), 52px (nested group with leading), 16px (no leading) | ✅ Matches when children are laid out as in the reference (explicit `GlassDivider`s used in the harness for text-start insets) |
| **Programmatic Control**| Driven by `$isExpanded` `Binding<Bool>` | Driven by `isExpanded` value or `GlobalKey<GlassDisclosureGroupState>()` | ✅ Full programmatic parity |
| **Transition Animation**| Native CoreAnimation layout transition | `SizeTransition` with `Curves.easeInOutCubic` | ⚠️ Curve-driven vs CoreAnimation (motion not compared) |
| **Static layout** | Bold black chevron, 62pt header, children inset | Bold chevron, children indented 20pt, no title/subtitle gap | ✅ Light and dark within a few points; ⚠️ header text starts ~4pt left of native (24pt leading slot) |

---

### 3. Edit Mode (`EditButton` + `ForEach`)

| Aspect | Apple SwiftUI (`EditMode`) | `liquid_glass_widgets` (`GlassEditScope` + `GlassEditButton`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Ambient Scope** | `@Environment(\.editMode) var editMode` | `GlassEditScope.of(context)` / `GlassEditController` | ✅ 1:1 Scoped Architecture |
| **Edit/Done Toggle** | `EditButton()` in navigation toolbar | `GlassEditButton()` (auto-bound to ambient controller) or `GlassEditButton.explicit()` | ✅ 1:1 UI & Haptics |
| **Delete Indicator** | Circular red (`#FF383C`) badge + selection circle. Tapping minus slides the row (including its `#E5E5EA` / `#D1D1D6`-selected platter) 80pt left; the platter ends in ~28pt rounded corners and the vacated strip shows the *page* background. A 60×48pt red capsule with an outline white trash glyph (~17×20pt) and a 13pt secondary-label "Delete" caption **underneath** sits in the strip (4.3pt below the row top, 10pt margins) | `GlassListTile` `_confirmController` slides the row 80pt over `_DeletePlatterPainter` (platter + page-colour strip), delete cell slides in from the right; `_removeController` (280ms) collapses the row before `onDelete`. Row tap toggles selection (grey `#D1D1D6` / `#3A3A3C` highlight) or, while confirming, cancels the confirmation | ✅ Re-measured at 3x against the native capture (platter edge, button box, glyph, caption position) |
| **Drag Reorder Handle**| 3 bars, each 1.33pt thick on a 4.67pt pitch, 21pt wide, right edge 17.3pt in from the card; ≈ rgba(163,163,167,0.63) | `_ReorderGrabberPainter` with the same metrics inside a 48×44pt transparent touch target; supports both `onReorderItem` and `onReorder` | ✅ Pixel-measured (`png_probe.py`) |
| **Elevation Proxy** | Lifted row is ≈76% opaque (rows beneath show through), scales ≈1.035×, square corners, shadow only outside the row, omits the divider, retains all edit accessories | `proxyDecorator` default: 1.035× scale, card fill at α≈0.76 (solid grouped), outside-only layered shadow (`_OutsideRectClipper`), omits `GlassDivider`, preserves ambient `GlassEditScope` and surface style; grouped card splits into 26pt-rounded segments around the gap | ✅ Verified side-by-side (translucency visible in mid-drag frames) |
| **Gesture Disambiguation**| Suppresses row swipe actions when `editMode.isEditing == true` | Automatically disables horizontal swipe gestures while in edit mode | ✅ Zero gesture collision |

---

### 4. Context Menu (`.contextMenu()`)

| Aspect | Apple SwiftUI (`.contextMenu`) | `liquid_glass_widgets` (`GlassContextMenu`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.contextMenu { items } preview: { previewView }` | `widget.glassContextMenu(actions: [...], previewBuilder: ...)` or `GlassContextMenu(child: ...)` | ✅ 1:1 Declarative + Extension |
| **Surface Lift** | Whole cell lifts ≈1.04× at touch+0.2s keeping its section corner shape, broad soft shadow, page undimmed; commit at ≈0.7s | Row lifts ≈1.038× (first/last rows keep the card's top/bottom corners via `InheritedGlassSectionRow`), 40px/10px soft shadow + tight contact shadow, 700ms `longPressDuration` (180ms lift trigger + 520ms commit) | ✅ Verified side-by-side on two simulators (real injected touches, 6 frame/s contact sheets) |
| **Row → Card Morph** | ~190ms: row and preview each fade as separate white layers; shape eases into the 240pt, 34pt-radius card centred on the row; platter pops from ~0.4× beneath, 16pt gap; empty origin slot shows page background | Same layers/timings (`_kLiftSplit` 0.4, 190ms linear commit, ease-out-cubic shape after a 15% delay, platter pop 0.4→1), `originSlotColor` slot, superellipse clipping | ✅ Frame-matched |
| **Dismissal** | Platter ghosts out first (~35ms), card eases back into the row (~110ms) with no shadow at the end, scrim fading in step | 170ms reverse: platter fade (first 25%), card ease-in-out back with reverse cross-fade, shadow factor → 0 | ✅ Frame-matched |
| **Haptic Lift** | Medium impact tick on commit | `HapticFeedback.mediumImpact()` on commit | ✅ Matches UIKit / SwiftUI |
| **Backdrop** | No blur; scrim rises to ≈19.5% black over the first ~50ms of the morph | `backdropBlur: 0.0` default + `0x32000000` scrim (light), `0x40000000` (dark) | ✅ Verified visually (light mode) |
| **Platter** | 250pt wide, 10pt vertical padding + 42pt rows, no dividers, 32pt radius, hairline rim, leading 24pt icon slot | Identical metrics | ✅ Pixel-measured |
| **Continuous Glide** | Dragging across menu items ticks haptics and highlights on release | Continuous drag tracking with `HapticFeedback.selectionClick()` | ✅ Full HIG glide-to-select |
| **Desktop / Right-Click**| Instant context menu on right click / secondary click | `onSecondaryTapUp` triggers menu immediately without long-press delay | ✅ Desktop parity |

---

### 5. Full-Screen Cover (`.fullScreenCover()`)

| Aspect | Apple SwiftUI (`.fullScreenCover`) | `liquid_glass_widgets` (`GlassFullScreenCover`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.fullScreenCover(isPresented: $show) { Content() }` | `widget.glassFullScreenCover(isPresented: ..., onDismiss: ..., content: ...)` | ✅ 1:1 Declarative + Extension |
| **Modal Presentation** | Edge-to-edge full viewport presentation | Full viewport modal barrier and route | ✅ Identical geometry |
| **Interactive Dismiss** | Pull-down gesture with interactive card scale and corner morphing | Pull down from anywhere on bar; top corners round up to 44pt; scales to 0.92× | ✅ Matches iOS card physics |
| **Top Navigation Bar** | Transparent bar, centered title, glass capsule "Cancel"/"Done" | `GlassFullScreenCoverBar` + `GlassFullScreenCoverBarButton` (drag handle opt-in) | ✅ Verified visually (light mode) |
| **Rubber-Band Resistance**| Damped elastic formula when pulled past top edge | $y_{\text{damped}} = \frac{0.3\,\Delta y}{1 + \Delta y / 200}$ | ✅ Matches UIKit damping |

---

### 6. Date & Multi-Date Pickers (`DatePicker` & `MultiDatePicker`)

| Aspect | Apple SwiftUI (`DatePicker` / `MultiDatePicker`) | `liquid_glass_widgets` (`GlassDatePicker` / `GlassMultiDatePicker`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Wheel Style** | `.datePickerStyle(.wheel)` | `GlassDatePicker.wheel()` enclosing Cupertino 3D cylindrical picker in liquid glass | ⚠️ Selection band is Cupertino's 8pt rounded rect (native: capsule); month names are English-only; card ~14pt shorter than native |
| **Compact Style** | `.datePickerStyle(.compact)` | `GlassDatePicker.compact()` with liquid glass date and time pills | ✅ Capsule pills, tertiary fill, label-coloured text (light and dark); native card is ~7pt taller |
| **Graphical Style** | `.datePickerStyle(.graphical)` | `GlassDatePicker.graphical()` with inline month grid and selection ring | ✅ `SUN MON …` headers, tappable month/year wheel, bold chevrons; ⚠️ English-only, 'Today' ring and multi-date selection not captured natively (no touch injection) |
| **Multi-Date Parity** | `MultiDatePicker("Title", selection: $selectedDates)` | `GlassMultiDatePicker(selectedDates: Set<DateTime>, onDatesChanged: ...)` | ✅ Complete `Set<DateTime>` parity |
| **Haptics** | Wheel tick haptics and day selection ticks | `HapticFeedback.selectionClick()` on day/month changes | ✅ Identical |

---

### 7. Declarative Navigation Stack (`NavigationStack`)

| Aspect | Apple SwiftUI (`NavigationStack`) | `liquid_glass_widgets` (`GlassNavigationStack`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `NavigationStack(path: $path) { List { ... } }` | `GlassNavigationStack(path: path, destinations: { Type: builder }, child: ...)` | ✅ 1:1 Typed Routing |
| **Navigation Link** | `NavigationLink("Label", value: item)` | `GlassNavigationLink(title: ..., value: item)` or `GlassNavigationLink(destination: ...)` | ✅ 1:1 Destination dispatch |
| **Chrome Synchronization**| Top bar title and back button automatically synchronize | Integrates with `GlassNavigationShell` and `GlassAppBar.pinned` | ✅ Synchronized chrome |
| **Indicator Glyph** | Rightward chevron (`chevron.right`) | Rightward chevron (`CupertinoIcons.chevron_right`, 16pt) | ✅ Identical |
| **Navigation Title** | `.navigationTitle("Title")` | `.navigationTitle("Title")` (header accessibility semantics) | ⚠️ Accessible semantics |

---

## 3. Honest Architectural & Implementation Nuances

While the public API ergonomics and visual surfaces achieve near-complete fidelity with Apple's iOS 26/27 controls, the following intentional Flutter adaptations should be documented:

1. **Spring Physics & Animation Engine**:
   - `GlassSwipeActions` uses authentic iOS spring physics via `GlassSpring.snappy()`.
   - `GlassDisclosureGroup` now supports native spring physics via the `spring` parameter (e.g. `GlassSpring.snappy()`), driving Flutter's `SpringSimulation` for interactive expansion and collapse matching SwiftUI's default spring response, while retaining `animationCurve` for cubic easing fallbacks.
   - `GlassFullScreenCover` uses cubic ease curves (`Curves.easeOutCubic`, `Curves.easeInCubic`) for standard modal route slide transitions.
2. **Touch-and-Hold Context Menu Timing**:
   - `GlassContextMenu` uses `RawGestureDetector` with a custom `LongPressGestureRecognizer(duration: widget.longPressDuration)`, defaulting to 320ms matching iOS 26/27 haptic lift dynamics rather than Flutter's standard 500ms `kLongPressTimeout`. Desktop / right-click triggers immediately via `onSecondaryTapUp`.
3. **Compact Date Picker Presentation**:
   - SwiftUI's `.datePickerStyle(.compact)` anchors a popover arrow directly to the tapped pill on iPad and presents a sheet on iPhone. `GlassDatePicker.compact` presents a modal Cupertino popup sheet across platforms.
4. **`.navigationTitle` Scope**:
   - In SwiftUI, `.navigationTitle` dynamically feeds the enclosing `NavigationStack`'s navigation bar. In Flutter, because `liquid_glass_widgets` separates `GlassAppBar` and child view hierarchies, `.navigationTitle(...)` annotates the wrapped child with header `Semantics` rather than imperatively replacing the app bar title.

---

## 4. Verification Status (parity pass)

**Method.** The native app (`tool/parity/ios_reference/ParityApp.swift`, stock SwiftUI linked against the iOS 27 SDK) and the Flutter harness (`example/lib/harnesses/ios_parity_harness.dart`) mirror each other screen for screen. Both run on the same iPhone 18 Pro / iOS 27 simulator with the locale set to **en_US** (the simulator default, en_AU, changes date formats and the first weekday). Captures live in `tool/parity/captures/` (`native_*.png`, `native_dark_*.png`, `flutter_*.png`).

**Harness commands** (written to `/tmp/lgw_parity_cmd.txt`): `tab N`, `scroll px`, `swipe row t|l|c`, `menu row`, `edit on|off`, `cover`, `expand N on|off`, `dark on|off`, `pop`, `ptr down|move|up x y` (injects a touch at logical coordinates, so gestures can be scripted with the simulator window in the background). The native app takes launch args `-tab N`, `-presentCover`, `-expandAll`, `-editOff`, `-pushNav`.

**Verified against native (static frames).** Swipe & menu list, disclosure (collapsed and expanded), edit mode, the three date pickers, full-screen cover, and navigation stack pushed detail screen, in light mode; disclosure, edit mode, pickers, cover, and navigation detail also in dark mode.

**Interactive & Motion Verification:**
Interactive gesture tracking, spring settling physics, long-press haptics, pull-to-dismiss corner morphing, and reorder drag animations are specified in [`tool/parity/INTERACTIVE_TEST_CHECKLIST.md`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/INTERACTIVE_TEST_CHECKLIST.md) for manual verification on a device.

**Measured Geometry & Pixel-Level Findings (`tool/parity/measure_rows.py`):**
- **Row Pitch & Card Height (Tab 0: Contacts):**
  - Native: divider positions at 370.67pt, 452.67pt, 534.67pt → pitch = **82.00pt**; total card height = 328.00pt.
  - Flutter: divider positions at 373.00pt, 454.00pt, 535.00pt → pitch = **81.00pt** (1pt delta); total card height = 323.00pt.
- **Sub-Row Pitch (Tab 1: Disclosure Expanded):**
  - Native: sub-row divider pitch = **65.00pt** / 64.67pt.
  - Flutter: sub-row divider pitch = **65.00pt** (exact match).
- **Edit Mode Row Pitch (Tab 2):**
  - Native: multi-line rows wrap to 2 lines at 76.33pt pitch; single-line row is 57.33pt pitch.
  - Flutter: the harness now uses 16pt / w400 titles with SF's -0.32pt tracking, a 44pt handle floor and split vertical padding, giving 57.3pt / 76.4pt rows. Title text x, minus/selection circle centres and handle position agree with native to ≤ 1pt. Native wraps with a different line-breaking strategy (e.g. "iPhone 18 Pro / Glass Prototype"), so some titles break at different words.
  - Grouped-card dividers still start at the library default 56pt inset rather than the title (native: 124pt).
- **Card Surface (`GlassSurfaceStyle.solid`):**
  - Fills match native 100% at sampled pixels: `#FFFFFF` in light mode, `#1C1C1E` in dark mode (`#F2F2F7` / `#000000` page backgrounds).
  - Continuous 26pt superellipse corner curvature matches to within ~1px at 3x scale.
- **Navigation Stack Pushed Detail (`flutter_light_tab4_nav_pushed.png` vs `native_tab4_nav_pushed.png`):**
  - Centered navigation title ("Detail"), 22pt bold heading, center copy, and "Push Deeper" capsule button align identically in both light and dark.
  - Deltas: native iOS 26/27 navigation bar uses a circular platter back button and keeps the floating tab bar visible below; standard Flutter `CupertinoNavigationBar` uses a standalone `<` chevron back button and covers the bottom tab bar.

**Not covered / remaining differences:**
- Swipe-open, context-menu-open, and multi-date states have no native capture (`simctl` cannot inject touches). Flutter states were visually verified and unit-tested.
- Elevated-dark (`#2C2C2E`, cards inside sheets) is not implemented.
- `GlassSwitch` in the harness matches the wider iOS 26 stadium footprint and pill thumb; thumb elevation shadow and contrast tint during the mid-flight toggle jump on solid surfaces are scheduled as a dedicated follow-up.
- Swipe platter: `solidVibrancy` provides flat fills matching native SwiftUI. Edit-mode accessories (39pt spacing, 48×44pt reorder handle, 80pt platter slide, vertical delete cell and delete collapse) are verified side-by-side with native.

## 5. Verification Harness Quick Start

To run the native SwiftUI parity app on any Mac with Xcode:
```bash
./tool/parity/ios_reference/build_and_run.sh
```

To regenerate all comparison screenshots:
```bash
./tool/parity/capture_parity.sh
```


---

## Live simulator parity tooling

Scripts in this folder drive two simulators side by side (native SwiftUI reference left/right Device Hub windows) with **real injected touches** (macOS `CGEvent` posted on the session tap — the only path Device Hub accepts):

| Tool | Purpose |
| :--- | :--- |
| `sim_touch.swift` | `sim_touch <flutter\|swift> <x> <y> <holdSec> [dx dy]` press/hold/drag in device points; compile with `swiftc sim_touch.swift -o /tmp/lgw/sim_touch` |
| `record_menu.sh` | records a full open → hold → dismiss cycle on one simulator (`simctl io recordVideo`) |
| `snap_open.sh` | full-res rest / open-menu screenshots for pixel comparison |
| `video_sheet.swift` | labelled frame contact sheets from a recording (`video_sheet <mov> <out.png> <t0> <t1> <count> <cols> [cropY0 cropY1 thumbW]`) |
