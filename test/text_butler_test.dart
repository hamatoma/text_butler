import 'package:test/test.dart';
import 'package:text_butler/text_butler.dart';

void main() {
  group('ParameterSet', () {
    final butler = TextButler();
    final set = ParameterSet(
        {
          'intList': ParameterValue(ParameterType.natList, intList: [10, 19]),
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
        expect(exc.message, 'ambiguous parameter "va": value/variable');
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
        expect(exc.message, 'ambiguous command "s": show/swap');
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
        expect(exc.message,
            'not a name: only letters are allowed, starting with upper case');
      }
      try {
        butler.stringParameters = 'name="K"';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.message, 'parameter "name" is too short (2): [string]: K');
      }
      try {
        butler.stringParameters = 'name="VeryLongName"';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.message, 'parameter "name" is too long (8): [string]: VeryLongName');
      }
    });
    test('checkParameters-int-error', () {
      butler.stringParameters = 'number=one';
      try {
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.message, 'parameter "number": non negative number expected, not one');
      }
    });
    test('checkParameters-stringList-error', () {
      try {
        butler.stringParameters = 'stringList=one';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.message,
            'parameter "stringList": separator not allowed character: o');
      }
    });
    test('checkParameters-intList-error', () {
      try {
        butler.stringParameters = 'intList=one,two';
        butler.checkParameters(butler.splitParameters(expected), expected);
        expect('missing WordingError', isNull);
      } on WordingError catch (exc) {
        expect(exc.message,
            'parameter "intList": not a non negative number in natList: one');
      }
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
  });
  group('TextButler-rest', () {
    final butler = TextButler();
    butler.buffers['animals'] = 'cat\ndog';
    butler.buffers['Numbers'] = 'one\ntwo';
    butler.buffers['jonny'] = 'abc';
    test('show', () {
      expect(butler.execute('show'), isNull);
      expect(butler.buffers['output'],
          'Numbers\nanimals\nexamples\nhistory\ninput\njonny\noutput');
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
              'Filters=";<(name)>(.*?)<;<id>(.*?)<" '
              'repeat=2 Templates=";%1%: %2%\n;no: %1%\n"'),
          isNull);
      expect(butler.buffers['output'], '''no: 1
name: Adam
no: 2
name: Berta
''');
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
          '''replace i=sql what=;":from";"'2021-06-01'";":to";"'2021-07-01'";':customer';"1133"
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
  group('TextButler-interpreted text', () {
    final butler = TextButler();
    test('simple', () {
      butler.buffers['name'] = 'Joe';
      expect(butler.execute('copy text=i~"Hi ~[name]!"'), isNull);
      expect(butler.getBuffer('output'), 'Hi Joe!');
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
  });
}
