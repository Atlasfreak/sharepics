library sharepics.globals;

import 'package:path_provider/path_provider.dart';

const String templatesDir = "templates";
final RegExp fileNameRegex =
    RegExp(r"^(?:\/.*\/)(.*?)(?:\.svg)?$", unicode: true);
const double containerBorderRadius = 10;

Future<String> Function() generateTemplatePath = () async =>
    "${(await getApplicationDocumentsDirectory()).path}/$templatesDir";

Future<String> generateTemplateFilePath(String fileName) async {
  return "${await generateTemplatePath()}/$fileName";
}
