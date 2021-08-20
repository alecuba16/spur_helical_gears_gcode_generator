# Author
Alejandro Blanco-M ![email](https://raw.githubusercontent.com/alecuba16/profile/main/email.jpg)

<https://github.com/alecuba16>

## License
Copyright by Alejandro Blanco-M. Licensed under Eclipse Public License v2.0.

## Warning!
Consider this code/program as in the beta stage. This means that any GCODE generated should be handled carefully. I recommend trying first the generated GCODE without the milling tool and with enough distance from the milling head to the table, also to set up the feed/seek rates I recommend using a wood base material to test which speed is better for your case.

## Usage
Select the units (mm/inch). Select the working axis, which is where the spindle moves (commonly at the Z, in vertical), or X-axis, if your milling machine has the head horizontally like a lathe machine.  The A axis is assumed to be at the X-Y plane. Select what kind of gear you want to make, spur (90º degree teeth gear) or helical. In case of a helical select right hand or left-handed. Fill the other required fields, which are diameter, gear with, number of tooth, etc. Once you have checked everything is consistent, you can press generate button, and a screen with the gcode will appear at the bottom of the interface. You can copy from them or download by setting the filename field (predefined to gearGcode) and then pressing save file.

## Screenshot

![Windows executable screenshot](https://raw.githubusercontent.com/alecuba16/spur_helical_gears_gcode_generator/main/screenshot.png)
