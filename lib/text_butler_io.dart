import 'dart:io';

import 'text_butler.dart';

/// Implements a text processor that interprets "commands" to convert
/// an input string into another.
/// Administrates "buffers" that can store intermediate results.
///
class TextButlerIO extends TextButler {
  static final examplesIO = <String>[
    '',
    'load output=data file="data.txt" append',
    '',
    'store input=data file="data.txt append',
    '',
  ];
  @override
  List<String> get examples {
    final rc = super.examples + examplesIO;
    return rc;
  }

  /// Executes the command [commandName] with the [parameters].
  /// This method must be overridden by classes to implement other commands.
  @override
  bool dispatch(String? commandName, String parameters) {
    var toHistory = true;
    switch (commandName) {
      case 'load':
        toHistory = false;
        executeLoad(parameters);
        break;
      case 'store':
        executeStore(parameters);
        break;
      default:
        super.dispatch(commandName, parameters);
    }
    return toHistory;
  }

  /// Implements the command "load" specified by some [parameters].
  /// Throws an exception on errors.
  void executeLoad(String parameters) {
    // 'load output=data file=/home/data.txt',
    final expected = {
      'append': paramBool,
      'file': paramString,
      'output': paramBufferName,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final filename = current.asString('file');
    File file2 = File(filename);
    if (!file2.existsSync()) {
      throw WordingError('missing file "$filename"');
    }
    store(current, file2.readAsStringSync());
  }

  /// Implements the command "store" specified by some [parameters].
  /// Throws an exception on errors.
  void executeStore(String parameters) {
    // 'store input=data file=/home/data.txt',
    final expected = {
      'append': paramBool,
      'file': paramString,
      'input': paramBufferName,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('input', 'output');
    checkParameters(current, expected);
    final filename = current.asString('file');
    File file2 = File(filename);
    bool append = current.asBool('append');
    try {
      file2.writeAsStringSync(getBuffer(current.asString('input')),
          mode: append ? FileMode.append : FileMode.writeOnly);
    } on FileSystemException catch (exc) {
      throw InternalError('executeStore()', exc.toString());
    }
  }
}
