import 'package:flutter/material.dart';

class LoadingEllipsis extends StatefulWidget {
  const LoadingEllipsis(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.dots = 5,
    this.enabled = true,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int dots;
  final bool enabled;

  @override
  State<LoadingEllipsis> createState() => _LoadingEllipsisState();
}

class _LoadingEllipsisState extends State<LoadingEllipsis>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _ellipsis =>
      '.' * ((_animationController.value * widget.dots + 1) ~/ 1);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Text(
          '${widget.text}${widget.enabled ? _ellipsis : ''}',
          style: widget.style ??
              TextStyle(
                color: widget.style?.color?.withOpacity(0.5) ?? Colors.black38,
              ),
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
