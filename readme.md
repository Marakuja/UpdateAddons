# Update-Addons (Powershell)

## A simple script to keep your World of Warcraft Addons up to date

I just don't want to use the Twitch Client anymore for updating my addons. And after seeing amazing
projects in scripting like the python variant from Derek Kuhnert's
[wow-addon-updater](https://github.com/kuhnerdm/wow-addon-updater) written in python, I want to have
something similar for the .NET world with powershell.

My script is heavily copied from the ideas from Peter Provost's
[update-addons.ps1](https://github.com/PProvost/dotfiles/blob/master/powershell/modules/posh-wow/update-addons.ps1).
But I updated it to today's websites and tweaked it here and there.

## Usage

This addon uses a csv file to manage addon information you want to keep updated. This has to be
stored in the same path as the `UpdateAddons.ps1` file.

Use `.\UpdateAddons.ps1 -Scan` in PowerShell to see which addons are currently stored in your
WoW/_retail/Interface/Addons directory to help you configure the csv file.

To run, execute `.\UpdateAddons.ps1` in powershell or doubleclick `Start_UpdateAddons.bat`.

You can edit the addons.csv directly or call `.\UpdateAddons.ps1 -Edit` or `Start_UpdateAddons.bat
-Edit`.

### scoop

You can also use this script with [scoop](https://scoop.sh/). Just install this script with the
following command

> `scoop install https://raw.githubusercontent.com/Marakuja/UpdateAddons/master/UpdateAddons.json`

You get some preconfigured batch files added to your start menu for easy use.

- UpdateAddons (main script)
- UpdateAddons -Scan
- UpdateAddons -Edit

### addons.csv

First line is always the base description:

```text
Name,Source,UID
```

The data is stored in each line representing the info, seperated by commas:

| field  | description                                       | valid parameters                                |
| ------ | ------------------------------------------------- | ----------------------------------------------- |
| Name   | the Name of the folder you see when used the scan | <string> (drom directory)                       |
| Source | the Website to look for the addon                 | [curseforge, wowinterface, packaged-with, skip] |
| UID    | the identifier of the addon                       | <string> (from url)                             |

e.g. for Weakauras you have the following data in the file (from url):

`https://www.curseforge.com/wow/addons/weakauras-2`

```text
Name,Source,UID
WeakAuras,curseforge,weakauras-2
```

e.g. for BigWigs you have the following data in the file (from url):

`https://wowinterface.com/downloads/info5086-BigWigsBossmods.html`

```text
Name,Source,UID
BigWigs,wowi,5086
```
