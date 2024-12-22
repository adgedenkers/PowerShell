# <PORTALBOOT_updater.ps1>
# author:  adge denkers
# github:  @adgedenkers
# created: 2024-12-22
# updated: 2024-12-22
#
# version: 0.1

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
    Copy-Item -Path $outputFile -Destination $DevicePath
    Write-Host "Bootloader updated successfully!"
}

# Main loop
while ($true) {
    $drives = Get-Volume | Where-Object { $_.FileSystemLabel -eq "PORTALBOOT" }

    if ($drives.Count -gt 0) {
        foreach ($drive in $drives) {
            $devicePath = $drive.DriveLetter
            Write-Host "PORTALBOOT drive detected at $devicePath."

            $boardName = Read-Host "Enter the board name (e.g., Adafruit Feather)"
            $currentVersion = Read-Host "Enter the current bootloader version"

            Update-Bootloader -BoardName $boardName -DevicePath "$devicePath:\" -CurrentVersion $currentVersion
        }
    }

    Start-Sleep -Seconds 5
}
