$dotfilesPath = Split-path -parent $PSScriptRoot
$profileSourceDir = join-path $dotfilesPath 'psprofile'
$componentSourceDir = join-path $profileSourceDir 'components'
$dotfilesSourceDir = join-path $dotfilesPath 'dotfiles'


$profileDir = Split-Path -parent $profile
$componentDir = Join-Path $profileDir "components"

New-Item $profileDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item $componentDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

Copy-Item -Path (join-path $profileSourceDir '*.ps1') -Destination $profileDir
Copy-Item -Path (join-path $componentSourceDir '**') -Destination $componentDir -Include **
Copy-Item -Path (join-path $dotfilesSourceDir '**') -Destination $home -Include **

Remove-Variable componentDir
Remove-Variable profileDir