. (join-path (split-path -parent $PSScriptRoot) '.helpers.ps1')
$InformationPreference = 'Continue'

if (!(Verify-Elevated)) {
    Start-Elevated $myInvocation.MyCommand.Definition;
    return
}

###############################################################################
### Security and Identity                                                     #
###############################################################################
# Enable Developer Mode
Set-RegistryItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" "AllowDevelopmentWithoutDevLicense" 1 -ShouldRebootAfterChange
# Bash on Windows
Enable-WindowsOptionalFeatureOnline "Microsoft-Windows-Subsystem-Linux"

###############################################################################
### Devices, Power, and Startup                                               #
###############################################################################
Write-Header "Configuring Devices, Power, and Startup..." 

# Sound: Disable Startup Sound
Set-RegistryItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1
Set-RegistryItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1

# Power: Disable Hibernation
powercfg /hibernate off

# Power: Set standby delay to 24 hours
powercfg /change /standby-timeout-ac 1440

# SSD: Disable SuperFetch
Set-RegistryItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 0

# Network: Disable WiFi Sense
Set-RegistryItemProperty "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" 0

###############################################################################
### Explorer, Taskbar, and System Tray                                        #
###############################################################################
Write-Header "Configuring Explorer, Taskbar, and System Tray..." 

# Ensure necessary registry paths
if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Type Folder | Out-Null}
if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState")) {New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Type Folder | Out-Null}
if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search")) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search" -Type Folder | Out-Null}

# Explorer: Show hidden files by default: Show Files: 1, Hide Files: 2
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1

# Explorer: Show file extensions by default
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0

# Explorer: Show path in title bar
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1

# Explorer: Avoid creating Thumbs.db files on network volumes
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "DisableThumbnailsOnNetworkFolders" 1

# Taskbar: Enable small icons
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarSmallIcons" 1

# Taskbar: Don't show Windows Store Apps on Taskbar
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "StoreAppsOnTaskbar" 0

# Recycle Bin: Disable Delete Confirmation Dialog
Set-RegistryItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "ConfirmFileDelete" 0

###############################################################################
### Default Windows Applications                                              #
###############################################################################
Write-Header "Configuring Default Windows Applications..."

$UnwantedAppxPackages = @(
    "Microsoft.3DBuilder"
    "Microsoft.WindowsAlarms"
    "*.AutodeskSketchBook"
    "*.AutodeskSketchBook"
    "Microsoft.BingFinance"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingWeather"
    "king.com.BubbleWitch3Saga"
    "Microsoft.WindowsCommunicationsApps"
    "king.com.CandyCrushSodaSaga"
    "*.DisneyMagicKingdoms"
    "*.Facebook"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.GetStarted"
    "Microsoft.WindowsMaps"
    "*.MarchofEmpires"
    "Microsoft.Messaging"
    "Microsoft.OneConnect"
    "Microsoft.Office.OneNote"
    "Microsoft.MSPaint"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.SkypeApp"
    "*.SlingTV"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.XboxApp"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.PowerAutomateDesktop"
    "*.HPPrinterControls"
    "*.HPInc.EnergyStar"
    "*.DropboxOEM"
)
write-information 'removing unwanted appx packages:'
foreach ($UnwantedAppxPackage in $UnwantedAppxPackages){
    write-information ('  - {0}' -f $UnwantedAppxPackage)
    try{
    Get-AppxPackage $UnwantedAppxPackage -AllUsers | Remove-AppxPackage | out-null
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -like $UnwantedAppxPackage | Remove-AppxProvisionedPackage -Online | out-null
    }
    catch{
        Write-Information ('    [ERR]:' -f $_)
    }
}


Write-Information 'removing unwanted start menu links:'
$unwantedlinks = @(
    'lastpass.lnk'
)
$startmenupath = "C:\ProgramData\Microsoft\Windows\Start Menu\"
foreach($unwantedlink in $unwantedlinks){
    write-information ('  - {0}' -f $unwantedlink)
    Get-ChildItem -Path $startmenupath -Filter $unwantedlink -Recurse |
        Remove-Item -Force |
        out-null
}

# Uninstall Windows Media Player
Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart -WarningAction SilentlyContinue | Out-Null

# Prevent "Suggested Applications" from returning
Set-RegistryItemProperty "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1

if((get-packageprovider -ListAvailable).Name -notcontains ('Winget')){
    Install-PackageProvider WinGet -Force | out-null
}


###############################################################################
### Default Windows Applications                                              #
###############################################################################
Write-Header "Configuring Windows Defender..."
write-information "Uninstalling preinstalled services"
try{
Get-AppxPackage "*.McAfeeSecurity" -AllUsers | Remove-AppxPackage | out-null
Get-AppXProvisionedPackage -Online | Where-Object DisplayName -like $UnwantedAppxPackage | Remove-AppxProvisionedPackage -Online | out-null
}
catch{
    Write-Information ('    [ERR]:' -f $_)
}

# Bash on Windows
Enable-WindowsOptionalFeatureOnline 'Windows-Defender-Default-Definitions'
Enable-WindowsOptionalFeatureOnline 'Windows-Defender-ApplicationGuard'
