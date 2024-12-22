# <monitor__PYPORTAL_bootloader_update>
# author:  adge denkers
# github:  @adgedenkers
# created: 2024-12-22
# updated: 2024-12-22
#
# version: 0.2

# Function to get the latest bootloader version for a specific board
function Get-LatestBootloader {
    param (
        [string]$BoardName
    )

    $url = "https://circuitpython.org/downloads"
    Write-Host "Fetching board data from $url..."

    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $data = $html.Content | ConvertFrom-Json

    $board = $data.boards | Where-Object { $_.name -eq $BoardName }
    if ($null -eq $board) {
        Write-Warning "Board $BoardName not found on CircuitPython."
        return $null
    }

    return $board.latest_version
}

# Function to parse INFO_UF2.TXT for current bootloader details
function Parse-InfoFile {
    param (
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        Write-Warning "INFO_UF2.TXT not found at $FilePath."
        return $null
    }

    $info = Get-Content -Path $FilePath
    $currentVersion = ($info | Select-String -Pattern 'UF2 Bootloader v([\d\.\-\w]+)' | ForEach-Object { $_.Matches.Groups[1].Value })
    $model = ($info | Select-String -Pattern 'Model: (.+)' | ForEach-Object { $_.Matches.Groups[1].Value })
    
    if ($null -eq $currentVersion -or $null -eq $model) {
        Write-Warning "Could not parse INFO_UF2.TXT."
        return $null
    }

    return [PSCustomObject]@{
        CurrentVersion = $currentVersion
        Model = $model
    }
}

# Function to download and copy the bootloader to the drive
function Update-Bootloader {
    param (
        [string]$BoardName,
        [string]$DevicePath,
        [string]$CurrentVersion
    )

    $latestVersion = Get-LatestBootloader -BoardName $BoardName

    if ($null -eq $latestVersion) {
        Write-Warning "Could not fetch the latest version for $BoardName."
        return
    }

    if ($CurrentVersion -eq $latestVersion) {
        Write-Host "The bootloader is up to date ($CurrentVersion)."
        return
    }

    Write-Host "Current version: $CurrentVersion"
    Write-Host "Latest version: $latestVersion"
    $confirm = Read-Host "Would you like to update the bootloader? (yes/no)"

    if ($confirm -ne "yes") {
        Write-Host "Update skipped."
        return
    }

    $downloadUrl = "https://circuitpython.org/boards/$BoardName/download"
    $outputFile = "$env:USERPROFILE\Downloads\$BoardName-bootloader-$latestVersion.uf2"

    Write-Host "Downloading $latestVersion bootloader to $outputFile..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile

    Write-Host "Copying bootloader to $DevicePath..."
    Copy-Item -Path $outputFile -Destination "$DevicePath\"
    Write-Host "Bootloader updated successfully!"
}

# Main loop
while ($true) {
    $drives = Get-Volume | Where-Object { $_.FileSystemLabel -eq "PORTALBOOT" }

    if ($drives.Count -gt 0) {
        foreach ($drive in $drives) {
            $devicePath = "$($drive.DriveLetter):"
            Write-Host "PORTALBOOT drive detected at $devicePath."

            $infoFilePath = "$devicePath\INFO_UF2.TXT"
            $info = Parse-InfoFile -FilePath $infoFilePath

            if ($info -ne $null) {
                $boardName = $info.Model
                $currentVersion = $info.CurrentVersion

                Update-Bootloader -BoardName $boardName -DevicePath $devicePath -CurrentVersion $currentVersion
            }
        }
    }

    Start-Sleep -Seconds 5
}
