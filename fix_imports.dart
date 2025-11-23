import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final content = file.readAsStringSync();
    if (content.contains('package:physiq/utils/design_system.dart')) {
      final newContent = content.replaceAll('package:physiq/utils/design_system.dart', 'package:physiq/theme/design_system.dart');
      file.writeAsStringSync(newContent);
      print('Updated ${file.path}');
    }
  }
}
