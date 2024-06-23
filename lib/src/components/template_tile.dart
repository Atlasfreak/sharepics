import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TemplateTile extends StatelessWidget {
  final String name;
  final String svgPath;
  const TemplateTile({super.key, required this.name, required this.svgPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
                boxShadow: kElevationToShadow[3],
              ),
              height: 100,
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SvgPicture.file(File(svgPath)),
              )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Center(child: Text(name)),
        ),
      ],
    );
  }
}
