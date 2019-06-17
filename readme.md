# Update-Addons (Powershell)

## A simple script to keep your World of Warcraft Addons up to date

I just don't want to use the Twitch Client anymore for updating my addons. And after seeing amazing
projects in scripting like the python variant from Derek Kuhnert's
[wow-addon-updater](https://github.com/kuhnerdm/wow-addon-updater) written in python, I want to have
something similar for the .NET world with powershell.

My script is heavily copied from the ideas from Peter Provost's
[update-addons.ps1](https://github.com/PProvost/dotfiles/blob/master/powershell/modules/posh-wow/update-addons.ps1).
But I updated it to today's websites and tweaked it here and there.

## Installation

Just download the master branch as a zip file or use the zip files listed in the releases category
of this repo and extract the files on your drive and edit the [addons.csv](#addonscsv). Then you are ready to
go.

### scoop

You can also use this script with [scoop](https://scoop.sh/). Just install this script with the
following command

```text
scoop install https://raw.githubusercontent.com/Marakuja/UpdateAddons/master/UpdateAddons.json
```

You get some preconfigured batch files added to your start menu for easy use.

- UpdateAddons (main script)
- UpdateAddons -Scan
- UpdateAddons -Edit

## Usage

This addon uses a csv file to manage addon information you want to keep updated. This has to be
stored in the same path as the `UpdateAddons.ps1` file.

You can call `UpdateAddons.ps1` via PowerShell if script execution is enabled on your pc. Otherwise
you can use `Start_UpdateAddons.bat` for starting the script without trouble. Parameters can be
given to either one of the ways in the following way.

### Parameter `-ManifestPath`

You can define another location for your addons.csv. Just put the full path to the file into this
parameter.

```text
Update-Addons -ManifestPath "C:\full\path\to\addons.csv"
```

### Parameter `-Addon`

Just search for and update the Addon name you give to the script. It must be defined in your
`addons.csv` however.

```text
Update-Addons -Addon "WeakAuras"
```

### Parameter `-Scan`

Use this to output which addons are currently stored in your WoW/_retail/Interface/Addons directory
to help you configure the csv file.

```text
Update-Addons -Scan
```

### Parameter `-Edit`

You can edit the `addons.csv` directly with this command. The standard editor for CSV files will be
called and you can edit the data here.

```text
Update-Addons -Edit
```

## addons.csv

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

### Source: curseforge

For Weakauras you have the following data in the file (from url):

`https://www.curseforge.com/wow/addons/weakauras-2`

```text
Name,Source,UID
WeakAuras,curseforge,weakauras-2
```

### Source: wowinterface

For BigWigs you have the following data in the file (from url):

`https://wowinterface.com/downloads/info5086-BigWigsBossmods.html`

```text
Name,Source,UID
BigWigs,wowinterface,5086
```

### Source: skip

For own managed addons (here "AddonDirectory"), you can type the following

```text
AddonDirectory,skip,null
```

### Source: packaged-with

For AddonDirectories, which are part of a main Addon, you can use the 'packaged-with' source

```text
Name,Source,UID
WeakAuras,curseforge,weakauras-2
WeakAurasModelPaths,packaged-with,WeakAuras
WeakAurasOptions,packaged-with,WeakAuras
WeakAurasTemplates,packaged-with,WeakAuras
```
