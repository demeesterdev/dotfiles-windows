function Install-WSLDistribution {
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='medium',DefaultParameterSetName='Distro-Install.Init.Configure')]
    param (
        [Parameter()]
        [ValidateSet('Debian','Ubuntu','Ubuntu-20.04')]
        [string]
        $Distribution='Debian',

        # Install Distro
        [Parameter(Mandatory=$true,ParameterSetName='Distro-Install')]
        [switch]
        $Install,

        # Install and Initialize Distro
        [Parameter(Mandatory=$true,ParameterSetName='Distro-Install.Init')]
        [switch]
        $InstallInit,

        # username to use for distribution
        [Parameter(Mandatory=$true,ParameterSetName='Distro-Install.Init')]
        [Parameter(Mandatory=$true,ParameterSetName='Distro-Install.Init.Configure')]
        [string]
        $UserName,

        # password to set for user
        [Parameter(Mandatory=$true,ParameterSetName='Distro-Install.Init')]
        [Parameter(Mandatory=$true,ParameterSetName='Distro-Install.Init.Configure')]
        [securestring]
        $Password,

        # dotfiles repository
        # github-id/your-dotfiles-repo
        [Parameter(ParameterSetName='Distro-Install.Init.Configure')]
        [string]
        $DotfilesRepository='demeesterdev/dotfiles',

        # path to install the repository to
        [Parameter(ParameterSetName='Distro-Install.Init.Configure')]
        [string]
        $DotfilesTargetPath='~/dotfiles',

        # command to run installing the repository
        [Parameter(ParameterSetName='Distro-Install.Init.Configure')]
        [string]
        $DotfilesInstallCommand='~/dotfiles/bin/install.sh',

        [Parameter()]
        [switch]
        $Force
    )

    #prerequisites
    Write-verbose "Checking For dependency WSL"
    if ($null -eq (get-command 'wsl.exe' -erroraction 'SilentlyContinue')) {
        Write-Error "Could not find WSL.exe, check if it is installed and avilable in current session" -ErrorAction 'stop'
    }
    Write-verbose "Checking For dependency Winget"
    if ($null -eq (get-command 'wsl.exe' -erroraction 'SilentlyContinue')) {
        Write-Error "Could not find Winget.exe, check if it is installed and avilable in current session" -ErrorAction 'stop'
    }

    #check if distro is installed and configured to run
    $WSLDistributions = Get-WslDistribution 
    $WSLInstalled = $WSLDistributions.Name -contains $Distribution

    if($WSLInstalled){
        $wrnMessage = 'WSL Distribution `{0}` has previously been installed on `{1}`. This action will reinitialize the distribution' -f @(
            $Distribution,
            $env:COMPUTERNAME
        )
        Write-Warning $wrnMessage
        $oldConfirmPreference = $ConfirmPreference 
        $ConfirmPreference = 'Low'
        if($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME,('reinitialize WSL Distribution {0}' -f $Distribution))){
            Remove-WslDistribution -Name $Distribution
        }else{
            return
        }
        $ConfirmPreference = $oldConfirmPreference
    }else{
        if($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, ('install WSL Distribution {0}' -f $Distribution))){
            switch ($Distribution) {
                'Debian' { $PackageName = 'Debian.Debian' }
                'Ubuntu' { $PackageName = 'Canonical.Ubuntu' }
                'Ubuntu-20.04' { $PackageName = 'Canonical.Ubuntu.2004' }
                default {
                    write-error ('Distribution {0} not configured in function.' -f $Distribution) -ErrorAction 'Stop'
                }
            }
            if(!(Get-package $PackageName -provider Winget -requiredversion latest -ErrorAction 'silentlyContinue')){
                write-verbose "Installing '$PackageName' with winget"
                Install-Package $PackageName -Provider WinGet -Force | Out-Null
            }else{
                write-verbose "Installing '$PackageName' with winget [SKIPPED] already up to date "
            }
        }else{
            return
        }
    }

    Restore-Environment
    write-verbose $PSCmdlet.ParameterSetName
    if($PSCmdlet.ParameterSetName -in @('Distro-Install.Init', 'Distro-Install.Init.Configure')){
        Initialize-WSLDistribution `
            -Distribution $Distribution `
            -UserName $UserName `
            -Password $Password `
            -Force
    }

    if($PSCmdlet.ParameterSetName -eq 'Distro-Install.Init.Configure' ){
        Install-WSLDotfiles `
            -Distribution $Distribution `
            -DotfilesRepository $DotfilesRepository `
            -DotfilesTargetPath $DotfilesTargetPath `
            -DotfilesInstallCommand $DotfilesInstallCommand `
    }
}