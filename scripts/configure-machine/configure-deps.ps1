. (join-path (split-path -parent $PSScriptRoot) '.helpers.ps1')
$InformationPreference = 'Continue'

if (!(Verify-Elevated)) {
    Start-Elevated $myInvocation.MyCommand.Definition;
    return
}

###############################################################################
### Package providers and modules                                             #
###############################################################################

### package providers
write-header 'Installing Package Providers'

if((get-packageprovider -ListAvailable).Name -notcontains ('NuGet')){
    Install-PackageProvider NuGet -Force | out-null
}
if((get-packageprovider -ListAvailable).Name -notcontains ('Winget')){
    Install-PackageProvider WinGet -Force | out-null
}

write-information " ... Complete ..."

### Install PowerShell Modules
write-header 'Installing PowerShell Modules'

write-information " - Posh-git "
Install-Module Posh-Git -Scope CurrentUser -Force
write-information " ... Complete ..."


###############################################################################
### winget packages                                                              #
###############################################################################

write-header "Installing Desktop Utilities"
if ($null -eq (get-command winget -erroraction 'SilentlyContinue')) {
    write-information "  - Installing Winget"
    $dotfilesTempDir = Join-Path $env:TEMP "dotfiles"
    if (![System.IO.Directory]::Exists($dotfilesTempDir)) {[System.IO.Directory]::CreateDirectory($dotfilesTempDir)}

    $wgLatestRelease = invoke-restmethod -UseBasicParsing -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $wgetPackageAsset = @($wgLatestRelease.assets | Where-Object {$_.name -like '*.msixbundle'})[0]
    
    $DownloadfilePath = join-path $dotfilesTempDir $wgetPackageAsset.Name
    Invoke-WebRequest -Uri $wgetPackageAsset.browser_download_url -OutFile $DownloadfilePath -UseBasicParsing
    Add-AppxPackage $DownloadfilePath
}else {
    write-information "  - Installing Winget [SKIPPED] already up to date"
}

if ($null -eq (get-command cinst -erroraction 'SilentlyContinue')) {
    write-information "  - Installing chocolaty"
    Invoke-Expression (new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')
    Refresh-Environment
    choco feature enable -n=allowGlobalConfirmation
}else{
    write-information "  - Installing chocolaty [SKIPPED] already up to date"
}

Refresh-Environment

$requiredPackages = @(
    #system and cli
    'Git.Git'
    'GitHub.cli'
    'Microsoft.PowerShell'
    'Microsoft.WindowsTerminal'
    'Microsoft.AzureCLI'
    
    #utilities
    'VideoLAN.VLC'
    'Bitwarden.Bitwarden'   
    'Google.Chrome'
    'Docker.DockerDesktop'
    'Logitech.GHUB'
    'Obsidian.Obsidian'
    'SlackTechnologies.Slack'
    # '7zip.7zip' -forces reboot using choco

    # dev tools and frameworks
    'Microsoft.PowerToys'
    'Microsoft.VisualStudioCode'
    'vim.vim'
    'GoLang.Go'
    'Python.Python.3'
)

#installing os packages

foreach ($package in $requiredPackages){
    if(!(Get-package $package -provider Winget -requiredversion latest -ErrorAction 'silentlyContinue')){
        write-information "  - Installing $package"
        Install-Package $package -Provider WinGet -Force | Out-Null
    }else{
        write-information "  - Installing $package [SKIPPED] already up to date "
    }
}

write-information "  - Installing 7zip"
choco install 7zip.install --limit-output


Refresh-Environment

write-information " ... Complete ..."