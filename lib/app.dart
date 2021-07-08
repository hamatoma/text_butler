import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

import 'text_butler.dart';
import 'text_butler_io.dart';

class BufferInfo {
  final int id;
  String bufferName = '';
  final controller = TextEditingController();
  BufferInfo(this.id, [this.bufferName = '']);
}

class FieldState {
  final bufferInfo = <BufferInfo>[
    BufferInfo(0),
    BufferInfo(1),
    BufferInfo(2),
    BufferInfo(3)
  ];
  String command = '';
  var bufferNames = <String>[];

  /// Return -1 or the id of the first bufferInfo with [name] as buffer name.
  int hasBuffer(String name) {
    var rc = -1;
    for (var info in bufferInfo) {
      if (info.bufferName == name) {
        rc = info.id;
        break;
      }
    }
    return rc;
  }

  /// Ensures that the buffer names of all displayed buffer are different.
  void organizeBuffers(int id, List<String> defaultNames) {
    final bufferName = bufferInfo[id].bufferName;
    for (var info in bufferInfo) {
      if (info.id != id) {
        if (info.bufferName == bufferName) {
          for (var name in defaultNames) {
            if (hasBuffer(name) < 0) {
              info.bufferName = name;
              break;
            }
          }
        }
      }
    }
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final regExpLayout = RegExp(r'ratio=(\d+(\.\d+)?)');
  double _ratio = 1.0;
  double _lastWidth = 0;
  double _lastHeight = 0;
  final fieldState = FieldState();
  final textManipulator = TextButlerIO();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'text_butler');
  final _layoutController = TextEditingController();

  final _commandController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    handleDimension(context);
    final padding = 16.0;
    fieldState.bufferNames = textManipulator.buffers.keys.toList();
    fieldState.bufferNames.sort();
    final widgets = Column(children: [
      TextFormField(
        controller: _commandController,
        decoration: InputDecoration(labelText: 'Command'),
      ),
      SizedBox(height: padding),
      Row(children: [
        Container(
            width: 200,
            child: ElevatedButton(
              onPressed: () => execute(context),
              child: Text('Execute'),
            )),
        SizedBox(width: padding),
        Expanded(
            child: Text(textManipulator.errorMessage ?? '',
                style: TextStyle(color: Colors.red))),
        SizedBox(width: padding),
        Row(
          children: <Widget>[
            Container(
                width: 200,
                child: TextFormField(
                  controller: _layoutController,
                  decoration: InputDecoration(labelText: 'Layout'),
                )),
            Container(
                width: 100,
                child: ElevatedButton(
                  onPressed: () => handleLayout(_layoutController.text),
                  child: Text('Resize'),
                )),
          ],
        ),
      ]),
      Expanded(
          child: GridView.count(
              primary: false,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: _ratio,
              crossAxisCount: 2,
              shrinkWrap: true,
              children: <Widget>[
            gridItem(0, padding),
            gridItem(1, padding),
            gridItem(2, padding),
            gridItem(3, padding),
          ]))
    ]);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Form(
          key: _formKey,
          child: Card(
              margin:
                  EdgeInsets.symmetric(vertical: padding, horizontal: padding),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: padding, horizontal: padding),
                child: widgets,
              ))),
    );
  }

  void execute(context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final command = _commandController.text;
      // Note: the "focus lost" is not thrown if the button is pressed
      // So we must safe the buffer content of "input":
      int ix;
      if ((ix = fieldState.hasBuffer('input')) >= 0) {
        final info = fieldState.bufferInfo[ix];
        if (info.bufferName == 'input') {
          textManipulator.buffers[info.bufferName] = info.controller.text;
        }
      }
      textManipulator.execute(command);
      setState(() => 1);
    }
  }

  Widget gridItem(int id, double padding) {
    //final items = <DropdownMenuItem<int>>[];
    var ix = 0;
    final info = fieldState.bufferInfo[id];
    final items = fieldState.bufferNames
        .map((name) => DropdownMenuItem<int>(child: Text(name), value: ix++))
        .toList(growable: false);
    if (info.bufferName.isEmpty) {
      info.bufferName = TextButler.defaultBufferNames[id];
    }
    info.controller.text = info.bufferName.isEmpty
        ? ''
        : textManipulator.getBuffer(info.bufferName);

    final rc = Column(children: [
      DropdownButtonFormField<int>(
        key: GlobalKey(debugLabel: 'dropdown_$id'),
        value: fieldState.bufferNames
            .indexOf(fieldState.bufferInfo[id].bufferName),
        items: items,
        isExpanded: true,
        decoration: InputDecoration(labelText: 'Buffer ${id + 1}'),
        onChanged: (value) {
          if (value != null) {
            fieldState.bufferInfo[id].bufferName =
                fieldState.bufferNames[value];
            fieldState.organizeBuffers(id, TextButler.defaultBufferNames);
            setState(() => 1);
          }
        },
      ),
      SizedBox(
        height: padding,
      ),
      Expanded(
          child: Card(
        child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                if (info.bufferName == 'input') {
                  textManipulator.buffers[info.bufferName] =
                      info.controller.text;
                  setState(() {
                    //
                  });
                }
              }
            },
            child: TextField(
              key: GlobalKey(debugLabel: 'buffer_$id'),
              expands: true,
              maxLines: null,
              minLines: null,
              onSubmitted: (String content) {
                if (info.bufferName == 'input') {
                  textManipulator.buffers[info.bufferName] = content;
                }
              },
              controller: fieldState.bufferInfo[id].controller,
              // decoration: InputDecoration.collapsed(hintText: "Enter your text here"),
            )),
      ))
    ]);
    return rc;
  }

  void handleDimension(BuildContext context) {
    // Full screen width and height
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    // Height (without SafeArea)
    var padding = MediaQuery.of(context).padding;
    //double height1 = height - padding.top - padding.bottom;

    // Height (without status bar)
    //double height2 = height - padding.top;

    // Height (without status and toolbar)
    double height3 = height - padding.top - kToolbarHeight;
    if ((_lastWidth - width).abs() >= 1.0 ||
        (_lastHeight - height3).abs() >= 1.0) {
      _ratio = width / height3;
      _layoutController.text = 'ratio=' + sprintf('%.1f', [_ratio]);
      _lastWidth = width;
      _lastHeight = height3;
    }
  }

  void handleLayout(String input) {
    RegExpMatch? match;
    if ((match = regExpLayout.firstMatch(input)) != null) {
      _ratio = double.parse(match!.group(1)!);
      setState(() => 1);
    }
  }

  @override
  void initState() {
    super.initState();
    //_commandController.text = r'duplicate count=5 pattern="#" template=/<%index%> /';
    //textManipulator.buffers['input'] = 'one # xxx\n';
  }
}
