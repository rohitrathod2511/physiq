import 'dart:io';

void main() {
  final file = File('C:/Users/rdrat/AppData/Local/Pub/Cache/hosted/pub.dev/iconsax_flutter-1.0.1/lib/iconsax_flutter.dart');
  final bytes = file.readAsBytesSync();
  final content = String.fromCharCodes(bytes).replaceAll('\u0000', '');
  final re = RegExp(r'static const ([\w_]+) = IconData');
  final matches = re.allMatches(content).map((m) => m.group(1)!).toList();
  List<String> keywords = ['weight', 'fire', 'energy', 'muscle', 'drop', 'water', 'oil', 'leaf', 'tree', 'plant'];
  for (final kw in keywords) {
    var found = matches.where((icon) => icon.toLowerCase().contains(kw)).toList();
    if (found.isNotEmpty) print('$kw: ${found.join(", ")}');
  }
}
