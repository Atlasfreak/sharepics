import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sharepics/src/components/template_tile.dart';
import 'package:sharepics/src/pages/add_template_page.dart';
import 'package:sharepics/src/globals.dart' as globals;

class HomePage extends StatefulWidget {
  HomePage({super.key});

  static const routeName = "/";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<File> _files = [];

  Future<List<File>> _getFiles() async {
    return Directory(await globals.generateTemplatePath())
        .list()
        .where((event) => event.path.endsWith(".svg"))
        .where((event) => event is File)
        .map((event) => event as File)
        .toList();
  }

  @override
  void initState() {
    _getFiles().then(
      (value) {
        setState(() {
          _files = value.toList();
        });
      },
    );
    print(_files);
    super.initState();
  }

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
      body: _files.isNotEmpty
          ? GridView.builder(
              restorationId: "homePage",
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150, mainAxisExtent: 150),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                File file = _files[index];
                String name = globals.fileNameRegex
                    .allMatches(file.path)
                    .toList()[0]
                    .group(1)
                    .toString();
                return TemplateTile(
                  name: name,
                  svgPath: file.path,
                );
              },
            )
          : const Center(
              child: Text(
              "Keine Vorlagen gefunden",
              style: TextStyle(fontSize: 20),
            )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTemplatePage(),
              ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
