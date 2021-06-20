typedef MapParameter = Map<String, String?>;

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

  /// If [pattern] does not match, this message is print.
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
    if (type == ParameterType.int || type == ParameterType.intList) {
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

  /// Returns a parameter given by [name] as an integer.
  bool asBool(String name) {
    bool rc = map.containsKey(name) && (map[name] == null || map[name] == 'T');
    return rc;
  }

  /// Returns a parameter given by [name] as an integer.
  int asInt(String name) {
    if (!map.containsKey(name)) {
      throw InternalError('ParameterSet.asInt', 'unknown parameter $name');
    }
    int? rc = int.tryParse(map[name]!);
    if (rc == null) {
      throw InternalError(
          'ParameterSet.asInt', 'not an int: parameter "$name"');
    }
    return rc;
  }

  /// Returns a member of a "auto selector list" stored in parameter [name].
  /// The list starts with a separator: free choice of a separator.
  /// Example: parameter 'animals' contains ",cat,dog".
  /// Returns the [index]-th member of the list.
  String asListMember(String name, int index) {
    String listAsString = asString(name);
    bool autoSeparator = expected[name]!.autoSeparator;
    if (!autoSeparator) {}
    List<String> list = !autoSeparator
        ? listAsString.split(',')
        : listAsString.substring(1).split(listAsString[0]);
    if (index < 0 || index >= list.length) {
      throw WordingError(
          'parameter "$name" contains too few list members: index: $index list: $listAsString');
    }
    return list[index];
  }

  /// Returns a member of a "auto selector list" stored in parameter [name].
  /// The list starts with a separator: free choice of a separator.
  /// Example: parameter 'animals' contains ",cat,dog".
  /// Returns the [index]-th member of the list.
  int asListMemberInt(String name, int index, {int? defaultValue}) {
    int? rc;
    if (!hasParameter(name)) {
      if (defaultValue == null) {
        throw WordingError('missing parameter $name');
      } else {
        rc = defaultValue;
      }
    }
    if (rc == null) {
      String item = asListMember(name, index);
      rc = int.tryParse(item);
      if (rc == null) {
        throw WordingError('parameter "$name" contains a non integer: $item');
      }
    }
    return rc;
  }

  /// Returns a parameter given by [name] as an integer.
  /// [defaultValue]: the result if [defaultValue] is not null and the parameter
  /// [name] is not defined:
  String asString(String name, {String? defaultValue}) {
    String rc;
    if (!map.containsKey(name)) {
      if (defaultValue != null) {
        rc = defaultValue;
      } else {
        throw InternalError('ParameterSet.asString', 'unknown parameter $name');
      }
    } else {
      rc = map[name]!;
    }
    return rc;
  }

  /// Checks whether one of two parameters is defined or none.
  /// [first] is the name of the first parameter to inspect.
  /// [second] is the name of the second parameter to inspect.
  /// On error [WordingError] is thrown.
  void checkAtMostOneOf(String first, String second) {
    if (map.containsKey(first) && map.containsKey(second)) {
      throw WordingError(
          'Do not define parameter "$first" and "$second" at the same time');
    }
  }

  /// Checks whether exactly one of two parameters is defined.
  /// [first] is the name of the first parameter to inspect.
  /// [second] is the name of the second parameter to inspect.
  /// On error [WordingError] is thrown.
  void checkExactlyOneOf(String first, String second) {
    if (!map.containsKey(first) && !map.containsKey(second)) {
      throw WordingError('missing parameter "$first" or "$second"');
    }
    if (map.containsKey(first) && map.containsKey(second)) {
      throw WordingError('define parameter "$first" or "$second", not both');
    }
  }

  /// Returns the length of a list (stringList, intList...) given by [name].
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
      case ParameterType.intList:
        rc = current.split(',').length;
        break;
      case ParameterType.regExpList:
      case ParameterType.stringList:
        final separator = info.autoSeparator ? current[0] : ',';
        rc = current.split(separator).length - (info.autoSeparator ? 1 : 0);
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
  void setIfUndefined(String name, String? value) {
    if (!map.containsKey(name)) {
      map[name] = value;
    }
  }

  /// Tests whether two list parameters have the same length.
  /// If not a [WordingException] is thrown.
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
  int,
  regExp,
  string,
  stringList,
  intList,
  regExpList
}

/// Implements a text processor that interprets "commands" to convert
/// an input string into another.
/// Administrates "buffers" that can store intermediate results.
///
class TextButler {
  static TextButler? lastInstance;
  static final _examplesBasic = <String>[
    'clear output=history',
    '',
    'copy input=input output=output append',
    'copy text="Hello" output=output',
    '',
    r'count regexpr="\d+" output=count',
    '',
    'duplicate count=2 offset=100 step=10',
    r'#input: index: %index% item: %number% name: %char%\n',
    '',
    'duplicate count=3 Offsets=10,0 Steps=10,1 BaseChars=Aa meta=%"',
    r'#input: "no: %index% id: %number0% place %char0% class %char1%\n',
    '',
    'duplicate count=2 offset=1 Values=",cat,dog"',
    r'#input: "%number%: %value%\n"',
    '',
    'duplicate count=2 ListValues=";,cat,dog;,Mia,Harro;,London,Rome"',
    r'#input: A %value0% named %value1% comes from %value2%."',
    '',
    'execute input=input',
    r'#input: copy text="Hi "\ncopy append text="world',
    ''
        r'filter start=/^Name: Miller/ end=/^Name:/ filter=/^\s*[^#\s]/',
    r'filter Filters=%/<(name|id|email>(.*?)</href="(.*?)"% meta=% Templates=",%group2%: %group1%1,link: %group2%"',
    '',
    r'replace regexpr=/ (\d+)/ meta=\ with=": \0"',
    r'replace what="Hello" value="Hi"',
    '',
    'show what=buffers',
    '',
    'swap a=input b=output',
  ];
  List<String> get examples => _examplesBasic;
  static final defaultBufferNames = ['input', 'history', 'output', 'examples'];
  static const patternBufferName = r'^[a-zA-Z]\w*$';
  String? errorLineInfo;
  final commandNames = <String>[];
  final buffers = <String, String>{'output': '', 'input': '', 'history': ''};
  String? errorMessage;
  final regExpEndOfParameter = RegExp(r'[ =]');
  final regExprAutoSeparator = RegExp(r'[^a-zA-Z0-9]');

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
  final paramIntDefault1 =
      ParameterInfo(ParameterType.int, defaultValue: '1', optional: false);
  final paramIntList = ParameterInfo(ParameterType.intList, delimited: false);
  final paramIntNeeded = ParameterInfo(ParameterType.int, optional: false);
  final paramMarker = ParameterInfo(ParameterType.string,
      defaultValue: '#', minLength: 1, optional: false);
  final paramMeta = ParameterInfo(ParameterType.string,
      defaultValue: '%',
      optional: false,
      minLength: 1,
      maxLength: 1,
      delimited: false);
  final paramRegExpList =
      ParameterInfo(ParameterType.regExpList, autoSeparator: true);
  final paramOffset =
      ParameterInfo(ParameterType.int, defaultValue: '0', optional: false);
  final paramRegExpr = ParameterInfo(ParameterType.regExp, minLength: 1);
  final paramStep =
      ParameterInfo(ParameterType.int, optional: false, defaultValue: '1');
  final paramSteps = ParameterInfo(ParameterType.intList, delimited: false);
  final paramString = ParameterInfo(ParameterType.string);
  final paramStringListAutoSeparator = ParameterInfo(ParameterType.stringList,
      minLength: 2, autoSeparator: true);
  final paramStringMinLength1 =
      ParameterInfo(ParameterType.string, minLength: 1);

  var groupPattern = RegExp(r'%(\w+)%');

  TextButler() {
    for (var item in examples) {
      final name = item.split(' ')[0];
      if (!commandNames.contains(name)) {
        commandNames.add(name);
      }
    }
    buffers['history'] = '';
    buffers['examples'] = examples.join('\n');
  }

  /// Tests whether the [current] parameters match the [expected].
  /// Throws [WordingErrors] on error.
  void checkParameters(ParameterSet current, MapParameterInfo expected) {
    /// Supply default values in current if that does not exist:
    for (var entry in expected.entries) {
      if (!current.hasParameter(entry.key) &&
          entry.value.defaultValue != null &&
          !entry.value.optional) {
        current.map[entry.key] = entry.value.defaultValue;
      }
    }
    for (var name in current.map.keys) {
      if (!expected.containsKey(name)) {
        throw WordingError('unknown parameter "$name"');
      } else {
        final expectedParameter = expected[name];
        var currentValue = current.map[name];
        if (expectedParameter!.defaultValue != null && currentValue == null) {
          currentValue = current.map[name] = expectedParameter.defaultValue;
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
              if (currentValue.length < expectedParameter.minLength) {
                throw WordingError(
                    'parameter "$name" is too short (${expectedParameter.minLength}): $currentValue');
              }
              if (currentValue.length > expectedParameter.maxLength) {
                throw WordingError(
                    'parameter "$name" is too long (${expectedParameter.maxLength}): $currentValue');
              }
              if (expectedParameter.pattern != null &&
                  expectedParameter.pattern!.firstMatch(currentValue) == null) {
                final message = expectedParameter.patternError != null
                    ? expectedParameter.patternError
                    : 'wrong syntax in parameter "$name": $currentValue';
                throw WordingError(message!);
              }
            }
            break;
          case ParameterType.int:
            if (currentValue == null) {
              throw WordingError('missing int value in parameter "$name"');
            } else if (int.tryParse(currentValue) == null) {
              throw WordingError(
                  'parameter "$name" must be an int not $currentValue');
            }
            break;
          case ParameterType.regExp:
            if (currentValue != null)
              try {
                RegExp(currentValue);
              } on Exception catch (exc) {
                throw WordingError(
                    'wrong regular expression in parameter "$name": $exc');
              }
            break;
          case ParameterType.regExpList:
            if (currentValue != null) {
              List<String> list;
              if (expectedParameter.autoSeparator) {
                if (currentValue.length < 2) {
                  throw WordingError(
                      'parameter "$name" is too short for auto-delimiter');
                }
                list = currentValue.substring(1).split(currentValue[0]);
              } else {
                list = currentValue.split(',');
              }
              for (var item in list) {
                try {
                  RegExp(item);
                } on Exception catch (exc) {
                  errorMessage =
                      'wrong regular expression in parameter "$name": $exc [$item]';
                }
              }
            }
            break;
          case ParameterType.stringList:
            if (currentValue != null &&
                expectedParameter.autoSeparator &&
                regExprAutoSeparator.firstMatch(currentValue) == null) {
              throw WordingError(
                  'parameter "$name" must start with a separator, e.g. ",one,two"');
            }
            break;
          case ParameterType.intList:
            if (currentValue!.isEmpty && !expectedParameter.optional) {
              throw WordingError('parameter "$name" is empty');
            }
            final list = currentValue.split(',');
            for (var item in list) {
              if (int.tryParse(item) == null) {
                throw WordingError(
                    'parameter "$name" has a non int $item in list: $currentValue');
              }
            }
            if (list.length < expectedParameter.minLength) {
              throw WordingError(
                  'parameter "$name" has too few list entries (${expectedParameter.minLength}): $currentValue');
            }
            if (list.length > expectedParameter.maxLength) {
              throw WordingError(
                  'parameter "$name" has too many entries (${expectedParameter.maxLength}): $currentValue');
            }
            break;
        }
      }
    }
  }

  /// Executes the command [commandName] with the [parameters].
  /// This method must be overridden by classes to expand to other commands.
  bool dispatch(String? commandName, String parameters) {
    var toHistory = true;
    switch (commandName) {
      case 'clear':
        toHistory = false;
        executeClear(parameters);
        break;
      case 'copy':
        executeCopy(parameters);
        break;
      case 'count':
        executeCount(parameters);
        break;
      case 'duplicate':
        executeDuplicate(parameters);
        break;
      case 'execute':
        executeExecute(parameters);
        break;
      case 'filter':
        executeFilter(parameters);
        break;
      case 'replace':
        executeReplace(parameters);
        break;
      case 'show':
        executeShow(parameters);
        break;
      case 'swap':
        executeSwap(parameters);
        break;
      default:
        throw WordingError('unknown command: "$commandName"');
    }
    return toHistory;
  }

  /// Executes a command.
  /// [command] is a command (with parameters) like "show what=buffers"
  /// [input] is the string to manipulate.
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

  /// Implements the command "clear" specified by some [parameters].
  /// Throws an exception on errors.
  void executeClear(String parameters) {
    // 'copy input=input output=output append',
    final expected = {
      'output': paramBufferName,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final target = current.asString('output');
    buffers[target] = '';
  }

  /// Implements the command "copy" specified by some [parameters].
  /// Throws an exception on errors.
  void executeCopy(String parameters) {
    // 'copy input=input output=output append',
    final expected = {
      'append': paramBool,
      'input': paramBufferName,
      'output': paramBufferName,
      'text': paramString,
    };
    final current = splitParameters(parameters, expected);
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

  /// Implements the command "count" specified by some [parameters].
  /// Throws an exception on errors.
  void executeCount(String parameters) {
    // r'count regexpr="\d+" output=count',
    final expected = {
      'append': paramBool,
      'ignore': paramBool,
      'input': paramBufferName,
      'output': paramBufferName,
      'marker': paramMarker,
      'template': paramStringMinLength1,
      'regexpr': paramRegExpr,
      'what': paramString,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    current.checkExactlyOneOf('regexpr', 'what');
    final source = getBuffer(current.asString('input'));
    final target = current.asString('output');
    var count = 0;
    final ignoreCase = current.asBool('ignore');
    final append = current.asBool('append');
    if (current.hasParameter('what')) {
      current.map['regexpr'] = RegExp.escape(current.asString('what'));
    }
    count = RegExp(current.asString('regexpr'), caseSensitive: !ignoreCase)
        .allMatches(source)
        .length;
    final template = current.asString('template', defaultValue: '');
    final result = template.isEmpty
        ? count.toString()
        : template.replaceAll(current.asString('marker'), count.toString());
    buffers[target] = append ? getBuffer(target) + result : result;
  }

  /// Implements the command "duplicate" specified by some [parameters].
  /// Throws an exception on errors.
  void executeDuplicate(String parameters) {
    //     'duplicate count=5 var=# offset=-1 meta=% value=/%n/',
    final expected = {
      'append': paramBool,
      'baseChar': paramBaseChar,
      'BaseChars': paramBaseChars,
      'count': paramIntNeeded,
      'input': paramBufferName,
      'ListValues': paramStringListAutoSeparator,
      'offset': paramOffset,
      'Offsets': paramIntList,
      'output': paramBufferName,
      'meta': paramMeta,
      'step': paramIntDefault1,
      'Steps': paramSteps,
      'Values': paramStringListAutoSeparator,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('input', 'input');
    current.testSameListLength('Offsets', 'Steps');
    current.testSameListLength('Steps', 'ListValues');
    current.testSameListLength('Offsets', 'ListValues');
    checkParameters(current, expected);
    final input = getBuffer(current.asString('input'));
    StringBuffer buffer = StringBuffer();
    final count = current.asInt('count');
    for (var ix = 0; ix < count; ix++) {
      final part = replacePlaceholders(input, ix, current);
      buffer.write(part);
    }
    store(current, buffer.toString());
  }

  /// Implements the command "execute" specified by some [parameters].
  /// Throws an exception on errors.
  void executeExecute(String parameters) {
    // 'execute input=filter_log',
    final expected = {
      'input': paramBufferName,
    };
    final current = splitParameters(parameters, expected);
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

  /// Implements the command "replace" specified by some [parameters].
  /// Throws an exception on errors.
  void executeFilter(String parameters) {
    // r'filter start=/^Name: Miller/ end=/^Name:/ regexpr=/^\s*[^#\s] count=1/',
    // filter regexpr=/<(name|id|email>(.*?)</ meta=! template="!2: !1"'
    final expected = {
      'append': paramBool,
      'end': paramRegExpr,
      'filter': paramRegExpr,
      'Filters': paramRegExpList,
      'input': paramBufferName,
      'meta': paramMeta,
      'output': paramBufferName,
      'repeat': paramIntDefault1,
      'start': paramRegExpr,
      'template': paramString,
      'Templates': paramStringListAutoSeparator,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    current.checkExactlyOneOf('filter', 'Filters');
    current.checkAtMostOneOf('template', 'Templates');
    List<RegExp> filters;
    if (current.hasParameter('filter')) {
      filters = [RegExp(current.asString('filter'))];
    } else {
      filters = <RegExp>[];
      final patterns = current.asString('Filters');
      for (var pattern in patterns.substring(1).split(patterns[0])) {
        filters.add(RegExp(pattern));
      }
    }
    List<String>? templates;
    if (current.hasParameter('template')) {
      templates = [current.asString('template')];
    } else if (current.hasParameter('Templates')) {
      final templates2 = current.asString('Templates');
      templates = templates2.substring(1).split(templates2[0]);
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
            buffer.write(replaceGroups(hit.hit!, templates[hit.index!]));
          }
          start = ixHit! + 1;
        }
      }
      if (hasStart) {
        start = search(source, [RegExp(current.asString('start'))], hit,
            from: end + 1);
      }
      if (current.hasParameter('end')) {
        end = search(source, [RegExp(current.asString('start'))], hit,
                from: (start ?? 0) + 1) ??
            source.length - 1;
      }
    }
    store(current, buffer.toString());
  }

  /// Implements the command "replace" specified by some [parameters].
  /// Throws an exception on errors.
  void executeReplace(String parameters) {
    // r'replace regexpr=/ (\d+)/ meta=\ with=": \0"',
    // r'replace what="Hello" value="*"',
    final expected = {
      'append': paramBool,
      'input': paramBufferName,
      'output': paramBufferName,
      'meta': paramMeta,
      'regexpr': paramRegExpr,
      'value': paramString,
      'with': paramRegExpr,
      'what': paramString,
    };
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('input', 'input');
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    current.checkExactlyOneOf('value', 'with');
    current.checkExactlyOneOf('regexpr', 'what');
    final source = getBuffer(current.asString('input'));
    var count = 0;
    if (current.hasParameter('regexpr')) {
      count = RegExp(current.asString('regexpr')).allMatches(source).length;
    } else {
      var start = 0;
      final pattern = current.asString('what');
      while ((start = source.indexOf(pattern, start)) >= 0) {
        count++;
      }
    }
    final template = current.asString('template', defaultValue: '');
    store(
        current,
        template.isEmpty
            ? count.toString()
            : template.replaceAll(
                current.asString('marker'), count.toString()));
  }

  /// Implements the command "replace" specified by some [parameters].
  /// Throws an exception on errors.
  void executeShow(String parameters) {
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
    final current = splitParameters(parameters, expected);
    current.setIfUndefined('output', 'output');
    checkParameters(current, expected);
    final list = buffers.keys.toList();
    list.sort();
    store(current, list.join('\n'));
  }

  /// Implements the command "swap" specified by some [parameters].
  /// Throws an exception on errors.
  void executeSwap(String parameters) {
    // 'swap a=input b=output',
    final expected = {
      'a': paramBufferName,
      'b': paramBufferName,
    };
    final current = splitParameters(parameters, expected);
    checkParameters(current, expected);
    final a = current.asString('a');
    final b = current.asString('b');
    final contentA = getBuffer(a);
    final contentB = getBuffer(b);
    buffers[a] = contentB;
    buffers[b] = contentA;
  }

  /// Returns the full name of a command, given as abbreviation.
  /// [abbreviation]: the first part of a command name.
  /// Returns null on error ([errorMessage] is set in this case) or
  /// the full name of the command.
  String? expandCommand(String abbreviation) {
    final rc = _expand('command', abbreviation, commandNames);
    return rc;
  }

  /// Returns the full name of a command, given as abbreviation.
  /// [abbreviation]: the first part of a command name.
  /// Returns null on error ([errorMessage] is set in this case) or
  /// the full name of the command.
  String? expandParameter(String abbreviation, List<String> parameterNames) {
    final rc = _expand('parameter', abbreviation, parameterNames);
    return rc;
  }

  /// Returns the content of a buffer with [name].
  String getBuffer(String name) {
    if (!buffers.containsKey(name)) {
      throw WordingError('buffer "$name" does not exist');
    }
    final rc = buffers[name]!;
    return rc;
  }

  /// Replaces meta symbols in a given [value].
  /// [escChar] is a character that introduces a meta symbol.
  /// Meta symbols witch escChar backslash are \n (newline), \r (carriage return)
  /// \f (form feed) \t (tabulator) \v (vertical tabulator.
  /// Returns the interpolated [value].
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
          default:
            buffer.write(value[ix + 1]);
            break;
        }
        ix = value.indexOf(escChar, lastIx = ix + 2);
      }
    }
    return buffer.toString();
  }

  /// Returns the names defined in [expected].
  List<String> namesOf(MapParameterInfo expected) {
    final rc = expected.keys.toList(growable: false);
    return rc;
  }

  /// Replaces the templates in the 'filter' command.
  String replaceGroups(RegExpMatch filterMatch, String template) {
    String rc = template;
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
          replacement = parameters.asListMember('Values', index);
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
          final items = parameters.asListMember('ListValues', index2);
          if (items.length < 2) {
            throw WordingError(
                '"ListValues": entry $index2 is too short: $items');
          }
          final list = items.substring(1).split(items[0]);
          if (index >= list.length) {
            throw WordingError(
                '"ListValues": entry $index2 has too few items ($index): $items (${items.length})');
          }
          replacement = list[index];
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
  /// [lines] is a list of lines to inspect.
  /// [patterns] is a list of regular expressions to find.
  /// [hit]: OUT: returns the RegExpMatch instance and the index of the matching
  /// pattern in [patterns].
  /// [from] is the first index of [lines] to inspect.
  /// [until] is the first index of [lines] not to inspect (excluding).
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

  /// Splits the command into [parameters].
  /// [input] contains a list of parameters, e.g. 'rexp=/\d/ value="123"
  /// [parameters]: OUT the parameters will be stored in this map.
  /// Returns true on success or false otherwise: the error message is in [errorMessage].
  ParameterSet splitParameters(String input, MapParameterInfo expected) {
    String abbreviation = '';
    final MapParameter map = {};
    final parameterNames = namesOf(expected);
    while (errorMessage == null && input.isNotEmpty) {
      final name = expandParameter(
          abbreviation = input.split(regExpEndOfParameter)[0], parameterNames);
      if (name == null) {
        throw InternalError('splitParameter()', 'cannot expand $name');
      }
      if (!expected.containsKey(name)) {
        throw InternalError('splitParameter()', 'not in expected: $name');
      }
      final expectedParameter = expected[name]!;
      input = input.substring(abbreviation.length);
      String? value;
      if (!input.startsWith('=')) {
        input = input.trimLeft();
      } else {
        input = input.substring(1);
        if (!expectedParameter.delimited) {
          value = input.split(' ')[0];
          input = input.substring(value.length).trimLeft();
        } else if (input.isEmpty) {
          throw WordingError('missing starting delimiter for $name');
        } else {
          final interpolate = input.startsWith('i');
          String delimiter;
          String? escChar;
          if (!interpolate) {
            delimiter = input[0];
            input = input.substring(1);
          } else {
            if (input.length < 4) {
              throw WordingError(
                  'interpolated string to short: at least ESC character and two delimiters expected');
            }
            escChar = input[1];
            delimiter = input[2];
            input = input.substring(3);
          }
          final index = input.indexOf(delimiter);
          if (index < 0) {
            throw WordingError(
                'missing end delimiter $delimiter for parameter "$name"');
          } else {
            value = input.substring(0, index);
            if (interpolate) {
              value = interpolateString(escChar!, value);
            }
            input = input.substring(index + 1).trimLeft();
          }
        }
      }
      map[name] = value;
    }
    return ParameterSet(map, this, expected);
  }

  /// Returns the full name of a command, given as abbreviation.
  /// [abbreviation]: the first part of a command name.
  /// Throws [WordingError] on error.
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

  /// Stores the given [content] into the buffer specified by parameter "output"
  /// depending on the parameter "append".
  void store(ParameterSet current, String content) {
    final target = current.asString('output');
    if (current.asBool('append')) {
      buffers[target] = getBuffer(target) + content;
    } else {
      buffers[target] = content;
    }
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
