param(
    [switch]$FirstTimeInstall = $false
)

Write-Host "First Time Install flag: $FirstTimeInstall"

$repoUrl = "https://raw.githubusercontent.com/jjpainter1/MediaCraft/main"

# Create a temporary version file for first-time installs
if ($FirstTimeInstall) {
    $localVersion = @{version = "0.0.0"; components = @{}} | ConvertTo-Json
    $localVersion | Set-Content -Path "temp_version.json"
} else {
    $localVersion = Get-Content -Raw -Path "version.json"
}

$localVersionObj = $localVersion | ConvertFrom-Json
$remoteVersion = Invoke-RestMethod -Uri "$repoUrl/version.json"

Write-Host "Local version: $($localVersionObj.version)"
Write-Host "Remote version: $($remoteVersion.version)"

if ($FirstTimeInstall -or ($remoteVersion.version -gt $localVersionObj.version)) {
    Write-Host "Update available or first-time install. Downloading changes..."
    
    # Define root files to download
    $rootFiles = @("changelog.txt", "LICENSE", "mediacraft.bat", "README.md", "requirements.txt", "setup.py", "version.json")
    
    # Download root files
    foreach ($file in $rootFiles) {
        Write-Host "Downloading $file"
        Invoke-WebRequest -Uri "$repoUrl/$file" -OutFile $file
    }
    
    # Download directories and their contents
    $directories = @("src", "resources", "docs")
    foreach ($dir in $directories) {
        Write-Host "Downloading $dir directory"
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }
        $files = Invoke-RestMethod -Uri "https://api.github.com/repos/jjpainter1/MediaCraft/contents/$dir"
        foreach ($file in $files) {
            $filePath = Join-Path $dir $file.name
            Write-Host "Downloading $filePath"
            Invoke-WebRequest -Uri $file.download_url -OutFile $filePath
        }
    }
    
    foreach ($component in $remoteVersion.components.PSObject.Properties) {
        $componentPath = $component.Name
        $newVersion = $component.Value
        
        Write-Host "Checking component: $componentPath"
        if ($FirstTimeInstall -or ($newVersion -gt $localVersionObj.components.$componentPath)) {
            Write-Host "Updating $componentPath to version $newVersion"
            
            # If it's a directory, download all files in that directory
            if (Test-Path $componentPath -PathType Container) {
                $files = Invoke-RestMethod -Uri "https://api.github.com/repos/jjpainter1/MediaCraft/contents/$componentPath"
                foreach ($file in $files) {
                    $filePath = Join-Path $componentPath $file.name
                    Write-Host "Downloading $filePath"
                    Invoke-WebRequest -Uri $file.download_url -OutFile $filePath
                }
            } else {
                # If it's a file, just download that file
                Write-Host "Downloading file $componentPath"
                Invoke-WebRequest -Uri "$repoUrl/$componentPath" -OutFile $componentPath
            }
        }
    }
    
    # Update local version file
    $remoteVersion | ConvertTo-Json -Depth 4 | Set-Content -Path "version.json"
    
    # Download and display the changelog
    $changelog = Invoke-RestMethod -Uri "$repoUrl/changelog.txt"
    $latestChanges = $changelog -split "`nVersion" | Select-Object -First 1
    
    Write-Host "Update completed successfully."
    Write-Host "Latest changes:"
    Write-Host $latestChanges
    
    # Update local changelog file
    $changelog | Set-Content -Path "changelog.txt"
    
} else {
    Write-Host "Your MediaCraft is up to date."
}

# Clean up temporary version file if it exists
if (Test-Path "temp_version.json") {
    Remove-Item "temp_version.json"
}