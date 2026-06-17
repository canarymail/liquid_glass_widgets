// Internal bridge — holds the single global accessibility flag set by
// LiquidGlassWidgets.initialize(). Kept in its own file to avoid circular
// imports between liquid_glass_setup.dart and glass_accessibility_scope.dart.
//
// NOT part of the public API. Do not export from the barrel.
library;

/// Whether glass widgets should auto-read system accessibility flags from
/// [MediaQuery] when no [GlassAccessibilityScope] is present.
///
/// Set by [LiquidGlassWidgets.wrap(respectSystemAccessibility: ...)].
/// Defaults to `true`.
bool respectSystemAccessibility = true;

/// Whether the built-in light-mode drop shadow also renders in dark mode.
///
/// Off by default — iOS 26 skips the shadow in dark mode because it is
/// invisible against a black background. Enable it when the app's dark
/// background is light enough (e.g. a dark grey) for a shadow to read; this
/// gives flat/solid glass surfaces (which have no refraction to lift them off
/// the background) the same depth they get in light mode.
///
/// Set by [LiquidGlassWidgets.shadowInDarkMode].
bool shadowInDarkMode = false;

/// Whether shader-free frosted/solid surfaces draw a uniform hairline border.
///
/// Off by default. Enable it for the no-blur "solid" tier (an opaque fill with
/// no refraction to separate it from the background): a 1px brightness-aware
/// stroke gives the surface a crisp edge — black-ish in light mode, white-ish
/// in dark mode — the way Material/iOS separate flat cards.
///
/// Set by [LiquidGlassWidgets.solidSurfaceBorder].
bool solidSurfaceBorder = false;
