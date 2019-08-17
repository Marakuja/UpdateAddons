<#
.SYNOPSIS
Updates World of Warcraft addons to the latest version
.DESCRIPTION
Use UpdateAddons.ps1 with your addons.csv file you have to create and set to the same path as the script or give the ManifestPath Parameter with path information
.PARAMETER ManifestPathRetail
Full path to the addons-retail.csv file, defaults to .\addons-retail.csv
.PARAMETER ManifestPathClassic
Full path to the addons-classic.csv file, default to .\addons-classic.csv
.PARAMETER Scan
Compares the contents of your csv file with your WoW Addons directories, default: false
.PARAMETER Edit
Opens addons.csv for editing in the default editor
.EXAMPLE
.\UpdateAddons.ps1, .\UpdateAddons.ps1 -scan
.NOTES
This script scans your registry for the installation path of World of Warcraft. Please bear in mind, this script is not perfect!

Reading of sample 'addons.csv' (first line has to be like that!!)
Name,Source,UID
WeakAuras,curseforge,weakauras-2
BigWigs,wowi,5086

Version 2.0.0
    Added classic as new option to manage addons (see addons-classic.csv)
    Renamed addons.csv to addons-retail.csv
Version 1.0.2
    fixed link scraping for curseforge as the site was changed a little
Version 1.0.1
    Scoop manifest fixes
Version 1.0.0
	Rework of script and repo
        Added scoop installer manifest
Version 0.1.1
	Fixed bug when addon name is with spaces
Version 0.1.0
	Startup batch added for convenient use
Version 0.0.1
	First working version of the script
#>

#Requires -Version 5

param (
    [string]$ManifestPathRetail = (Resolve-Path -Path "$PSScriptRoot\addons-retail.csv" -Erroraction SilentlyContinue),
    [string]$ManifestPathClassic = (Resolve-Path -path "$PSScriptRoot\addons-classic.csv" -Erroraction SilentlyContinue),
    #[string]$Addon = '',
    [switch]$Scan,
    [switch]$Edit
)

function output($msg, $tabs = 0) {
    Write-Output ("$("`t" * $tabs)$msg")
}
function abort($msg, [int]$ExitCode = 1) {
    $f = $host.ui.RawUI.ForegroundColor
    $host.ui.RawUI.ForegroundColor = "Red"
    Write-Output "ERROR $msg"
    $host.ui.RawUI.ForegroundColor = $f
    exit $ExitCode
}
function success($msg, $tabs = 0) {
    $f = $host.ui.RawUI.ForegroundColor
    $host.ui.RawUI.ForegroundColor = "Green"
    Write-Output ("$("`t" * $tabs)$msg")
    $host.ui.RawUI.ForegroundColor = $f
}

# path to the addons.csv
try {
    if (-not (Test-Path -Path $ManifestPathRetail) -or
        -not (Test-Path -Path $ManifestPathClassic)) {
        abort "You need to create an addons[-retail|-classic].csv to the script path or provide -ManifestPath Parameter with full Path to file!"
    }
} catch {
    abort "You need to create an addons.csv to the script path or provide -ManifestPath Parameter with full Path to file!"
}
$ManifestRetail = Import-Csv -Path $ManifestPathRetail -ErrorAction Stop
$ManifestClassic = Import-Csv -Path $ManifestPathClassic -ErrorAction Stop

if ($Edit) {
    # just open addons.csv and exit
    Start-Process -FilePath 'notepad.exe' -ArgumentList $ManifestPathRetail
    Start-Process -FilePath 'notepad.exe' -ArgumentList $ManifestPathClassic

    exit 0
}

# get current World of Warcraft installation path
if (Test-Path -Path 'HKLM:\SOFTWARE\Wow6432Node\Blizzard Entertainment\World of Warcraft') {
    $wowDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Blizzard Entertainment\World of Warcraft').InstallPath
}
else {
    if (Test-Path -Path 'HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft') {
        $wowDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft').InstallPath
    }
    else {
        abort "World of Warcraft Installation Path could not be found."
    }
}

$WowDirRetail = Join-Path -Path (Split-Path -Path $wowDir -Parent) -ChildPath "_retail_"
$WowAddonDirRetail = Join-Path -Path $WowDirRetail -ChildPath 'Interface\Addons'

$WowDirClassic = Join-Path -Path (Split-Path -Path $wowDir -Parent) -ChildPath "_classic_"
$WowAddonDirClassic = Join-Path -Path $WowDirClassic -ChildPath 'Interface\Addons'

# temp store location for downloaded files
$tempDir = Join-Path -Path $env:TEMP -ChildPath 'UpdateAddons'
if (-not (Test-Path -Path $tempDir)) { New-Item -Path $tempDir -Type Directory | Out-Null }
# webclient used for getting the files
$wc = New-Object System.Net.WebClient

# Name of the file created in every addon directory tracking current version information
$stateFile = 'UpdateAddons.state'

# scan the Interface/Addon directory and compare the contents with the contents of $ManifestPath
# TODO: needs updating to work with classic too
if ($scan) {
    $set = @{}

    $ManifestRetail | ForEach-Object {
        $set[$_.Name] = $true
    }

    output 'Not configured'
    output '--------------'

    Get-ChildItem -Path $WowAddonDirRetail | Where-Object {
        $_.PSIsContainer -and $_.Name -notmatch 'Blizzard'
    } | Where-Object {
        -not $set.ContainsKey($_.Name)
    } | ForEach-Object {
        output "$_"
    }

    output ''

    output 'Not installed'
    output '-------------'

    $set.Keys | Where-Object {
        -not (Test-Path "$WowAddonDirRetail\$_")
    }

    return
}

#########################################################################
# Update functions
#
function UpdateAddon {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('retail', 'classic')]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$File
    )

    DownloadExtractAddon -Version $Version -Url $url -TempFile (Join-Path -Path $tempDir -ChildPath $File)
}

function DownloadExtractAddon {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('retail', 'classic')]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$TempFile
    )

    output "Downloading $Url" 1
    $wc.DownloadFile( $Url, $TempFile )
    success "done." 2

    output "Extracting Archive..." 1
    if ($Version -eq 'retail') {
        Expand-Archive -Path $TempFile -DestinationPath $WowAddonDirRetail -Force
    } elseif ($Version -eq 'classic') {
        Expand-Archive -Path $TempFile -DestinationPath $WowAddonDirClassic -Force
    }
    success "done." 2

    output "Deleting file..." 1
    Remove-Item $TempFile -Force
    success "done." 2
}

#########################################################################
# Updater functions
#

function UpdateWowinterface {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('retail', 'classic')]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$UID,
        [string]$urlBase = 'http://www.wowinterface.com'
    )

    output "$Name - $urlBase - $UID : $Version"

    # prepare variables
    $AddonPath = switch($Version) {
        'retail' { Join-Path -Path $WowAddonDirRetail -ChildPath $Name }
        'classic' { Join-Path -Path $WowAddonDirClassic -ChildPath $Name }
    }

    try {
        $StateFilePath = Join-Path -Path $AddonPath -ChildPath $stateFile -Resolve -Erroraction Stop
        $LocalVer = Get-Content -Path $StateFilePath
    } catch {
        $StateFilePath = Join-Path -Path $AddonPath -ChildPath $stateFile
        $LocalVer = ''
    }

    $uri = "$urlBase/patcher$UID.xml"
    $wowiXml = [xml]$wc.DownloadString($uri)

    $DownloadUrl = $wowiXml.UpdateUI.Current.UIFileURL
    $RemoteVer = $wowiXml.UpdateUI.Current.UIVersion
    $File = $wowiXml.UpdateUI.Current.UIFile

    if ($LocalVer -ne $RemoteVer) {
        output "Update required: Current ver=$LocalVer, Remote ver=$RemoteVer" 1
        if (Test-Path -Path $AddonPath) {
            Get-ChildItem -Path $AddonPath -Recurse -Force | Remove-Item -Force -Recurse
            Remove-Item -Path $AddonPath -Force
        }
        UpdateAddon -Version $Version -Url $DownloadUrl -File $File
        Set-Content -Path $StateFilePath -Value $RemoteVer
    }
    else {
        output "Addon up-to-date. Skipping." 1
    }
}

function UpdateCurseforge {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('retail', 'classic')]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$UID,
        [string]$UrlBase = 'http://www.curseforge.com'
    )

    output "$Name - $urlBase - $UID : $Version"

    $AddonPath = switch ($Version) {
        'retail' { Join-Path -Path $WowAddonDirRetail -ChildPath $Name }
        'classic' { Join-Path -Path $WowAddonDirClassic -ChildPath $Name }
    }

    try {
        $StateFilePath = Join-Path -Path $AddonPath -ChildPath $stateFile -Resolve -Erroraction Stop
        $LocalVer = Get-Content -Path $StateFilePath
    } catch {
        $StateFilePath = Join-Path -Path $AddonPath -ChildPath $stateFile
        $LocalVer = ''
    }

    # Screenscrape out the links...
    $Html = $wc.DownloadString("$UrlBase/wow/addons/$UID/download")

    if ($Html -match '.*If your download doesn.t start automatically, click <a href="(?<url>.*)">here<\/a>.*') {
        $UrlChild = $matches['url']
        $DownloadUrl = "$UrlBase$UrlChild"

        if ($DownloadUrl -match '.*\/download\/(?<RemoteVer>.*)\/.*') {
            $RemoteVer = $matches['RemoteVer']
            $File = "$RemoteVer.zip"
        } else {
            abort "Error while parsing version number from $DownloadUrl"
        }
    } else {
        abort "Error while parsing curseforge html from '$UrlBase/wow/addons/$UID/download'."
    }

    if ($LocalVer -ne $RemoteVer) {
        output "Update required: Current ver=$LocalVer, Remote ver=$RemoteVer" 1
        if (Test-Path -Path $AddonPath) {
            Get-ChildItem -Path $AddonPath -Recurse -Force | Remove-Item -Force -Recurse
            Remove-Item $AddonPath -Force
        }
        UpdateAddon -Version $Version -Url $DownloadUrl -File $File
        Set-Content -Path $StateFilePath -Value $RemoteVer
    }
    else {
        output "Addon up-to-date. Skipping." 1
    }
}

function UpdatePackagedWith {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$UID
    )

    output "$Name packaged with $UID"
    output "Skipping..." 1
}

# # Single addon mode: the -addon flag
# if ($addon -ne '') {
#     $ManifestRetail | Where-Object {
#         $_.Name -eq $addon
#     } | ForEach-Object {
#         $Source = $_.Source
#         $Name = $_.Name
#         $UID = $_.UID

#         $Name = $Name.Replace("'", "``'")

#         if ($Source -eq $null) {
#             $Source = 'skip'
#         }

#         $expr = "update-$Source -name $Name -UID $UID"
#         Invoke-Expression $expr
#     }

#     return
# }

#########################################################################
# Main processing loop
#
# This loop processes everything in the manifest, passing the info to
# one of the helper methods defined above.
#

@('retail', 'classic') | ForEach-Object {
    $Version = $_

    output '-------------------------'
    output "WoW Update Addons: $_"
    output ''
    
    (Get-Variable -Name ("Manifest" + $_) -Value) | ForEach-Object {
        $Source = $_.Source
        $Name = $_.Name
        $UID = $_.UID

        $Name = $Name.Replace("'", "``'")

        switch ($Source) {
            'wowinterface' {
                UpdateWowinterface -Version $Version -Name $Name -UID $UID
                break
            }
            'curseforge' {
                UpdateCurseforge -Version $Version -Name $Name -UID  $UID
                break
            }
            'packaged-with' {
                UpdatePackagedWith -Version $Version -Name $Name -UID $UID
                break
            }
            'skip' {
                output "Skipping file: $Name"
                break
            }
            default {
                output "Unknown source: $Source"
                break
            }
        }
    }
}
