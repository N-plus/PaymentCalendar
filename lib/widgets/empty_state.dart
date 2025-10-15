import 'package:flutter/material.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.verticalOffset = 0,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final double verticalOffset;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  static const _spacingToAction = 16.0;

  final GlobalKey _actionKey = GlobalKey();
  double? _actionHeight;

  @override
  void initState() {
    super.initState();
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAction());
    }
  }

  @override
  void didUpdateWidget(covariant EmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAction());
    } else if (_actionHeight != null) {
      setState(() => _actionHeight = null);
    }
  }

  void _measureAction() {
    if (!mounted) return;
    final context = _actionKey.currentContext;
    if (context == null) return;
    final size = context.size;
    if (size == null) return;

    if (_actionHeight != size.height) {
      setState(() => _actionHeight = size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAction());
    }

    final textColor = Colors.grey[600];
    final iconColor = Colors.grey[400];
    final double additionalOffset = widget.action != null
        ? ((_actionHeight ?? 0) + _spacingToAction) / 2
        : 0.0;
    final double totalOffset = additionalOffset + widget.verticalOffset;

    return Center(
      child: Transform.translate(
        offset: Offset(0, totalOffset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
            if (widget.action != null) ...[
              const SizedBox(height: _spacingToAction),
              KeyedSubtree(
                key: _actionKey,
                child: widget.action!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
