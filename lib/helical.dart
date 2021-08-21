import 'dart:math' as math;

enum GearStyle { spur, helical }
enum HelicalGearRotationDirection { rightHand, leftHand }
enum WorkingAxis { XA, ZA }
enum Units { metric, imperial }

class Helical {
  var gearStyle = GearStyle.spur;
  var workingAxis = WorkingAxis.XA;
  var units = Units.metric;
  double outsideDiameter = 50;
  double toothDepth = 5;
  int toothCount = 5;
  double pitchDiameter = 5 / ((5 + 2) / 50);
  double gearWidth = 10;
  double cutterDiameter = 1;
  var helicalGearRotationDirection = HelicalGearRotationDirection.rightHand;
  double leadAngle = 90;
  int millingToothDepthSteps = 2;
  int cutFrom = 1;
  double safetyDistance = 3;
  double feedRate = 50;
  double seekRate = 200;
  double leadInOutOfTool = 0;
  double calculatedToothAngle = 90;
  bool withLeadIn = false;

  gcodeSeek(arrayMovements) {
    var concatenate = StringBuffer();
    arrayMovements.forEach((k) {
      concatenate.write((concatenate.isEmpty ? '' : ' ') +
          k.keys.toList()[0] +
          k.values.toList()[0]);
    });
    return "G00 " +
        concatenate.toString() +
        " F" +
        seekRate.toStringAsFixed(0) +
        "\n";
  }

  gcodeFeed(arrayMovements) {
    var concatenate = StringBuffer();
    arrayMovements.forEach((k) {
      concatenate.write((concatenate.isEmpty ? '' : ' ') +
          k.keys.toList()[0] +
          k.values.toList()[0]);
    });
    return "G01 " +
        concatenate.toString() +
        " F" +
        feedRate.toStringAsFixed(0) +
        "\n";
  }

  String calculateToothGcode(
      int toothNumber, double depth, int step, int totalSteps) {
    var s = "(TOOTH " +
        (toothNumber + 1).toString() +
        "/" +
        toothCount.toString() +
        ((totalSteps > 1)
            ? (", step " + step.toString() + "/" + totalSteps.toString())
            : "") +
        ", depth:" +
        depth.toStringAsFixed(3) +
        ")\n";

    //Zero from the middle of the gear
    //double y0 = ((outsideDiameter + cutterDiameter) / 2);
    //Zero from the top of the gear
    double y0 = outsideDiameter;
    double a0 = 360 / toothCount * toothNumber;

    var spindleAxis = workingAxis == WorkingAxis.XA ? "Z" : "X";
    var xAxis = (workingAxis == WorkingAxis.XA) ? 'X' : 'Z';
    var xAxisMayInvert = (workingAxis == WorkingAxis.XA) ? 1 : -1;
    var aAxis = (workingAxis == WorkingAxis.XA) ? 'A' : 'B';
    // go to safety distance
    s += gcodeSeek([
      {spindleAxis: ((y0 + safetyDistance) * cutFrom).toStringAsFixed(3)}
    ]);

    s += gcodeSeek([
      {xAxis: (xAxisMayInvert * -leadInOutOfTool).toStringAsFixed(3)},
      {aAxis: (a0 * cutFrom).toStringAsFixed(3)},
    ]);

    s += gcodeSeek([
      {spindleAxis: ((y0 - depth) * cutFrom).toStringAsFixed(3)},
    ]);

    s += gcodeFeed([
      {
        xAxis:
            (xAxisMayInvert * (gearWidth + leadInOutOfTool)).toStringAsFixed(3)
      },
      {aAxis: ((a0 + calculatedToothAngle) * cutFrom).toStringAsFixed(3)},
    ]);

    s += gcodeSeek([
      {spindleAxis: ((y0 + safetyDistance) * cutFrom).toStringAsFixed(3)}
    ]);
    return s;
  }

  double calculatePitchDiameter(outsideDiameter, numberOfTooths) {
    /* Pitch diameter (D) defined by:
    https://www.bostongear.com/-/media/Files/Literature/Brand/boston-gear/catalogs/p-1930-bg-sections/p-1930-bg_engineering-info-spur-gears.ashx
    Number of Teeth(N) & Diametral Pitch(P)
    D=N/P
    
    Diametral pitch(P) is given approx by Number of tooths and Outside diameter (Do)
    P=(N+2)/Do
    */
    double diametralPitch = (numberOfTooths + 2) / outsideDiameter;
    double pitchDiameterD = numberOfTooths / diametralPitch;
    return pitchDiameterD;
  }

  generateGcode() {
    // leadInOutOfTool = withLeadIn ? calculateLeadInOutOfTool(cutterDiameter, toothDepth) : 0;
    double helixAngle = (90 - leadAngle).abs();
    /* Pitch diameter (D) defined by:
    https://www.bostongear.com/-/media/Files/Literature/Brand/boston-gear/catalogs/p-1930-bg-sections/p-1930-bg_engineering-info-spur-gears.ashx
    Number of Teeth(N) & Diametral Pitch(P)
    D=N/P
    
    Diametral pitch(P) is given approx by Number of tooths and Outside diameter (Do)
    P=(N+2)/Do
    */
    pitchDiameter = calculatePitchDiameter(outsideDiameter, toothCount);

    if (gearStyle == GearStyle.helical) {
      calculatedToothAngle = calculateToothAngle(
          pitchDiameter,
          gearWidth + 2 * leadInOutOfTool,
          helixAngle *
              (helicalGearRotationDirection ==
                      HelicalGearRotationDirection.leftHand
                  ? -1
                  : 1));
    } else {
      calculatedToothAngle = 0;
    }

    String gcode = "(Spur/helical Gear g-code generator)\n";
    gcode += "(code by Alejandro Blanco <alecuba16@gmail.com)\n";
    gcode +=
        "(Warning test in-the-air without the milling tool to be sure that doesn't break anything)\n";
    gcode += "\n";

    gcode += units == Units.metric
        ? "G21 (Coordinates in millimeters)\n"
        : "G20 (Coordinates in  Imperial, inch)\n";
    gcode += "G40 (Cancel cutter radius compensation)\n";
    gcode += "G49 (Cancel cutter length offset)\n";
    gcode += "G90 (Absolute coordinates mode)\n";
    gcode += "G98 (Retract to initial Z)\n";
    gcode += "G0 " +
        seekRate.toStringAsFixed(0) +
        " (Seek rate set to " +
        seekRate.toStringAsFixed(0) +
        ")\n";
    gcode += "G1 " +
        feedRate.toStringAsFixed(0) +
        " (Feed rate set to " +
        feedRate.toStringAsFixed(0) +
        ")\n";
    gcode += "\n";
    gcode += "M3 (Spindle start)\n";
    gcode += "G4 P4000 (Wait 4 seconds for the spindle start)\n";
    gcode += "\n";

    int currentTooth;
    double acummDepth;
    double stepDepth =
        (toothDepth / millingToothDepthSteps * 1000).floor() / 1000;
    int step;
    for (currentTooth = 0; currentTooth < toothCount; currentTooth++) {
      gcode += "\n";
      acummDepth = 0;
      step = 1;
      while (acummDepth < toothDepth) {
        if ((acummDepth + stepDepth) < toothDepth) {
          acummDepth += stepDepth;
          gcode += calculateToothGcode(
              currentTooth, acummDepth, step, millingToothDepthSteps);
        } else {
          acummDepth = toothDepth;
          gcode += calculateToothGcode(
              currentTooth, acummDepth, step, millingToothDepthSteps);
        }
        step++;
      }
    }
    gcode += "\n";
    gcode += "M5 (Stop spindle)\n";
    gcode += "M2 (End program)\n";

    return gcode;
  }

  calculateLeadInOutOfTool(cutterDiameter, toothDepth) {
    return math.sqrt((cutterDiameter * toothDepth) - math.pow(toothDepth, 2));
  }

  double deg2rad(double deg) => deg * (math.pi / 180.0);
  double rad2deg(double rad) => rad * (180.0 / math.pi);

  calculateToothAngle(pitchDiameter, gearWidth, helixAngle) {
    double angleAbsoluteValue = helixAngle.abs();
    double complementaryAngle = 90 - angleAbsoluteValue;
    double tmp = math.sin(deg2rad(complementaryAngle)) / gearWidth;
    double angleLenght = math.sin(deg2rad(angleAbsoluteValue)) / tmp;
    double circleLenght = math.pi * pitchDiameter;
    double toothAngle = (360 / circleLenght) * angleLenght;
    return (helixAngle < 0) ? -toothAngle : toothAngle;
  }
}
