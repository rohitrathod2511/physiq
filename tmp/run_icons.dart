import 'dart:io';

void main() async {
  print('Starting icons generation...');
  final result = await Process.run('flutter', ['pub', 'run', 'flutter_launcher_icons:main']);
  print('Exit code: ${result.exitCode}');
  print('Stdout: ${result.stdout}');
  print('Stderr: ${result.stderr}');
}
