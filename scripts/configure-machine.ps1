. (join-path $PSScriptRoot '.helpers.ps1')
$InformationPreference = 'Continue'
if (!(Verify-Elevated)) {
    Start-Elevated (join-path $PSScriptRoot 'configure-machine.ps1')
    return
}

$ConfigureMachineScriptFolder = join-path $PSScriptRoot 'configure-machine'

. (Join-Path $ConfigureMachineScriptFolder 'configure-os.ps1')
. (Join-Path $ConfigureMachineScriptFolder 'configure-privacy.ps1')
. (Join-Path $ConfigureMachineScriptFolder 'configure-deps.ps1')