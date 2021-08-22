import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import "helical.dart";
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:form_field_validator/form_field_validator.dart';

class AppBody extends StatefulWidget {
  @override
  AppBodyState createState() {
    return AppBodyState();
  }
}

class AppBodyState extends State<AppBody> {
  String generatedGcodeData = "";
  bool enableDownload = false;
  TextEditingController textEditingController = TextEditingController();
  Helical helical = new Helical();
  GlobalKey<FormState> _form = GlobalKey<FormState>();
  double axesIconSize = 200;

  Widget gcodeWidget(BuildContext context) {
    return Row(children: [
      Center(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: TextField(
                  controller: TextEditingController(text: generatedGcodeData),
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: 10,
                ),
              )))
    ]);
  }

  Widget generatedGcodeWidget(BuildContext context) {
    return Flexible(
        child: Column(children: [
      TextField(
        controller: textEditingController,
        decoration: const InputDecoration(
            labelText: "File name",
            hintText: "gearGcode",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder()),
        onChanged: (String text) => {
          if (text.isNotEmpty && text.length > 1)
            setState(() {
              enableDownload = true;
            })
        },
      ),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(primary: Colors.orangeAccent),
                    onPressed: () => {
                          setState(() {
                            generatedGcodeData = "";
                          })
                        },
                    child: const Text("Back")),
                ElevatedButton(
                    onPressed: () async {
                      if (!kIsWeb) {
                        if (Platform.isIOS || Platform.isAndroid) {
                          bool status = await Permission.storage.isGranted;
                          if (!status) await Permission.storage.request();
                        }
                      }
                      String fileName = (textEditingController.text == "")
                          ? "gearGcode"
                          : textEditingController.text;
                      var path;
                      Directory dir = await getApplicationDocumentsDirectory();
                      Directory? dirn = await getDownloadsDirectory();
                      if (dirn != null) {
                        dir = dirn;
                      }
                      if (!kIsWeb) {
                        path = await FilesystemPicker.open(
                          title: 'Save to folder',
                          context: context,
                          rootDirectory: dir,
                          fsType: FilesystemType.folder,
                          pickText: 'Save file to this folder',
                          folderIconColor: Colors.teal,
                        );
                        final file =
                            File(path.toString() + '/' + fileName + '.ngc');
                        file.writeAsString(generatedGcodeData);
                        path = file.absolute;
                      } else {
                        MimeType type = MimeType.TEXT;
                        List<int> list = generatedGcodeData.codeUnits;
                        Uint8List bytes = Uint8List.fromList(list);
                        path = await FileSaver.instance.saveFile(
                            textEditingController.text == ""
                                ? "gearGcode"
                                : textEditingController.text,
                            bytes,
                            "ngc",
                            mimeType: type);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('The file have been saved to ' +
                                path.toString())),
                      );
                    },
                    child: const Text("Save File"))
              ])),
      Container(
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
              child: TextField(
            controller: TextEditingController(text: generatedGcodeData),
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: 10,
          )))
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _form,
        child: ListView(shrinkWrap: true, children: [
          Row(
              //Row1
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  Text(
                    'Units:',
                    style: new TextStyle(fontSize: 15.0),
                  ),
                  Container(
                      color: helical.units == Units.metric
                          ? Colors.greenAccent
                          : null,
                      child: Row(children: [
                        Radio(
                          value: Units.metric,
                          groupValue: helical.units,
                          onChanged: (val) {
                            setState(() {
                              helical.units = Units.metric;
                              generatedGcodeData = "";
                            });
                          },
                        ),
                        Text(
                          'Metric (mm)',
                          style: new TextStyle(fontSize: 10.0),
                        ),
                      ])),
                  Container(
                      color: helical.units == Units.imperial
                          ? Colors.greenAccent
                          : null,
                      child: Row(children: [
                        Radio(
                          value: Units.imperial,
                          groupValue: helical.units,
                          onChanged: (val) {
                            setState(() {
                              helical.units = Units.imperial;
                              generatedGcodeData = "";
                            });
                          },
                        ),
                        Text(
                          'Imperial (inch)',
                          style: new TextStyle(fontSize: 10.0),
                        ),
                      ]))
                ]),
                Row(children: [
                  Column(children: [
                    Text(
                      'Working axis (touch over to expand):',
                      style: new TextStyle(fontSize: 15.0),
                    ),
                    IconButton(
                      icon: SvgPicture.asset('assets/images/axes.svg'),
                      iconSize: axesIconSize,
                      onPressed: () {
                        axesIconSize = axesIconSize == 500 ? 200 : 500;
                      },
                    )
                  ]),
                  Column(children: [
                    Container(
                        color: helical.workingAxis == WorkingAxis.XA
                            ? Colors.greenAccent
                            : null,
                        child: Row(children: [
                          Radio(
                            value: WorkingAxis.XA,
                            groupValue: helical.workingAxis,
                            onChanged: (val) {
                              setState(() {
                                helical.workingAxis = WorkingAxis.XA;
                                generatedGcodeData = "";
                              });
                            },
                          ),
                          Text(
                            'Cut moves along X and A rotation',
                            style: new TextStyle(fontSize: 10.0),
                          )
                        ])),
                    Container(
                        color: helical.workingAxis == WorkingAxis.ZA
                            ? Colors.greenAccent
                            : null,
                        child: Row(children: [
                          Radio(
                            value: WorkingAxis.ZA,
                            groupValue: helical.workingAxis,
                            onChanged: (val) {
                              setState(() {
                                helical.workingAxis = WorkingAxis.ZA;
                                generatedGcodeData = "";
                              });
                            },
                          ),
                          Text(
                            'Cut moves along Z and C rotation ',
                            style: new TextStyle(fontSize: 10.0),
                          )
                        ]))
                  ]),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 0),
                      child: Column(children: <Widget>[
                        Text(
                          'Cut direction:',
                          style: new TextStyle(fontSize: 15.0),
                        ),
                        Container(
                            color: helical.cutFrom == 1
                                ? Colors.greenAccent
                                : null,
                            child: Row(children: [
                              Radio(
                                value: 1,
                                groupValue: helical.cutFrom,
                                onChanged: (val) {
                                  setState(() {
                                    helical.cutFrom = 1;
                                    generatedGcodeData = "";
                                  });
                                },
                              ),
                              Text(
                                'Axis positive',
                                style: new TextStyle(
                                  fontSize: 10.0,
                                ),
                              )
                            ])),
                        Container(
                            color: helical.cutFrom == -1
                                ? Colors.greenAccent
                                : null,
                            child: Row(children: [
                              Radio(
                                value: -1,
                                groupValue: helical.cutFrom,
                                onChanged: (val) {
                                  setState(() {
                                    helical.cutFrom = -1;
                                    generatedGcodeData = "";
                                  });
                                },
                              ),
                              Text(
                                'Axis negative',
                                style: new TextStyle(
                                  fontSize: 10.0,
                                ),
                              )
                            ]))
                      ])),
                ]),
              ]),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Row(
                  //Row2
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Column(children: [
                    //   Text(
                    //     'Tooth face style:',
                    //     style: new TextStyle(fontSize: 15.0),
                    //   ),
                    //   Container(
                    //       color: helical.withLeadIn == false
                    //           ? Colors.greenAccent
                    //           : null,
                    //       child: Row(children: [
                    //         Radio(
                    //           value: false,
                    //           groupValue: helical.withLeadIn,
                    //           onChanged: (val) {
                    //             setState(() {
                    //               helical.withLeadIn = false;
                    //               generatedGcodeData = "";
                    //             });
                    //           },
                    //         ),
                    //         IconButton(
                    //           icon: SvgPicture.asset(
                    //               'assets/images/tooth_square.svg'),
                    //           iconSize: 70,
                    //           onPressed: () {
                    //             setState(() {
                    //               helical.withLeadIn = false;
                    //               generatedGcodeData = "";
                    //             });
                    //           },
                    //         ),
                    //         Text(
                    //           'Square',
                    //           style: new TextStyle(fontSize: 10.0),
                    //         ),
                    //       ])),
                    //   Container(
                    //       color: helical.withLeadIn == true
                    //           ? Colors.greenAccent
                    //           : null,
                    //       child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.start,
                    //           children: [
                    //             Radio(
                    //               value: true,
                    //               groupValue: helical.withLeadIn,
                    //               onChanged: (val) {
                    //                 setState(() {
                    //                   helical.withLeadIn = true;
                    //                   generatedGcodeData = "";
                    //                 });
                    //               },
                    //             ),
                    //             IconButton(
                    //               icon: SvgPicture.asset(
                    //                   'assets/images/tooth_rounded.svg'),
                    //               iconSize: 70,
                    //               onPressed: () {
                    //                 setState(() {
                    //                   helical.withLeadIn = true;
                    //                   generatedGcodeData = "";
                    //                 });
                    //               },
                    //             ),
                    //             Text(
                    //               'Curved',
                    //               style: new TextStyle(fontSize: 10.0),
                    //             ),
                    //           ])),
                    // ]),
                    Column(
                      children: [
                        Text(
                          'Gear Style:',
                          style: new TextStyle(fontSize: 15.0),
                        ),
                        Container(
                            color: helical.gearStyle == GearStyle.spur
                                ? Colors.greenAccent
                                : null,
                            child: Row(children: [
                              Radio(
                                value: GearStyle.spur,
                                groupValue: helical.gearStyle,
                                onChanged: (val) {
                                  setState(() {
                                    helical.gearStyle = GearStyle.spur;
                                    generatedGcodeData = "";
                                  });
                                },
                              ),
                              Text(
                                'Spur Gear',
                                style: new TextStyle(fontSize: 10.0),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                    'assets/images/spurGear.svg'),
                                iconSize: 80,
                                onPressed: () {
                                  setState(() {
                                    helical.leadAngle = 90;
                                    helical.gearStyle = GearStyle.spur;
                                    generatedGcodeData = "";
                                  });
                                },
                              )
                            ])),
                        Container(
                            color: helical.gearStyle == GearStyle.helical
                                ? Colors.greenAccent
                                : null,
                            child: Row(children: [
                              Radio(
                                value: GearStyle.helical,
                                groupValue: helical.gearStyle,
                                onChanged: (val) {
                                  setState(() {
                                    helical.leadAngle = 80;
                                    helical.gearStyle = GearStyle.helical;
                                    generatedGcodeData = "";
                                  });
                                },
                              ),
                              Text(
                                'Helical',
                                style: new TextStyle(
                                  fontSize: 10.0,
                                ),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                    'assets/images/leftHand.svg'),
                                iconSize: 80,
                                onPressed: () {
                                  setState(() {
                                    helical.leadAngle = 80;
                                    helical.gearStyle = GearStyle.helical;
                                    generatedGcodeData = "";
                                  });
                                },
                              )
                            ]))
                      ],
                    ),
                    if (helical.gearStyle == GearStyle.helical)
                      Column(children: [
                        Text(
                          'Helical gear rotation direction (Right/Left) hand:',
                          textAlign: TextAlign.justify,
                          style: new TextStyle(fontSize: 15.0),
                        ),
                        Column(children: [
                          Container(
                              color: helical.helicalGearRotationDirection ==
                                      HelicalGearRotationDirection.leftHand
                                  ? Colors.greenAccent
                                  : null,
                              child: Row(children: [
                                Radio(
                                  value: HelicalGearRotationDirection.leftHand,
                                  groupValue:
                                      helical.helicalGearRotationDirection,
                                  onChanged: (val) {
                                    setState(() {
                                      helical.helicalGearRotationDirection =
                                          HelicalGearRotationDirection.leftHand;
                                      generatedGcodeData = "";
                                    });
                                  },
                                ),
                                Text(
                                  'Left hand rotation',
                                  style: new TextStyle(
                                    fontSize: 10.0,
                                  ),
                                ),
                                IconButton(
                                  icon: SvgPicture.asset(
                                      'assets/images/leftHand.svg'),
                                  iconSize: 80,
                                  onPressed: () {
                                    setState(() {
                                      helical.helicalGearRotationDirection =
                                          HelicalGearRotationDirection.leftHand;
                                      generatedGcodeData = "";
                                    });
                                  },
                                )
                              ])),
                          Container(
                              color: helical.helicalGearRotationDirection ==
                                      HelicalGearRotationDirection.rightHand
                                  ? Colors.greenAccent
                                  : null,
                              child: Row(children: [
                                Radio(
                                  value: HelicalGearRotationDirection.rightHand,
                                  groupValue:
                                      helical.helicalGearRotationDirection,
                                  onChanged: (val) {
                                    setState(() {
                                      helical.helicalGearRotationDirection =
                                          HelicalGearRotationDirection
                                              .rightHand;
                                      generatedGcodeData = "";
                                    });
                                  },
                                ),
                                Text(
                                  'Right hand rotation',
                                  style: new TextStyle(fontSize: 10.0),
                                ),
                                IconButton(
                                  icon: SvgPicture.asset(
                                      'assets/images/rightHand.svg'),
                                  iconSize: 80,
                                  onPressed: () {
                                    setState(() {
                                      helical.helicalGearRotationDirection =
                                          HelicalGearRotationDirection
                                              .rightHand;
                                      generatedGcodeData = "";
                                    });
                                  },
                                ),
                              ]))
                        ])
                      ])
                  ])),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                  //Row3
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Flexible(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 0),
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  initialValue: helical.outsideDiameter
                                      .toStringAsFixed(3),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Gear Outside diameter" +
                                        (Units.metric == helical.units
                                            ? " (mm)"
                                            : " (inch)"),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,6}')),
                                  ],
                                  // validator: RangeValidator(
                                  //     min: ((2 * helical.toothDepth) + 0.001),
                                  //     max: 99999999,
                                  //     errorText:
                                  //         "Gear Outside diameter should be between " +
                                  //             ((2 * helical.toothDepth) + 0.001)
                                  //                 .toString() +
                                  //             " and 99999999"),
                                  onChanged: (val) {
                                    setState(() {
                                      helical.outsideDiameter =
                                          double.parse(val);
                                      generatedGcodeData = "";
                                      helical.pitchDiameter =
                                          helical.calculatePitchDiameter(
                                              helical.outsideDiameter,
                                              helical.toothCount);
                                    });
                                  },
                                )
                              ],
                            ))),
                    Flexible(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 0),
                            child: Column(children: <Widget>[
                              new Container(
                                  child: new TextFormField(
                                initialValue:
                                    helical.gearWidth.toStringAsFixed(3),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Gear Width (gear Face)" +
                                      (Units.metric == helical.units
                                          ? " (mm)"
                                          : " (inch)"),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,6}')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    helical.gearWidth = double.parse(val);
                                    generatedGcodeData = "";
                                  });
                                },
                              ))
                            ]))),
                    Flexible(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 0),
                            child: TextFormField(
                              initialValue:
                                  helical.toothCount.toStringAsFixed(0),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Number of tooths (u)",
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  helical.toothCount = int.parse(val);
                                  helical.pitchDiameter =
                                      helical.calculatePitchDiameter(
                                          helical.outsideDiameter,
                                          helical.toothCount);
                                  generatedGcodeData = "";
                                });
                              },
                            ))),
                    Flexible(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                        child: TextFormField(
                          initialValue: helical.toothDepth.toStringAsFixed(3),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Tooth depth" +
                                (Units.metric == helical.units
                                    ? " (mm)"
                                    : " (inch)"),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,6}')),
                          ],
                          validator: RangeValidator(
                              min: 0.001,
                              max: ((helical.outsideDiameter / 2) - 0.001),
                              errorText: "Valid values 0.001 and " +
                                  ((helical.outsideDiameter / 2) - 0.001)
                                      .toString()),
                          onChanged: (val) {
                            setState(() {
                              helical.toothDepth = double.parse(val);
                              generatedGcodeData = "";
                              helical.pitchDiameter =
                                  helical.calculatePitchDiameter(
                                      helical.outsideDiameter,
                                      helical.toothCount);
                            });
                          },
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                        child: TextFormField(
                          initialValue: helical.feedRate.toStringAsFixed(3),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Feed rate",
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              helical.feedRate = double.parse(val);
                              generatedGcodeData = "";
                            });
                          },
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                        child: TextFormField(
                          initialValue: helical.seekRate.toStringAsFixed(3),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Seek rate",
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              helical.seekRate = double.parse(val);
                              generatedGcodeData = "";
                            });
                          },
                        ),
                      ),
                    )
                  ])),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                  //Row4
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Flexible(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                        child: TextFormField(
                          initialValue:
                              helical.safetyDistance.toStringAsFixed(3),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Safety distance" +
                                (Units.metric == helical.units
                                    ? " (mm)"
                                    : " (inch)"),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              helical.safetyDistance = double.parse(val);
                              generatedGcodeData = "";
                            });
                          },
                        ),
                      ),
                    ),
                    Flexible(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 0),
                            child: Column(children: <Widget>[
                              DropdownButtonFormField(
                                  decoration: InputDecoration(
                                      labelText:
                                          'Tooth milling steps (toot depth in N passes):'),
                                  items: List<int>.generate(10, (i) => i + 1)
                                      .map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: new Text(value.toString()),
                                    );
                                  }).toList(),
                                  value: helical.millingToothDepthSteps,
                                  onChanged: (val) {
                                    setState(() {
                                      helical.millingToothDepthSteps =
                                          int.parse(val.toString());
                                      generatedGcodeData = "";
                                    });
                                  })
                            ]))),
                    // if (helical.withLeadIn == true)
                    //   Flexible(
                    //       child: Padding(
                    //           padding: EdgeInsets.symmetric(
                    //               horizontal: 5, vertical: 0),
                    //           child: Column(children: <Widget>[
                    //             TextFormField(
                    //                 initialValue: helical.cutterDiameter
                    //                     .toStringAsFixed(3),
                    //                 decoration: InputDecoration(
                    //                   border: OutlineInputBorder(),
                    //                   labelText: "Cutter tool diameter" +
                    //                       (Units.metric == helical.units
                    //                           ? " (mm)"
                    //                           : " (inch)"),
                    //                 ),
                    //                 inputFormatters: [
                    //                   FilteringTextInputFormatter.allow(
                    //                       RegExp(r'^\d+\.?\d{0,6}')),
                    //                 ],
                    //                 onChanged: (val) {
                    //                   setState(() {
                    //                     helical.cutterDiameter =
                    //                         double.parse(val);
                    //                     generatedGcodeData = "";
                    //                   });
                    //                 })
                    //           ]))),

                    if (helical.gearStyle == GearStyle.helical)
                      Flexible(
                          child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 0),
                              child: Column(children: <Widget>[
                                TextFormField(
                                    initialValue:
                                        helical.leadAngle.toStringAsFixed(0),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: "Lead angle (º)",
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    validator: RangeValidator(
                                        min: 1,
                                        max: 89,
                                        errorText: "Accepted values 1º -> 89º"),
                                    onChanged: (val) {
                                      setState(() {
                                        helical.leadAngle = double.parse(val);
                                        generatedGcodeData = "";
                                      });
                                    })
                              ]))),
                  ])),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                  //Row5
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    if (generatedGcodeData.length == 0)
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_form.currentState!.validate()) {
                              setState(() {
                                generatedGcodeData = helical.generateGcode();
                              });
                            }
                            // Validate returns true if the form is valid, or false otherwise.
                          },
                          child: const Text('Generate'),
                        ),
                      ),
                    if (generatedGcodeData.length > 0)
                      generatedGcodeWidget(context)
                  ]))
        ]));
  }
}
/*        
        if (generated == true)
          
    );
  }
}*/
