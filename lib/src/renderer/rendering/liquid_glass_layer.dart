// ignore_for_file: avoid_setters_without_getters

import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import '../internal/render_liquid_glass_geometry.dart';
import '../internal/transform_tracking_repaint_boundary_mixin.dart';
import '../liquid_glass_render_scope.dart';
import '../logging.dart';
import 'liquid_glass_render_object.dart';
import '../shaders.dart';
import 'package:meta/meta.dart';

/// Represents a layer of multiple [LiquidGlass] shapes or
/// [LiquidGlassBlendGroup]s that have shared [LiquidGlassSettings] and will be
/// rendered together.
///
/// If you create a [LiquidGlassLayer] with one or more [LiquidGlass] or
/// [LiquidGlassBlendGroup] widgets, the liquid glass effect will be rendered
/// where this layer is.
///
/// Make sure not to stack any other widgets between the [LiquidGlassLayer] and
/// the [LiquidGlass] widgets, otherwise the liquid glass effect will be behind
/// them.
///
/// ## Example
///
/// ```dart
/// Widget build(BuildContext context) {
///   return LiquidGlassLayer(
///     child: Column(
///       children: [
///         LiquidGlass(
///           shape: LiquidRoundedSuperellipse(
///             borderRadius: 10,
///           ),
///           child: const SizedBox.square(
///             dimension: 100,
///           ),
///         ),
///         const SizedBox(height: 100),
///         LiquidGlassBlendGroup(
///          blend: 20,
///          child: Row(
///             children: [
///               LiquidGlass.grouped(
///                 shape: const LiquidOval(),
///                 child: const SizedBox.square(
///                   dimension: 100,
///                 ),
///               ),
///               LiquidGlass.grouped(
///                 shape: const LiquidRoundedSuperellipse(
///                   borderRadius: 20,
///                 ),
///                 child: const SizedBox.square(
///                   dimension: 100,
///                 ),
///               ),
///             ],
///           ),
///         ),
///       ],
///     ),
///   );
/// }
class LiquidGlassLayer extends StatefulWidget {
  /// Creates a new [LiquidGlassLayer] with the given [child] and [settings].
  const LiquidGlassLayer({
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.shadows = const <BoxShadow>[],
    this.clipExpansion = EdgeInsets.zero,
    this.captureImage,
    this.captureOriginInScreenSpace = Offset.zero,
    super.key,
  });

  /// The subtree in which you should include at least one [LiquidGlass] widget.
  ///
  /// The [LiquidGlassLayer] will automatically register all [LiquidGlass]
  /// widgets in the subtree as shapes and render them.
  final Widget child;

  /// The settings for the liquid glass effect for all shapes in this layer.
  final LiquidGlassSettings settings;

  /// The shadows to render using the merged SDF geometry.
  final List<BoxShadow> shadows;

  /// Extra space to add around the geometry bounding box before clipping the
  /// [BackdropFilterLayer] that runs the glass shader.
  ///
  /// The clip rect is normally tight to the glass shape's geometry.  Any
  /// ancestor [Transform] (e.g. jelly squash-and-stretch on an indicator)
  /// can push painted pixels outside that tight rect, producing a hard edge
  /// cutoff.  Set [clipExpansion] to a safe margin that covers the maximum
  /// expected deformation so the shader is applied over the full animated area.
  ///
  /// Defaults to [EdgeInsets.zero] — zero extra GPU cost for static glass.
  final EdgeInsets clipExpansion;

  /// Pre-captured background image to use instead of a live [BackdropFilterLayer].
  ///
  /// When non-null, the glass shader reads from this image directly (sampler
  /// slot 0) instead of letting the compositor extract the backdrop. This
  /// eliminates the Impeller compositor ordering dependency that caused the
  /// opaque-white indicator bug (#99). The image must come from a
  /// [RenderRepaintBoundary.toImageSync] call on a boundary that covers the
  /// full background region behind the glass.
  ///
  /// Defaults to null — falls through to the BackdropFilterLayer path.
  final ui.Image? captureImage;

  /// The global (screen-space) logical-pixel origin of the [RepaintBoundary]
  /// that produced [captureImage]. Used to compute [uCaptureOffset] inside
  /// the shader so [FlutterFragCoord()] fragments are correctly mapped into
  /// the capture image's coordinate space.
  ///
  /// Ignored when [captureImage] is null.
  final Offset captureOriginInScreenSpace;

  @override
  State<LiquidGlassLayer> createState() => _LiquidGlassLayerState();
}

class _LiquidGlassLayerState extends State<LiquidGlassLayer>
    with SingleTickerProviderStateMixin {
  late final GeometryRenderLink _link = GeometryRenderLink();

  late final logger = Logger(LgrLogNames.layer);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ImageFilter.isShaderFilterSupported) {
      logger.warning(
          'LiquidGlassLayer requires Impeller. No glass effect will be '
          'rendered on this platform.');
      return LiquidGlassRenderScope(
        settings: widget.settings,
        child: InheritedGeometryRenderLink(
          link: _link,
          child: widget.child,
        ),
      );
    }

    return BackdropGroup(
      child: RepaintBoundary(
        child: LiquidGlassRenderScope(
          settings: widget.settings,
          child: InheritedGeometryRenderLink(
            link: _link,
            child: ShaderBuilder(
              assetKey: ShaderKeys.liquidGlassRender,
              (context, shader, child) => _RawShapes(
                renderShader: shader,
                backdropKey: BackdropGroup.of(context)?.backdropKey,
                settings: widget.settings,
                shadows: widget.shadows,
                link: _link,
                clipExpansion: widget.clipExpansion,
                captureImage: widget.captureImage,
                captureOriginInScreenSpace: widget.captureOriginInScreenSpace,
                child: child!,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _RawShapes extends SingleChildRenderObjectWidget {
  const _RawShapes({
    required this.renderShader,
    required this.backdropKey,
    required this.settings,
    required this.shadows,
    required Widget super.child,
    required this.link,
    this.clipExpansion = EdgeInsets.zero,
    this.captureImage,
    this.captureOriginInScreenSpace = Offset.zero,
  });

  final FragmentShader renderShader;
  final BackdropKey? backdropKey;
  final LiquidGlassSettings settings;
  final List<BoxShadow> shadows;
  final GeometryRenderLink link;
  final EdgeInsets clipExpansion;
  final ui.Image? captureImage;
  final Offset captureOriginInScreenSpace;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlassLayer(
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      renderShader: renderShader,
      backdropKey: backdropKey,
      settings: settings,
      shadows: shadows,
      link: link,
      clipExpansion: clipExpansion,
      captureImage: captureImage,
      captureOriginInScreenSpace: captureOriginInScreenSpace,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassLayer renderObject,
  ) {
    renderObject
      ..link = link
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..settings = settings
      ..shadows = shadows
      ..backdropKey = backdropKey
      ..clipExpansion = clipExpansion
      ..captureImage = captureImage
      ..captureOriginInScreenSpace = captureOriginInScreenSpace;
  }
}

@internal
class RenderLiquidGlassLayer extends LiquidGlassRenderObject
    with TransformTrackingRenderObjectMixin {
  RenderLiquidGlassLayer({
    required super.renderShader,
    required super.devicePixelRatio,
    required super.settings,
    required this.shadows,
    required super.link,
    super.backdropKey,
    super.captureImage,
    super.captureOriginInScreenSpace,
    EdgeInsets clipExpansion = EdgeInsets.zero,
  }) : _clipExpansion = clipExpansion;

  // ── Cached blur filter ──────────────────────────────────────────────────
  // The BackdropFilterLayer's blur filter is rebuilt only when blurSigma
  // changes — not on every paint frame during jelly/morph animations.
  ImageFilter? _cachedBlur;
  double _cachedBlurSigma = -1;

  final _shaderHandle = LayerHandle<BackdropFilterLayer>();
  final _blurLayerHandle = LayerHandle<BackdropFilterLayer>();
  final _clipRectLayerHandle = LayerHandle<ClipRectLayer>();
  final _clipPathLayerHandle = LayerHandle<ClipPathLayer>();
  final _blurBoundsClipRectLayerHandle = LayerHandle<ClipRectLayer>();

  // Per-shape forwarded blur clips (see the Pass 1 comment in
  // [paintLiquidGlass]): one BackdropFilterLayer + ClipRRectLayer per
  // disjoint shape, grown/shrunk to match the live shape count.
  final List<LayerHandle<BackdropFilterLayer>> _blurShapeLayerHandles = [];
  final List<LayerHandle<ClipRRectLayer>> _blurClipRRectLayerHandles = [];

  void _syncBlurShapeHandleCount(int count) {
    while (_blurShapeLayerHandles.length > count) {
      _blurShapeLayerHandles.removeLast().layer = null;
      _blurClipRRectLayerHandles.removeLast().layer = null;
    }
    while (_blurShapeLayerHandles.length < count) {
      _blurShapeLayerHandles.add(LayerHandle<BackdropFilterLayer>());
      _blurClipRRectLayerHandles.add(LayerHandle<ClipRRectLayer>());
    }
  }

  EdgeInsets _clipExpansion;
  set clipExpansion(EdgeInsets value) {
    if (_clipExpansion == value) return;
    _clipExpansion = value;
    markNeedsPaint();
  }

  List<BoxShadow> shadows;

  @override
  Size get desiredMatteSize => switch (owner?.rootNode) {
        final RenderView rv => rv.size,
        final RenderBox rb => rb.size,
        _ => Size.zero,
      };

  @override
  Matrix4 get matteTransform => getTransformTo(null);

  @override
  void onTransformChanged() {
    // Transform changes (position, jelly scale, scroll) no longer require a
    // geometry rebuild. The geometry image is in LOCAL space; matteTransform is
    // applied synchronously at paint time so the screen position is always
    // exact with zero async lag.  Only layout() still sets needsGeometryUpdate.
    markNeedsPaint();
  }

  @override
  void paintLiquidGlass(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
    Rect boundingBox,
  ) {
    if (!attached) return;

    // ── Pass 0: SDF Shadows ──────────────────────────────────────────────────
    if (shadows.isNotEmpty && geometryImage != null) {
      final localBounds = geometryLocalBounds.shift(offset);

      for (final shadow in shadows) {
        if (shadow.color.a == 0) continue;

        // Inflate clip rect to ensure large blurs aren't cut off
        final shadowClip = localBounds.shift(shadow.offset).inflate(
              shadow.spreadRadius + shadow.blurRadius * 3,
            );

        context.canvas.saveLayer(shadowClip, Paint());

        // 1. Draw the geometry matte as a blurred, tinted shadow
        final shadowPaint = Paint()
          ..colorFilter = ColorFilter.mode(shadow.color, BlendMode.srcIn)
          ..imageFilter = ImageFilter.blur(
            sigmaX: shadow.blurSigma,
            sigmaY: shadow.blurSigma,
            tileMode: TileMode.decal,
          );

        context.canvas.drawImageRect(
          geometryImage!,
          Rect.fromLTWH(
            0,
            0,
            geometryImage!.width.toDouble(),
            geometryImage!.height.toDouble(),
          ),
          localBounds.shift(shadow.offset),
          shadowPaint,
        );

        // 2. GPU Cutout (dstOut): punch out the interior using the same geometry
        // matte to prevent the glass from blurring its own shadow (dirty rim).
        context.canvas.drawImageRect(
          geometryImage!,
          Rect.fromLTWH(
            0,
            0,
            geometryImage!.width.toDouble(),
            geometryImage!.height.toDouble(),
          ),
          localBounds,
          Paint()..blendMode = BlendMode.dstOut,
        );

        context.canvas.restore();
      }
    }

    // ── Pass 1: Blur ─────────────────────────────────────────────────────────
    // Use Flutter's native ImageFilter.blur for smooth, multi-pass Gaussian
    // quality (the inline 9-tap shader approximation was pixelated with text).
    // Clip tightly to the actual pill shape path — no expansion needed here.
    //
    // PlatformView clip forwarding (framework PR #177551, 3.41+): when this
    // BackdropFilterLayer overlaps a hybrid-composed iOS PlatformView
    // (webview, map, video), the engine applies the blur to the platform view
    // through its mutator stack — which honours ClipRect/ClipRRect clips but
    // NOT ClipPath. A path clip therefore leaves the platform-view side of
    // the blur bounded only by the filter's rectangular coverage: a frosted
    // slab around (and between) the visually rounded glass shapes. Same wall
    // as the frosted fallback's `_ShapeClip`, fixed the same way:
    // - when every live shape is radius-expressible under a translation-only
    //   transform and the shapes are pairwise disjoint (no active metaball
    //   blend bridging them), each shape's blur is pushed in its own
    //   forwarded ClipRRect — one grouped backdrop read per shape, all
    //   sharing this layer's [backdropKey]. The circular-arc corner differs
    //   from the superellipse corner by under a pixel (see `_ShapeClip`),
    //   and the shader pass still renders the exact squircle on the Flutter
    //   side.
    // - otherwise (mid-morph blobs with a live blend bridge, rotated/scaled
    //   shapes) keep the exact union path clip for Flutter content, wrapped
    //   in a forwarded ClipRect of the shapes' bounding box so the
    //   platform-view frost cannot exceed it.
    if (settings.effectiveBlur > 0) {
      final blurSigma = settings.effectiveBlur;
      // Reuse cached blur filter when sigma hasn't changed.
      if (_cachedBlur == null || _cachedBlurSigma != blurSigma) {
        _cachedBlur = ImageFilter.blur(
          tileMode: TileMode.mirror,
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        );
        _cachedBlurSigma = blurSigma;
      }

      final forwardableRRects = _forwardableBlurClipRRects(shapes);
      if (forwardableRRects != null) {
        _syncBlurShapeHandleCount(forwardableRRects.length);
        for (var i = 0; i < forwardableRRects.length; i++) {
          final rrect = forwardableRRects[i];
          final blurLayer = (_blurShapeLayerHandles[i].layer ??=
              BackdropFilterLayer())
            ..backdropKey = backdropKey // Scoped to this layer's BackdropGroup
            ..filter = _cachedBlur!;
          // Each clip is disjoint, so painting the full contents inside every
          // clip renders each shape's content exactly once.
          _blurClipRRectLayerHandles[i].layer = context.pushClipRRect(
            needsCompositing,
            offset,
            rrect.outerRect,
            rrect,
            (context, offset) {
              context.pushLayer(
                blurLayer,
                (context, offset) {
                  paintShapeContents(context, offset, shapes,
                      insideGlass: true);
                },
                offset,
              );
            },
            oldLayer: _blurClipRRectLayerHandles[i].layer,
          );
        }
        _blurLayerHandle.layer = null;
        _clipPathLayerHandle.layer = null;
        _blurBoundsClipRectLayerHandle.layer = null;
      } else {
        final blurLayer = (_blurLayerHandle.layer ??= BackdropFilterLayer())
          ..backdropKey =
              backdropKey // Scoped to this LiquidGlassLayer's BackdropGroup
          ..filter = _cachedBlur!;

        final clipPath = Path();
        for (final geometry in shapes) {
          if (!geometry.$1.attached) continue;
          clipPath.addPath(
            geometry.$2.path,
            Offset.zero,
            matrix4: geometry.$3.storage,
          );
        }
        _blurBoundsClipRectLayerHandle.layer = context.pushClipRect(
          needsCompositing,
          offset,
          boundingBox,
          (context, offset) {
            _clipPathLayerHandle.layer = context.pushClipPath(
              needsCompositing,
              offset,
              boundingBox,
              clipPath,
              (context, offset) {
                context.pushLayer(
                  blurLayer,
                  (context, offset) {
                    paintShapeContents(context, offset, shapes,
                        insideGlass: true);
                  },
                  offset,
                );
              },
              oldLayer: _clipPathLayerHandle.layer,
            );
          },
          oldLayer: _blurBoundsClipRectLayerHandle.layer,
        );
        _syncBlurShapeHandleCount(0);
      }
    } else {
      _blurLayerHandle.layer = null;
      _clipPathLayerHandle.layer = null;
      _blurBoundsClipRectLayerHandle.layer = null;
      _syncBlurShapeHandleCount(0);
    }

    // ── Pass 2: Glass refraction + lighting shader ────────────────────────────
    // Inflate the clip rect by _clipExpansion so jelly squash-and-stretch can
    // push deformed pixels beyond the tight bounding box without a hard clip
    // edge. For static glass _clipExpansion == EdgeInsets.zero (no-op).
    final clipRect = _clipExpansion == EdgeInsets.zero
        ? boundingBox
        : Rect.fromLTRB(
            boundingBox.left - _clipExpansion.left,
            boundingBox.top - _clipExpansion.top,
            boundingBox.right + _clipExpansion.right,
            boundingBox.bottom + _clipExpansion.bottom,
          );

    // Capture path: when a pre-captured background image is available, bypass
    // the BackdropFilterLayer entirely and draw the shader directly onto the
    // canvas, binding the captured image as uBackgroundTexture (slot 0).
    // This eliminates the live compositor read, making the indicator rendering
    // deterministic and immune to Impeller compositor ordering bugs (#99).
    if (captureImage case final capture?) {
      paintLiquidGlassWithCapture(
        context,
        offset,
        shapes,
        clipRect,
        capture,
      );
      // paintLiquidGlassWithCapture handles all three passes (blur, shader, contents).
      // Release the stale BackdropFilter layer handles so the engine can collect
      // the offscreen surface when we're no longer using the backdrop path.
      _shaderHandle.layer = null;
      _clipRectLayerHandle.layer = null;
      return;
    }

    // BackdropFilter path (default): live compositor read via BackdropFilterLayer.
    final shaderLayer = (_shaderHandle.layer ??= BackdropFilterLayer())
      ..filter = ImageFilter.shader(renderShader);

    _clipRectLayerHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      clipRect,
      (context, offset) {
        context.pushLayer(
          shaderLayer,
          (context, offset) {
            paintShapeContents(context, offset, shapes, insideGlass: false);
          },
          offset,
        );
      },
      oldLayer: _clipRectLayerHandle.layer,
    );
  }

  /// The blur pass clips as one axis-aligned rounded rect per live shape in
  /// layer-local space, when every shape is radius-expressible under a
  /// translation-only transform and the resulting rects are pairwise disjoint
  /// — the settled pill/capsule layout (one capsule, or e.g. a bottom bar's
  /// action capsule + trailing pill). Returns null otherwise (jelly
  /// scale/rotation, overlapping shapes), which falls back to the exact union
  /// path clip bounded by a forwarded ClipRect.
  ///
  /// An active metaball blend does NOT disqualify the layer: the union path
  /// this replaces is itself built from each shape's exact path (see
  /// [GeometryCache.path]) and never covered the goo the shader grows between
  /// blended shapes — so for disjoint shapes, per-shape clips cover exactly
  /// the same region the path clip did.
  ///
  /// The RRects matter for iOS PlatformViews: the engine forwards
  /// ClipRRect — but not ClipPath — to the platform-view mutator stack, so
  /// only these clips bound the blur that the engine applies to a webview/map
  /// beneath the glass (#177551). A union path clip over a platform view
  /// degrades to the union's rectangular coverage, frosting the gaps between
  /// shapes.
  List<RRect>? _forwardableBlurClipRRects(
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
  ) {
    final rrects = <RRect>[];
    for (final geometry in shapes) {
      if (!geometry.$1.attached) continue;
      if (geometry.$2.shapes.isEmpty) continue;

      // Only a translation-only transform keeps a shape an axis-aligned
      // rounded rect with unscaled radii.
      final s = geometry.$3.storage;
      const eps = 1e-3;
      final translationOnly = (s[0] - 1).abs() < eps &&
          (s[5] - 1).abs() < eps &&
          (s[10] - 1).abs() < eps &&
          (s[15] - 1).abs() < eps &&
          s[1].abs() < eps &&
          s[2].abs() < eps &&
          s[4].abs() < eps &&
          s[6].abs() < eps &&
          s[8].abs() < eps &&
          s[9].abs() < eps;
      if (!translationOnly) return null;
      final translation = Offset(s[12], s[13]);

      for (final shape in geometry.$2.shapes) {
        final rect = shape.shapeBounds.shift(translation);
        // A zero-sized shape (e.g. a hidden indicator at rest) contributes
        // nothing to the union path either — skip it, don't give up.
        if (rect.isEmpty) continue;

        // An RRect with half-extent radii is an exact ellipse, so LiquidOval
        // is representable too — same substitution `_ShapeClip` makes over
        // PlatformViews.
        if (shape.shape is LiquidOval) {
          rrects.add(RRect.fromRectXY(rect, rect.width / 2, rect.height / 2));
          continue;
        }
        final halfMin = rect.shortestSide / 2;
        final top =
            Radius.circular(clampDouble(shape.rawCornerRadius, 0, halfMin));
        final bottom = Radius.circular(
            clampDouble(shape.rawBottomCornerRadius, 0, halfMin));
        rrects.add(RRect.fromRectAndCorners(
          rect,
          topLeft: top,
          topRight: top,
          bottomLeft: bottom,
          bottomRight: bottom,
        ));
      }
    }
    if (rrects.isEmpty) return null;

    // Disjoint check: each clip paints the full shape contents, so any
    // overlap would render content (and blur) twice in the shared region.
    for (var i = 0; i < rrects.length; i++) {
      for (var j = i + 1; j < rrects.length; j++) {
        if (rrects[i].outerRect.overlaps(rrects[j].outerRect)) return null;
      }
    }
    return rrects;
  }

  @override
  void dispose() {
    // Eagerly clear filter references on the backdrop layers before nulling
    // the handles. During isolate shutdown on Mali GPUs, GC finalization of
    // BackdropFilterLayer retains DlRuntimeEffectColorSource → TextureVK →
    // Vulkan mutex chains that outlive the GPU context (Crash 2). Clearing
    // the filter property breaks this retention chain immediately.
    _shaderHandle.layer?.filter = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    _blurLayerHandle.layer?.filter = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    for (final handle in _blurShapeLayerHandles) {
      handle.layer?.filter = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    }
    _syncBlurShapeHandleCount(0);
    _shaderHandle.layer = null;
    _blurLayerHandle.layer = null;
    _clipRectLayerHandle.layer = null;
    _clipPathLayerHandle.layer = null;
    _blurBoundsClipRectLayerHandle.layer = null;
    super.dispose();
  }
}
