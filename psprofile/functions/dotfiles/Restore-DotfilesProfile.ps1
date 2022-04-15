function Restore-DotfilesProfile {
    #testing for global scope with variables while not leaving any trace
    (new-guid).guid | ForEach-Object {
        try {
            New-Variable -Scope 'local' -name $_ -value (get-date)
            if ((Get-Variable -Scope 'global' -name $_ -ErrorAction 'silentlycontinue')) {
                . ($Env:DOTFILES_PSLOADERPATH)
                write-information ("Loading dotfile profiles took {0}ms." -f ((get-date) - (Get-Variable -Name $_).value).Milliseconds)
            }
            else {
                write-error -Message ("cannot restore profile without running in parent scope.`r`n" + `
                        "run commands in parent scope by executing ``. $($MyInvocation.InvocationName)``.") `
                    -ErrorAction 'Stop'
            }
        }
        catch {
            write-error $_
        }
        finally {
            remove-variable -Scope 'local' -name $_ -ErrorAction 'silentlycontinue'
        }
    }
}
        
