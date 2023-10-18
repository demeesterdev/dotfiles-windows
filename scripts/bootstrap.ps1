$ProgressPreference = "SilentlyContinue"
$dotfilesPath = Split-path -parent $PSScriptRoot
$dotfilesPath | set-content (join-path $env:USERPROFILE '.dotfileslocation')

# copy dotfiles from ./dotfiles
$dotfilesSourceDir = join-path $dotfilesPath 'dotfiles'
Copy-Item -Path (join-path $dotfilesSourceDir '**') -Destination $home -Include ** -Recurse

# link to the psprofile files

$GroupStartLine = '#group dotfiles autoloader'
$GroupEndLine = '#endgroup dotfiles autoloader'
$profileSourceDir = join-path $dotfilesPath 'psprofile' 
$profileloader = join-path $profileSourceDir 'profile.loader.ps1' 

#configure for windows powershell and pwsh
$currentProfileDir = Split-Path -parent $profile
$ProfileDirs = @()
if(!$IsCoreCLR -or $IsWindows){
    $ProfileDirs += join-path (split-path -Parent $currentProfileDir) 'Powershell'
    $ProfileDirs += join-path (split-path -Parent $currentProfileDir) 'WindowsPowershell'
}else{
    $profileDirs += $currentProfileDir
}

#create regerence to loader

$loaderContent = @"
# loads the psprofile from a managed dotfiles repository at $dotfilesSourceDir
Invoke-Expression ". '$profileloader'"
"@

$loaderBlock = @"

$GroupStartLine
$loaderContent
$GroupEndline
"@ 

foreach ($profileDir in $ProfileDirs) {
    if(-not (Test-Path $profileDir)){
        New-Item -ItemType Directory -Path $profileDir
    }

    $psprofilefile = join-path $profileDir 'profile.ps1'
    if(-not (Test-Path $psprofilefile -PathType Leaf)){
        "# PSprofile Created by dotfile script" | Set-Content $psprofilefile -Force
    }
    $PSProfile = get-content $psprofilefile -Raw 
    $autoloaderSelector = '[\n\r]?[\n\r]({0}[\n\r]+)([\s\S]*)([\n\r]+{1}[\n\r]+)' -f $GroupStartLine, $GroupEndLine 
    if ($PSProfile -match $autoloaderSelector) { 
        $PSProfile = $PSProfile -replace $autoloaderSelector, $loaderBlock
        set-content -Value $PSProfile -Path $psprofilefile
    }
    else {
        $loaderBlock | Add-Content -Path $psprofilefile
    }       
}

