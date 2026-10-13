/// How a card-like surface is rendered.
///
/// Used by `GlassContainer.card`, `GlassGroupedSection` and
/// `GlassReorderableList.grouped` via their `surfaceStyle` parameter.
enum GlassSurfaceStyle {
  /// A liquid glass surface (blur, refraction, rim light).
  ///
  /// This is the default in 1.x. Glass is best reserved for chrome that floats
  /// above content (bars, sheets, menus, controls). Using it for cards that sit
  /// inside **scrolling list content** is discouraged: iOS itself renders those
  /// as flat, opaque surfaces, and every glass card in a list adds a backdrop
  /// sampling cost while it scrolls. Prefer [solid] for that case.
  glass,

  /// A flat, opaque fill with no blur, rim light, refraction or shadow.
  ///
  /// Matches the inset-grouped list cards used by iOS Settings-style screens:
  /// white in light mode and `#1C1C1E` in dark mode, with a continuous
  /// (superellipse) corner. The fill follows the ambient brightness (the
  /// nearest `CupertinoTheme`, falling back to the platform brightness).
  ///
  /// This path does not sample the backdrop and does not use any shader, so
  /// the surface renders identically on every platform and rendering backend,
  /// and per-widget glass `settings`, `quality` and `useOwnLayer` have no
  /// effect on it.
  solid,
}
