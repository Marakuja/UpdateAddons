
<#
.SYNOPSIS
Updates World of Warcraft addons to the latest version
.DESCRIPTION
use updateaddons with your addons.csv file you have to preconfigure!
.PARAMETER scan
[switch] scan - compares the contents of your csv file with your WoW Addons directories, default: false
.PARAMETER debug
[switch] debug - get some more debug information, default: false
.PARAMETER addon
[string] addon - only check a specific addon given in your csv, default: empty
.EXAMPLE
updateaddons, updateaddons -scan -debug, updateaddons -addon "BigWigs"
.NOTES
This script scans your registry for the installation path of World of Warcraft and if everything fails defaults to "C:\Program Files\World of Warcraft\". Please bear in mind, this script is not perfect!
#>

param (
    [switch] $scan,
    [switch] $debug,
    [string] $addon = ""
)

# path to the addons.csv
$manifestFile = ".\addons.csv"
if (-not (Test-Path $manifestFile)) {
    throw "You need to create an addons.csv to your script location!"
}
$manifest = Import-Csv $manifestFile

# check if 7z is installed
if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
    Set-Alias 7z "$env:ProgramFiles\7-Zip\7z.exe"
}
else {
    throw "You need to have 7z installed to $env:ProgramFiles\7-Zip\7z.exe"
}

# get current World of Warcraft installation path
if (test-path "HKLM:\SOFTWARE\Wow6432Node\Blizzard Entertainment\World of Warcraft") {
    $wowDir = (Get-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Blizzard Entertainment\World of Warcraft").InstallPath
}
else {
    if (test-path "HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft") {
        $wowDir = (Get-ItemProperty -path "HKLM:\SOFTWARE\Blizzard Entertainment\World of Warcraft").InstallPath
    }
    else {
        $wowDir = "C:\Program Files\World of Warcraft\"
    }
}
$wowAddonDir = Join-Path $wowDir "Interface\Addons"

# temp store location for downloaded files
$tempDir = Join-Path $env:TEMP "UpdateAddons"
if (-not (Test-Path $tempDir)) {
    New-Item -Type Directory -Path $tempDir | Out-Null
}

# scan the Interface/Addon directory and compare the contents with the contents of $manifestFile
if ($scan.isPresent) {
    $set = @{}

    $manifest | ForEach-Object {
        $set[$_.Name] = $true
    }

    Write-Output "Not configured"

    Get-ChildItem $wowAddonDir | Where-Object {
        $_.PSIsContainer -and $_.Name -notmatch "Blizzard"
    } | Where-Object {
        -not $set.ContainsKey($_.Name)
    } | ForEach-Object {
        Write-Output $_.Name
    }

    Write-Output ""

    Write-Output "Not installed"
    $set.Keys | Where-Object {
        -not (Test-Path "$wowAddonDir\$_")
    }

    return
}

# webclient used for getting the files
$wc = New-Object System.Net.WebClient

# name of the file created in every addon directory tracking current version information
$stateFile = "PSUpdateAddons.state"

#########################################################################
# Update functions
#
function update-addon {
    param (
        $url = $(throw "url required"),
        $fileName = $(throw "fileName required")
    )

    $tempFilePath = Join-Path $tempDir $fileName
    downloadextract-addon -uri $url -tempFile $tempFilePath
}

function downloadextract-addon {
    param (
        $uri = $(throw "uri required"),
        $tempFile = $(throw "tempFile required")
    )

    Write-Output "`tDownloading $uri..."
    $wc.DownloadFile( $uri, $tempFile )
    Write-Output "`tdone."

    Write-Output "`tExtracting Archive..."
    if ($verbose) {
        7z x $tempFile "-o$wowAddonDir" "-y"
    }
    else {
        7z x $tempFile "-o$wowAddonDir" "-y" *>$null
    }

    Write-Output "`tdone."

    Write-Output "`tDeleting file..."
    Remove-Item $tempFile
    Write-Output "`tdone."
}

#########################################################################
# Updater functions
#
# These functions are named with a special form that enables
# dynamic calling based on the source specified in the CSV file
#

function update-wowi {
    param (
        $name = $(throw "You must provide the addon name"),
        $uid = $(throw "You must provide the addon UID")
    )

    Write-Output "$name - wowinterface.com - $uid"

    $addonPath = Join-Path $wowAddonDir $name
    $stateFilePath = Join-Path $addonPath $stateFile
    $localVer = ""
    if (Test-Path $stateFilePath) {
        $localVer = (Get-Content $stateFilePath)
    }

    $uri = "http://www.wowinterface.com/patcher$uid.xml"
    $wowiXml = [xml] $wc.DownloadString($uri)

    $downloadUrl = $wowiXml.UpdateUI.Current.UIFileURL
    $remoteVer = $wowiXml.UpdateUI.Current.UIVersion
    $fileName = $wowiXml.UpdateUI.Current.UIFile

    if ($localVer -ne $remoteVer) {
        Write-Output "`tUpdate required: Current ver=$localVer, Remote ver=$remoteVer"
        update-addon -url $downloadUrl -fileName $fileName
        Set-Content -Value $remoteVer -Path $stateFilePath -Force
    }
    else {
        Write-Output "`tAddon up-to-date. Skipping."
    }
}

function update-curseforge {
    param (
        $name = $(throw "You must provide the addon name"),
        $uid = $(throw "You must provide the addon UID"),
        $urlBase = "http://www.curseforge.com"
    )

    Write-Output "$name - $urlBase - $uid"

    $addonPath = Join-Path $wowAddonDir $name
    $stateFilePath = Join-Path $addonPath $stateFile
    $lastUrl = ""
    if (Test-Path $stateFilePath) {
        $lastUrl = (Get-Content $stateFilePath)
    }

    # Screenscrape out the links...

    $html = $wc.DownloadString("$urlBase/wow/addons/$uid/download")
    $tmp = ($html -match ".*class=`"download__link`".*=`"(?<url>.*)`">.*")
    if ($tmp -eq $false) {
        Write-Output "ERROR PARSING CURSEFORGE HTML!"
        return
    }

    $url_path = $matches["url"]
    $currentUrl = "$urlBase$url_path"
    $tmp = $currentUrl -match ".*\/download\/(?<fileVer>.*)\/.*"
    if ($tmp -eq $false) {
        Write-Output "ERROR Parsing Version number from url string!"
        return
    }
    $filename = $matches["fileVer"]

    if ($lastUrl -ne $currentUrl) {
        Write-Output "`tUpdate required: Remote ver=$filename"
        Write-Debug "`tSecond URL: $currentUrl"
        if (Test-Path $addonPath) {
            Get-ChildItem -Path $addonPath -Recurse -Force | Remove-Item -Force -Recurse
            Remove-Item $addonPath -Force
        }
        update-addon -url $currentUrl -fileName $filename
        Set-Content -Value $currentUrl -Path $stateFilePath -Force
    }
    else {
        Write-Output "`tAddon up-to-date. Skipping."
    }
}

function update-skip {
    param (
        $name = $(throw "You must provide the addon name."),
        $uid = "No note provided"
    )

    Write-Output "$name - skipping $uid"
    Write-Output "`tSkipping $name - $uid"
}

function update-packaged-with {
    param (
        $name = $(throw "You must provide the addon name."),
        $uid = "No note provided"
    )

    Write-Output "$name - packaged with $uid"
    Write-Output "`tSkipping $name - $uid"
}

# Single addon mode: the -addon flag
if ($addon -ne "") {
    $manifest | Where-Object {
        $_.Name -eq $addon
    } | ForEach-Object {
        $source = $_.Source
        $name = $_.Name
        $uid = $_.UID

        $name = $name.Replace("'", "``'")

        if ($source -eq $null) {
            $source = "skip"
        }

        $expr = "update-$source -name $name -UID $uid"
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

$manifest | ForEach-Object {
    $source = $_.Source
    $name = $_.Name
    $uid = $_.UID

    $name = $name.Replace("'", "``'")

    if ($source -eq $null) {
        $source = "skip"
    }

    $expr = "update-$source -name '$name' -UID '$uid'"
    Invoke-Expression $expr
}
