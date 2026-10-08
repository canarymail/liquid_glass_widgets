import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import 'glass_card.dart';
import 'glass_container.dart';
import 'glass_divider.dart';
import 'glass_list_tile.dart';

/// A collapsible disclosure accordion group rendered with liquid glass styling,
/// providing direct parity with SwiftUI's `DisclosureGroup`.
///
/// [GlassDisclosureGroup] presents a header row with an interactive title, optional
/// leading icon, and an animated disclosure chevron. Tapping toggles the visibility
/// of its child rows with a smooth spring-based height transition.
///
/// ## Modes
///
/// 1. **Grouped mode** (default constructor): Designed for placement inside
///    [GlassGroupedSection] or [GlassCard]. Shares the outer glass platter.
/// 2. **Standalone mode** ([GlassDisclosureGroup.standalone]): Manages its own
///    independent [GlassContainer] layer with superellipse curvature.
///
/// ## Usage
///
/// ```dart
/// GlassGroupedSection(
///   header: const Text('PREFERENCES'),
///   children: [
///     GlassDisclosureGroup(
///       leading: const Icon(CupertinoIcons.bell),
///       title: const Text('Notifications'),
///       initiallyExpanded: true,
///       children: [
///         GlassListTile(
///           title: const Text('Allow Alerts'),
///           trailing: CupertinoSwitch(value: true, onChanged: (v) {}),
///         ),
///         GlassListTile(
///           title: const Text('Show Previews'),
///           subtitle: const Text('When Unlocked'),
///           trailing: GlassListTile.chevron,
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class GlassDisclosureGroup extends StatefulWidget {
  /// Creates a [GlassDisclosureGroup] designed to be nested inside
  /// a [GlassGroupedSection] or [GlassCard].
  const GlassDisclosureGroup({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.trailing,
    this.isExpanded,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.childrenPadding,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOutCubic,
    this.enableHaptics = true,
    this.showDividers = true,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingIconColor,
    this.headerBuilder,
  })  : _useOwnLayer = false,
        _settings = null,
        _quality = null;

  /// Creates a standalone [GlassDisclosureGroup] that renders inside its
  /// own independent [GlassContainer].
  const GlassDisclosureGroup.standalone({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.trailing,
    this.isExpanded,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.childrenPadding,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOutCubic,
    this.enableHaptics = true,
    this.showDividers = true,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingIconColor,
    this.headerBuilder,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
  })  : _useOwnLayer = true,
        _settings = settings,
        _quality = quality;

  /// Primary title widget displayed in the disclosure header.
  final Widget title;

  /// Optional subtitle widget displayed under [title].
  final Widget? subtitle;

  /// Optional leading widget (e.g. an [Icon] or [CircleAvatar]).
  final Widget? leading;

  /// Optional custom trailing widget.
  ///
  /// If null, an animated iOS-style rotating chevron is displayed.
  final Widget? trailing;

  /// The list of child widgets revealed when expanded.
  final List<Widget> children;

  /// Controlled expansion state.
  ///
  /// When non-null, the widget operates in controlled mode and reflects this state.
  final bool? isExpanded;

  /// Initial expansion state when [isExpanded] is null.
  ///
  /// Defaults to `false`.
  final bool initiallyExpanded;

  /// Callback invoked when the expansion state changes.
  final ValueChanged<bool>? onExpansionChanged;

  /// Padding for the header row.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` matching iOS list insets.
  final EdgeInsetsGeometry contentPadding;

  /// Optional padding around the expanded children container.
  final EdgeInsetsGeometry? childrenPadding;

  /// Duration of the expansion and collapse animation.
  ///
  /// Defaults to 250 milliseconds.
  final Duration animationDuration;

  /// Easing curve for the expansion and collapse animation.
  ///
  /// Defaults to [Curves.easeInOutCubic].
  final Curve animationCurve;

  /// Whether to trigger subtle haptic feedback when toggling expansion.
  ///
  /// Defaults to `true`.
  final bool enableHaptics;

  /// Whether to automatically insert [GlassDivider]s between adjacent expanded children.
  ///
  /// Defaults to `true`.
  final bool showDividers;

  /// Custom text style for [title].
  final TextStyle? titleStyle;

  /// Custom text style for [subtitle].
  final TextStyle? subtitleStyle;

  /// Tint applied to [leading] icon.
  final Color? leadingIconColor;

  /// Optional custom builder for the entire header row.
  final Widget Function(
    BuildContext context,
    bool isExpanded,
    VoidCallback toggle,
  )? headerBuilder;

  final bool _useOwnLayer;
  final LiquidGlassSettings? _settings;
  final GlassQuality? _quality;

  @override
  State<GlassDisclosureGroup> createState() => GlassDisclosureGroupState();
}

/// State for [GlassDisclosureGroup] providing programmatic toggle capabilities.
class GlassDisclosureGroupState extends State<GlassDisclosureGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _chevronTurns;

  bool _isExpanded = false;
  bool _isPressed = false;

  /// Whether the disclosure group is currently expanded.
  bool get isExpanded => _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded ?? widget.initiallyExpanded;

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
      reverseCurve: widget.animationCurve.flipped,
    );

    _heightFactor = curvedAnimation;
    // 0.0 turns = points forward (right in LTR); 0.25 turns = 90 deg clockwise (points down)
    _chevronTurns =
        Tween<double>(begin: 0.0, end: 0.25).animate(curvedAnimation);
  }

  @override
  void didUpdateWidget(covariant GlassDisclosureGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _isExpanded) {
      _setExpanded(widget.isExpanded!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the disclosure group expansion state.
  void toggle() {
    _setExpanded(!_isExpanded);
  }

  /// Programmatically expands the disclosure group.
  void expand() {
    if (!_isExpanded) {
      _setExpanded(true);
    }
  }

  /// Programmatically collapses the disclosure group.
  void collapse() {
    if (_isExpanded) {
      _setExpanded(false);
    }
  }

  void _setExpanded(bool expanded) {
    if (_isExpanded == expanded) return;

    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _isExpanded = expanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    Widget header = widget.headerBuilder != null
        ? widget.headerBuilder!(context, _isExpanded, toggle)
        : _buildDefaultHeader(context);

    // Accessibility semantics
    header = Semantics(
      button: true,
      expanded: _isExpanded,
      child: header,
    );

    final childrenWidgets = _buildChildren(context);

    final expandedContent = AnimatedBuilder(
      animation: _controller.view,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: child,
          ),
        );
      },
      child: childrenWidgets,
    );

    Widget group = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        expandedContent,
      ],
    );

    if (widget._useOwnLayer) {
      group = GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 12),
        settings: widget._settings,
        quality: widget._quality,
        padding: EdgeInsets.zero,
        child: group,
      );
    }

    return group;
  }

  Widget _buildDefaultHeader(BuildContext context) {
    final dynamicLabelColor =
        CupertinoTheme.of(context).textTheme.textStyle.color ??
            CupertinoColors.label;

    final effectiveTitleStyle = widget.titleStyle ??
        TextStyle(
          color: dynamicLabelColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );

    final effectiveSubtitleStyle = widget.subtitleStyle ??
        TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        );

    Widget? leadingWidget = widget.leading;
    if (leadingWidget != null && widget.leadingIconColor != null) {
      leadingWidget = IconTheme(
        data: IconThemeData(color: widget.leadingIconColor),
        child: leadingWidget,
      );
    }

    Widget trailingWidget = widget.trailing ??
        RotationTransition(
          turns: _chevronTurns,
          child: const Icon(
            CupertinoIcons.chevron_forward,
            color: CupertinoColors.systemGrey,
            size: 18,
          ),
        );

    Widget titleColumn = widget.subtitle != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(
                style: effectiveTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: widget.title,
              ),
              const SizedBox(height: 2),
              DefaultTextStyle(
                style: effectiveSubtitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: widget.subtitle!,
              ),
            ],
          )
        : DefaultTextStyle(
            style: effectiveTitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: widget.title,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isPressed
            ? CupertinoColors.systemGrey4
                .resolveFrom(context)
                .withValues(alpha: 0.18)
            : CupertinoColors.transparent,
        padding: widget.contentPadding,
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: Center(child: leadingWidget),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: titleColumn),
            const SizedBox(width: 8),
            trailingWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildChildren(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final processedChildren = <Widget>[];

    // Divider separating header from expanded children
    if (widget.showDividers) {
      final double headerDividerIndent = widget.leading != null ? 52.0 : 16.0;
      processedChildren.add(GlassDivider(indent: headerDividerIndent));
    }

    for (var i = 0; i < widget.children.length; i++) {
      final currentChild = widget.children[i];
      processedChildren.add(currentChild);

      final isLastChild = i == widget.children.length - 1;
      if (!isLastChild && widget.showDividers) {
        final nextChild = widget.children[i + 1];
        if (currentChild is GlassDivider || nextChild is GlassDivider) continue;

        double indent = 16.0;
        if (currentChild is GlassListTile && currentChild.leading != null) {
          indent = 56.0;
        } else if (currentChild is GlassDisclosureGroup &&
            currentChild.leading != null) {
          indent = 52.0;
        }

        processedChildren.add(GlassDivider(indent: indent));
      }
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: processedChildren,
    );

    if (widget.childrenPadding != null) {
      content = Padding(
        padding: widget.childrenPadding!,
        child: content,
      );
    }

    return content;
  }
}
