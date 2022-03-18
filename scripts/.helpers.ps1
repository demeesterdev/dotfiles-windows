function Verify-Elevated {
    # Get the ID and security principal of the current user account
    $myIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myPrincipal=new-object System.Security.Principal.WindowsPrincipal($myIdentity)
    # Check to see if we are currently running "as Administrator"
    return $myPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-Elevated ($CommandDefinition) {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = $CommandDefinition;
    $newProcess.Verb = "runas";
    $newProcessObj = [System.Diagnostics.Process]::Start($newProcess);

}

function write-header ($header){
    write-information '*--' -InformationAction 'Continue'
    foreach ($line in ($header -split "`r`n")){
    write-information ('*    {0}' -f $line)  -InformationAction 'Continue'
    }
    write-information '*--'  -InformationAction 'Continue'
}

#create variable to keep track of needed reboot
New-variable -Name ShouldRebootFromDotfiles -Scope Script -ErrorAction 'SilentlyContinue'

function Set-RegistryItemProperty {
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Position=1,Mandatory=$true)]
        [string]
        $PropertyName,

        [Parameter(Position=2,Mandatory=$true)]
        [string]
        $PropertyValue,

        [Parameter()]
        [string]
        $PropertyType,

        [switch]
        $ShouldRebootAfterChange=$false
    )
    
    $Parent = split-path -Parent $Path
    if(!(Test-Path $Parent)){
        New-RegistryPath -Path $Parent
    }

    if (Test-Path $Path) {
        $oldValue = Get-ItemPropertyValue -Path $Path -Name $PropertyName -erroraction SilentlyContinue    
    }else{
        $oldValue = $null
    }
    
    $SetItemPropertySplat = @{
        Path = $Path
        Name = $PropertyName
        Value = $PropertyValue
    }
    if ($PSBoundParameters.ContainsKey('PropertyType')){
        $SetItemPropertySplat.Add('Type', $type)
    }
    Set-ItemProperty @SetItemPropertySplat

    if($ShouldRebootAfterChange -and ($oldValue -ne $PropertyValue)){
        $script:ShouldRebootFromDotfiles = $true
    }
}

function New-RegistryPath {
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        $Path
    )
    $Parent = split-path -Parent $Path
    if(!(Test-Path $Parent)){
        New-RegistryPath -Path $Parent
    }
    New-Item -Path $Path -Type Folder | Out-Null
}

function Enable-WindowsOptionalFeatureOnline {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline)]
        [string]
        $FeatureName
    )

    process {
        $Feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
        if($feature.State -ne 'Enabled'){
            Enable-WindowsOptionalFeature -Online -All -FeatureName $featureName -NoRestart -WarningAction SilentlyContinue | Out-Null
            $script:ShouldRebootFromDotfiles = $true
        }

    }
}

function Test-WaitingRebootAfterDotfiles {
    return [bool]$script:ShouldRebootFromDotfiles
}

# Reload the $env object from the registry
function Refresh-Environment {
    $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
                 'HKCU:\Environment'

    $locations | ForEach-Object {
        $k = Get-Item $_
        $k.GetValueNames() | ForEach-Object {
            $name  = $_
            $value = $k.GetValue($_)
            Set-Item -Path Env:\$name -Value $value
        }
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
