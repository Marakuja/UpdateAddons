<#
.SYNOPSIS
Updates World of Warcraft addons to the latest version
.DESCRIPTION
Use UpdateAddons.ps1 with your addons.csv file you have to create and set to the same path as the script or give the ManifestPath Parameter with path information
.PARAMETER ManifestPath
Full path to the addons.csv file, defaults to .\addons.csv
.PARAMETER Addon
[string] addon - only check a specific addon given in your csv, default: empty
.PARAMETER Scan
Compares the contents of your csv file with your WoW Addons directories, default: false
.PARAMETER Edit
Opens addons.csv for editing in the default editor
.EXAMPLE
.\UpdateAddons.ps1, .\UpdateAddons.ps1 -scan, .\UpdateAddons.ps1 -addon "BigWigs"
.NOTES
This script scans your registry for the installation path of World of Warcraft and if everything fails defaults to "C:\Program Files\World of Warcraft\". Please bear in mind, this script is not perfect!

Reading of sample 'addons.csv' (first line has to be like that!!)
Name,Source,UID
WeakAuras,curseforge,weakauras-2
BigWigs,wowi,5086

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
    [string]$ManifestPath = (Resolve-Path -Path "$PSScriptRoot\addons.csv" -Erroraction SilentlyContinue),
    [string]$Addon = '',
    [switch]$Scan,
    [switch]$Edit
)

# path to the addons.csv
try {
    if (-not (Test-Path -Path $ManifestPath)) {
        throw "You need to create an addons.csv to the script path or provide -ManifestPath Parameter with full Path to file!"
    }
} catch {
    throw "You need to create an addons.csv to the script path or provide -ManifestPath Parameter with full Path to file!"
}
$Manifest = Import-Csv -Path $ManifestPath -ErrorAction Stop

if ($Edit) {
    # just open addons.csv and exit
    Invoke-Expression $ManifestPath

    return
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
        throw "World of Warcraft Installation Path could not be found."
    }
}
$wowAddonDir = Join-Path -Path $wowDir -ChildPath 'Interface\Addons'

# temp store location for downloaded files
$tempDir = Join-Path -Path $env:TEMP -ChildPath 'UpdateAddons'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -Type Directory | Out-Null
}

# webclient used for getting the files
$wc = New-Object System.Net.WebClient

# Name of the file created in every addon directory tracking current version information
$stateFile = 'PSUpdateAddons.state'

# scan the Interface/Addon directory and compare the contents with the contents of $ManifestPath
if ($scan) {
    $set = @{}

    $Manifest | ForEach-Object {
        $set[$_.Name] = $true
    }

    Write-Output 'Not configured'
    Write-Output '--------------'

    Get-ChildItem -Path $wowAddonDir | Where-Object {
        $_.PSIsContainer -and $_.Name -notmatch 'Blizzard'
    } | Where-Object {
        -not $set.ContainsKey($_.Name)
    } | ForEach-Object {
        Write-Output "$_"
    }

    Write-Output ''

    Write-Output 'Not installed'
    Write-Output '-------------'

    $set.Keys | Where-Object {
        -not (Test-Path "$wowAddonDir\$_")
    }

    return
}

#########################################################################
# Update functions
#
function Update-Addon {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$File
    )

    DownloadExtract-Addon -Url $url -TempFile (Join-Path -Path $tempDir -ChildPath $File)
}

function DownloadExtract-Addon {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$TempFile
    )

    Write-Output "`tDownloading $Url"
    $wc.DownloadFile( $Url, $TempFile )
    Write-Output "`t`tdone."

    Write-Output "`tExtracting Archive..."
    Expand-Archive -Path $TempFile -DestinationPath $wowAddonDir -Force
    Write-Output "`t`tdone."

    Write-Output "`tDeleting file..."
    Remove-Item $TempFile -Force
    Write-Output "`t`tdone."
}

#########################################################################
# Updater functions
#

function Update-Wowinterface {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$UID,
        [string]$urlBase = 'http://www.wowinterface.com'
    )

    Write-Output "$Name - $urlBase - $UID"

    $AddonPath = Join-Path -Path $wowAddonDir -ChildPath $Name
    $StateFilePath = Join-Path -Path $AddonPath -ChildPath $stateFile
    $LocalVer = ''
    if (Test-Path -Path $StateFilePath) {
        $LocalVer = Get-Content -Path $StateFilePath
    }

    $uri = "$urlBase/patcher$UID.xml"
    $wowiXml = [xml]$wc.DownloadString($uri)

    $DownloadUrl = $wowiXml.UpdateUI.Current.UIFileURL
    $RemoteVer = $wowiXml.UpdateUI.Current.UIVersion
    $File = $wowiXml.UpdateUI.Current.UIFile

    if ($LocalVer -ne $RemoteVer) {
        Write-Output "`tUpdate required: Current ver=$LocalVer, Remote ver=$RemoteVer"
        if (Test-Path -Path $AddonPath) {
            Get-ChildItem -Path $AddonPath -Recurse -Force | Remove-Item -Force -Recurse
            Remove-Item -Path $AddonPath -Force
        }
        Update-Addon -url $DownloadUrl -File $File
        Set-Content -Value $RemoteVer -Path $StateFilePath -Force
    }
    else {
        Write-Output "`tAddon up-to-date. Skipping."
    }
}

function Update-Curseforge {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$UID,
        [string]$UrlBase = 'http://www.curseforge.com'
    )

    Write-Output "$Name - $urlBase - $UID"

    $AddonPath = Join-Path -Path $wowAddonDir -ChildPath $Name
    $StateFilePath = Join-Path -Path $AddonPath -ChildPath $stateFile
    $LocalVer = ''
    if (Test-Path -Path $StateFilePath) {
        $LocalVer = Get-Content -Path $StateFilePath
    }

    # Screenscrape out the links...

    $Html = $wc.DownloadString("$UrlBase/wow/addons/$UID/download")

    if ($Html -match '.*class="download__link".*="(?<url>.*)">.*') {
        $UrlChild = $matches['url']
        $DownloadUrl = "$UrlBase$UrlChild"

        if ($DownloadUrl -match '.*\/download\/(?<RemoteVer>.*)\/.*') {
            $RemoteVer = $matches['RemoteVer']
            $File = "$RemoteVer.zip"
        } else {
            throw "Error while parsing version number from $DownloadUrl"
        }
    } else {
        throw "Error while parsing curseforge html from '$UrlBase/wow/addons/$UID/download'."
    }

    if ($LocalVer -ne $RemoteVer) {
        Write-Output "`tUpdate required: Current ver=$LocalVer, Remote ver=$RemoteVer"
        if (Test-Path -Path $AddonPath) {
            Get-ChildItem -Path $AddonPath -Recurse -Force | Remove-Item -Force -Recurse
            Remove-Item $AddonPath -Force
        }
        Update-Addon -url $DownloadUrl -File $File
        Set-Content -Value $RemoteVer -Path $StateFilePath -Force
    }
    else {
        Write-Output "`tAddon up-to-date. Skipping."
    }
}

function Update-PackagedWith {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$UID
    )

    Write-Output "$Name packaged with $UID"
    Write-Output "`tSkipping..."
}

# Single addon mode: the -addon flag
if ($addon -ne '') {
    $Manifest | Where-Object {
        $_.Name -eq $addon
    } | ForEach-Object {
        $source = $_.Source
        $name = $_.Name
        $UID = $_.UID

        $name = $name.Replace("'", "``'")

        if ($source -eq $null) {
            $source = 'skip'
        }

        $expr = "update-$source -name $name -UID $UID"
        Invoke-Expression $expr
    }

    return
}

#########################################################################
# Main processing loop
#
# This loop processes everything in the manifest, passing the info to
# one of the helper methods defined above.
#

$Manifest | ForEach-Object {
    $Source = $_.Source
    $Name = $_.Name
    $UID = $_.UID

    $name = $name.Replace("'", "``'")

    switch ($Source) {
        'wowinterface' {
            Update-Wowinterface -name $name -UID $UID
            break
        }
        'curseforge' {
            Update-Curseforge -Name $Name -UID  $UID
            break
        }
        'packaged-with' {
            Update-PackagedWith -Name $Name -UID $UID
            break
        }
        default {
            break
        }
    }
}
