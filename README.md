# Matlab GUI creation using JSON
## Background
Well, I needed something quick and dirty and I wanted to use it also for Python.

Do you need a dialog in MATLAB in five minutes?
Well this could work for you if you don't have too high expectations.

This hacky code is translating a simplified dialog declaration (JSON syntax) into a MATLAB GUI and also keeps the values stored (in the same JSON file).

So any values you enter into the gui fields are stored in the JSON configuration file for the next call.

To use this in your program a MATLAB structure is returned with all the values.

## Quick start
```
params = json_GUI('params','parameter_file.json')
```
This will read the parameter_file creating and showing a dialog.
You can enter values into the dialog and the values will be stored into the json file and also returned as a structure (params).

## Create a default JSON definition
```
json_GUI('init','new_params.json')
```

This creates a new file `new_params.json` with all available dialog element definitions.

Simply open and edit the JSON file adding new elements.

Each new element is aligned in one column.

If you need to start a new column of items in the dialogue frame you have to add an `Position` element:

```
{"type":"Position",
"name":"pos_offset",
"help":"Move subsequent parameter elements in the GUI by some offset X and Y",
"X":0.4,
"Y":0.92},
```
This will start a new column at X=0.4 and Y=0.92 based on the fraction of the total size of the GUI.
That means X starts the column at 0.4 of the width of the GUI and Y at 0.92 from the top relative to the GUI height.

## What it is not
This is not supposed to be extensible, although there might be some minor tweaks that could be done.
This is not supposed to be complete, but help yourself in case you think you like it.

I may not develop this too much further as it is then better to use more professional tools.
But let me know if it is just something minor.

