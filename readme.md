# update-addons.ps1 Script

- [update-addons.ps1 Script](#update-addonsps1-script)
    - [A simple script to keep your World of Warcraft Addons up to date](#a-simple-script-to-keep-your-world-of-warcraft-addons-up-to-date)
    - [Usage](#usage)
        - [addons.csv](#addonscsv)
    - [Project layout](#project-layout)

## A simple script to keep your World of Warcraft Addons up to date

I just don't want to use the Twitch Client anymore for updating my addons. And after seeing amazing projects in scripting like the python variant from Derek Kuhnert's [wow-addon-updater](https://github.com/kuhnerdm/wow-addon-updater) written in python, I want to have something similar for the .NET world with powershell.

My script is heavily copied from the ideas from Peter Provost's [update-addons.ps1](https://github.com/PProvost/dotfiles/blob/master/powershell/modules/posh-wow/update-addons.ps1). But I updated it to today's websites and tweaked it here and there.

## Usage

This addon uses a csv file to manage addon information you want to keep updated. Normally this is stored in the same path as the `update-addons.ps1` file.

Use `UpdateAddons -scan.bat` to see which addons are currently stored in your WoW/Interface/Addons directory to configure the csv file.

To run, execute `update-addons.ps1` in powershell or click `UpdateAddons.bat`.

### addons.csv

First line is always the base description:

>Name,Source,UID

The data is stored in each line representing the info, seperated by commas:

| field  | description                                       | valid parameters                      |
| ------ | ------------------------------------------------- | ------------------------------------- |
| Name   | the Name of the folder you see when used the scan | string                                |
| Source | the Website to look for the addon ()              | curseforge, wowi, skip, packaged-with |
| UID    | the identifier of the addon                       | string in url                         |

e.g. for Weakauras you have the following data in the file (from url: `https://www.curseforge.com/wow/addons/weakauras-2`)

>Name,Source,UID
>
>WeakAuras,curseforge,weakauras-2

## Project layout

Just as a reference: My projects are laid out like this

| folder  | description                                |
| ------- | ------------------------------------------ |
| build   | output from build.bat                      |
| code    | here goes all the code                     |
| scripts | here goes all the development scripts used |

If you wonder about the `shell.bat`: Read the blog post from Anthony Reddan [here](http://anthonyreddan.com/active-project-shell/). Long story short: It is a way to setup the command line for this project and is only used to get the right path when opening up my dev commandline :).