# Basic commands
function which($name) { Get-Command $name -ErrorAction SilentlyContinue | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

# Common Editing needs
function Edit-Hosts { Invoke-Expression "sudo $(if($null -ne $env:EDITOR)  {$env:EDITOR } else { 'notepad' }) '$env:windir\system32\drivers\etc\hosts'" }
function Edit-Profile { Invoke-Expression "$(if($null -ne $env:EDITOR)  {$env:EDITOR } else { 'notepad' }) '$profile'" }

# Sudo
function sudo() {
    if ($args.Length -eq 1) {
        start-process $args[0] -verb "runAs"
    }
    if ($args.Length -gt 1) {
        start-process $args[0] -ArgumentList $args[1..$args.Length] -verb "runAs"
    }
}

function Get-SoundVolume {[math]::Round([Audio]::Volume * 100)}
function Get-SoundMute {[Audio]::Mute}
Function Set-SoundVolume([Parameter(mandatory=$true)][Int32] $Volume){
    [Audio]::Volume = ($Volume / 100)
}
Function Set-SoundMute {[Audio]::Mute = $true}
Function Set-SoundUnmute {[Audio]::Mute = $false}

get-childitem (join-path $PSScriptRoot "functions") -filter '*.ps1' -Recurse | foreach-Object {
    . ($_.fullname)
}