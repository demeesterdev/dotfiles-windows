function Initialize-WSLDistribution {
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='medium')]
    param (
        [Parameter()]
        [ValidateSet('Debian','Ubuntu','Ubuntu-20.04')]
        [string]
        $Distribution='Debian',

        # Default User to install and configure for distribution
        [Parameter(Mandatory=$true)]
        [string]
        $UserName,

        # username to use for distribution
        [Parameter(Mandatory=$true)]
        [securestring]
        $Password,

        [Parameter()]
        [switch]
        $Force
    )

    switch ($Distribution) {
        'Debian' { $DistExecutable = 'debian.exe' }
        'Ubuntu' { $DistExecutable = 'ubuntu.exe' }
        'Ubuntu-20.04' { $DistExecutable = 'ubuntu2004.exe' }
        default {
            write-error ('Distribution {0} not configured in powershell function Initialize-WSLDistribution.' -f $Distribution) -ErrorAction 'Stop'
        }
    }
    if ($null -eq (get-command $DistExecutable -erroraction 'SilentlyContinue')) {
        Write-Error "Could not find $DistExecutable, check if the appx package for distribution $Distribution is installed and avilable in current session. Use Install-WSLDistribution to install." -ErrorAction 'stop'
    }

    #check if distro is installed and configured to run
    $WSLDistributions = Get-WslDistribution 
    $WSLInstalled = $WSLDistributions.Name -contains $Distribution
    
    if($WSLInstalled){
        $wrnMessage = 'WSL Distribution `{0}` has previously been initialized on `{1}`. This action will reinitialize the distribution' -f @(
            $Distribution,
            $env:COMPUTERNAME
        )
        Write-Warning $wrnMessage
        $oldConfirmPreference = $ConfirmPreference 
        $ConfirmPreference = 'Low'
        # check if it is ok to reinitialize the repo
        if($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME,('reinitialize WSL Distibution {0}' -f $Distribution))){
            Remove-WslDistribution -Name $Distribution
        }else{
            return
        }
        $ConfirmPreference = $oldConfirmPreference
    }

    #register WSL distro from appx package but do not configure it
    Write-Verbose "Distribution $Distribution - Installing"
    $distributionArgs = @('install','--root')
    . $DistExecutable $distributionArgs 1>$Null
    if ($LASTEXITCODE -ne 0) {
        # Note: this could be the exit code of wsl.exe, or of the launched command.
        throw "Wsl.exe returned exit code $LASTEXITCODE"
    } 
    Write-Verbose "Installing Distribution $Distribution successfull."

    # configure User and password

    Write-Verbose "Distribution $Distribution : user account $UserName - create"
    $command = "/usr/sbin/adduser --disabled-password --quiet --gecos '' '$Username';"

    Write-Verbose "Distribution $Distribution : user account $UserName - add to relevant groups"
    $command += "/usr/sbin/usermod -aG adm,cdrom,sudo,dip,plugdev '$Username';"
    Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command $command

    Write-Verbose "Distribution $Distribution : user account $UserName - set passwrd"
    if($IsCoreCLR){
        Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "echo '${username}:$(ConvertFrom-SecureString $Password -AsPlainText)' | /usr/sbin/chpasswd" 1>$Null
    }else{
        Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "echo '${username}:$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)))' | /usr/sbin/chpasswd" 1>$Null
    }

    Write-Verbose "Distribution $Distribution - Set default user $UserName"
    $distributionArgs = @('config','--default-user', $UserName)
    . $DistExecutable $distributionArgs 1>$Null
    if ($LASTEXITCODE -ne 0) {
        # Note: this could be the exit code of wsl.exe, or of the launched command.
        throw "Wsl.exe returned exit code $LASTEXITCODE"
    } 
}