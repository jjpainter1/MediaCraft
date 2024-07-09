# Bypass execution policy for this session
Set-ExecutionPolicy Bypass -Scope Process -Force

$repoUrl = "https://raw.githubusercontent.com/jjpainter1/MediaCraft/main"

# Create MediaCraft directory if it doesn't exist
$installDir = "$env:USERPROFILE\MediaCraft"
if (!(Test-Path -Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir
}

# Change to the MediaCraft directory
Set-Location -Path $installDir

# Download version.json and updates.ps1
Invoke-WebRequest -Uri "$repoUrl/version.json" -OutFile "version.json"
Invoke-WebRequest -Uri "$repoUrl/scripts/updates.ps1" -OutFile "updates.ps1"

# Run the update script
& .\updates.ps1

Write-Host "MediaCraft has been installed to $installDir"
Write-Host "You can run updates in the future by navigating to this directory and running .\updates.ps1"