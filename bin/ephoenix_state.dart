import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: ephoenix_state <state_name>');
    stderr.writeln('Example: ephoenix_state home_state');
    exit(1);
  }

  final name = args.first;
  final fileName = '$name.dart';
  final className = _toPascalCase(name);

  final file = File(fileName);
  if (file.existsSync()) {
    stderr.writeln('Error: $fileName already exists.');
    exit(1);
  }

  final content = '''import 'package:ephoenix_state/ephoenix_state.dart';

part '$name.ephoenix_state.dart';

@ephoenixState
abstract class $className with _\$$className {
  const $className._();

  const factory $className({

  }) = _$className;
}
''';

  file.writeAsStringSync(content);
  stdout.writeln('Created $fileName');
}

String _toPascalCase(String input) {
  return input
      .split('_')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join();
}
