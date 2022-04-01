function Update-DotFiles {
    $dotfilespointerfilePath = join-path $env:USERPROFILE '.dotfileslocation'
    
    if(!(test-path $dotfilespointerfilePath -PathType Leaf)){
        Write-Error 'dotfiles pointerfile not found. run bootstrap or install script. See Readme for more info' -erroraction 'stop'
    }

    $dotfilesPath = get-content $dotfilespointerfilePath
    if (!(Test-Path $dotfilesPath -PathType Container)){
        Write-Error 'dotfiles pointerfile pointing to nonexistent folder. run bootstrap or install script. See Readme for more info' -erroraction 'stop'
    }

    $dotfilesGitPath = join-path $dotfilesPath '.\.git'
    if (test-Path $dotfilesGitPath){
        #folder is git folder can update with git.
        push-location $dotfilesPath
        try{
            $null = git remote update 2>1
            $localhash= git rev-parse '@'
            $remotehash= git rev-parse '@{u}'
            if($localhash -ne $remotehash){
                $null = git clean -f #cleaning to avoid mergeconflicts
                $null = git pull
            }
            pop-location
            & (join-path (join-path $dotfilesPath 'scripts') 'bootstrap.ps1')
        }
        catch{
            Pop-Location
            write-error $_ -ErrorAction 'stop'
        }
        
    }else{
        $installSCriptLocation = join-path (join-path $dotfilesPath 'scripts') 'install.ps1'
        #missing git as item installing from install.ps1
        if(test-path $installSCriptLocation){
            . $installSCriptLocation -targetPath $dotfilesPath
        }else{
            Write-Error "could not find install script 'scripts/install.ps1' in dotfileslocation $dotfilespath. run bootstrap or install script. See Readme for more info" -ErrorAction 'stop'
        }
    }
}