$repoUrl = "https://raw.githubusercontent.com/jjpainter1/MediaCraft/main"
$localVersion = Get-Content -Raw -Path "version.json" | ConvertFrom-Json
$remoteVersion = Invoke-RestMethod -Uri "$repoUrl/version.json"

if ($remoteVersion.version -gt $localVersion.version) {
    Write-Host "Update available. Downloading changes..."
    
    foreach ($component in $remoteVersion.components.PSObject.Properties) {
        $componentPath = $component.Name
        $newVersion = $component.Value
        
        if ($newVersion -gt $localVersion.components.$componentPath) {
            Write-Host "Updating $componentPath to version $newVersion"
            
            # If it's a directory, download all files in that directory
            if (Test-Path $componentPath -PathType Container) {
                $files = Invoke-RestMethod -Uri "$repoUrl/api/v3/repos/jjpainter1/MediaCraft/contents/$componentPath"
                foreach ($file in $files) {
                    Invoke-WebRequest -Uri $file.download_url -OutFile (Join-Path $componentPath $file.name)
                }
            } else {
                # If it's a file, just download that file
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