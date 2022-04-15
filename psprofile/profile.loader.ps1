# Profile for all hosts
# ===========

$Env:DOTFILES_PSLOADERPATH = join-path $PSScriptRoot 'profile.loader.ps1'

@("components", "functions", "aliases", "exports", "extra") |
Foreach-Object { join-path $PSScriptRoot "$_.ps1" } |
Where-Object { Test-Path $_ } |
ForEach-Object -Process { Invoke-Expression ". '$_'"}