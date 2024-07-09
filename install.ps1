# Bypass execution policy for this session
Set-ExecutionPolicy Bypass -Scope Process -Force

# Load Windows Forms assembly for folder browser dialog
Add-Type -AssemblyName System.Windows.Forms

$repoUrl = "https://raw.githubusercontent.com/jjpainter1/MediaCraft/main"

# Check if MediaCraft is already installed
$registryPath = "HKCU:\Software\MediaCraft"
$installLocation = Get-ItemProperty -Path $registryPath -Name "InstallLocation" -ErrorAction SilentlyContinue

if ($installLocation) {
    $reinstall = [System.Windows.Forms.MessageBox]::Show(
        "MediaCraft is already installed at $($installLocation.InstallLocation).`n`nDo you want to reinstall or update?",
        "MediaCraft Already Installed",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($reinstall -eq 'No') {
        [System.Windows.Forms.MessageBox]::Show("Installation cancelled.", "Installation Cancelled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }
    $isFirstTimeInstall = $false
} else {
    $isFirstTimeInstall = $true
}

# Display welcome message
[System.Windows.Forms.MessageBox]::Show(
    "Welcome to the MediaCraft installer!`n`nThis wizard will guide you through the installation process.",
    "MediaCraft Installer",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)

# Function to show folder selection dialog
function Select-Folder($description="Select Installation Folder", $initialDirectory="C:\Program Files") {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $description
    $folderBrowser.SelectedPath = $initialDirectory
    $folderBrowser.ShowNewFolderButton = $true

    if ($folderBrowser.ShowDialog() -eq "OK") {
        return $folderBrowser.SelectedPath
    } else {
        return $null
    }
}

# Prompt for default installation directory
$defaultInstallDir = if ($installLocation) { $installLocation.InstallLocation } else { "C:\Program Files\MediaCraft" }
$useDefault = [System.Windows.Forms.MessageBox]::Show(
    "Would you like to install MediaCraft to the default directory?`n`nDefault: $defaultInstallDir",
    "Installation Directory",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($useDefault -eq 'Yes') {
    $installDir = $defaultInstallDir
} else {
    # Show folder selection dialog
    $selectedDir = Select-Folder "Select MediaCraft Installation Folder" "C:\Program Files"
    if ($null -eq $selectedDir) {
        [System.Windows.Forms.MessageBox]::Show("Installation cancelled by user.", "Installation Cancelled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }
    $installDir = Join-Path $selectedDir "MediaCraft"
}

# Check if we have permission to write to the chosen directory
try {
    New-Item -ItemType Directory -Force -Path $installDir -ErrorAction Stop | Out-Null
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Error: Unable to create directory at $installDir. You may need to run this script as an administrator.", "Installation Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Change to the installation directory
Set-Location -Path $installDir

# # Download version.json and updates.ps1
# try {
#     Invoke-WebRequest -Uri "$repoUrl/version.json" -OutFile "version.json" -ErrorAction Stop
#     Invoke-WebRequest -Uri "$repoUrl/scripts/updates.ps1" -OutFile "updates.ps1" -ErrorAction Stop
# }
# catch {
#     [System.Windows.Forms.MessageBox]::Show("Error: Unable to download necessary files. Please check your internet connection.", "Download Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
#     exit 1
# }

# Copy version.json and updates.ps1 from local paths
try {
    Copy-Item "C:\MediaCraft\version.json" -Destination "version.json" -ErrorAction Stop
    Copy-Item "C:\MediaCraft\scripts\updates.ps1" -Destination "updates.ps1" -ErrorAction Stop
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Error: Unable to copy necessary files. Please check your file paths.", "Copy Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Run the update script with the first-time install flag
try {
    Write-Host "Running updates.ps1 with FirstTimeInstall: $isFirstTimeInstall"
    if ($isFirstTimeInstall) {
        & .\updates.ps1 -FirstTimeInstall
    } else {
        & .\updates.ps1
    }
}
catch {
    $errorMessage = $_.Exception.Message
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    $errorScript = $_.InvocationInfo.ScriptName
    $detailedError = "Error in script $errorScript at line $errorLine $errorMessage"
    Write-Host $detailedError
    [System.Windows.Forms.MessageBox]::Show("Error: Unable to run the update script. Installation may be incomplete.`n`nDetailed error: $detailedError", "Update Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Save installation location to registry
try {
    if (!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    New-ItemProperty -Path $registryPath -Name "InstallLocation" -Value $installDir -PropertyType String -Force | Out-Null
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Warning: Unable to save installation location to registry. This won't affect the installation, but may cause issues with future updates.", "Registry Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

[System.Windows.Forms.MessageBox]::Show("MediaCraft has been installed to $installDir`nYou can run updates in the future by navigating to this directory and running .\updates.ps1", "Installation Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

[System.Windows.Forms.MessageBox]::Show("Installation completed successfully.", "Installation Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)