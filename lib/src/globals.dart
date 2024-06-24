library sharepics.globals;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

const String templatesDir = "templates";
const String fontsDir = "fonts";
final RegExp fileNameRegex =
    RegExp(r"^(?:\/.*\/)(.*?)(?:\.svg)?$", unicode: true);
final RegExp dirNameRgex = RegExp(r"^(?:\/.*\/)(.*?)(?:\/)?$", unicode: true);
const double containerBorderRadius = 10;

Future<String> Function() generateTemplatePath = () async =>
    "${(await getApplicationDocumentsDirectory()).path}/$templatesDir";

Future<String> generateTemplateFilePath(String fileName) async {
  return "${await generateTemplatePath()}/$fileName";
}

Future<List<String>> listFonts() async {
  String fontsDirPath =
      "${(await getApplicationDocumentsDirectory()).path}/$fontsDir";
  List<String> fontDirs = (await (await Directory(fontsDirPath)
              .create(recursive: true))
          .list()
          .toList())
      .whereType<Directory>()
      .map(
        (e) => dirNameRgex.allMatches(e.path).toList()[0].group(1).toString(),
      )
      .toList();
  return fontDirs;
}
