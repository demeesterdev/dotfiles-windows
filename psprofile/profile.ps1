# Profile for all hosts
# ===========

@("components", "functions", "aliases", "exports", "extra") |
Foreach-Object { join-path $PSScriptRoot "$_.ps1" } |
Where-Object { Test-Path $_ } |
ForEach-Object -Process { Invoke-Expression ". '$_'"}