//import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';
import 'dart:io';
//import 'package:text_butler/text_butler.dart';
import 'package:text_butler/text_butler_io.dart';

void main() {
  group('TextButlerIO-load', () {
    test('simple load', () {
      final butler = TextButlerIO();
      final fnTemp = Directory.systemTemp.path +
          Platform.pathSeparator +
          'textbutler.load.txt';
      final content = 'abc\ndef\n123';
      File(fnTemp).writeAsStringSync(content);
      expect(butler.execute('load output=input file="$fnTemp"'), isNull);
      expect(content, butler.getBuffer('input'));
    });
    test('error: not existing file', () {
      final butler = TextButlerIO();
      final fnTemp = '<not.existing!>';
      expect(butler.execute('load output=input file="$fnTemp"'),
          'missing file "$fnTemp"');
    });
  });
  group('TextButlerIO-store', () {
    test('simple storage', () {
      final butler = TextButlerIO();
      butler.buffers['input'] = 'abc\n123\n';
      final fnTemp = Directory.systemTemp.path +
          Platform.pathSeparator +
          'textbutler.store.txt';
      expect(butler.execute('store input=input file="$fnTemp"'), isNull);
      final file = File(fnTemp);
      expect(file, isNotNull);
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, butler.buffers['input']);
    });
    test('error: illegal filename', () {
      final butler = TextButlerIO();
      expect(
          butler.execute('store input=input file="/tmp"'),
          'executeStore(): FileSystemException: Cannot open file, '
          "path = '/tmp' (OS Error: Is a directory, errno = 21)");
    });
  });
}
