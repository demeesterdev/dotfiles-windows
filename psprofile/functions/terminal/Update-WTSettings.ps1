function Update-WTSettings {
    [CmdletBinding()]
    param (
    )

    # get windows terminal settings file location
    $TerminalAppx = Get-AppxPackage -Name 'Microsoft.WindowsTerminal'
    if (@($TerminalAppx).count -eq 0) {
        Write-Error "could not find windows terminal. install from ms store (https://aka.ms/terminal) or use `winget install Microsoft.WindowsTerminal` to install" -ErrorAction 'stop'
    }

    $PackageDataPath = join-path $env:LOCALAPPDATA 'Packages'
    $WTAppdataPath = join-path $PackageDataPath $TerminalAppx.PackageFamilyName
    $SettingsFile = join-path (join-path $WTAppdataPath 'LocalState') 'settings.json'

    # get dotfiles install location
    $dotfilespointerfilePath = join-path $env:USERPROFILE '.dotfileslocation'
    
    if (!(test-path $dotfilespointerfilePath -PathType Leaf)) {
        Write-Error 'dotfiles pointerfile not found. run bootstrap or install script. See Readme for more info' -erroraction 'stop'
    }

    $dotfilesPath = get-content $dotfilespointerfilePath
    if (!(Test-Path $dotfilesPath -PathType Container)) {
        Write-Error 'dotfiles pointerfile pointing to nonexistent folder. run bootstrap or install script. See Readme for more info' -erroraction 'stop'
    }
    $iconSourcePath = join-path $dotfilesPath "static" "img"
    $iconFiles = Get-ChildItem $iconSourcePath -filter '*_icon.png'


    # create settinsgfile if not exists
    if ( ! (Test-Path $SettingsFile)) {
        @{
            '$help'   = 'https://aka.ms/terminal-documentation'
            '$schema' = 'https://aka.ms/terminal-profiles-schema'
            profiles = @{
                list = @()
            }
        } | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile
    }
    
    $settingsObj = Get-Content $SettingsFile | Convertfrom-Json -Depth 10 -AsHashtable

    # setup profiles
    $profiles = $settingsObj.profiles.list

    # setup wsl profiles

    $WSLDistributions = Get-WslDistribution
    $WTWSLDistributions = $WSLDistributions | Where-Object 'Name' -NotLike 'docker-desktop*'

    foreach ($WSLDistro in $WTWSLDistributions) {
        $tempProfiles = $profiles | Where-Object 'name' -NE $WSLDistro.Name
        $currentProfile = $profiles | Where-Object 'name' -eq $WSLDistro.Name | Select-Object -First 1
        if (@($currentProfile).count -eq 0) {
            $currentProfile = @{
                guid = '{{{0}}}' -f (new-guid).Guid
                name = $WSLDistro.Name
                
            }
        }
        $currentProfile.source = 'Windows.Terminal.Wsl'
        $currentProfile.hidden = $false
        $currentProfile.commmandline = 'C:\\WINDOWS\\system32\\wsl.exe -d {0}' -f $WSLDistro.Name
        $currentProfile.startingDirectory = '~'
        $currentProfile.colorScheme = 'Campbell'
        $currentProfile.font = @{face='Cascadia Code'}

        $iconfilename = '{0}_icon.png' -f $WSLDistro.name
        $iconfile = $iconFiles | where-object 'Name' -EQ $iconfilename
        if($iconfile){
            $currentProfile.backgroundImage = $iconfile.FullName
            $currentProfile.backgroundImageStretchMode = 'none'
            $currentProfile.backgroundImageOpacity = 0.20
            $currentProfile.icon = $iconfile.FullName
        }else{
            $currentProfile.Remove('backgroundImage')
            $currentProfile.Remove('backgroundImageStretchMode')
            $currentProfile.Remove('backgroundImageOpacity')
            $linuxIconFile = $iconFiles | where-object 'Name' -EQ 'linux_icon.png'
            if($linuxIconFile){
                $currentProfile.icon = $linuxIconFile.FullName
            }else{
                $currentProfile.icon = 'ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png'
            }
        }
        $profiles = @($tempProfiles) + $currentProfile
    }
        
    # setup pwsh profile

    if(@(Get-command 'pwsh' -erroraction 'silentlycontinue').Count -ge 1){
        $tempProfiles = $profiles | Where-Object 'name' -NotIn @('pwsh', 'Powershell')
        $currentProfile = @{
            guid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
            name = 'pwsh'
            hidden = $false
            source = 'Windows.Terminal.PowershellCore'
        }
        $profiles = @($tempProfiles) + $currentProfile
    }

    # setup windows powershell profile
    if(@(Get-command 'pwsh' -erroraction 'silentlycontinue').Count -ge 1){
        $tempProfiles = $profiles | Where-Object 'name' -NotIn @('Windows Powershell', 'Powershell')
        $currentProfile = @{
            guid = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
            name = 'Windows Powershell'
            hidden = $false
            commandline = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
            colorScheme = 'Campbell Powershell'
        }
        $profiles = @($tempProfiles) + $currentProfile
    }

    # setup command prompt profile
    if(@(Get-command 'cmd' -erroraction 'silentlycontinue').Count -ge 1){
        $tempProfiles = $profiles | Where-Object 'name' -NotIn @('Command Prompt', 'cmd')
        $currentProfile = @{
            guid = '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}'
            name = 'Command Prompt'
            hidden = $false
            commandline = '%SystemRoot%\System32\cmd.exe'
            colorScheme = 'Vintage'
            font = @{face='Consolas'}
        }
        $profiles = @($tempProfiles) + $currentProfile
    }
    # setup profile order

    $sortedprofiles = @()
        #debian first
        $sortedprofiles += $profiles.Where({$_.name -eq 'debian'})
        #pwsh seconf
        $sortedprofiles += $profiles.Where({$_.source -eq 'Windows.Terminal.PowershellCore'})
        #windows powershell
        $sortedprofiles += $profiles.Where({$_.commandline -like '*\powershell.exe'})
        #command line
        $sortedprofiles += $profiles.Where({$_.commandline -like '*\cmd.exe'})
        #other profiles
        $sortedprofiles += $profiles.Where({$_.guid -notin $sortedprofiles.guid})

    $settingsObj.profiles.list = $sortedprofiles
    
    # set default profile from order
    $settingsObj.defaultProfile = $sortedprofiles[0].guid

    $settingsObj | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile
}