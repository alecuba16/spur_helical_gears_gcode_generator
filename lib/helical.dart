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
  double pitchDiameter = 15;
  int toothCount = 5;
  double toothDepth = 5;
  double gearWidth = 10;
  double cutterDiameter = 8;
  var helicalGearRotationDirection = HelicalGearRotationDirection.rightHand;
  double helicalAngle = 90;
  double roughingStepDown = 10;
  double finishingStepDown = 0;
  int cutFrom = 1;
  double safetyDistance = 3;
  double feedRate = 50;
  double seekRate = 200;
  double leadInOut = 0;
  double calculatedToothAngle = 90;

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
        this.seekRate.toStringAsFixed(0) +
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
        this.feedRate.toStringAsFixed(0) +
        "\n";
  }

  String tooth2g(int toothNumber, {depth}) {
    if (depth == null) {
      depth = this.toothDepth;
    }
    var s = "(TOOTH " +
        (toothNumber + 1).toString() +
        "/" +
        this.toothCount.toString() +
        ", depth:" +
        depth.toString() +
        ")\n";

    double y0 = ((this.outsideDiameter + this.cutterDiameter) / 2);
    double a0 = 360 / this.toothCount * toothNumber;

    var spindleAxis = this.workingAxis == WorkingAxis.XA ? "Z" : "X";
    var xAxis = (this.workingAxis == WorkingAxis.XA) ? 'X' : 'Z';
    var xAxisMayInvert = (this.workingAxis == WorkingAxis.XA) ? 1 : -1;
    // go to safety distance
    s += gcodeSeek([
      {
        spindleAxis:
            ((y0 + this.safetyDistance) * this.cutFrom).toStringAsFixed(3)
      }
    ]);

    s += gcodeSeek([
      {xAxis: (xAxisMayInvert * -this.leadInOut).toStringAsFixed(3)},
      {'A': (a0 * this.cutFrom).toStringAsFixed(3)},
    ]);

    s += gcodeSeek([
      {spindleAxis: ((y0 - depth) * this.cutFrom).toStringAsFixed(3)},
    ]);

    s += gcodeFeed([
      {
        xAxis: (xAxisMayInvert * (this.gearWidth + this.leadInOut))
            .toStringAsFixed(3)
      },
      {
        'A':
            ((a0 + this.calculatedToothAngle) * this.cutFrom).toStringAsFixed(3)
      },
    ]);

    s += gcodeSeek([
      {
        spindleAxis:
            ((y0 + this.safetyDistance) * this.cutFrom).toStringAsFixed(3)
      }
    ]);
    return s;
  }

  gcode() {
    this.leadInOut = this.getLeadInOut(this.cutterDiameter, this.toothDepth);

    if (this.gearStyle == GearStyle.spur) {
      this.calculatedToothAngle = 0;
    } else {
      this.calculatedToothAngle = this.getToothAngle(
          this.pitchDiameter,
          this.gearWidth + 2 * this.leadInOut,
          this.helicalAngle *
              (helicalGearRotationDirection ==
                      HelicalGearRotationDirection.leftHand
                  ? -1
                  : 1));
    }

    String gcode = "(Spur/helical Gear g-code generator)\n";
    gcode += "(author Alejandro Blanco <alecuba16@gmail.com)\n";
    gcode += "\n";

    // setup everything
    //gcode += "G17 (XY plane)\n";

    gcode += this.units == Units.metric
        ? "G21 (Coordinates in millimeters)\n"
        : "G20 (Coordinates in  Imperial, inch)\n";
    gcode += "G90 (Absolute coordinates mode)\n";
    gcode += "G40 (Cancel cutter radius compensation)\n";
    gcode += "G49 (Cancel cutter length offset)\n";
    gcode += "G98 (Retract to initial Z)\n";
    gcode += "G0 " +
        this.seekRate.toStringAsFixed(0) +
        " (Seek rate set to " +
        this.seekRate.toStringAsFixed(0) +
        ")\n";
    gcode += "G1 " +
        this.feedRate.toStringAsFixed(0) +
        " (Feed rate set to " +
        this.feedRate.toStringAsFixed(0) +
        ")\n";
    gcode += "\n";
    gcode += "M3 (Spindle start)\n";
    gcode += "G4 P4000 (Wait 4 seconds for the spindle start)\n";
    gcode += "\n";

    int tooth;
    double depth = 0;
    //double other_steps=0;
    double totalRoughingDepth;
    for (tooth = 0; tooth < this.toothCount; tooth++) {
      gcode += "\n";
      depth = 0;
      totalRoughingDepth = this.toothDepth - this.finishingStepDown;
      while (depth < totalRoughingDepth) {
        if ((depth + this.roughingStepDown) < totalRoughingDepth) {
          depth += this.roughingStepDown;
          gcode += tooth2g(tooth, depth: depth);
        } else {
          depth = totalRoughingDepth;
          gcode += this.tooth2g(tooth, depth: totalRoughingDepth);
        }
      }

      //other_steps = totalRoughingDepth / this.roughingStepDown;

      // Do finishing cut only if it is significant.
      if ((this.finishingStepDown.abs()) > 0.001) {
        gcode += this.tooth2g(tooth, depth: null);
      }
    }

    gcode += "\n";
    gcode += "M5 (Stop spindle)\n";
    gcode += "M2 (End program)\n";

    return gcode;
  }

  getLeadInOut(cutterDiameter, toothDepth) {
    return math.sqrt((cutterDiameter * toothDepth) - math.pow(toothDepth, 2));
  }

  double deg2rad(double deg) => deg * (math.pi / 180.0);
  double rad2deg(double rad) => rad * (180.0 / math.pi);

  getToothAngle(pitchDiameter, width, angle) {
    double absAngle = angle.abs();
    double otherAngle = 90 - absAngle;
    double tmp1 = math.sin(deg2rad(otherAngle)) / width;
    double angleLenght = math.sin(deg2rad(absAngle)) / tmp1;
    double circleLenght = math.pi * pitchDiameter;
    double toothAngle = (360 / circleLenght) * angleLenght;
    return (angle < 0) ? -toothAngle : toothAngle;
  }
}
