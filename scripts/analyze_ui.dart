import 'dart:io';

void main() {
  final dir = Directory('lib');
  final issues = <String>[];
  
  void scan(Directory d) {
    for (var entity in d.listSync()) {
      if (entity is Directory) {
        scan(entity);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        final content = entity.readAsStringSync();
        final lines = content.split('\n');
        
        bool inColumn = false;
        int columnDepth = 0;

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          
          if (line.contains('Column(') || line.contains('Column (')) {
            columnDepth++;
          }
          if (line.contains(')')) {
            // this is too naive, but we can look for specific patterns
          }
          
          // A simple regex to catch common anti-pattern: ListView right after children: [ without Expanded
          if (RegExp(r'children:\s*\[[^\]]*ListView\.builder').hasMatch(content.replaceAll('\n', ' '))) {
            issues.add('${entity.path}: Potential unbounded ListView in Column/Row');
          }
        }
      }
    }
  }
  
  scan(dir);
  for (var issue in issues.toSet()) {
    print(issue);
  }
}
