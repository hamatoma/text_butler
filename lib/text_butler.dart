import 'dart:math';

typedef MapParameter = Map<String, ParameterValue>;

typedef MapParameterInfo = Map<String, ParameterInfo>;

/// Stores a partial result of the method search.
class Hit {
  int? index;
  RegExpMatch? hit;
}

/// Each recognized programming error throw this error.
class InternalError extends FormatException {
  String message;
  String location;

  InternalError(this.location, this.message);

  @override
  String toString() {
    return 'Internal Error: [$location] $message';
  }
}

abstract class Logger {
  void clear();
  bool log(String message);
}

/// Stores the properties of one parameter.
class ParameterInfo {
  final ParameterType type;
  final String? defaultValue;
  final bool optional;

  /// Only meaningful for strings, stringList and intList
  final int minLength;

  /// Only meaningful for strings, stringList and intList
  final int maxLength;

  /// Specifies the "syntax" of the parameter, the only meaningful for strings
  final RegExp? pattern;

  /// If [:pattern:] does not match, this message is print.
  final String? patternError;

  /// Only for a string: the parameter must be put between two delimiters
  bool delimited;

  /// If true the parameter must start with a free selectable separator.
  /// Only meaningful for stringList.
  final bool autoSeparator;

  ParameterInfo(this.type,
      {this.defaultValue,
      this.delimited = true,
      this.optional = true,
      this.minLength = 0,
      this.maxLength = 1024,
      this.pattern,
      this.autoSeparator = false,
      this.patternError}) {
    if (type == ParameterType.nat || type == ParameterType.natList) {
      this.delimited = false;
    }
  }
}

/// Stores the current parameters of one command.
class ParameterSet {
  final MapParameter map;
  final TextButler butler;
  final MapParameterInfo expected;

  ParameterSet(this.map, this.butler, this.expected);

  /// Returns a parameter given by [:name:] as an integer.
  bool asBool(String name) {
    bool rc = map.containsKey(name);
    if (rc && (map[name]!.parameterType != ParameterType.bool)) {
      throw InternalError('ParameterSet.asBool()', 'not a bool: $name');
    }
    return rc;
  }

  /// Returns a parameter given by [:name:] as an integer.
  int asInt(String name) {
    if (!map.containsKey(name)) {
      throw InternalError('ParameterSet.asInt', 'unknown parameter $name');
    }
    int rc = map[name]!.asInt();
    return rc;
  }

  /// Returns a member of a "auto selector list" stored in parameter [:name:].
  /// The list starts with a separator: free choice of a separator.
  /// Example: parameter 'animals' contains ",cat,dog".
  /// Returns the [:index:]-th member of the list.
  int asListMemberInt(String name, int index, {int? defaultValue}) {
    int? rc;
    if (!hasParameter(name)) {
      if (defaultValue == null) {
        throw WordingError('missing parameter "$name"');
      } else {
        rc = defaultValue;
      }
    }
    if (rc == null) {
      final list = map[name]!.natList;
      if (list == null) {
        throw InternalError('asListMemberInt', 'not an intList: $name');
      }
      if (index < 0 || index >= list.length) {
        throw WordingError('wrong index $index in "$name');
      }
      rc = list[index];
    }
    return rc;
  }

  /// Returns a member of a "list of string lists" stored in parameter [:name:]
  /// at [:index:].
  /// Returns the [:index:]-th member of the list as list of strings.
  List<String> asListMemberList(String name, int index) {
    if (!hasParameter(name)) {
      throw InternalError('asListMember()', 'unknown parameter "$name"');
    }
    List<String> rc;
    final parameterValue = map[name]!;
    switch (parameterValue.parameterType) {
      case ParameterType.listOfStringList:
        if (index < 0 || index >= parameterValue.list!.length) {
          throw WordingError(
              'parameter "$name" contains too few list members: index: $index list: $parameterValue');
        }
        final list = parameterValue.list![index].list!;
        rc = list.map((value) => value.string!).toList();
        break;
      // case ParameterType.listOfStringList:
      default:
        throw InternalError('asListMemberString()',
            'unhandled type: ${parameterValue.parameterType}');
    }
    return rc;
  }

  /// Returns a member of a "auto selector list" stored in parameter [:name:].
  /// The list starts with a separator: free choice of a separator.
  /// Example: parameter 'animals' contains ",cat,dog".
  /// Returns the [:index:]-th member of the list.
  String asListMemberString(String name, int index) {
    if (!hasParameter(name)) {
      throw InternalError('asListMember()', 'unknown parameter "$name"');
    }
    String? rc;
    final parameterValue = map[name]!;
    switch (parameterValue.parameterType) {
      case ParameterType.stringList:
        if (index < 0 || index >= parameterValue.list!.length) {
          throw WordingError(
              'parameter "$name" contains too few list members: index: $index list: $parameterValue');
        }
        rc = parameterValue.list![index].string;
        break;
      // case ParameterType.listOfStringList:
      default:
        throw InternalError('asListMemberString()',
            'unhandled type: ${parameterValue.parameterType}');
    }
    return rc!;
  }

  /// Returns a RegExp instance.
  /// Throws [:InternalError:] on error.
  RegExp asRegExp(String name) {
    if (!map.containsKey(name)) {
      throw InternalError('ParameterSet.asInt', 'unknown parameter $name');
    }
    RegExp rc = map[name]!.asRegExp();
    return rc;
  }

  /// Returns a parameter given by [:name:] as an integer.
  /// [:defaultValue:]: the result if [:defaultValue:] is not null and the parameter
  /// [:name:] is not defined:
  String asString(String name, {String? defaultValue}) {
    String rc;
    if (!map.containsKey(name)) {
      if (defaultValue != null) {
        rc = defaultValue;
      } else {
        throw InternalError('ParameterSet.asString', 'unknown parameter $name');
      }
    } else {
      rc = map[name]!.asString();
    }
    return rc;
  }

  /// Checks whether one of two parameters is defined or none.
  /// [:first:] is the name of the first parameter to inspect.
  /// [:second:] is the name of the second parameter to inspect.
  /// On error [:WordingError:] is thrown.
  void checkAtMostOneOf(String first, String second) {
    if (map.containsKey(first) && map.containsKey(second)) {
      throw WordingError(
          'Do not define parameter "$first" and "$second" at the same time');
    }
  }

  /// Checks whether exactly one of two parameters is defined.
  /// [:first:] is the name of the first parameter to inspect.
  /// [:second:] is the name of the second parameter to inspect.
  /// On error [:WordingError:] is thrown.
  void checkExactlyOneOf(String first, String second) {
    if (!map.containsKey(first) && !map.containsKey(second)) {
      throw WordingError('missing parameter "$first" or "$second"');
    }
    if (map.containsKey(first) && map.containsKey(second)) {
      throw WordingError('define parameter "$first" or "$second", not both');
    }
  }

  /// Returns the length of a list (stringList, intList...) given by [:name:].
  int countOfList(String name) {
    int? rc;
    if (!expected.containsKey(name)) {
      throw InternalError('countOfList()', 'missing parameter $name');
    }
    if (!map.containsKey(name)) {
      throw WordingError('missing parameter $name');
    }
    final info = expected[name];
    final current = map[name]!;
    switch (info!.type) {
      case ParameterType.natList:
        rc = current.asNatList().length;
        break;
      case ParameterType.patternList:
        rc = current.asPatternList().length;
        break;
      case ParameterType.stringList:
      case ParameterType.listOfStringList:
        rc = current.asValueList().length;
        break;
      default:
        throw InternalError('countOfList()', 'not a list: $name');
    }
    return rc;
  }

  /// Tests whether a parameter given by name is part of the instance.
  bool hasParameter(String name) {
    final rc = map.containsKey(name);
    return rc;
  }

  /// Sets a current parameter if it does not exist yet.
  void setIfUndefined(String name, String? value,
      [StringType stringType = StringType.string]) {
    if (!map.containsKey(name)) {
      map[name] = ParameterValue(ParameterType.string,
          stringType: stringType, string: value);
    }
  }

  /// Tests whether two list parameters have the same length.
  /// If not a [:WordingException:] is thrown.
  void testSameListLength(String name1, String name2) {
    if (hasParameter(name1) && hasParameter(name2)) {
      int length1 = countOfList(name1);
      int length2 = countOfList(name2);
      if (length1 != length2) {
        throw WordingError(
            'different list lengths of "$name1" and "$name2": $length1/$length2');
      }
    }
  }
}

enum ParameterType {
  bool,
  listOfStringList,

  /// non negative integer
  nat,
  natList,

  /// pattern: string or regular expression
  pattern,
  patternList,
  string,
  stringList,
}

class ParameterValue {
  final ParameterType parameterType;
  final StringType stringType;
  String? string;
  final List<ParameterValue>? list;
  final List<int>? natList;
  int? natValue;

  ParameterValue(this.parameterType,
      {this.stringType = StringType.undef,
      this.string,
      this.list,
      this.natList,
      this.natValue});

  /// Returns the "value" as integer.
  int asInt() {
    if (parameterType != ParameterType.nat) {
      throw InternalError(
          'ParameterValue.asInt()', 'parameter is $parameterType');
    }
    return natValue!;
  }

  /// Returns the "value" as list of integers
  List<int> asNatList() {
    if (parameterType != ParameterType.natList) {
      throw InternalError(
          'ParameterValue.asIntList()', 'parameter is $parameterType');
    }
    return natList!;
  }

  /// Returns the "value" as list of ParameterValue instances.
  List<ParameterValue> asPatternList() {
    if (parameterType != ParameterType.patternList) {
      throw InternalError(
          'ParameterValue.asPatternList()', 'parameter is $parameterType');
    }
    return list!;
  }

  /// Returns the "value" as a list of RegExp instances.
  List<RegExp> asPatterns() {
    if (parameterType != ParameterType.patternList) {
      throw InternalError('asPatterns()', 'parameter is $parameterType');
    }
    final rc = <RegExp>[];
    for (var item in list!) {
      rc.add(item.asRegExp());
    }
    return rc;
  }

  /// Returns the value as RegExp instance.
  /// @throws InternalError() on error.
  RegExp asRegExp() {
    RegExp rc;
    switch (stringType) {
      case StringType.regExp:
      case StringType.string:
        rc = RegExp(string!);
        break;
      case StringType.regExpIgnoreCase:
        rc = RegExp(string!, caseSensitive: false);
        break;
      case StringType.stringIgnoreCase:
        rc = RegExp(RegExp.escape(string!), caseSensitive: false);
        break;
      default:
        throw InternalError(
            'asRegExpr()', 'unexpected string type: $stringType');
    }
    return rc;
  }

  /// Returns the "value" as string.
  String asString() {
    if (parameterType != ParameterType.string &&
        parameterType != ParameterType.pattern) {
      throw InternalError(
          'ParameterValue.asString()', 'parameter is $parameterType');
    }
    return string!;
  }

  /// Returns the "value" as list of strings.
  List<String> asStringList() {
    final rc = <String>[];
    for (var item in list!) {
      rc.add(item.string!);
    }
    return rc;
  }

  /// Returns the "value" as list of ParameterValue instances.
  List<ParameterValue> asValueList() {
    if (parameterType != ParameterType.stringList &&
        parameterType != ParameterType.listOfStringList) {
      throw InternalError(
          'ParameterValue.asStringList()', 'parameter is $parameterType');
    }
    return list!;
  }

  @override
  String toString() {
    String rc;
    switch (parameterType) {
      case ParameterType.bool:
        rc = '[bool]';
        break;
      case ParameterType.nat:
        rc = '[nat]: $int';
        break;
      case ParameterType.natList:
        rc = natList!.fold(
            '[natList]',
            (previousValue, element) =>
                previousValue + ' ' + element.toString());
        break;
      case ParameterType.pattern:
        rc = '[pattern]: $string';
        break;
      case ParameterType.patternList:
        rc = natList!.fold(
            '[patternList]',
            (previousValue, element) =>
                previousValue + ' ' + element.toString());
        break;
      case ParameterType.string:
        rc = '[string]: $string';
        break;
      case ParameterType.stringList:
        rc = natList!.fold(
            '[stringList]',
            (previousValue, element) =>
                previousValue + ' ' + element.toString());
        break;
      case ParameterType.listOfStringList:
        rc = list!.fold(
            '[listOfStringList]',
            (previousValue, element) =>
                previousValue +
                ' ' +
                '[' +
                element.toString().substring(13) +
                ']');
        break;
    }
    return rc;
  }
}

/// Stores the sort parameters.
class SortInfo {
  static final defaultRangeList = [SortRange(0, 0xffffffff, false)];
  static final defaultItem = SortItem(false, stringValues: ['']);
  final String mode;
  final RegExp? separator;
  final RegExp? regExpRelevant;
  final List<SortRange>? ranges;
  var sortItems = <SortLineInfo>[];
  final Logger logger;

  SortInfo(this.logger, this.mode, this.ranges,
      {this.separator, this.regExpRelevant});

  /// Builds the sort relevant string from a [:line:]: cuts the parts defined
  /// in the command line: some character/word ranges
  List<SortItem> build(String line, int lineNo) {
    final rc = <SortItem>[];
    int length = line.length;
    if (this.mode == 'c') {
      var rangeNo = 0;
      for (var range in this.ranges ?? defaultRangeList) {
        rangeNo++;
        if (range.from < length) {
          final last = min(length - 1, range.to);
          final value = line.substring(range.from, last + 1);
          if (range.numeric) {
            var value2 = double.tryParse(value);
            if (value2 == null) {
              logger.log(
                  'line {lineNo}: word "$value" in range $rangeNo is not a number');
              value2 = 0.0;
            }
            rc.add(SortItem(true, floatValues: [value2]));
          } else {
            rc.add(SortItem(false, stringValues: [value]));
          }
        }
      }
    } else if (this.mode == 'w') {
      final words = line.split(this.separator ?? RegExp(r'\s+'));
      final count = words.length;
      for (var range in this.ranges ?? defaultRangeList) {
        if (range.from < count) {
          final last = min(count - 1, range.to);
          final items = words.sublist(range.from, last + 1);
          if (range.numeric) {
            final items2 = <double>[];
            var rangeNo = 0;
            for (var value in items) {
              var value2 = double.tryParse(value);
              if (value2 == null) {
                logger.log(
                    'line {lineNo}: word "$value" in range $rangeNo is not a number');
                value2 = 0.0;
              }
              items2.add(value2);
            }
            rc.add(SortItem(true, floatValues: items2));
          } else {
            rc.add(SortItem(false, stringValues: items));
          }
        }
      }
    } else if (this.mode == 'r') {
      if (this.regExpRelevant == null) {
        rc.add(defaultItem);
      } else {
        final matcher = this.regExpRelevant?.firstMatch(line);
        if (matcher == null) {
          logger.log('unmatched: $line');
        } else {
          if (this.ranges == null) {
            rc.add(defaultItem);
          } else {
            final words = <String>[];
            for (var ix = 1; ix <= matcher.groupCount; ix++) {
              words.add(matcher.group(ix) ?? '');
            }
            final count = words.length;
            for (var range in this.ranges ?? defaultRangeList) {
              if (range.from < count) {
                final last = min(count - 1, range.to);
                final items = words.sublist(range.from, last + 1);
                if (range.numeric) {
                  final items2 = <double>[];
                  var rangeNo = 0;
                  for (var value in items) {
                    var value2 = double.tryParse(value);
                    if (value2 == null) {
                      logger.log(
                          'line $lineNo: word "$value" in range $rangeNo is not a number');
                      value2 = 0.0;
                    }
                    items2.add(value2);
                  }
                  rc.add(SortItem(true, floatValues: items2));
                } else {
                  rc.add(SortItem(false, stringValues: items));
                }
              }
            }
          }
        }
      }
    } else {
      throw InternalError('SortInfo.build()', 'unknown mode: $mode');
    }
    return rc;
  }

  /// Compares two items of sort relevant data [:a:] and [:b:].
  /// @return 0: a and b are equal
  /// lower 0: a lower than b
  /// greater 0: a greater than b
  int compare(SortLineInfo a, SortLineInfo b) {
    var rc = a.compare(b);
    return rc;
  }

  /// Sorts a list of [:lines:] with the sort relevant info.
  /// Than the list is sorted.
  /// The result is the join of the sorted lines.
  String sort(List<String> lines) {
    sortItems.clear();
    var lineNo = 0;
    for (var line in lines) {
      lineNo++;
      sortItems.add(SortLineInfo(logger, line, build(line, lineNo)));
    }
    sortItems.sort((a, b) => compare(a, b));
    final rc = this.sortItems.map((e) => e.line).join('\n');
    return rc;
  }

  double toDouble(String value) {
    double rc = double.tryParse(value) ?? 0.0;
    return rc;
  }
}

/// Stores the sort relevant data for one range range of the line
class SortItem {
  final List<String>? stringValues;
  final List<double>? floatValues;
  bool numeric;
  SortItem(this.numeric, {this.stringValues, this.floatValues});
}

/// Stores the sort info of one line.
class SortLineInfo {
  final List<SortItem> sortItems;
  final String line;
  SortLineInfo(logger, this.line, this.sortItems);

  int compare(SortLineInfo b) {
    int rc = 0;
    final last = min(sortItems.length, b.sortItems.length);
    for (var ix = 0; ix < last && rc == 0; ix++) {
      final itemA = sortItems[ix];
      final itemB = b.sortItems[ix];
      final sizeA = (itemA.numeric
              ? itemA.floatValues?.length
              : itemA.stringValues?.length) ??
          0;
      final sizeB = (itemB.numeric
              ? itemB.floatValues?.length
              : itemB.stringValues?.length) ??
          0;
      final last2 = min(sizeA, sizeB);
      if (itemA.numeric) {
        for (int ix2 = 0; ix2 < last2 && rc == 0; ix2++) {
          final valueA = itemA.floatValues?[ix2] ?? 0.0;
          final valueB = itemB.floatValues?[ix2] ?? 0.0;
          if (valueA < valueB) {
            rc = -1;
          } else if (valueA > valueB) {
            rc = 1;
          }
        }
      } else {
        for (int ix2 = 0; ix2 < last2 && rc == 0; ix2++) {
          final valueA = itemA.stringValues?[ix2];
          final valueB = itemB.stringValues?[ix2];
          rc = valueA == null || valueB == null ? 0 : valueA.compareTo(valueB);
        }
      }
      if (rc == 0) {
        if (sizeA > last2) {
          rc = 1;
        } else if (sizeB > last2) {
          rc = -1;
        }
      }
    }
    return rc;
  }
}

/// Stores the sort definition data for one range range.
class SortRange {
  final int from;
  final int to;
  final bool numeric;
  SortRange(this.from, this.to, this.numeric);
}

enum StringType { undef, regExp, regExpIgnoreCase, string, stringIgnoreCase }

/// Implements a text processor that interprets "commands" to convert
/// an input string into another.
/// Administrates "buffers" that can store intermediate results.
///
class TextButler extends Logger {
  static TextButler? lastInstance;
  static final _examplesBasic = <String>[
    'clear output=history',
    '',
    'copy input=input output=output append',
    'copy text="Hello" output=output',
    '',
    r'count regexpr=r"\d+" output=count',
    '',
    'duplicate count=2 offset=100 step=10',
    r'#input: index: %index% item: %number% name: %char%\n',
    '',
    'duplicate count=3 Offsets=10,0 Steps=10,1 BaseChars="Aa" meta=%"',
    r'#input: "no: %index% id: %number0% place %char0% class %char1%\n',
    '',
    'duplicate count=2 offset=1 Values=,"cat","dog"',
    r'#input: "%number%: %value%\n"',
    '',
    'duplicate count=2 ListValues=";,cat,dog;,Mia,Harro;,London,Rome"',
    r'#input: A %value0% named %value1% comes from %value2%."',
    '',
    'execute input=input',
    r'#input: copy text="Hi "\ncopy append text="world',
    ''
        r'filter start=r/^Name: Miller/ end=r/^Name:/ filter=r/^\s*[^#\s]/',
    r'filter Filters=;r/<(name|id|email>(.*?)</;r/href="(.*?)"/ meta=% '
        'Templates=,"%group2%: %group1%1","link: %group2%"',
    '',
    r'replace meta=& What=;r/ (\d+)/;": &0&"',
    r'replace What=;"Hello";"Hi"',
    '',
    'show',
    'show what=buffers',
    '',
    'sort',
    'sort',
    'sort output=sorted how="c1-4,8-10"',
    'sort input=sorted how="w3,n4,1" separator=","',
    r'sort how="w3,n4,1" separator=/\s*,\s*/',
    r'sort how="r1,n2-3/name: (\w+) id: (\d+) role: (\w+)/i"'
        '',
    'swap a=input b=output',
  ];
  static final defaultBufferNames = [
    'input',
    'history',
    'output',
    'examples',
    'log'
  ];
  static const patternBufferName = r'^[a-zA-Z]\w*$';
  static final regExprNumber = RegExp(r'^\d+');
  static final regExpNonSpaces = RegExp(r'^\S+');
  static final regExprDelimiter = RegExp(r'^[_\W]');
  String? errorLineInfo;
  final commandNames = <String>[];
  final buffers = <String, String>{
    'output': '',
    'input': '',
    'history': '',
    'log': ''
  };
  String? errorMessage;

  final regExpEndOfParameter = RegExp(r'[ =]');
  final regExprAutoSeparator = RegExp(r'[^a-zA-Z0-9]');
  final regexprSortInfo = RegExp(r'^[cw][\dn,-]*|^r[\dn,-]*(/.*)?');
  final paramBool = ParameterInfo(ParameterType.bool);
  final paramBaseChar = ParameterInfo(ParameterType.string,
      defaultValue: 'A', minLength: 1, maxLength: 1, delimited: false);
  final paramBaseChars = ParameterInfo(ParameterType.string, minLength: 2);
  final paramBufferName = ParameterInfo(ParameterType.string,
      optional: false,
      defaultValue: 'output',
      pattern: RegExp(patternBufferName),
      patternError: 'wrong buffer name: only letters allowed',
      delimited: false);
  final paramListOfStringList =
      ParameterInfo(ParameterType.listOfStringList, autoSeparator: true);
  final paramIntDefault1 =
      ParameterInfo(ParameterType.nat, defaultValue: '1', optional: false);
  final paramIntList = ParameterInfo(ParameterType.natList, delimited: false);
  final paramIntNeeded = ParameterInfo(ParameterType.nat, optional: false);
  final paramMarker = ParameterInfo(ParameterType.string,
      defaultValue: '#',
      minLength: 1,
      maxLength: 1,
      delimited: false,
      optional: false);
  final paramMeta = ParameterInfo(ParameterType.string,
      defaultValue: '%',
      optional: false,
      minLength: 1,
      maxLength: 1,
      delimited: false);
  final paramPatternList =
      ParameterInfo(ParameterType.patternList, autoSeparator: true);
  final paramOffset =
      ParameterInfo(ParameterType.nat, defaultValue: '0', optional: false);
  final paramPattern = ParameterInfo(ParameterType.pattern, minLength: 1);
  final paramStep =
      ParameterInfo(ParameterType.nat, optional: false, defaultValue: '1');
  final paramSteps = ParameterInfo(ParameterType.natList, delimited: false);
  final paramString = ParameterInfo(ParameterType.string);
  final ParameterInfo paramSelector =
      ParameterInfo(ParameterType.string, minLength: 1);
  // Will be changed in the constructor!
  ParameterInfo paramSortInfo = ParameterInfo(ParameterType.string);

  final paramStringListAutoSeparator = ParameterInfo(ParameterType.stringList,
      minLength: 2, autoSeparator: true);

  // The input of splitParameters(). Not local: so parts of splitParameters()
  // can be done in other methods.
  final paramStringMinLength1 =
      ParameterInfo(ParameterType.string, minLength: 1);

  String stringParameters = '';

  TextButler() {
    paramSortInfo = ParameterInfo(ParameterType.string,
        minLength: 1, pattern: regexprSortInfo);
    for (var item in examples) {
      if (item.isNotEmpty) {
        final name = item.split(' ')[0];
        if (!commandNames.contains(name)) {
          commandNames.add(name);
        }
      }
    }
    buffers['history'] = '';
    buffers['examples'] = examples.join('\n');
  }

  List<String> get examples => _examplesBasic;

  /// Tests whether the [:current:] parameters match the [:expected:].
  /// Throws [:WordingErrors:] on error.
  void checkParameters(ParameterSet current, MapParameterInfo expected) {
    /// Supply default values in current if that does not exist:
    for (var entry in expected.entries) {
      if (!current.hasParameter(entry.key) &&
          entry.value.defaultValue != null &&
          !entry.value.optional) {
        current.map[entry.key] =
            defaultValue(entry.value.defaultValue, entry.value.type);
      }
    }
    for (var name in current.map.keys) {
      if (!expected.containsKey(name)) {
        throw WordingError('unknown parameter "$name"');
      } else {
        final expectedParameter = expected[name];
        var currentValue = current.map[name];
        if (expectedParameter!.defaultValue != null && currentValue == null) {
          currentValue = current.map[name] = defaultValue(
              expectedParameter.defaultValue, expectedParameter.type);
        }
        if (currentValue == null && !expectedParameter.optional) {
          throw WordingError('missing value for parameter "$name"');
        }
        switch (expectedParameter.type) {
          case ParameterType.bool:
            // nothing to do
            break;
          case ParameterType.string:
            if (currentValue != null) {
              if (currentValue.asString().length <
                  expectedParameter.minLength) {
                throw WordingError(
                    'parameter "$name" is too short (${expectedParameter.minLength}): $currentValue');
              }
              if (currentValue.asString().length >
                  expectedParameter.maxLength) {
                throw WordingError(
                    'parameter "$name" is too long (${expectedParameter.maxLength}): $currentValue');
              }
              if (expectedParameter.pattern != null &&
                  expectedParameter.pattern!
                          .firstMatch(currentValue.asString()) ==
                      null) {
                final message = expectedParameter.patternError != null
                    ? expectedParameter.patternError
                    : 'wrong syntax in parameter "$name": $currentValue';
                throw WordingError(message!);
              }
            }
            break;
          case ParameterType.nat:
          case ParameterType.pattern:
          case ParameterType.patternList:
          case ParameterType.stringList:
          case ParameterType.listOfStringList:
          case ParameterType.natList:
            if (currentValue == null) {
              throw WordingError('missing value of parameter "$name"');
            } else if (currentValue.parameterType != expectedParameter.type) {
              throw WordingError(
                  'parameter "$name" must have the the type ${expectedParameter.type} not ${currentValue.parameterType}');
            }
            break;
        }
      }
    }
  }

  /// Clears the buffer log:
  @override
  void clear() {
    buffers['log'] = '';
  }

  ParameterValue defaultValue(String? defaultValue, ParameterType type) {
    ParameterValue rc;
    switch (type) {
      case ParameterType.bool:
      case ParameterType.natList:
      case ParameterType.pattern:
      case ParameterType.patternList:
      case ParameterType.stringList:
      case ParameterType.listOfStringList:
        throw InternalError('defaultValue()', 'unexpected type: $type');
      case ParameterType.nat:
        if (defaultValue == null) {
          throw InternalError('defaultValue()', 'defaultValue is null');
        }
        final value = int.tryParse(defaultValue);
        if (value == null) {
          throw InternalError(
              'defaultValue()', 'defaultValue is not a nat: $value');
        }
        rc =
            ParameterValue(type, stringType: StringType.undef, natValue: value);
        break;
      case ParameterType.string:
        rc = ParameterValue(type,
            stringType: StringType.string, string: defaultValue);
        break;
    }
    return rc;
  }

  /// Executes the command [:commandName:] with the [:parameters:].
  /// This method must be overridden by classes to expand to other commands.
  bool dispatch(String? commandName, String parameters) {
    var toHistory = true;
    stringParameters = parameters;
    switch (commandName) {
      case 'clear':
        toHistory = false;
        executeClear();
        break;
      case 'copy':
        executeCopy();
        break;
      case 'count':
        executeCount();
        break;
      case 'duplicate':
        executeDuplicate();
        break;
      case 'execute':
        executeExecute();
        break;
      case 'filter':
        executeFilter();
        break;
      case 'replace':
        executeReplace();
        break;
      case 'show':
        executeShow();
        break;
      case 'sort':
        executeSort();
        break;
      case 'swap':
        executeSwap();
        break;
      default:
        throw WordingError('unknown command: "$commandName"');
    }
    return toHistory;
  }

  /// Executes a command.
  /// [:command:] is a command (with parameters) like "show what=buffers"
  /// [:stringParameters:] is the string to manipulate.
  /// Returns null on success, an error message otherwise.
  String? execute(String command) {
    errorMessage = null;
    var toHistory = true;
    try {
      final commandName = expandCommand(command.split(' ')[0]);
      final ixBlank = command.indexOf(' ');
      final parameters = ixBlank <= 0 ? '' : command.substring(ixBlank + 1);
      toHistory = dispatch(commandName, parameters);
    } on InternalError catch (exc) {
      errorMessage = exc.location + ': ' + exc.message;
    } on WordingError catch (exc) {
      errorMessage = exc.message;
    }
    if (toHistory || getBuffer('history') != '') {
      buffers['history'] = (errorMessage == null ? '' : '# ') +
          getBuffer('history') +
          command +
          '\n';
    }

    return errorMessage;
  }

  /// Implements the command "clear" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeClear() {
    // 'copy input=input output=output append',
    final expected = {
      'output': paramBufferName,
    };

    final current = splitParameters(expected);
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final target = current.asString('output');
    buffers[target] = '';
  }

  /// Implements the command "copy" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeCopy() {
    // 'copy input=input output=output append',
    final expected = {
      'append': paramBool,
      'input': paramBufferName,
      'output': paramBufferName,
      'text': paramString,
    };
    final current = splitParameters(expected);
    String content;
    current.setIfUndefined('output', 'output');
    if (current.hasParameter('text')) {
      checkParameters(current, expected);
      content = current.asString('text');
    } else {
      current.setIfUndefined('input', 'input');
      checkParameters(current, expected);
      content = getBuffer(current.asString('input'));
    }
    final target = current.asString('output');
    final append = current.asBool('append');
    if (!append || !buffers.containsKey(target) && append) {
      buffers[target] = content;
    } else {
      buffers[target] = buffers[target]! + content;
    }
  }

  /// Implements the command "count" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeCount() {
    // r'count regexpr="\d+" output=count',
    final expected = {
      'append': paramBool,
      'input': paramBufferName,
      'output': paramBufferName,
      'marker': paramMarker,
      'template': paramStringMinLength1,
      'what': paramPattern,
    };
    final current = splitParameters(expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final source = getBuffer(current.asString('input'));
    final target = current.asString('output');
    var count = 0;
    final append = current.asBool('append');
    final regExp = current.asRegExp('what');
    count = regExp.allMatches(source).length;
    final template = current.asString('template', defaultValue: '');
    final result = template.isEmpty
        ? count.toString()
        : template.replaceAll(current.asString('marker'), count.toString());
    buffers[target] = append ? getBuffer(target) + result : result;
  }

  /// Implements the command "duplicate" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeDuplicate() {
    //     'duplicate count=5 var=# offset=-1 meta=% value=/%n/',
    final expected = {
      'append': paramBool,
      'baseChar': paramBaseChar,
      'BaseChars': paramBaseChars,
      'count': paramIntNeeded,
      'input': paramBufferName,
      'ListValues': paramListOfStringList,
      'offset': paramOffset,
      'Offsets': paramIntList,
      'output': paramBufferName,
      'meta': paramMeta,
      'step': paramIntDefault1,
      'Steps': paramSteps,
      'Values': paramStringListAutoSeparator,
    };
    final current = splitParameters(expected);
    current.setIfUndefined('input', 'input');
    current.testSameListLength('Offsets', 'Steps');
    current.testSameListLength('Steps', 'ListValues');
    current.testSameListLength('Offsets', 'ListValues');
    checkParameters(current, expected);
    final input = getBuffer(current.asString('input'));
    StringBuffer buffer = StringBuffer();
    final count = current.asInt('count');
    // if (current.hasParameter('ListValues')) {
    //   throw WordingError(
    //       'sorry: evaluation of ListValues is not implemented yet');
    // }
    for (var ix = 0; ix < count; ix++) {
      final part = replacePlaceholders(input, ix, current);
      buffer.write(part);
    }
    store(current, buffer.toString());
  }

  /// Implements the command "execute" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeExecute() {
    // 'execute input=filter_log',
    final expected = {
      'input': paramBufferName,
    };
    final current = splitParameters(expected);
    current.setIfUndefined('input', 'input');
    checkParameters(current, expected);
    final input = getBuffer(current.asString('input'));
    final commands = input.split('\n');
    for (var line in commands) {
      line = line.trimLeft();
      // Ignore empty lines and comments:
      if (line.isNotEmpty && !line.startsWith('#')) {
        execute(line);
      }
    }
  }

  /// Implements the command "replace" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeFilter() {
    // r'filter start=/^Name: Miller/ end=/^Name:/ regexpr=/^\s*[^#\s] count=1/',
    // filter regexpr=/<(name|id|email>(.*?)</ meta=! template="!2: !1"'
    final expected = {
      'append': paramBool,
      'end': paramPattern,
      'filter': paramPattern,
      'Filters': paramPatternList,
      'input': paramBufferName,
      'meta': paramMeta,
      'output': paramBufferName,
      'repeat': paramIntDefault1,
      'start': paramPattern,
      'template': paramString,
      'Templates': paramStringListAutoSeparator,
    };
    final current = splitParameters(expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    current.checkExactlyOneOf('filter', 'Filters');
    current.checkAtMostOneOf('template', 'Templates');
    List<RegExp> filters;
    if (current.hasParameter('filter')) {
      filters = [RegExp(current.asString('filter'))];
    } else {
      filters = current.map['Filters']!.asPatterns();
    }
    List<String>? templates;
    if (current.hasParameter('template')) {
      templates = [current.asString('template')];
    } else if (current.hasParameter('Templates')) {
      templates = current.map['Templates']!.asStringList();
    }
    final source = getBuffer(current.asString('input')).split('\n');
    final repeat = current.asInt('repeat');
    final hasStart = current.hasParameter('start');
    if (!(hasStart && current.hasParameter('end')) && repeat != 1) {
      throw WordingError(
          'parameter "repeat" is only meaningful with "start" and "end"');
    }
    int? start, end;
    final hit = Hit();
    if (hasStart) {
      start = search(source, [RegExp(current.asString('start'))], hit);
    }
    if (current.hasParameter('end')) {
      end = search(source, [RegExp(current.asString('end'))], hit);
    }
    final buffer = StringBuffer();
    var loop = 0;
    start ??= 0;
    end ??= source.length - 1;
    while (repeat == 0 || loop++ < repeat) {
      int? ixHit;
      while (start! <= end!) {
        if ((ixHit = search(source, filters, hit, from: start, until: end)) ==
            null) {
          break;
        } else {
          if (templates == null) {
            buffer.write(source[ixHit!]);
            buffer.write('\n');
          } else {
            buffer.write(replaceGroups(
                hit.hit!, templates[hit.index!], current.asString('meta')));
          }
          start = ixHit! + 1;
        }
      }
      if (hasStart) {
        start = search(source, [RegExp(current.asString('start'))], hit,
            from: end + 1);
        if (start == null) {
          break;
        }
      }
      if (current.hasParameter('end')) {
        end = search(source, [RegExp(current.asString('start'))], hit,
                from: start + 1) ??
            source.length - 1;
      }
    }
    store(current, buffer.toString());
  }

  /// Implements the command "replace" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeReplace() {
    // r'replace regexpr=/ (\d+)/ meta=\ with=": \0"',
    // r'replace what="Hello" value="*"',
    final expected = {
      'append': paramBool,
      'input': paramBufferName,
      'output': paramBufferName,
      'meta': paramMeta,
      'What': paramPatternList,
    };
    final current = splitParameters(expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    var content = getBuffer(current.asString('input'));
    if (!current.hasParameter('What')) {
      throw WordingError('missing parameter "What"');
    }
    final parameterValue = current.map['What']!;
    int maxIx = parameterValue.list!.length - 1;
    for (var ix = 0; ix <= maxIx; ix += 2) {
      final pattern = parameterValue.list![ix];
      if (ix >= maxIx) {
        throw WordingError('parameter "What" has not an even count of entries');
      }
      var replacement = parameterValue.list![ix + 1];
      if (replacement.stringType != StringType.string) {
        throw WordingError('parameter "What": replacement at index ${ix + 1} '
            'is not a string: ${StringType.string} [$replacement]');
      }
      var replacement2 = replacement.string;
      switch (pattern.stringType) {
        case StringType.undef:
          throw InternalError('executeReplace()', 'wrong undef: $pattern');
        case StringType.regExp:
        case StringType.regExpIgnoreCase:
        case StringType.stringIgnoreCase:
          final buffer = StringBuffer();
          var lastStart = 0;
          final pattern2 = pattern.asRegExp();
          for (var match in pattern2.allMatches(content)) {
            if (match.start > 0) {
              buffer.write(content.substring(lastStart, match.start));
            }
            final replacement3 =
                replaceGroups(match, replacement2!, current.asString('meta'));
            buffer.write(replacement3);
            lastStart = match.end;
          }
          buffer.write(content.substring(lastStart));
          content = buffer.toString();
          break;
        case StringType.string:
          final meta = current.asString('meta');
          replacement2 =
              replacement2!.replaceAll('${meta}group0$meta', replacement2);
          replacement2 = replacement2.replaceAll('${meta}0$meta', replacement2);
          content = content.replaceAll(pattern.string!, replacement2);
          break;
      }
    }
    store(current, content);
  }

  /// Implements the command "replace" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeShow() {
    // 'show what=buffers',
    final expected = {
      'append': paramBool,
      'output': paramBufferName,
      'what': ParameterInfo(ParameterType.string,
          optional: false,
          pattern: RegExp('buffer'),
          patternError: 'unknown value in "what". Use buffer',
          defaultValue: 'buffer'),
    };
    final current = splitParameters(expected);
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final list = buffers.keys.toList();
    list.sort();
    store(current, list.join('\n'));
  }

  /// Implements the command "sort" specified by some [:parameters:].
  /// Throws an exception on errors.
  void executeSort() {
    // 'sort a=input b=output how=c2-4,8- separator=,
    // 'sort a=input b=output how="w4,2,8-',
    // 'sort a=input b=output how="r3,2-3/bytes: (\d+) files: (\d+) dirs: (\d+)',
    final expected = {
      'input': paramBufferName,
      'output': paramBufferName,
      'how': paramSortInfo,
      'separator': paramPattern
    };
    final current = splitParameters(expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final input = current.asString('input');
    final output = current.asString('output');
    final how = current.hasParameter('how') ? current.asString('how') : null;
    final separator = current.hasParameter('separator')
        ? current.asRegExp('separator')
        : null;

    final lines = getBuffer(input).split('\n');
    String content;
    if (how == null) {
      lines.sort();
      content = lines.join('\n');
    } else {
      final mode = how.substring(0, 1);
      final parts = how.substring(1).split('/').toList();
      final ranges = parts[0].split(',');
      final ranges2 = <SortRange>[];
      var rangeNo = 0;
      for (var range in ranges) {
        rangeNo++;
        var numeric = false;
        if (range.startsWith('n')) {
          numeric = true;
          range = range.substring(1);
        }
        if (range.isEmpty) {
          ranges2.add(SortRange(0, 0xffffffff, numeric));
        } else {
          final items = range.split('-');
          final value1 = int.tryParse(items[0]);
          if (value1 == null) {
            throw WordingError(
                'range $rangeNo: first column is not a decimal: ${items[0]}');
          }
          final value2 = items.length < 2 || items[1].isEmpty
              ? value1
              : int.tryParse(items[1]);
          if (value2 == null) {
            throw WordingError(
                'range $rangeNo: second column is not a decimal: ${items[1]}');
          }
          ranges2
              .add(SortRange(max(1, value1) - 1, max(1, value2) - 1, numeric));
        }
      }
      RegExp? regExpRelevant;
      if (mode == 'r') {
        if (parts.length < 2) {
          throw WordingError(
              'missing regexpr behind the ranges in {how}. example: "r2-3,1/name: (\\w+) id: (\\d+) role: (\\w+)/i"');
        } else {
          bool caseSensitive = parts[2].contains('i');
          regExpRelevant = RegExp(parts[1], caseSensitive: caseSensitive);
        }
      }
      final info = SortInfo(this, mode, ranges2,
          separator: separator, regExpRelevant: regExpRelevant);
      content = info.sort(lines);
    }
    buffers[output] = content;
  }

  /// Implements the command "swap".
  /// Throws an exception on errors.
  void executeSwap() {
    // 'swap a=input b=output',
    final expected = {
      'a': paramBufferName,
      'b': paramBufferName,
    };
    final current = splitParameters(expected);
    checkParameters(current, expected);
    final a = current.asString('a');
    final b = current.asString('b');
    final contentA = getBuffer(a);
    final contentB = getBuffer(b);
    buffers[a] = contentB;
    buffers[b] = contentA;
  }

  /// Returns the full name of a command, given as abbreviation.
  /// [:abbreviation:]: the first part of a command name.
  /// Returns null on error ([:errorMessage:] is set in this case) or
  /// the full name of the command.
  String? expandCommand(String abbreviation) {
    final rc = _expand('command', abbreviation, commandNames);
    return rc;
  }

  /// Returns the full name of a command, given as abbreviation.
  /// [:abbreviation:]: the first part of a command name.
  /// Returns null on error ([:errorMessage:] is set in this case) or
  /// the full name of the command.
  String? expandParameter(String abbreviation, List<String> parameterNames) {
    final rc = _expand('parameter', abbreviation, parameterNames);
    return rc;
  }

  /// Returns the content of a buffer with [:name:].
  String getBuffer(String name) {
    if (!buffers.containsKey(name)) {
      throw WordingError('buffer "$name" does not exist');
    }
    final rc = buffers[name]!;
    return rc;
  }

  /// Replaces meta symbols in a given [:value:].
  /// [:escChar:] is a character that introduces a meta symbol.
  /// Meta symbols witch escChar backslash are \n (newline), \r (carriage return)
  /// \f (form feed) \t (tabulator) \v (vertical tabulator.
  /// Returns the interpolated [:value:].
  String interpolateString(String escChar, String value) {
    int ix = value.indexOf(escChar);
    StringBuffer buffer = StringBuffer();
    int lastIx = 0;
    while (ix >= 0) {
      if (ix > 0) {
        buffer.write(value.substring(lastIx, ix));
      }
      if (ix >= value.length - 1) {
        buffer.write(escChar);
        break;
      } else {
        var processed = true;
        switch (value[ix + 1]) {
          case 'n':
            buffer.write('\n');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case 'f':
            buffer.write('\f');
            break;
          case 't':
            buffer.write('\t');
            break;
          case 'v':
            buffer.write('\v');
            break;
          case '[':
            final ixEnd = value.indexOf(']', ix + 1);
            if (ixEnd <= 0) {
              processed = false;
            } else {
              final bufferName = value.substring(ix + 2, ixEnd);
              if (!buffers.containsKey(bufferName)) {
                processed = false;
              } else {
                buffer.write(getBuffer(bufferName));
                ix += bufferName.length + 1;
              }
            }
            break;
          default:
            buffer.write(value[ix + 1]);
            break;
        }
        if (processed) {
          ix = value.indexOf(escChar, lastIx = ix + 2);
        } else {
          ix = value.indexOf(escChar, ix + 2);
        }
      }
    }
    if (lastIx < value.length) {
      buffer.write(value.substring(lastIx));
    }
    return buffer.toString();
  }

  /// Tests whether a [:text:] is a decimal number
  bool isDecimal(String text) {
    final rc = regExprNumber.hasMatch(text);
    return rc;
  }

  /// Logs a [:message:] in the buffer 'messages':
  @override
  bool log(String message) {
    if (buffers['log'] == '') {
      buffers['log'] = buffers['log']! + message;
    } else {
      buffers['log'] = buffers['log']! + '\n' + message;
    }
    return true;
  }

  /// Returns the names defined in [:expected:].
  List<String> namesOf(MapParameterInfo expected) {
    final rc = expected.keys.toList(growable: false);
    return rc;
  }

  /// Parses an integer list into a ParameterValue instance.
  /// [:name:] is the name of the parameter to parse.
  /// The ParameterValue instance is stored in [:map:].
  void parseIntList(String name, MapParameter map) {
    final list = <int>[];
    final list2 = unshiftNonSpaces().split(',');
    for (var item in list2) {
      final intValue = int.tryParse(item);
      if (intValue == null) {
        throw WordingError(
            'parameter "$name": not a non negative number in natList: $item');
      }
      list.add(intValue);
    }
    final parameterValue = ParameterValue(ParameterType.natList, natList: list);
    map[name] = parameterValue;
  }

  /// Parses a list of string lists into a ParameterValue instance.
  /// [:name:] is the name of the parameter to parse.
  /// [:isPattern:]: true: patterns are allowed. false: only strings are allowed.
  /// The ParameterValue instance is stored in [:map:].
  void parseListOfStringList(String name, MapParameter map) {
    String separator =
        unshiftChar('parameter "$name": separator', regExprAutoSeparator);
    final list = <ParameterValue>[];
    var again = true;
    while (again) {
      list.add(parseStringList(name, null));
      again = stringParameters.startsWith(separator);
      if (again) {
        stringParameters = stringParameters.substring(1);
      }
    }
    map[name] = ParameterValue(ParameterType.listOfStringList, list: list);
  }

  /// Parses a string or a pattern into a ParameterValue instance.
  /// [:name:] is the name of the parameter to parse.
  /// The ParameterValue instance is stored in [:map:] (if not null).
  /// [:isPattern:]: if true a regular expression or a ignore case string is allowed.
  ParameterValue parseString(String name, MapParameter? map, bool isPattern) {
    String name2 = 'parameter "$name": ';
    var stringType = StringType.string;
    if (stringParameters.startsWith('R')) {
      stringType = StringType.regExpIgnoreCase;
    } else if (stringParameters.startsWith('r')) {
      stringType = StringType.regExp;
    } else if (stringParameters.startsWith('I')) {
      stringType = StringType.stringIgnoreCase;
    }
    if (stringType != StringType.string) {
      if (!isPattern) {
        throw WordingError(
            '$name2: reg. expr. or ignore case string is not meaningful here');
      }
      stringParameters = stringParameters.substring(1);
    }
    String delimiter;
    String esc = '';
    if (stringParameters.startsWith('i')) {
      stringParameters = stringParameters.substring(1);
      esc = unshiftChar('$name2: esc character', regExprDelimiter);
    }
    delimiter = unshiftChar('$name2: delimiter', regExprDelimiter);
    final ix = stringParameters.indexOf(delimiter);
    if (ix < 0) {
      throw WordingError('$name2: missing trailing delimiter "$delimiter"');
    }
    final rc = ParameterValue(
        isPattern ? ParameterType.pattern : ParameterType.string,
        stringType: stringType,
        string: stringParameters.substring(0, ix));
    if (map != null) {
      map[name] = rc;
    }
    stringParameters = stringParameters.substring(ix + 1);
    if (esc.isNotEmpty) {
      rc.string = interpolateString(esc, rc.string!);
    }
    return rc;
  }

  /// Parses a pattern list into a ParameterValue instance.
  /// [:name:] is the name of the parameter to parse.
  /// [:isPattern:]: true: patterns are allowed. false: only strings are allowed.
  /// The ParameterValue instance is stored in [:map:] (if not null).
  ParameterValue parseStringList(String name, MapParameter? map,
      {bool isPattern = false}) {
    String separator =
        unshiftChar('parameter "$name": separator', regExprAutoSeparator);
    final list = <ParameterValue>[];
    var again = true;
    while (again) {
      list.add(parseString(name, null, isPattern));
      again = stringParameters.startsWith(separator);
      if (again) {
        stringParameters = stringParameters.substring(1);
      }
    }
    final rc = ParameterValue(
        isPattern ? ParameterType.patternList : ParameterType.stringList,
        list: list);
    if (map != null) {
      map[name] = rc;
    }
    return rc;
  }

  /// Replaces the templates in the 'filter' command.
  String replaceGroups(RegExpMatch filterMatch, String template, String meta) {
    String rc = template;
    var groupPattern = RegExp('$meta(\\w+)$meta');
    final matches = groupPattern.allMatches(template);
    for (var match in matches) {
      final macro = match.group(0)!;
      final placeholder = match.group(1)!;
      var groupNo = placeholder.startsWith('group')
          ? int.tryParse(placeholder.substring(5))
          : int.tryParse(placeholder);
      if (groupNo != null) {
        rc = rc.replaceFirst(macro, filterMatch.group(groupNo) ?? '');
      }
    }
    return rc;
  }

  /// Replaces placeholders by their values.
  ///
  String replacePlaceholders(
      String template, int index, ParameterSet parameters) {
    var rc = template;
    final meta = RegExp.escape(parameters.asString('meta'));
    final pattern = RegExp('$meta(\\w+)$meta');
    final matches = pattern.allMatches(template);
    for (var match in matches) {
      var replacement = '';
      final macro = match.group(0)!;
      final placeholder = match.group(1)!;
      switch (placeholder) {
        case 'index':
          replacement = index.toString();
          break;
        case 'number':
          final offset = parameters.asInt('offset');
          final step = parameters.asInt('step');
          replacement = (offset + index * step).toString();
          break;
        case 'number0':
        case 'number1':
        case 'number2':
        case 'number3':
        case 'number4':
        case 'number5':
        case 'number6':
        case 'number7':
        case 'number8':
        case 'number9':
          final index2 = placeholder.codeUnits[6] - '0'.codeUnits[0];
          final offset =
              parameters.asListMemberInt('Offsets', index2, defaultValue: 0);
          final step =
              parameters.asListMemberInt('Steps', index2, defaultValue: 1);
          replacement = (offset + index * step).toString();
          break;
        case 'value':
          replacement = parameters.asListMemberString('Values', index);
          break;
        case 'value0':
        case 'value1':
        case 'value2':
        case 'value3':
        case 'value4':
        case 'value5':
        case 'value6':
        case 'value7':
        case 'value8':
        case 'value9':
          final index2 = placeholder.codeUnits[5] - '0'.codeUnits[0];
          final items = parameters.asListMemberList('ListValues', index2);
          if (items.length < index) {
            throw WordingError(
                '"ListValues": entry $index is too short: $items');
          }
          replacement = items[index];
          break;
        case 'char':
          replacement = String.fromCharCode(
              parameters.asString('baseChar').codeUnits[0] + index);
          break;
        case 'char0':
        case 'char1':
        case 'char2':
        case 'char3':
        case 'char4':
        case 'char5':
        case 'char6':
        case 'char7':
        case 'char8':
        case 'char9':
          if (!parameters.hasParameter('BaseChars')) {
            throw WordingError(
                'placeholder %$placeholder% detected. Missing parameter BaseChars');
          }
          final bases = parameters.asString('BaseChars');
          final index2 = placeholder.codeUnits[4] - '0'.codeUnits[0];
          if (index2 >= bases.length) {
            throw WordingError(
                'placeholder %$placeholder% detected: BaseChars is too short: $bases');
          }
          replacement = String.fromCharCode(bases[index2].codeUnits[0] + index);
          break;
        default:
          break;
      }
      rc = rc.replaceFirst(macro, replacement);
    }
    return rc;
  }

  /// Searches the first hit of a given list of patterns in an interval of lines.
  /// [:lines:] is a list of lines to inspect.
  /// [:patterns:] is a list of regular expressions to find.
  /// [:hit:]: OUT: returns the RegExpMatch instance and the index of the matching
  /// pattern in [:patterns:].
  /// [:from:] is the first index of [:lines:] to inspect.
  /// [:until:] is the first index of [:lines:] not to inspect (excluding).
  /// Returns null if not found, or the line index of the first hit.
  int? search(List<String> lines, List<RegExp> patterns, Hit hit,
      {int from = 0, int? until}) {
    int? rc;
    until ??= lines.length;
    while (rc == null && from < until) {
      var ix = 0;
      final line = lines[from];
      for (var regExp in patterns) {
        if ((hit.hit = regExp.firstMatch(line)) != null) {
          hit.index = ix;
          rc = from;
          break;
        }
        ix++;
      }
      from++;
    }
    return rc;
  }

  /// Splits the command into [:parameters:].
  /// [:expected:]: the meta data of the parameters of the related command.
  /// [:stringParameters:] contains a list of parameters, e.g. 'rexp=/\d/ value="123"
  /// Returns the description of the parameters as ParameterSet instance.
  ParameterSet splitParameters(MapParameterInfo expected) {
    String abbreviation = '';
    final MapParameter map = {};
    final parameterNames = namesOf(expected);
    while (errorMessage == null && stringParameters.isNotEmpty) {
      final name = expandParameter(
          abbreviation = stringParameters.split(regExpEndOfParameter)[0],
          parameterNames);
      if (name == null) {
        throw InternalError('splitParameter()', 'cannot expand $name');
      }
      if (!expected.containsKey(name)) {
        throw InternalError('splitParameter()', 'not in expected: $name');
      }
      final expectedParameter = expected[name]!;
      stringParameters = stringParameters.substring(abbreviation.length);
      if (!stringParameters.startsWith('=')) {
        map[name] = ParameterValue(ParameterType.bool);
        stringParameters = stringParameters.trimLeft();
        if (expectedParameter.type != ParameterType.bool) {
          throw WordingError('parameter "$name" needs "="');
        }
      } else {
        stringParameters = stringParameters.substring(1);
        switch (expectedParameter.type) {
          case ParameterType.bool:
            throw InternalError('splitParameters()',
                'unexpected type: ${expectedParameter.type}');
          case ParameterType.nat:
            final match = regExprNumber.firstMatch(stringParameters);
            if (match == null) {
              final head = stringParameters.length > 5
                  ? stringParameters.substring(0, 5)
                  : stringParameters;
              throw WordingError(
                  'parameter "$name": non negative number expected, not $head');
            }
            map[name] = ParameterValue(ParameterType.nat,
                natValue: int.parse(match.group(0)!));
            stringParameters =
                stringParameters.substring(match.group(0)!.length).trimLeft();
            break;
          case ParameterType.natList:
            parseIntList(name, map);
            break;
          case ParameterType.pattern:
            parseString(name, map, true);
            break;
          case ParameterType.patternList:
            parseStringList(name, map, isPattern: true);
            break;
          case ParameterType.string:
            if (expectedParameter.delimited) {
              parseString(name, map, false);
            } else {
              map[name] = ParameterValue(ParameterType.string,
                  string: unshiftNonSpaces());
            }
            break;
          case ParameterType.stringList:
            parseStringList(name, map, isPattern: false);
            break;
          case ParameterType.listOfStringList:
            parseListOfStringList(name, map);
            break;
        }
        stringParameters = stringParameters.trimLeft();
      }
    }
    return ParameterSet(map, this, expected);
  }

  /// Stores the given [:content:] into the buffer specified by parameter "output"
  /// depending on the parameter "append".
  void store(ParameterSet current, String content) {
    final target = current.asString('output');
    if (current.asBool('append')) {
      buffers[target] = getBuffer(target) + content;
    } else {
      buffers[target] = content;
    }
  }

  /// Returns the first character from [:stringParameters:] and remove it.
  /// [:error:] is the error message, if no character is available.
  /// [:pattern:]: null or a regular expression to validate the character.
  String unshiftChar(String error, RegExp? pattern) {
    if (stringParameters.isEmpty) {
      throw WordingError('$error (too short)');
    }
    final rc = stringParameters[0];
    stringParameters = stringParameters.substring(1);
    if (pattern != null && !pattern.hasMatch(rc)) {
      throw WordingError('$error not allowed character: $rc');
    }
    return rc;
  }

  /// Returns all non spaces from the top of [:stringParameters:].
  /// That string is than removed from [:stringParameters:].
  String unshiftNonSpaces() {
    RegExpMatch? match = regExpNonSpaces.firstMatch(stringParameters);
    String rc;
    if (match == null) {
      rc = '';
    } else {
      rc = match.group(0)!;
      stringParameters = stringParameters.substring(rc.length).trimLeft();
    }
    return rc;
  }

  /// Returns the full name of a command, given as abbreviation.
  /// [:abbreviation:]: the first part of a command name.
  /// Throws [:WordingError:] on error.
  String _expand(String object, String abbreviation, List<String> names) {
    String rc = '';
    String error = '';
    for (var name in names) {
      if (name == abbreviation) {
        rc = name;
        break;
      }
      if (name.startsWith(abbreviation)) {
        if (rc.isEmpty) {
          rc = name;
        } else {
          if (error.isEmpty) {
            error = 'ambiguous $object "$abbreviation": $rc/$name';
          } else {
            error = '$error/$name';
          }
        }
      }
    }
    if (error.isEmpty && rc.isEmpty) {
      error = 'unknown $object "$abbreviation"';
    }
    if (error.isNotEmpty) {
      throw WordingError(error);
    }
    return rc;
  }
}

/// Each error in command formulation throw this exception.
class WordingError extends FormatException {
  String message;

  WordingError(this.message);

  @override
  String toString() {
    return 'WordingError: $message';
  }
}
