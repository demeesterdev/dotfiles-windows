. (join-path $PSScriptRoot '.helpers.ps1')
$InformationPreference = 'Continue'
$ProgressPreference = "SilentlyContinue"

if (!(Verify-Elevated)) {
    Start-Elevated (join-path $PSScriptRoot 'configure-machine.ps1')
    return
}

$ConfigureMachineScriptFolder = join-path $PSScriptRoot 'configure-machine'

. (Join-Path $ConfigureMachineScriptFolder 'configure-os.ps1')
. (Join-Path $ConfigureMachineScriptFolder 'configure-privacy.ps1')
. (Join-Path $ConfigureMachineScriptFolder 'configure-deps.ps1')

Write-Information "===================================="
Write-Information ""
Write-Information "   Machine Configuration Finished"
Write-Information ""
Write-Information "   Some changes might require a reboot"
Write-Information "   This script can initate a reboot if wanted:"
$rebootChoice = Read-Host "Reboot [Y[es]: reboot](default: exit script)"
if ($rebootChoice -eq 'Y' -or $rebootChoice -eq 'Yes'){
    Restart-Computer 
}
