function Install-WSLDotfiles {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'medium')]
    param (
        [Parameter()]
        [ValidateSet('Debian', 'Ubuntu', 'Ubuntu-20.04')]
        [string]
        $Distribution = 'Debian',

        # dotfiles repository
        # github-id/your-dotfiles-repo
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DotfilesRepository = 'demeesterdev/dotfiles',

        # path to install the repository to
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DotfilesTargetPath = '~/dotfiles',

        # command to run installing the repository
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DotfilesInstallCommand = '~/dotfiles/bin/install.sh dotfiles',

        # user to install the dotfiles repo as uses default user if no user was passed
        [Parameter]
        [string]
        $User
    )


    #check if distro is installed and configured to run
    $WSLDistribution = Get-WslDistribution -name $Distribution
    if (!$WSLDistribution) {
        write-verbose "Distribution $Distribution not found"
        write-error 'Distribution WSL not installed' -ErrorAction 'stop'
    }
    write-verbose "Distribution $Distribution found"

    #check if dotfilesReposoitory exists
    $repoAPiUrl = 'https://api.github.com/repos/{0}' -f $DotfilesRepository
    try{
        $RepoObj = Invoke-Restmethod $repoAPiUrl -UseBasicParsing
        write-Verbose "Github Repo $DotfilesRepository found"
    }
    catch{
        write-Verbose "Github Repo $DotfilesRepository not found"
        write-error "cannot reach repository '$DotFilesRepository' at ${repoAPiUrl}: $_" -ErrorAction 'stop'
    }

    if (-not $PSBoundParameters.ContainsKey('user')) {
        $UserName = (Invoke-WSLCommand -Distribution $WSLDistribution -Command 'whoami')
    }else{
        $UserName = $User
    }

    $InvokeWSLCommandSplat = @{
        Distribution = $WSLDistribution
        ErrorAction  = 'SilentlyContinue'
        User         = 'root'
    }

    $missingpackages = @()
    # test if certificates are present
    $BashTestDir = 'if [[ -d {0} ]]; then echo 1 ; else echo 0 ; fi'
    $caCertsDir = '/etc/ca-certificates'
    $TestCaCertDirResult = (Invoke-WslCommand -Command ($BashTestDir -f $caCertsDir) @InvokeWSLCommandSplat)
    write-verbose "dependency availability \> test_dir($caCertsDir) : [$TestCaCertDirResult]"
    if ('0' -eq $TestCaCertDirResult ) {
        $missingpackages += 'ca-certificates'
    }

    #check for packages present in distribution for download of repo    
    $requiredpackages = @(
        'git'
        'make'
    )
    foreach ($package in $requiredpackages) {
        $whichSource = Invoke-WslCommand -Command "which $package" @InvokeWSLCommandSplat
        write-verbose "dependency availability \> which ${Package}: [$whichSource]"
        if ($null -eq $whichSource) {
            $missingpackages += $package   
        }
    }

    
    if (@($missingpackages).count -ne 0) {
        write-verbose ('installing {0} dependencies' -f @($missingpackages).count)
        $InvokeWSLCommandSplat.ErrorAction = 'Stop'
        $bashUpdateCommand = 'apt-get update' 
        write-verbose $bashUpdateCommand
        Invoke-WslCommand -Command $bashUpdateCommand @InvokeWSLCommandSplat 

        $BashInstallCommand = 'apt-get install -y {0} --no-install-recommends' -f ($missingpackages -join ' ')
        write-verbose $bashInstallCommand
        Invoke-WslCommand -Command $BashInstallCommand @InvokeWSLCommandSplat        
    }
    else {
        write-verbose 'dependencies available'
    }

    
    $InvokeWSLCommandSplat.User = $UserName
    $DotFilesTargetFullPath = (Invoke-WslCommand -Command ('readlink -f {0}' -f $DotfilesTargetPath) @InvokeWSLCommandSplat)

    $TestTargetDirResult = (Invoke-WslCommand -Command ($BashTestDir -f $DotFilesTargetFullPath) @InvokeWSLCommandSplat)
    write-verbose "test preexisting folder at targetPath \> test_dir($DotFilesTargetFullPath) : [$TestTargetDirResult]"
    if ('1' -eq $TestTargetDirResult) {
        $InvokeWSLCommandSplat.User = 'root'
        Invoke-WslCommand -Command "rm $DotFilesTargetFullPath -drf" @InvokeWSLCommandSplat
    }

    Write-Verbose "Clone $($RepoObj.clone_url) to  $DotFilesTargetFullPath"
    $InvokeWSLCommandSplat.User = $UserName
    $CloneCommand = 'git clone {0} {1}' -f @(
        $RepoObj.clone_url,
        $DotFilesTargetFullPath
    )
    Invoke-WSLCommand -Command $CloneCommand @InvokeWSLCommandSplat

    Write-Verbose "Running install Command $DotfilesInstallCommand"
    Invoke-WSLCommand -Command $DotfilesInstallCommand @InvokeWSLCommandSplat
}