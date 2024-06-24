import 'package:flutter/material.dart';
import 'package:sharepics/src/globals.dart' as globals;

class SvgContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const SvgContainer({
    super.key,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(globals.containerBorderRadius),
      ),
      alignment: Alignment.bottomLeft,
      child: child,
    );
  }
}
