import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharepics/src/globals.dart' as globals;

class AddFontPage extends StatefulWidget {
  List<String> existingFonts = [];
  AddFontPage({super.key, required this.existingFonts});

  @override
  State<AddFontPage> createState() => _AddFontPageState();
}

class _AddFontPageState extends State<AddFontPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameFieldController = TextEditingController();
  final Map<String, Uint8List> _fontFileBytes = {};

  void _selectFontFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["ttf", "otf"],
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }
    for (var fontFile in result.files) {
      Uint8List bytes = await fontFile.xFile.readAsBytes();
      setState(() {
        _fontFileBytes[fontFile.name] = bytes;
      });
    }
  }

  void _removeFontFile(String fileName) {
    setState(() {
      _fontFileBytes.remove(fileName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schriftart hinzufügen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "Arial",
                  labelText: "Schriftart Name",
                  border: UnderlineInputBorder(),
                ),
                controller: _nameFieldController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Bitte einen Namen angeben";
                  }
                  if (widget.existingFonts.contains(value)) {
                    return "Schriftart existiert bereits";
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Schriftdateien:",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _selectFontFile,
                  ),
                ],
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: _fontFileBytes.keys.length,
                        (context, index) {
                          return ListTile(
                            title: Text(_fontFileBytes.keys.elementAt(index)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeFontFile(
                                  _fontFileBytes.keys.elementAt(index)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_fontFileBytes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Bitte mindestens eine Datei auswählen",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onError)),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        showCloseIcon: true,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  var name = _nameFieldController.value.text;
                  var fontDir = await Directory(
                          "${(await getApplicationDocumentsDirectory()).path}/${globals.fontsDir}/$name")
                      .create(recursive: true);
                  var fontLoader = FontLoader(name);
                  for (var fontName in _fontFileBytes.keys) {
                    (await File("${fontDir.path}/$fontName").create())
                        .writeAsBytesSync(_fontFileBytes[fontName]!);
                    fontLoader.addFont(
                      Future(
                        () => _fontFileBytes[fontName]!.buffer.asByteData(),
                      ),
                    );
                  }
                  await fontLoader.load();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$name erstellt"),
                      showCloseIcon: true,
                      behavior: SnackBarBehavior.fixed,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                label: const Text("Hinzufügen"),
                icon: const Icon(Icons.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
