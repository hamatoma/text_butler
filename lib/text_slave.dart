import 'text_butler_io.dart';
import 'dart:io';

void main(List<String> args) {
  List<String>? script;
  if (args.isEmpty) {
    script = [];
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      script.add(line!);
    }
  } else if (args[0] == '-h' || args[0] == '--help') {
    print('''Usage:
text_slave
  Reads the script from stdin and executes that.
text_slave --help
  Print this message.
text_slave <script_file>
  Reads the script from <script_file> and executes that.
''');
  } else {
    final filename = args[0];
    final file = File(filename);
    if (!file.existsSync()) {
      print('+++ script file not found: $filename');
    } else {
      script = file.readAsLinesSync();
    }
  }
  if (script != null) {
    final textButler = TextButlerIO();
    textButler.buffers['script'] = script.join('\n');
    textButler.execute('execute input=script');
    final output = textButler.getBuffer('output');
    if (output.isNotEmpty) {
      print(output);
    }
  }
}
