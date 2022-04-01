function Get-DotFilesFolder {
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param ()

    $dotfilespointerfilePath = join-path $env:USERPROFILE '.dotfileslocation'
    
    $ErrorActionPreference = 'stop'

    if (! (Test-Path $dotfilespointerfilePath -PathType Leaf)) {
        Write-error ('Could not find dotfilespointerfile: {0}' -f $_) 
    }
    else {
        try {
            $dotfilesPath = get-content $dotfilespointerfile.FullName
        }
        catch {
            Write-Error ('Could not read dotfilespointerfile: {0}' -f $_) 
        }
    }
    if (!(Test-Path $dotfilesPath -PathType Container)) {
        $errormsg = 'dotfilespointerfile ~/.dotfileslocation pointing to nonexistent folder[{0}]' -f $dotfilesPath
        $errormsg += 'run bootstrap or install script. See dotfiles README.md for more information.'
        Write-Error $errormsg
    }

    write-output (get-item $dotfilesPath)
}