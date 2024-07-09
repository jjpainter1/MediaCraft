param(
    [switch]$FirstTimeInstall = $false
)

function Write-Log {
    param([string]$message)
    Write-Host $message
    Add-Content -Path "install_log.txt" -Value $message
}

function Download-Directory {
    param (
        [string]$path,
        [string]$localPath
    )
    
    Write-Log "Attempting to download directory: $path"
    if (!(Test-Path $localPath)) {
        New-Item -ItemType Directory -Force -Path $localPath | Out-Null
    }
    
    try {
        $files = Invoke-RestMethod -Uri "$apiUrl/$path" -Headers @{"Accept" = "application/vnd.github.v3+json"} -ErrorAction Stop
        foreach ($file in $files) {
            $filePath = Join-Path $localPath $file.name
            if ($file.type -eq "dir") {
                Download-Directory -path "$path/$($file.name)" -localPath $filePath
            } else {
                Write-Log "Downloading $filePath"
                Invoke-WebRequest -Uri $file.download_url -OutFile $filePath -ErrorAction Stop
            }
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Log "Directory $path not found. Skipping."
        }
        else {
            Write-Log "Error downloading $path $_"
            throw
        }
    }
}

Write-Log "First Time Install flag: $FirstTimeInstall"

$repoUrl = "https://raw.githubusercontent.com/jjpainter1/MediaCraft/main"
$apiUrl = "https://api.github.com/repos/jjpainter1/MediaCraft/contents"

# Create a temporary version file for first-time installs
if ($FirstTimeInstall) {
    $localVersion = @{version = "0.0.0"; components = @{}} | ConvertTo-Json
    $localVersion | Set-Content -Path "temp_version.json"
} else {
    $localVersion = Get-Content -Raw -Path "version.json"
}

$localVersionObj = $localVersion | ConvertFrom-Json
$remoteVersion = Invoke-RestMethod -Uri "$repoUrl/version.json"

Write-Log "Local version: $($localVersionObj.version)"
Write-Log "Remote version: $($remoteVersion.version)"

if ($FirstTimeInstall -or ($remoteVersion.version -gt $localVersionObj.version)) {
    Write-Log "Update available or first-time install. Downloading changes..."
    
    # Define root files to download
    $rootFiles = @("changelog.txt", "LICENSE", "mediacraft.bat", "README.md", "requirements.txt", "setup.py", "version.json")
    
    # Download root files
    foreach ($file in $rootFiles) {
        Write-Log "Downloading $file"
        try {
            Invoke-WebRequest -Uri "$repoUrl/$file" -OutFile $file -ErrorAction Stop
        }
        catch {
            Write-Log "Error downloading $file $_"
            throw
        }
    }
    
    # Download directories and their contents
    $directories = @("src", "resources", "docs")
    foreach ($dir in $directories) {
        Download-Directory -path $dir -localPath $dir
    }
    
    # Update local version file
    $remoteVersion | ConvertTo-Json -Depth 4 | Set-Content -Path "version.json"
    
    # Download and display the changelog
    $changelog = Invoke-RestMethod -Uri "$repoUrl/changelog.txt"
    $latestChanges = $changelog -split "`nVersion" | Select-Object -First 1
    
    Write-Log "Update completed successfully."
    Write-Log "Latest changes:"
    Write-Log $latestChanges
    
    # Update local changelog file
    $changelog | Set-Content -Path "changelog.txt"
    
} else {
    Write-Log "Your MediaCraft is up to date."
}

# Clean up temporary version file if it exists
if (Test-Path "temp_version.json") {
    Remove-Item "temp_version.json"
}