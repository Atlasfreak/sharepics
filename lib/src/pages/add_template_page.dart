import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sharepics/src/globals.dart' as globals;

class AddTemplatePage extends StatefulWidget {
  const AddTemplatePage({super.key});

  static const routeName = "/add_template";

  @override
  State<AddTemplatePage> createState() => _AddTemplatePageState();
}

class _AddTemplatePageState extends State<AddTemplatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PlatformFile? _svgPath;
  Uint8List? _svgBytes;
  PlatformFile? _ymlPath;
  Uint8List? _ymlBytes;
  String? nameValid;

  final TextEditingController _ymlPathFieldController = TextEditingController();
  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _svgPathFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vorlage hinzufügen"),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: "Vorlage 1",
                    labelText: "Name",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    return nameValid;
                  },
                  controller: _nameFieldController,
                  onChanged: (value) async {
                    if (value.isEmpty) {
                      nameValid = "Bitte einen Namen angeben";
                      return;
                    }
                    if (await File(await globals
                            .generateTemplateFilePath("$value.svg"))
                        .exists()) {
                      nameValid = "Name bereits genutzt";
                      return;
                    }
                    nameValid = null;
                    return;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: hasSvg()
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.errorContainer,
                      width: 3,
                    ),
                    borderRadius:
                        BorderRadius.circular(globals.containerBorderRadius),
                  ),
                  alignment: Alignment.bottomLeft,
                  child: !hasSvg()
                      ? const Center(child: Text("Keine Vorlage gewählt"))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(
                              globals.containerBorderRadius),
                          child: SvgPicture.memory(_svgBytes!),
                        ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.file_open_outlined),
                    border: UnderlineInputBorder(),
                    labelText: ".svg Vorlage",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || _svgBytes == null) {
                      return "keine Vorlage gewählt";
                    }
                    return null;
                  },
                  controller: _svgPathFieldController,
                  onTap: _selectSvg,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.file_open_outlined),
                    border: UnderlineInputBorder(),
                    labelText: ".yml Konfigurationsdatei",
                  ),
                  controller: _ymlPathFieldController,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !(value.endsWith(".yml") || value.endsWith(".yaml")) ||
                        _ymlBytes == null) {
                      return "Ungültige Konfigurationsdatei";
                    }
                    return null;
                  },
                  onTap: _selectYml,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final form = _formKey.currentState;
                    if (form != null && form.validate()) {
                      var name = _nameFieldController.value.text;
                      (await File(await globals
                                  .generateTemplateFilePath("$name.svg"))
                              .create(recursive: true))
                          .writeAsBytes(_svgBytes!);
                      (await File(await globals
                                  .generateTemplateFilePath("$name.yaml"))
                              .create(recursive: true))
                          .writeAsBytes(_ymlBytes!);
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$name erstellt"),
                          showCloseIcon: true,
                          behavior: SnackBarBehavior.fixed,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  label: const Text("Speichern"),
                  icon: const Icon(Icons.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool hasSvg() {
    if (_svgBytes != null) {
      return true;
    }
    return false;
  }

  void _selectSvg() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["svg"],
    );
    _svgPath = result?.files.first;

    if (_svgPath != null && _svgPath!.path != null) {
      _svgPathFieldController.text = _svgPath!.name;
      XFile svgFile = _svgPath!.xFile;
      var svgBytes = await svgFile.readAsBytes();
      setState(() {
        _svgBytes = svgBytes;
      });
    }
  }

  void _selectYml() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    _ymlPath = result?.files.first;
    Uint8List? ymlBytes;
    if (_ymlPath?.path != null) {
      ymlBytes = await _ymlPath!.xFile.readAsBytes();
    }
    setState(() {
      if (_ymlPath?.path != null && ymlBytes != null) {
        _ymlPathFieldController.text = _ymlPath!.name;
        _ymlBytes = ymlBytes;
      }
    });
  }
}
