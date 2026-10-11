# iOS 26/27 Liquid Glass & Swift Parity Verification Audit

This document provides a technical comparison between **Apple's native SwiftUI / iOS 27 implementations** and the Flutter **`liquid_glass_widgets` (1.12.0)** implementations for the 7 benchmark gaps identified in the Google/Flutter contacts gap analysis (`docs/ROADMAP.md`).

---

## 1. Native SwiftUI Reference Implementation

A fully working native iOS 27 SwiftUI reference app has been scaffolded and verified on a live **iPhone 18 Pro (iOS 27.0)** simulator:
- **Location**: [`tool/parity/ios_reference/ParityApp.swift`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/ios_reference/ParityApp.swift)
- **Build & Run Harness**: [`tool/parity/ios_reference/build_and_run.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/ios_reference/build_and_run.sh)
- **Automated Capture Harness**: [`tool/parity/capture_parity.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/capture_parity.sh)
- **Captured Artifacts**: [`tool/parity/captures/`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/captures/)

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
| **Materials** | Frosted vibrancy / liquid glass tint on button platters | `GlassSwipeActionStyle.tintedGlass` (with specular sheen) & `solidVibrancy` | ✅ Native material fidelity |

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
| **Divider Inset** | Inset aligns with row content (skips leading icon width) | Dynamic indent: 56px (tiles with leading), 52px (nested group with leading), 16px (no leading) | ✅ Identical alignment |
| **Programmatic Control**| Driven by `$isExpanded` `Binding<Bool>` | Driven by `isExpanded` value or `GlobalKey<GlassDisclosureGroupState>()` | ✅ Full programmatic parity |
| **Transition Animation**| Native CoreAnimation layout transition | `SizeTransition` with `Curves.easeInOutCubic` | ⚠️ Curve-driven vs CoreAnimation |

---

### 3. Edit Mode (`EditButton` + `ForEach`)

| Aspect | Apple SwiftUI (`EditMode`) | `liquid_glass_widgets` (`GlassEditScope` + `GlassEditButton`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Ambient Scope** | `@Environment(\.editMode) var editMode` | `GlassEditScope.of(context)` / `GlassEditController` | ✅ 1:1 Scoped Architecture |
| **Edit/Done Toggle** | `EditButton()` in navigation toolbar | `GlassEditButton()` (auto-bound to ambient controller) or `GlassEditButton.explicit()` | ✅ 1:1 UI & Haptics |
| **Delete Indicator** | Circular red badge with centered white minus (`-`) | Circular red badge (`CupertinoIcons.minus_circle_fill`), rotates into inline "Delete" pill | ✅ Matches Contacts app |
| **Drag Reorder Handle**| 3-bar horizontal gripper (`CupertinoIcons.bars`) | 3-bar horizontal gripper, supports both `onReorderItem` and `onReorder` | ✅ Matches HIG layout |
| **Elevation Proxy** | 1.025x scale with elevated soft specular drop shadow | 1.025x scale proxy with elevated liquid glass soft shadow | ✅ Identical visual lift |
| **Gesture Disambiguation**| Suppresses row swipe actions when `editMode.isEditing == true` | Automatically disables horizontal swipe gestures while in edit mode | ✅ Zero gesture collision |

---

### 4. Context Menu (`.contextMenu()`)

| Aspect | Apple SwiftUI (`.contextMenu`) | `liquid_glass_widgets` (`GlassContextMenu`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.contextMenu { items } preview: { previewView }` | `widget.glassContextMenu(actions: [...], previewBuilder: ...)` or `GlassContextMenu(child: ...)` | ✅ 1:1 Declarative + Extension |
| **Touch Compression** | Target compresses to ~0.96× scale on initial touch-down | Compresses to 0.96× scale via immediate gesture response | ✅ Matches iOS compression |
| **Haptic Lift** | Medium impact tick as item lifts to 1.02× with elevated shadow | `HapticFeedback.mediumImpact()` + 1.02× lift + 28px blur shadow | ✅ Matches UIKit / SwiftUI |
| **Backdrop Blur** | Background progressively defocuses behind modal platter | Progressive Gaussian backdrop blur (`backdropBlur: 20.0`) + dimming barrier | ✅ Liquid glass material |
| **Continuous Glide** | Dragging across menu items ticks haptics and highlights on release | Continuous drag tracking with `HapticFeedback.selectionClick()` | ✅ Full HIG glide-to-select |
| **Desktop / Right-Click**| Instant context menu on right click / secondary click | `onSecondaryTapUp` triggers menu immediately without long-press delay | ✅ Desktop parity |

---

### 5. Full-Screen Cover (`.fullScreenCover()`)

| Aspect | Apple SwiftUI (`.fullScreenCover`) | `liquid_glass_widgets` (`GlassFullScreenCover`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.fullScreenCover(isPresented: $show) { Content() }` | `widget.glassFullScreenCover(isPresented: ..., onDismiss: ..., content: ...)` | ✅ 1:1 Declarative + Extension |
| **Modal Presentation** | Edge-to-edge full viewport presentation | Full viewport modal barrier and route | ✅ Identical geometry |
| **Interactive Dismiss** | Pull-down gesture with interactive card scale and corner morphing | Pull down from anywhere on bar; top corners round up to 44pt; scales to 0.92× | ✅ Matches iOS card physics |
| **Top Navigation Bar** | Centered title, circular frosted close button / Done label | `GlassFullScreenCoverBar` with `CupertinoIcons.xmark`, "Done"/"Cancel", drag handle | ✅ Complete HIG bar |
| **Rubber-Band Resistance**| Damped elastic formula when pulled past top edge | $y_{\text{damped}} = \frac{0.3\,\Delta y}{1 + \Delta y / 200}$ | ✅ Matches UIKit damping |

---

### 6. Date & Multi-Date Pickers (`DatePicker` & `MultiDatePicker`)

| Aspect | Apple SwiftUI (`DatePicker` / `MultiDatePicker`) | `liquid_glass_widgets` (`GlassDatePicker` / `GlassMultiDatePicker`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Wheel Style** | `.datePickerStyle(.wheel)` | `GlassDatePicker.wheel()` enclosing Cupertino 3D cylindrical picker in liquid glass | ✅ Complete parity |
| **Compact Style** | `.datePickerStyle(.compact)` | `GlassDatePicker.compact()` with liquid glass date and time pills | ✅ Complete parity |
| **Graphical Style** | `.datePickerStyle(.graphical)` | `GlassDatePicker.graphical()` with inline month grid and selection ring | ✅ Complete parity |
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

1. **Spring vs. Curve Animation Engine**:
   - Flutter's `SizeTransition` in `GlassDisclosureGroup` and `SlideTransition` in `GlassFullScreenCover` use cubic ease curves (`Curves.easeInOutCubic`, `Curves.easeOutCubic`) rather than interactive CASpringAnimation / `SpringDescription`.
   - `GlassSwipeActions` *does* use true spring physics via `GlassSpring.snappy()`.
2. **Long-Press Delay**:
   - iOS UIKit / SwiftUI uses private velocity and pressure-assisted timers for context menus. Flutter uses the engine's `kLongPressTimeout` (~500ms) unless triggered on desktop via right click (`onSecondaryTapUp`).
3. **Compact Date Picker Presentation**:
   - SwiftUI's `.datePickerStyle(.compact)` anchors a popover arrow directly to the tapped pill on iPad and presents a sheet on iPhone. `GlassDatePicker.compact` presents a modal Cupertino popup sheet on all platforms.
4. **`.navigationTitle` Scope**:
   - In SwiftUI, `.navigationTitle` dynamically feeds the enclosing `NavigationStack`'s navigation bar. In Flutter, because `liquid_glass_widgets` separates `GlassAppBar` and child view hierarchies, `.navigationTitle(...)` annotates the wrapped child with header `Semantics` rather than imperatively replacing the app bar title.

---

## 4. Verification Harness Quick Start

To run the native SwiftUI parity app on any Mac with Xcode:
```bash
./tool/parity/ios_reference/build_and_run.sh
```

To regenerate all comparison screenshots:
```bash
./tool/parity/capture_parity.sh
```
