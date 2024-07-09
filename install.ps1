# Bypass execution policy for this session
Set-ExecutionPolicy Bypass -Scope Process -Force

$repoUrl = "https://raw.githubusercontent.com/jjpainter1/MediaCraft/main"

# Suggest default installation directory
$defaultInstallDir = "C:\Program Files\MediaCraft"

# Prompt user for installation directory
$installDir = Read-Host "Enter installation directory (default: $defaultInstallDir)"
if ([string]::IsNullOrWhiteSpace($installDir)) {
    $installDir = $defaultInstallDir
}

# Check if we have permission to write to the chosen directory
try {
    New-Item -ItemType Directory -Force -Path $installDir -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "Error: Unable to create directory at $installDir. You may need to run this script as an administrator."
    Write-Host "Installation aborted."
    exit 1
}

# Change to the installation directory
Set-Location -Path $installDir

# Download version.json and updates.ps1
try {
    Invoke-WebRequest -Uri "$repoUrl/version.json" -OutFile "version.json" -ErrorAction Stop
    Invoke-WebRequest -Uri "$repoUrl/scripts/updates.ps1" -OutFile "updates.ps1" -ErrorAction Stop
}
catch {
    Write-Host "Error: Unable to download necessary files. Please check your internet connection."
    Write-Host "Installation aborted."
    exit 1
}

# Run the update script
try {
    & .\updates.ps1
}
catch {
    Write-Host "Error: Unable to run the update script. Installation may be incomplete."
    exit 1
}

Write-Host "MediaCraft has been installed to $installDir"
Write-Host "You can run updates in the future by navigating to this directory and running .\updates.ps1"

# Optionally, create a shortcut on the desktop
$createShortcut = Read-Host "Would you like to create a shortcut on the desktop? (y/n)"
if ($createShortcut -eq 'y') {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MediaCraft.lnk")
    $Shortcut.TargetPath = "$installDir\MediaCraft.exe"  # Adjust this to your main executable
    $Shortcut.Save()
    Write-Host "Shortcut created on the desktop."
}

Write-Host "Installation completed successfully."