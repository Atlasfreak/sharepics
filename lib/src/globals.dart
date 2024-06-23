library sharepics.globals;

import 'package:path_provider/path_provider.dart';

const String templatesDir = "templates";
Future<String> Function() generateTemplatePath = () async =>
    "${(await getApplicationDocumentsDirectory()).path}/$templatesDir";

Future<String> generateTemplateFilePath(String fileName) async {
  return "${await generateTemplatePath()}/$fileName";
}
