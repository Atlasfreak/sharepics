import 'package:flutter/material.dart';

class TemplateTile extends StatelessWidget {
  final String name;
  const TemplateTile({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
                boxShadow: kElevationToShadow[3]),
            height: 100,
            width: 100,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Center(child: Text(name)),
        ),
      ],
    );
  }
}
