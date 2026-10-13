import 'package:flutter/widgets.dart';

import '../../theme/glass_theme.dart';

/// Fill of a `GlassSurfaceStyle.solid` card in light mode (`#FFFFFF`).
const Color kGlassSolidSurfaceLight = Color(0xFFFFFFFF);

/// Fill of a `GlassSurfaceStyle.solid` card in dark mode (`#1C1C1E`).
const Color kGlassSolidSurfaceDark = Color(0xFF1C1C1E);

/// Resolves the fill of a `GlassSurfaceStyle.solid` card.
///
/// Mirrors iOS `secondarySystemGroupedBackground` (without its elevated-dark
/// variant). Brightness comes from [GlassTheme.brightnessOf], the package's
/// single brightness authority, so the card always agrees with the text and
/// highlight colours of `GlassListTile` and friends.
Color resolveGlassSolidSurfaceColor(BuildContext context) =>
    GlassTheme.brightnessOf(context) == Brightness.dark
        ? kGlassSolidSurfaceDark
        : kGlassSolidSurfaceLight;
