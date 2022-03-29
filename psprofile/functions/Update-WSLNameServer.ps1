function Update-WSLNameServer {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'medium')]
    param (
        [Parameter()]
        [ValidateSet('Debian', 'Ubuntu', 'Ubuntu-20.04')]
        [string]
        $Distribution = 'Debian',

        [Parameter()]
        [string[]]
        $FallBackNameServers = @(
            '1.1.1.1'
            '1.0.0.1'
        )
    )

    switch ($Distribution) {
        'Debian' { $DistExecutable = 'debian.exe' }
        'Ubuntu' { $DistExecutable = 'ubuntu.exe' }
        'Ubuntu-20.04' { $PackageName = 'ubuntu2004.exe' }
        default {
            write-error ('Distribution {0} not configured in powershell function Initialize-WSLDistribution.' -f $Distribution) -ErrorAction 'Stop'
        }
    }
    if ($null -eq (get-command $DistExecutable -erroraction 'SilentlyContinue')) {
        Write-Error "Could not find $DistExecutable, check if the appx package for distribution $Distribution is installed and avilable in current session. Use Install-WSLDistribution to install." -ErrorAction 'stop'
    }

    $hasWSLCOnf = Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command 'if [[ -f /etc/wsl.conf ]]; then echo 1 ; else echo 0 ; fi'
    write-verbose ("has wslconf: $hasWSLConf")
    if ($hasWSLCOnf -eq '1') {
        $HasREsolveConfFalse = Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "if [[ '`$(grep 'generateResolvConf = false' /etc/wsl.conf)' != '' ]]; then echo 1 ; else echo 0 ; fi"
        write-verbose ("HasREsolveConfFalse: $HasREsolveConfFalse")
        if ($HasREsolveConfFalse -eq '0') {

            $HasREsolveConfFalse = Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "echo '[network]' >> /etc/wsl.conf"
            $HasREsolveConfFalse = Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "echo 'generateResolvConf = false' >> /etc/wsl.conf"
        }
    }
    else {
        $HasREsolveConfFalse = Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "echo '[network]' > /etc/wsl.conf"
        $HasREsolveConfFalse = Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command "echo 'generateResolvConf = false' >> /etc/wsl.conf"
    }

    $IPConfigs = Get-NetIPConfiguration 
    $defaultrouteInterfaceIndex = (Get-netroute -DestinationPrefix '0.0.0.0/0').ifIndex
    $FirstConfig = $IPConfigs.where({ $_.InterfaceIndex -eq $defaultrouteInterfaceIndex })
    $restConfigs = $IPConfigs.where({ $_.InterfaceIndex -ne $defaultrouteInterfaceIndex })
    $sortedConfigs = @($FirstConfig) + @($restConfigs)
    
    $nameservers = $sortedConfigs.DNSServer.ServerAddresses |
    where { $_ -notin @(
            'fec0:0:0:ffff::1'
            'fec0:0:0:ffff::2'
            'fec0:0:0:ffff::3'
        ) }
    $nameservers = @($nameservers) + $FallBackNameServers | select-object -Unique 
    Write-Verbose 'removing previous nameserver entries'
    $command = "sed -i 's/^nameserver/# nameserver/g' /etc/resolv.conf"
    Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command ($command) 

    foreach ($server in $nameservers) {
        Write-Verbose ('adding dnsserver {0} to resolve.conf' -f $server)
        $command = "sed -i '/^# nameserver {0}/d' /etc/resolv.conf;" -f $server
        $command += "echo 'nameserver {0}' >> /etc/resolv.conf;" -f $server
        write-verbose $command
        Invoke-WSLCommand -DistributionName $Distribution -user 'root' -Command $command
    }

}