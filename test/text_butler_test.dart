import 'package:test/test.dart';
import 'package:text_butler/text_butler.dart';

class TestLogger extends Logger {
  @override
  bool log(String message) {
    print('+++ $message');
    return true;
  }

  @override
  void clear() {
    // do nothing
  }
}

final logger = TestLogger();
void main() {
  group('ParameterSet', () {
    final butler = TextButler();
    final set = ParameterSet(
        {
          'intList': ParameterValue(ParameterType.natList, natList: [10, 19]),
          'stringList':
              ParameterValue(ParameterType.stringList, list: <ParameterValue>[
            ParameterValue(ParameterType.string, string: 'adam'),
            ParameterValue(ParameterType.string, string: 'berta'),
            ParameterValue(ParameterType.string, string: 'charly'),
          ])
        },
        butler,
        {
          'intList': ParameterInfo(ParameterType.natList, delimited: false),
          'intList2': ParameterInfo(ParameterType.natList, delimited: false),
          'stringList': ParameterInfo(ParameterType.stringList,
              delimited: false, autoSeparator: true),
        });
    test('asListMemberInt', () {
      expect(set.asListMemberInt('intList', 0), 10);
      expect(set.asListMemberInt('intList', 1), 19);
      expect(set.asListMemberInt('intList2', 1, defaultValue: 99), 99);
    });
    test('countOfList', () {
      expect(set.countOfList('stringList'), 3);
      expect(set.countOfList('intList'), 2);
    });
  });
  group('TextButler-basics', () {
    final butler = TextButler();
    final expected = {
      'name': ParameterInfo(ParameterType.string,
          minLength: 2,
          maxLength: 8,
          pattern: RegExp(r'^[A-Z][a-z]*$'),
          patternError:
              'not a name: only letters are allowed, starting with upper case'),
      'number': ParameterInfo(ParameterType.nat),
      'stringList': ParameterInfo(ParameterType.stringList,
          minLength: 1, maxLength: 2, autoSeparator: true, delimited: false),
      'intList':
          ParameterInfo(ParameterType.natList, minLength: 1, maxLength: 2),
      'boolean': ParameterInfo(ParameterType.bool),
    };
    final expected2 = <String, ParameterInfo>{
      'meta': butler.paramMeta,
      'append': butler.paramBool,
      'value': butler.paramString,
      'variable': butler.paramString,
      'Values': butler.paramStringListAutoSeparator,
    };
    final names2 = butler.namesOf(expected2);
    test('splitArguments', () {
      ParameterSet set;
      butler.stringParameters = 'meta=% app value=/a b/ Values=,"one","two"';
      expect(set = butler.splitParameters(expected2), isNotNull);
      expect(set.map['meta']!.string, '%');
      expect(set.map['append']!.parameterType, ParameterType.bool);
      expect(set.map['value']!.string, 'a b');
      expect(set.map['Values']!.list!.length, 2);
      expect(set.map['Values']!.list![1].string, 'two');
      expect(butler.errorMessage, isNull);
    });
    test('expandParameter', () {
      expect(butler.expandParameter('me', names2), 'meta');
      expect(butler.errorMessage, isNull);
    });
    test('expandParameter-ambiguous', () {
      try {
        butler.expandParameter('va', names2);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage, 'ambiguous parameter "va": value/variable');
      }
    });
    test('expandCommand', () {
      expect(butler.expandCommand('sh'), 'show');
      expect(butler.errorMessage, isNull);
    });
    test('expandCommand-ambiguous', () {
      try {
        butler.expandCommand('s');
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage, 'ambiguous command "s": show/sort/swap');
      }
    });
    test('checkParameters-success', () {
      butler.stringParameters =
          'name="Jonny" number=24 boolean stringList=,"one","two" intList=2,4';
      butler.checkParameters(butler.splitParameters(expected), expected);
      expect(butler.errorMessage, isNull);
    });
    test('checkParameters-string-errors', () {
      try {
        butler.stringParameters = 'name=?Wr.name?';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage,
            'not a name: only letters are allowed, starting with upper case');
      }
      try {
        butler.stringParameters = 'name="K"';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(
            exc.theMessage, 'parameter "name" is too short (2): [string]: K');
      }
      try {
        butler.stringParameters = 'name="VeryLongName"';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage,
            'parameter "name" is too long (8): [string]: VeryLongName');
      }
    });
    test('checkParameters-int-error', () {
      butler.stringParameters = 'number=one';
      try {
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage,
            'parameter "number": non negative number expected, not one');
      }
    });
    test('checkParameters-stringList-error', () {
      try {
        butler.stringParameters = 'stringList=one';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage,
            'parameter "stringList": separator not allowed character: o');
      }
    });
    test('checkParameters-intList-error', () {
      try {
        butler.stringParameters = 'intList=one,two';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.theMessage,
            'parameter "intList": not a non negative number in natList: one');
      }
    });
  });
  group('TextButler-rest', () {
    final butler = TextButler();
    butler.buffers['animals'] = 'cat\ndog';
    butler.buffers['Numbers'] = 'one\ntwo';
    butler.buffers['jonny'] = 'abc';
    test('show', () {
      expect(butler.execute('show'), isNull);
      expect(butler.buffers['output'],
          'Numbers\nanimals\nexamples\nhistory\ninput\njonny\nlog\noutput');
    });
    test('swap', () {
      expect(butler.execute('swap a=animals b=Numbers'), isNull);
      expect(butler.buffers['Numbers'], 'cat\ndog');
      expect(butler.buffers['animals'], 'one\ntwo');
    });
    test('clear', () {
      expect(butler.execute('clear output=jonny'), isNull);
      expect(butler.buffers['jonny'], '');
    });
    test('clear-not existing', () {
      expect(butler.execute('clear output=missing'), isNull);
      expect(butler.buffers['missing'], '');
    });
  });
  group('TextButler-copy', () {
    final butler = TextButler();
    butler.buffers['input'] = 'abc\n123\n';
    test('minimal', () {
      expect(butler.execute('copy'), isNull);
      expect(butler.buffers['output'], 'abc\n123\n');
    });
    test('append to new target', () {
      expect(butler.execute('copy output=Any append'), isNull);
      expect(butler.buffers['Any'], 'abc\n123\n');
    });
    test('append to existing target', () {
      expect(butler.execute('copy output=x'), isNull);
      expect(butler.execute('copy o=x a'), isNull);
      expect(butler.buffers['x'], 'abc\n123\nabc\n123\n');
    });
    test('text', () {
      expect(butler.execute('copy text="Hi!" output=y'), isNull);
      expect(butler.buffers['y'], 'Hi!');
    });
    test('text with meta symbols', () {
      expect(
          butler.execute(r'copy text=i%"Hi!%n%t1%v2%f3%r" output=y'), isNull);
      expect(butler.buffers['y'], 'Hi!\n\t1\v2\f3\r');
    });
    test('max. count of parameters', () {
      butler.buffers['src'] = 'Hello world!';
      butler.buffers['trg'] = 'Saludos amigos! ';
      expect(butler.execute(r'copy i=src append output=trg'), isNull);
      expect(butler.buffers['trg'], 'Saludos amigos! Hello world!');
    });
    test('copy-example', () {
      butler.buffers['input'] = 'Hello World';
      butler.buffers['todo'] = 'Greetings';
      expect(butler.execute(r'copy text=i%"%n" out=todo append'), isNull);
      expect(butler.execute(r'copy out=todo append'), isNull);
      expect(butler.buffers['todo'], 'Greetings\nHello World');
      expect(butler.execute(r'copy text="Hi Jonny!"'), isNull);
      expect(butler.buffers['output'], 'Hi Jonny!');
    });
  });
  group('TextButler-count', () {
    final butler = TextButler();
    test('"regexpr" is defined, default marker, template defined', () {
      butler.buffers['input'] = ' 123\n4 5';
      expect(butler.execute(r'count what=r/ \d+/ template="count: #"'), isNull);
      expect(butler.buffers['output'], 'count: 2');
    });
    test('"what" is defined, default template', () {
      butler.buffers['input'] = '1 2 3 4 5\n';
      expect(butler.execute(r'count what=" "'), isNull);
      expect(butler.buffers['output'], '4');
    });
    test('max. parameters', () {
      butler.buffers['trg'] = '===\n';
      butler.buffers['src'] = '''Line1
start:
 e2
 E9
END
e33
''';
      expect(
          butler.execute('count i=src out=trg append marker=& '
              r'template="count: &" what=R/e\d/'),
          isNull);
      expect(butler.buffers['trg'], '===\ncount: 4');
    });
  });
  group('TextButler-duplicate', () {
    final butler = TextButler();
    test('%valuesX%', () {
      butler.buffers['input'] =
          'animal %value0% named %value1% comes from %value2%.\n';
      expect(
          butler.execute(
              'duplicate count=2 ListValues=;,"cat","dog";,"Mia","Harro";,"London","Rome"'),
          isNull);
      expect(butler.buffers['output'],
          'animal cat named Mia comes from London.\nanimal dog named Harro comes from Rome.\n');
    });
    test('%index% %number% %char%', () {
      butler.buffers['input'] = 'no: %index% id: %number% place: %char%\n';
      butler.buffers['output'] = '= List:\n';
      expect(
          butler.execute(
              'duplicate count=2 offset=100 step=10 baseChar=Q append'),
          isNull);
      expect(butler.buffers['output'],
          '= List:\nno: 0 id: 100 place: Q\nno: 1 id: 110 place: R\n');
    });
    test('!index! !number0! !char0! !char1!', () {
      butler.buffers['input'] =
          'no: !index! id: !number0! place !char0! key: !char1!!char1!!char1!\n';
      expect(
          butler.execute(
              'duplicate count=3 Offsets=10,0 Steps=5,1 BaseChar="Ak" meta=! out=list'),
          isNull);
      expect(butler.buffers['list'],
          'no: 0 id: 10 place A key: kkk\nno: 1 id: 15 place B key: lll\nno: 2 id: 20 place C key: mmm\n');
    });
    test('%numberX% %charX% value', () {
      butler.buffers['input'] = 'abc %index% %char0% %number1% %value% 123\n';
      expect(
          butler.execute(
              'duplicate count=2 Offsets=1,2 BaseChars="XX" Steps=1,10 Values=,"one","two"'),
          isNull);
      expect(
          butler.buffers['output'], 'abc 0 X 2 one 123\nabc 1 Y 12 two 123\n');
    });
    test('%number% %value%', () {
      butler.buffers['input'] = 'animal %number%: %value%\n';
      expect(butler.execute('duplicate count=2 offset=1 Values=,"cat","dog"'),
          isNull);
      expect(butler.buffers['output'], 'animal 1: cat\nanimal 2: dog\n');
    });
    test('max. parameters one current value', () {
      butler.buffers['src'] = '&index&: &number&: &value& &char&\n';
      butler.buffers['trg'] = '===\n';
      expect(
          butler.execute('duplicate app baseChar=X count=2 i=src m=& ou=trg '
              'offset=3 Values=,"cat","dog" step=2'),
          isNull);
      expect(butler.buffers['trg'], '===\n0: 3: cat X\n1: 5: dog Y\n');
    });
    test('max. parameters two current values', () {
      butler.buffers['src'] = '+index+: +number0+&+number1+: '
          '+value0+/+value1+ +char0+ +char1+\n';
      butler.buffers['trg'] = '===\n';
      expect(
          butler.execute(
              'duplicate app BaseChars="wF" count=2 i=src m=+ ou=trg '
              'Offsets=20,10 ListValues=;,"cat","dog";,"Mia","Wuff" Steps=2,4'),
          isNull);
      expect(butler.buffers['trg'],
          '===\n0: 20&10: cat/Mia w F\n1: 22&14: dog/Wuff x G\n');
    });
  });
  group('TextButler-execute', () {
    final butler = TextButler();
    test('sql-replace', () {
      butler.buffers['sql'] = '''SELECT
  pp.project_title, pp.project_end,
  (SELECT sum(workinghour_hours) 
    FROM workinghours w2 WHERE w2.workinghour_id = ww.workinghour_id) AS hours
FROM projects pp
  LEFT JOIN workinghours ww ON ww.project_id=pp.project_id
WHERE
  ww.workinghour_start >= :from AND ww.workinghour_start < :to
  AND pp.project_customerid = :customer
;
''';
      butler.buffers['input'] =
          '''replace i=sql What=;":from";"'2021-06-01'";":to";"'2021-07-01'";':customer';"1133"
''';
      expect(butler.execute('execute'), isNull);
      expect(butler.getBuffer('output'), '''SELECT
  pp.project_title, pp.project_end,
  (SELECT sum(workinghour_hours) 
    FROM workinghours w2 WHERE w2.workinghour_id = ww.workinghour_id) AS hours
FROM projects pp
  LEFT JOIN workinghours ww ON ww.project_id=pp.project_id
WHERE
  ww.workinghour_start >= '2021-06-01' AND ww.workinghour_start < '2021-07-01'
  AND pp.project_customerid = 1133
;
''');
    });
    test('simple', () {
      butler.buffers['input'] = '''copy out=script text="Hi "
copy append out=script text="world"''';
      expect(butler.execute('execute'), isNull);
      expect(butler.getBuffer('script'), 'Hi world');
    });
    test('from examples', () {
      butler.buffers['script'] =
          '''copy text=i~"%index%: Id: id%number% Name: %char%%char%%char%~n" output=template
duplicate input=template count=3 offset=1 baseChar=A''';
      expect(butler.execute('execute input=script'), isNull);
      expect(butler.getBuffer('output'), '''0: Id: id1 Name: AAA
1: Id: id2 Name: BBB
2: Id: id3 Name: CCC
''');
    });
  });
  group('TextButler-filter', () {
    final butler = TextButler();
    butler.buffers['input'] = '''<?xml version="1.0" encoding="UTF-8"?>
<staff>
  <company>
    <name>Easy Rider</name>
  </company>
  <person>
    <id>1</id>
    <name>Adam</name>
  </person>
  <person>
    <id>2</id>
    <name>Berta</name>
  </person>
  <person>
    <id>3</id>
    <name>Charly</name>
  </person>
</staff>
''';
    test('without start/end', () {
      expect(butler.execute('filter fi=/name/'), isNull);
      expect(butler.buffers['output'], '''    <name>Easy Rider</name>
    <name>Adam</name>
    <name>Berta</name>
    <name>Charly</name>
''');
    });
    test('start + end', () {
      expect(
          butler.execute(
              'filter start=/<person/ end=!</person! fi=/name/ repeat=2'),
          isNull);
      expect(butler.buffers['output'], '''    <name>Adam</name>
    <name>Berta</name>
''');
    });
    test('template', () {
      expect(
          butler.execute(
              'filter start=/<person/ end=!</person! fi=/<(name|id)>(.*?)</ repeat=2 template="%group1%: %group2%\n"'),
          isNull);
      expect(butler.buffers['output'], '''id: 1
name: Adam
id: 2
name: Berta
''');
    });
    test('Filters', () {
      expect(
          butler.execute('filter start=/<person/ end=!</person! '
              'Filters=;"<name";"<id" repeat=2'),
          isNull);
      expect(butler.buffers['output'], '''    <id>1</id>
    <name>Adam</name>
    <id>2</id>
    <name>Berta</name>
''');
    });
    test('Filters + Templates', () {
      expect(
          butler.execute('filter start=/<person/ end=!</person! '
              'Filters=;r/<(name)>(.*?)</;r/<id>(.*?)</ '
              'repeat=2 Templates=;i~"%1%: %2%~n";i~"no: %1%~n"'),
          isNull);
      expect(butler.buffers['output'], '''no: 1
name: Adam
no: 2
name: Berta
''');
    });
    test('max. parameters with filter', () {
      butler.buffers['src'] = '''line1
Start:
count: 34
id: 88
End:
''';
      butler.buffers['trg'] = '<<<\n';
      expect(
          butler.execute(r'filter app s=R/^st/ en=R!^end! f=r/(\w+): (\d+)/ '
              r'i=src m=& o=trg r=2 template="* &1&/&group2&"'),
          isNull);
      expect(butler.buffers['trg'], '<<<\n* count/34* id/88');
    });
  });
  group('TextButler-replace', () {
    final butler = TextButler();
    test('all parameters', () {
      butler.buffers['src'] = 'entry1 in line1\nentry2 in line2';
      butler.buffers['trg'] = '###\n';
      expect(
          butler.execute('replace a i=src o=trg m=& '
              r'What=;I"l";"L";R/([a-z]+)(\d+)/;"&1&=&group2&"'),
          isNull);
      expect(
          butler.getBuffer('trg'), '###\nentry=1 in Line=1\nentry=2 in Line=2');
    });
  });
  group('TextButler-interpreted text', () {
    final butler = TextButler();
    test('simple', () {
      butler.buffers['name'] = 'Joe';
      expect(butler.execute('copy text=i~"Hi ~[name]!"'), isNull);
      expect(butler.getBuffer('output'), 'Hi Joe!');
    });
  });
  group('SortInfo', () {
    test('char-one-range', () {
      final info = SortInfo(logger, 'c', [SortRange(1, 2, false)]);
      expect(info.sort('B12\nA3\nC222'.split('\n')), 'B12\nC222\nA3');
    });
    test('char-one-range-numeric', () {
      final info = SortInfo(logger, 'c', [SortRange(1, 2, true)]);
      expect(info.sort('B12\nA3\nC222'.split('\n')), 'A3\nB12\nC222');
    });
    test('word-3-ranges', () {
      final lines = 'x 12 xyz\na 12 abc\nb 13 abc'.split('\n');
      var info = SortInfo(logger, 'w', [
        SortRange(0, 0, false),
        SortRange(1, 1, false),
        SortRange(2, 2, false)
      ]);
      expect(info.sort(lines), 'a 12 abc\nb 13 abc\nx 12 xyz');
      info = SortInfo(logger, 'w', [
        SortRange(1, 1, false),
        SortRange(0, 0, false),
        SortRange(2, 2, false)
      ]);
      expect(info.sort(lines), 'a 12 abc\nx 12 xyz\nb 13 abc');
      info = SortInfo(logger, 'w', [
        SortRange(2, 2, false),
        SortRange(0, 0, false),
        SortRange(1, 1, false)
      ]);
      expect(info.sort(lines), 'a 12 abc\nb 13 abc\nx 12 xyz');
    });
    test('word-3-ranges-numeric', () {
      final lines = '12 3.2 777\n111 3.20 80.20\n999 2 80.2'.split('\n');
      var info = SortInfo(logger, 'w', [
        SortRange(0, 0, true),
        SortRange(1, 1, true),
        SortRange(2, 2, true)
      ]);
      expect(info.sort(lines), '12 3.2 777\n111 3.20 80.20\n999 2 80.2');
      info = SortInfo(logger, 'w', [
        SortRange(1, 1, true),
        SortRange(0, 0, true),
        SortRange(2, 2, true)
      ]);
      expect(info.sort(lines), '999 2 80.2\n12 3.2 777\n111 3.20 80.20');
      info = SortInfo(logger, 'w', [
        SortRange(2, 2, true),
        SortRange(0, 0, true),
        SortRange(1, 1, true)
      ]);
      expect(info.sort(lines), '111 3.20 80.20\n999 2 80.2\n12 3.2 777');
    });
    test('regexp-2-ranges-mixed-alnum-num', () {
      final lines =
          'name: joe *id: 12\n*name: bob id: 8\nname: charly id: 1'.split('\n');
      final regExp = RegExp(r'name: (\S+).*id: (\d+)');
      var info = SortInfo(
          logger, 'r', [SortRange(1, 1, true), SortRange(0, 0, false)],
          filter: regExp);
      expect(info.sort(lines),
          'name: charly id: 1\n*name: bob id: 8\nname: joe *id: 12');
      info = SortInfo(
          logger, 'r', [SortRange(0, 0, false), SortRange(1, 1, true)],
          filter: regExp);
      expect(info.sort(lines),
          '*name: bob id: 8\nname: charly id: 1\nname: joe *id: 12');
    });
    test('word-separator', () {
      final lines = 'Charly,22\nBob,222\nAda,20'.split('\n');
      final separator = RegExp(r',');
      var info = SortInfo(
          logger, 'w', [SortRange(0, 0, false), SortRange(1, 1, true)],
          separator: separator);
      expect(info.sort(lines), 'Ada,20\nBob,222\nCharly,22');
      info = SortInfo(
          logger, 'w', [SortRange(1, 1, true), SortRange(0, 0, false)],
          separator: separator);
      expect(info.sort(lines), 'Ada,20\nCharly,22\nBob,222');
    });
  });
  group('TextButler-sort', () {
    final butler = TextButler();
    test('simple', () {
      butler.buffers['input'] = 'd\nc\na\nb';
      expect(butler.execute('sort'), isNull);
      expect(butler.getBuffer('output'), 'a\nb\nc\nd');
    });
    test('simple-numeric', () {
      butler.buffers['input'] = '10\n3\n2\n4\n1';
      expect(butler.execute('sort ranges="n"'), isNull);
      expect(butler.getBuffer('output'), '1\n2\n3\n4\n10');
    });
    test('word-two-ranges-numeric-and-alnum', () {
      butler.buffers['input'] = '10,joe,adm\n3,bob,adm\n2,charly,usr';
      expect(butler.execute(r'sort ranges="n1,2-3" sep=r/\s*,\s*/'), isNull);
      expect(butler.getBuffer('output'), '2,charly,usr\n3,bob,adm\n10,joe,adm');
    });
    test('sort-examples', () {
      butler.buffers['data'] =
          '''home: dirs: 122 hidden-dirs: 29 files: 38299 MBytes: 1203.042
opt: dirs: 29 files: 1239 MBytes: 123.432
data: dirs: 4988 files: 792374 MBytes: 542034.774''';
      expect(
          butler.execute(
              r'sort input=data Filters=;r/MBytes: ([\d.]+)/;r/dirs: (\d+)/;r/files: (\d+)/ ranges="n1,n1,n1"'),
          isNull);
      expect(butler.getBuffer('output'),
          '''opt: dirs: 29 files: 1239 MBytes: 123.432
home: dirs: 122 hidden-dirs: 29 files: 38299 MBytes: 1203.042
data: dirs: 4988 files: 792374 MBytes: 542034.774''');

      butler.buffers['input'] = '''name: joe id: 3 year: 2016
Name: bob shortname: BOB id: 12 year: 2021
* name: charly id: 13 year: 2020''';
      expect(
          butler.execute(
              r'sort ranges="1,n2-3" filter=R/name: (\w+) id: (\d+) year: (\d+)/'),
          isNull);
      expect(butler.getBuffer('output'),
          '''Name: bob shortname: BOB id: 12 year: 2021
* name: charly id: 13 year: 2020
name: joe id: 3 year: 2016''');

      butler.buffers['input'] = '1234abc89Aabc\n1234567890abc\n123XABC89Aabc';
      expect(butler.execute(r'sort output=sorted ranges="1-4,8-10"'), isNull);
      expect(butler.getBuffer('sorted'),
          '1234567890abc\n1234abc89Aabc\n123XABC89Aabc');

      butler.buffers['sorted'] =
          'male,10,joe,adm\nmale,3,bob,adm\nfemale,2,charly,usr';
      expect(
          butler.execute(r'sort input=sorted ranges="3-4,n2,1" separator=","'),
          isNull);
      expect(butler.getBuffer('output'),
          'male,3,bob,adm\nfemale,2,charly,usr\nmale,10,joe,adm');

      butler.buffers['input'] =
          'male, 10,joe , 101\nmale, 3,divers, bob,87\nfemale, 2, charly, 53';
      expect(
          butler.execute(r'sort ranges="3,n4,1" separator=r/\s*,\s*/'), isNull);
      expect(butler.getBuffer('output'),
          'female, 2, charly, 53\nmale, 3,divers, bob,87\nmale, 10,joe , 101');
    });
  });
  group('TextButler-reverse', () {
    final butler = TextButler();
    test('simple', () {
      butler.buffers['input'] = '1\n2\n3';
      expect(butler.execute('reverse'), isNull);
      expect(butler.getBuffer('output'), '3\n2\n1');
    });
  });
  group('TextButler-insert', () {
    final butler = TextButler();
    test('at', () {
      butler.buffers['input'] = '1\n2\n3';
      expect(butler.execute('insert what="A" at=1'), isNull);
      expect(butler.execute('insert in=output what="Z" at=0'), isNull);
      expect(butler.getBuffer('output'), 'A\n1\n2\n3\nZ');
    });
    test('position', () {
      butler.buffers['input'] = '1\n2\n3';
      expect(butler.execute('insert what="A" position="2" above'), isNull);
      expect(
          butler.execute('insert in=output what="Z" position=r/[2]/ excl="Z"'),
          isNull);
      expect(
          butler.execute('insert in=output what="Z" position=r/[2]/ excl="Z"'),
          isNull);
      expect(butler.getBuffer('output'), '1\nA\n2\nZ\n3');
    });
    test('insert-examples-1', () {
      butler.buffers['html'] = '<h1>Wellcome</h1>\n<p>Read and enjoi!</p>';
      expect(
          butler.execute(
              r'insert in=html out=html at=1 what=i%"<html>%n<body>" exclusion=r/<body>/'),
          isNull);
      expect(
          butler.execute(
              r'insert in=html out=html at=0 what=i%"</body>%n</html>" exclusion=r%</body>%'),
          isNull);
      expect(butler.getBuffer('html'),
          '<html>\n<body>\n<h1>Wellcome</h1>\n<p>Read and enjoi!</p>\n</body>\n</html>');
    });
    test('insert-examples-2', () {
      butler.buffers['input'] = ''''# line1
[opcache]
;opcache.enabled=1</p>
''';
      expect(
          butler.execute(
              r'insert position=/[opcache]/ what=i%"opcache.enable=1%nopcache.enable_cli=1%nopcache.memory_consumption=512" exclusion=r/^opcache.enabled/'),
          isNull);
      expect(butler.getBuffer('output'), ''''# line1
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=512
;opcache.enabled=1</p>
''');
    });
    /*
        r'insert in=html out=html at=1 what=i\"<html><body>\n" excl=r/<html>',
    r'insert in=html out=html at=0 what=i\"</body>\n</html>" excl=r%</html>%',
    r'insert above position=r/debug|production/ what=i\"max_count=1\n" ',

     */
  });
  group('TextButler-filter-examples', () {
    final butler = TextButler();
    const input = '''
<?xml version="1.0" encoding="UTF-8"?>
<staff>
  <company>
    <name>Easy Rider</name>
  </company>
  <person>
    <id>1</id>
    <name>Adam</name>
  </person>
  <person>
    <id>2</id>
    <name>Berta</name>
  </person>
  <person>
    <id>3</id>
    <name>Charly</name>
  </person>
</staff>
''';
    test('example-1-filter-name', () {
      butler.buffers['input'] = input;
      expect(butler.execute('filter fi=/name/'), isNull);
      expect(butler.getBuffer('output'), '''
    <name>Easy Rider</name>
    <name>Adam</name>
    <name>Berta</name>
    <name>Charly</name>
''');
    });
    test('example-2-filter-start-end-repeat', () {
      butler.buffers['input'] = input;
      expect(
          butler.execute(
              'filter start=/<person/ end=!</person! fi=/name/ repeat=2'),
          isNull);
      expect(butler.getBuffer('output'), '''
    <name>Adam</name>
    <name>Berta</name>
''');
    });
    test('example-3-filter-start-end-template', () {
      butler.buffers['input'] = input;
      expect(
          butler.execute(
              'filter start=/<person/ end=!</person! fi=r/<(name|id)>(.*?)</ repeat=2 template="%group1%: %group2%\n"'),
          isNull);
      expect(butler.getBuffer('output'), '''
id: 1
name: Adam
id: 2
name: Berta
''');
    });
    test('example-4-filter-start-end-template', () {
      butler.buffers['input'] = input;
      expect(
          butler.execute(
              'filter start=/<person/ end=!/person! Filters=;"<name";"<id" repeat=2'),
          isNull);
      expect(butler.getBuffer('output'), '''
    <id>1</id>
    <name>Adam</name>
    <id>2</id>
    <name>Berta</name>
''');
    });
    test('example-5-filter-start-end-template', () {
      butler.buffers['input'] = input;
      expect(
          butler.execute(
              'filter start=/<person/ end=!</person! Filters=;r"<(name)>(.*?)<";r"<id>(.*?)<" repeat=2 Templates=;"%1%: %2%\n";"no: %1%\n"'),
          isNull);
      expect(butler.getBuffer('output'), '''
no: 1
name: Adam
no: 2
name: Berta
''');
    });
    test('example-6-excludes', () {
      butler.buffers['input'] = input;
      expect(
          butler.execute('filter start=/<person/ excluded=r!id|person|staff!'),
          isNull);
      expect(butler.getBuffer('output'), '''
    <name>Adam</name>
    <name>Berta</name>
    <name>Charly</name>
''');
    });
  });
}
