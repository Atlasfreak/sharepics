import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharepics/src/globals.dart' as globals;
import 'package:sharepics/src/pages/home_page.dart';

class AddTemplatePage extends StatefulWidget {
  AddTemplatePage({super.key});

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
  ImageProvider<Object>? _svgImage;
  String? nameValid;

  TextEditingController _ymlPathFieldController = TextEditingController();
  TextEditingController _nameFieldController = TextEditingController();
  TextEditingController _svgPathFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Template"),
      ),
      body: SingleChildScrollView(
        child: Container(
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
                            color: hasSvgImage()
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.errorContainer,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          image: hasSvgImage()
                              ? DecorationImage(
                                  image: _svgImage!, fit: BoxFit.contain)
                              : null),
                      alignment: Alignment.bottomLeft,
                      child: !hasSvgImage()
                          ? const Center(child: Text("Keine Vorlage gewählt"))
                          : null),
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
                          !(value.endsWith(".yml") ||
                              value.endsWith(".yaml")) ||
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
                        print(_svgBytes);
                        (await File(await globals.generateTemplateFilePath(
                                    "${_nameFieldController.value.text}.svg"))
                                .create(recursive: true))
                            .writeAsBytes(_svgBytes!);
                        (await File(await globals.generateTemplateFilePath(
                                    "${_nameFieldController.value.text}.yaml"))
                                .create(recursive: true))
                            .writeAsBytes(_ymlBytes!);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vorlage erstellt"),
                            showCloseIcon: true,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      }
                    },
                    label: const Text("Speichern"),
                    icon: const Icon(Icons.save),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool hasSvgImage() {
    if (_svgImage != null) {
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

      PictureInfo svgPictureInfo =
          (await vg.loadPicture(SvgBytesLoader(svgBytes), null));
      Uint8List imageBytes = Uint8List.view((await (await svgPictureInfo.picture
                  .toImage(svgPictureInfo.size.width.toInt(),
                      svgPictureInfo.size.height.toInt()))
              .toByteData(format: ui.ImageByteFormat.png))!
          .buffer);
      setState(() {
        _svgImage = MemoryImage(imageBytes);
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
