$ProgressPreference = "SilentlyContinue"
$dotfilesPath = Split-path -parent $PSScriptRoot
$profileSourceDir = join-path $dotfilesPath 'psprofile'
$componentSourceDir = join-path $profileSourceDir 'components'
$functionsSourceDir = join-path $profileSourceDir 'functions'
$dotfilesSourceDir = join-path $dotfilesPath 'dotfiles'

$dotfilesPath | set-content (join-path $env:USERPROFILE '.dotfileslocation')

$currentProfileDir = Split-Path -parent $profile
$ProfileDirs = @()
$profileDirs += $currentProfileDir
if ((split-path -Leaf $currentProfileDir) -eq 'WindowsPowershell') {
    $ProfileDirs += join-path (split-path -Parent $currentProfileDir) 'Powershell'
}
foreach ($profileDir in $ProfileDirs) {
    $componentDir = Join-Path $profileDir "components"
    $functionsDir = Join-Path $profileDir "functions"

    New-Item $profileDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item $componentDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if ([System.IO.Directory]::Exists($functionsDir)) { 
        # fix to avoid onedrive error Access to the cloud file is denied
        # removing all existing ps functions works as well
        get-childitem -LiteralPath $functionsdir -filter '*.ps1' -Recurse | foreach-Object {$_.delete()}
     }
    New-Item $functionsDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    Copy-Item -Path (join-path $profileSourceDir '*.ps1') -Destination $profileDir
    Copy-Item -Path (join-path $componentSourceDir '**') -Destination $componentDir -Include ** -Recurse
    Copy-Item -Path (join-path $functionsSourceDir '**') -Destination $functionsDir -Include ** -Recurse -ErrorAction SilentlyContinue
    Copy-Item -Path (join-path $dotfilesSourceDir '**') -Destination $home -Include **

}
Remove-Variable CurrentProfileDir
Remove-Variable ProfileDirs
Remove-Variable ProfileDir
Remove-Variable componentDir
Remove-Variable functionsDir
