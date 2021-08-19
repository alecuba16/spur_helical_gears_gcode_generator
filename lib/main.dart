import 'package:flutter/material.dart';
import 'appbody.dart';

const gcode_header =
    "G17 (XY plane) G21 (Coordinates in millimeters) G40 (Cancel cutter radius compensation) G49 (Cancel cutter length offset) G54 (Coordinate system?) G80 (Cancel motion mode) G90 (Absolute coordinates mode) G98 (Retract to prior position) M3 (Spindle start) G0 F%d, this->seekRate ) G1 F%d, this->feedRate )";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTitle = 'Spur/helical gear gcode generator';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: Text(appTitle),
        ),
        body: AppBody(),
      ),
    );
  }
}
