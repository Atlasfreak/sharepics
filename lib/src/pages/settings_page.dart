import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharepics/src/globals.dart' as globals;
import 'package:sharepics/src/pages/add_font_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _fonts = [];

  void _deleteFont(String fontName) async {
    String fontDir =
        "${(await getApplicationDocumentsDirectory()).path}/${globals.fontsDir}/$fontName";
    await Directory(fontDir).delete(recursive: true);
    setState(() {
      _fonts.remove(fontName);
    });
  }

  @override
  void initState() {
    super.initState();
    globals.listFonts().then((value) => setState(() {
          _fonts = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einstellungen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Schriftarten:",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return AddFontPage(
                            existingFonts: _fonts,
                          );
                        },
                      ),
                    ).then(
                      (value) async {
                        var fonts = await globals.listFonts();
                        setState(() {
                          _fonts = fonts;
                        });
                      },
                    );
                  },
                )
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _fonts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_fonts[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteFont(_fonts[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
