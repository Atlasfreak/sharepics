import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sharepics/src/components/svg_container.dart';
import 'package:sharepics/src/globals.dart' as globals;
import 'package:sharepics/src/pages/add_template_page.dart';
import 'package:yaml/yaml.dart';

class CreateSharepicPage extends StatefulWidget {
  String name;
  CreateSharepicPage({super.key, required this.name});

  @override
  State<CreateSharepicPage> createState() => _CreateSharepicPageState();
}

class _CreateSharepicPageState extends State<CreateSharepicPage> {
  File? _svgFile;
  String? _svgString;
  String? _originalSvgString;
  File? _yamlFile;
  dynamic _yamlData;
  final Map<String, String> _insertedTexts = {};
  final Map<String, File> _selectedImages = {};

  void _loadFiles() async {
    File svgFile =
        File(await globals.generateTemplateFilePath("${widget.name}.svg"));
    File yamlFile =
        File(await globals.generateTemplateFilePath("${widget.name}.yaml"));
    dynamic yamlData = loadYaml(await yamlFile.readAsString());
    String svgString = await svgFile.readAsString();

    setState(() {
      _svgFile = svgFile;
      _yamlFile = yamlFile;
      _yamlData = yamlData;
      _svgString = svgString;
      _originalSvgString = svgString;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _insertText(String key, String value) {
    if (_originalSvgString == null) return;
    _insertedTexts[key] = value;
    _svgString = _originalSvgString;
    _insertedTexts.forEach((key, value) {
      _svgString = _svgString!.replaceAll("{{$key}}", value);
    });
    setState(() {});
  }

  Future<ByteData?> _createImage(BuildContext context) async {
    return await (await (await vg.loadPicture(
                SvgStringLoader(_svgString!), context))
            .picture
            .toImage(_yamlData!["dimensions"]["width"],
                _yamlData!["dimensions"]["height"]))
        .toByteData(format: ImageByteFormat.png);
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
                  child: _svgString == null
                      ? const Center(child: CircularProgressIndicator())
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(
                              globals.containerBorderRadius),
                          child: SvgPicture.string(_svgString!),
                        ),
                ),
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
                    );
                  },
                  physics: const NeverScrollableScrollPhysics(),
                ),
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
                    return TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _yamlData["images"]
                            [_yamlData["images"].keys.toList()[index]]["name"],
                        border: const UnderlineInputBorder(),
                      ),
                    );
                  },
                  itemCount: _yamlData?["images"].keys.length ?? 0,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
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
