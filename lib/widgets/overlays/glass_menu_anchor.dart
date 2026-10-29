import 'package:flutter/widgets.dart';

import '../../src/renderer/liquid_glass_renderer.dart';

/// Marks a glass surface that a [GlassMenu] inside it morphs out of and back
/// into, instead of the menu's own trigger.
///
/// Native iOS toolbars do this: tapping one button of a grouped capsule turns
/// the whole capsule into the menu (the capsule and every icon in it vanish),
/// and closing the menu morphs it back into the whole capsule. A [GlassMenu]
/// with [GlassMenu.morphFromAnchor] set looks up the nearest anchor when it
/// opens, takes the morph's start and end geometry from the anchor's bounds,
/// and drives the anchor's visibility where it would otherwise fade its own
/// trigger.
///
/// The anchor fades through [GlassMaterializeScope], not opacity, since an
/// [Opacity] cannot fade glass.
class GlassMenuAnchor extends StatefulWidget {
  /// Wraps [child], typically a grouped glass capsule.
  const GlassMenuAnchor({required this.child, super.key});

  /// The surface the menu morphs from.
  final Widget child;

  /// The nearest anchor above [context], or null when there is none.
  static GlassMenuAnchorState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<GlassMenuAnchorState>();

  @override
  State<GlassMenuAnchor> createState() => GlassMenuAnchorState();
}

/// State of a [GlassMenuAnchor]: its bounds and the visibility a menu drives.
class GlassMenuAnchorState extends State<GlassMenuAnchor> {
  final ValueNotifier<double> _visibility = ValueNotifier<double>(1.0);

  /// The menu currently driving the anchor. Two menus in one capsule never
  /// fight over it: only the one that claimed it last can change it.
  Object? _owner;

  /// The anchor's render box, for the menu to take its geometry from.
  RenderBox? get renderBox {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Makes [owner] the menu driving the anchor.
  void claim(Object owner) => _owner = owner;

  /// Sets how visible the anchor is (0 = hidden, 1 = at rest), if [owner]
  /// holds it.
  void setVisibility(Object owner, double value) {
    if (!mounted || !identical(_owner, owner)) return;
    _visibility.value = value.clamp(0.0, 1.0);
  }

  /// Restores the anchor and gives it up, if [owner] holds it.
  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    if (mounted) _visibility.value = 1.0;
  }

  @override
  void dispose() {
    _visibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _visibility,
      child: widget.child,
      // One tree shape at every visibility: switching shapes would remount
      // the child, and with it the open menu's trigger.
      builder: (context, visibility, child) {
        // Composed with any enclosing scope, as the menu trigger does.
        final outer = GlassMaterializeScope.maybeOf(context);
        return Opacity(
          // Opacity only to skip painting once fully hidden.
          opacity: visibility > 0.0 ? 1.0 : 0.0,
          child: GlassMaterializeScope(
            glassProgress: visibility * (outer?.glassProgress ?? 1.0),
            contentOpacity: visibility * (outer?.contentOpacity ?? 1.0),
            contentSigma: outer?.contentSigma ?? 0.0,
            child: child!,
          ),
        );
      },
    );
  }
}
