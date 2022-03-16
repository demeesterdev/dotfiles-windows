# These components will be loaded for all PowerShell instances

. (join-path (join-path $PSScriptRoot "components") 'console.ps1')
. (join-path (join-path $PSScriptRoot "components") 'coreaudio.ps1')