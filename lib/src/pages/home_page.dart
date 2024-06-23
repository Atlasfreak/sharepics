import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharepics/src/components/template_tile.dart';
import 'package:sharepics/src/pages/add_template_page.dart';
import 'package:sharepics/src/globals.dart' as globals;

class HomePage extends StatelessWidget {
  HomePage({super.key});

  static const routeName = "/";

  final List<String> files = ["abc", "test123", "12345"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Titel",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryFixed),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GridView.builder(
        restorationId: "homePage",
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150, mainAxisExtent: 150),
        itemCount: 30,
        itemBuilder: (context, index) {},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTemplatePage(),
              ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
