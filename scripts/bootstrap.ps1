$ProgressPreference = "SilentlyContinue"
$dotfilesPath = Split-path -parent $PSScriptRoot
$dotfilesPath | set-content (join-path $env:USERPROFILE '.dotfileslocation')

# copy dotfiles
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
$profileDirs += $currentProfileDir
if ((split-path -Leaf $currentProfileDir) -eq 'WindowsPowershell') {
    $ProfileDirs += join-path (split-path -Parent $currentProfileDir) 'Powershell'
}

#create regerence to loader

$loaderContent = @"
# loads the psprofile from a managed dotfiles repository at $dotfilesSourceDir
Invoke-Expression ". '$profileloader'"
"@

foreach ($profileDir in $ProfileDirs) {
    $psprofilefile = join-path $profileDir 'profile.ps1'
    $PSProfile = get-content $psprofilefile -Raw -ErrorAction 'silentlycontinue' 
    $autoloaderSelector = '({0}[\n\r]+)([\s\S]*)([\n\r]+{1}[\n\r]+)' -f $GroupStartLine, $GroupEndLine 
    if ($PSProfile -match $autoloaderSelector) { 
        $PSProfile = $PSProfile -replace $autoloaderSelector, ('$1{0}$3' -f ($loaderContent.replace('$', '$$')))
        set-content -Value $PSProfile -Path $psprofilefile
    }
    else {
        $GroupStartLine >> $psprofilefile
        $loaderContent >> $psprofilefile
        $GroupEndLine >> $psprofilefile
    }       
}

