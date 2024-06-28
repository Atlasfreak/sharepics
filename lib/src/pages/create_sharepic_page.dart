import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sharepics/src/components/svg_container.dart';
import 'package:sharepics/src/globals.dart' as globals;
import 'package:sharepics/src/pages/add_template_page.dart';
import 'package:yaml/yaml.dart';

class CreateSharepicPage extends StatefulWidget {
  final String name;
  const CreateSharepicPage({super.key, required this.name});

  @override
  State<CreateSharepicPage> createState() => _CreateSharepicPageState();
}

class _CreateSharepicPageState extends State<CreateSharepicPage> {
  String? _svgString;
  String? _originalSvgString;
  dynamic _yamlData;
  final Map<String, String> _insertedTexts = {};
  final Map<String, XFile> _selectedImages = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;

  Future _loadFiles() async {
    File svgFile =
        File(await globals.generateTemplateFilePath("${widget.name}.svg"));
    File yamlFile =
        File(await globals.generateTemplateFilePath("${widget.name}.yaml"));
    dynamic yamlData = loadYaml(await yamlFile.readAsString());
    String svgString = await svgFile.readAsString();

    setState(() {
      _yamlData = yamlData;
      _svgString = svgString;
      _originalSvgString = svgString;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFiles().then((value) {
      for (var key in _yamlData?["images"].keys ?? []) {
        _controllers[key] = TextEditingController();
      }
    });
  }

  void _updateSvgString() async {
    if (_originalSvgString == null) return;
    _svgString = _originalSvgString;
    _insertedTexts.forEach((key, value) {
      _svgString = _svgString!.replaceAll("{{$key}}", value);
    });
    for (var key in _selectedImages.keys) {
      XFile? value = _selectedImages[key];
      if (value == null) continue;
      _svgString = _svgString!.replaceAll("{{$key}}",
          "data:image/png;base64,${base64.encode(await value.readAsBytes())}");
    }
    setState(() {
      _loading = false;
    });
  }

  void _insertText(String key, String value) {
    if (_originalSvgString == null) return;
    setState(() {
      _loading = true;
    });
    if (_yamlData["inputs"][key]["lines"] != null &&
        _yamlData["inputs"][key]["lines"] > 1) {
      var lines = value.split("\n");
      for (var i = 0; i < lines.length; i++) {
        _insertedTexts["$key${i + 1}"] = lines[i];
      }
    } else {
      _insertedTexts[key] = value;
    }
    _updateSvgString();
    setState(() {});
  }

  void _selectImage(String key) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ["png", "jpg", "jpeg"],
    );
    if (result == null) return;
    setState(() {
      _loading = true;
    });
    XFile file = result.files.first.xFile;
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: file.path,
      maxHeight: _yamlData["images"][key]["height"],
      maxWidth: _yamlData["images"][key]["width"],
      aspectRatio: CropAspectRatio(
        ratioX: (_yamlData["images"][key]["width"] as int).toDouble(),
        ratioY: (_yamlData["images"][key]["height"] as int).toDouble(),
      ),
    );
    if (croppedImage == null) return;

    _selectedImages[key] = XFile.fromData(await croppedImage.readAsBytes());

    setState(() {
      _controllers[key]!.text = result.files.first.name;
    });
    _updateSvgString();
  }

  Future<ByteData?> _createImage(BuildContext context) async {
    return await (await (await vg.loadPicture(
                SvgStringLoader(_svgString!), context))
            .picture
            .toImage(_yamlData!["dimensions"]["width"],
                _yamlData!["dimensions"]["height"]))
        .toByteData(format: ImageByteFormat.png);
  }

  List<Widget>? _createTextFields() {
    if ((_yamlData?["inputs"]?.keys.length ?? 0) <= 0) return null;
    return [
      const SizedBox(
        height: 20,
      ),
      const Center(
        child: Text(
          "Text eingeben:",
          style: TextStyle(fontSize: 20),
        ),
      ),
      const SizedBox(
        height: 10,
      ),
      ListView.builder(
        shrinkWrap: true,
        itemCount: _yamlData?["inputs"].keys.length ?? 0,
        itemBuilder: (context, index) {
          var key = _yamlData["inputs"].keys.toList()[index];
          var input = _yamlData["inputs"][key];
          return TextFormField(
            decoration: InputDecoration(
              labelText: input["name"] ?? key,
              border: const UnderlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            maxLength: input["max_length"],
            onChanged: (value) {
              _insertText(
                key,
                value,
              );
            },
            minLines: 1,
            maxLines: input["lines"] ?? 1,
          );
        },
        physics: const NeverScrollableScrollPhysics(),
      ),
    ];
  }

  List<Widget>? _createImageFields() {
    if ((_yamlData?["images"]?.keys.length ?? 0) <= 0) return null;
    return [
      const SizedBox(
        height: 20,
      ),
      const Center(
        child: Text(
          "Bilder auswählen:",
          style: TextStyle(fontSize: 20),
        ),
      ),
      const SizedBox(
        height: 10,
      ),
      ListView.builder(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          var key = _yamlData["images"].keys.toList()[index];
          return TextFormField(
            controller: _controllers[key],
            readOnly: true,
            decoration: InputDecoration(
              labelText: _yamlData["images"][key]["name"],
              border: const UnderlineInputBorder(),
            ),
            onTap: () {
              _selectImage(key);
            },
          );
        },
        itemCount: _yamlData?["images"].keys.length ?? 0,
        physics: const NeverScrollableScrollPhysics(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sharepic erstellen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return AddTemplatePage(name: widget.name);
                  },
                ),
              ).then((value) => _loadFiles());
            },
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Vorlage löschen"),
                    content: const Text(
                        "Möchtest du diese Vorlage wirklich löschen?"),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await File(await globals.generateTemplateFilePath(
                                    "${widget.name}.svg"))
                                .delete();
                            await File(await globals.generateTemplateFilePath(
                                    "${widget.name}.yaml"))
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text("Löschen")),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Abbrechen")),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                SvgContainer(
                  borderColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: _svgString == null || _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(
                              globals.containerBorderRadius),
                          child: SvgPicture.string(_svgString!),
                        ),
                ),
                ...?_createTextFields(),
                ...?_createImageFields(),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_svgString == null || _yamlData == null) return;
                        ByteData? imageBytes = await _createImage(context);
                        if (imageBytes == null) return;
                        String? result = await FilePicker.platform.saveFile(
                          fileName: "${widget.name}.png",
                          type: FileType.image,
                          allowedExtensions: ["png"],
                          bytes: imageBytes.buffer.asUint8List(),
                        );
                        if (result == null) return;
                        if (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS) {
                          await XFile.fromData(imageBytes.buffer.asUint8List())
                              .saveTo(result);
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Bild gespeichert unter: $result"),
                            showCloseIcon: true,
                          ),
                        );
                      },
                      label: const Text("Sharepic erstellen"),
                      icon: const Icon(Icons.save_alt),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_svgString == null || _yamlData == null) return;
                        ByteData? imageBytes = await _createImage(context);
                        if (imageBytes == null) return;
                        XFile imageFile = XFile.fromData(
                            imageBytes.buffer.asUint8List(),
                            mimeType: "image/png");
                        await Share.shareXFiles([imageFile]);
                      },
                      label: const Text("Teilen"),
                      icon: const Icon(Icons.share),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
