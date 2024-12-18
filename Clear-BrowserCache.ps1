#==============================================================================
# File Name: Clear-BrowserCache.ps1
# Author: Adge Denkers
# Created: 2024-12-12
# Updated: 2024-12-18
# Version: 1.1
#
# Description:
# This script clears the cache for Firefox, Chrome, and Edge (if installed).
# It checks for the presence of each browser and removes its cache accordingly.
#
# Usage:
# Run the script directly to clear the browser caches for installed browsers.
#==============================================================================

function Clear-BrowserCache {
    [CmdletBinding()]
    param ()

    # Helper function to check if a process exists
    # Input: Process name (string)
    # Output: Process path if found, otherwise $null
    function Get-ProcessPath($processName) {
        try {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($process) {
                return $process.Path
            } else {
                return $null
            }
        } catch {
            return $null
        }
    }

    # Clears Chrome cache
    # Checks if the Chrome cache directory exists and deletes its contents
    function Clear-ChromeCache {
        $chromeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        if (Test-Path $chromeCachePath) {
            Write-Host "Clearing Chrome cache..." -ForegroundColor Yellow
            try {
                Remove-Item -Path "$chromeCachePath\*" -Recurse -Force -ErrorAction Stop
                Write-Host "Chrome cache cleared successfully." -ForegroundColor Green
            } catch {
                Write-Warning "Failed to clear Chrome cache: $_"
            }
        } else {
            Write-Host "Chrome cache path not found. Skipping Chrome." -ForegroundColor Cyan
        }
    }

    # Clears Firefox cache
    # Iterates through all Firefox profiles and deletes their cache directories
    function Clear-FirefoxCache {
        $firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $firefoxProfilePath) {
            $profileDirectories = Get-ChildItem -Path $firefoxProfilePath -Directory -ErrorAction SilentlyContinue
            if ($profileDirectories) {
                foreach ($profile in $profileDirectories) {
                    $firefoxCachePath = "$profile.FullName\cache2"
                    if (Test-Path $firefoxCachePath) {
                        Write-Host "Clearing Firefox cache for profile $($profile.Name)..." -ForegroundColor Yellow
                        try {
                            Remove-Item -Path "$firefoxCachePath\*" -Recurse -Force -ErrorAction Stop
                            Write-Host "Firefox cache cleared successfully for profile $($profile.Name)." -ForegroundColor Green
                        } catch {
                            Write-Warning "Failed to clear Firefox cache for profile $($profile.Name): $_"
                        }
                    } else {
                        Write-Host "Firefox cache path not found for profile $($profile.Name)." -ForegroundColor Cyan
                    }
                }
            } else {
                Write-Host "No Firefox profiles found. Skipping Firefox." -ForegroundColor Cyan
            }
        } else {
            Write-Host "Firefox profile path not found. Skipping Firefox." -ForegroundColor Cyan
        }
    }

    # Clears Edge cache
    # Checks if the Edge cache directory exists and deletes its contents
    function Clear-EdgeCache {
        $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        if (Test-Path $edgeCachePath) {
            Write-Host "Clearing Edge cache..." -ForegroundColor Yellow
            try {
                Remove-Item -Path "$edgeCachePath\*" -Recurse -Force -ErrorAction Stop
                Write-Host "Edge cache cleared successfully." -ForegroundColor Green
            } catch {
                Write-Warning "Failed to clear Edge cache: $_"
            }
        } else {
            Write-Host "Edge cache path not found. Skipping Edge." -ForegroundColor Cyan
        }
    }

    # Main execution
    Write-Host "Starting browser cache cleanup..." -ForegroundColor Cyan

    # Clear Chrome cache if installed
    if (Get-ProcessPath "chrome") {
        Clear-ChromeCache
    } else {
        Write-Host "Google Chrome is not installed or not running. Skipping Chrome." -ForegroundColor Cyan
    }

    # Clear Firefox cache if installed
    if (Get-ProcessPath "firefox") {
        Clear-FirefoxCache
    } else {
        Write-Host "Mozilla Firefox is not installed or not running. Skipping Firefox." -ForegroundColor Cyan
    }

    # Clear Edge cache if installed
    if (Get-ProcessPath "msedge") {
        Clear-EdgeCache
    } else {
        Write-Host "Microsoft Edge is not installed or not running. Skipping Edge." -ForegroundColor Cyan
    }

    Write-Host "Browser cache cleanup complete." -ForegroundColor Cyan
}

# Run the Clear-BrowserCache function
Clear-BrowserCache
