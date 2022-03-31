param(
    $targetPath = (join-path $env:USERPROFILE 'dotfiles'),
    $account = "demeesterdev",
    $repo = "dotfiles-windows",
    $branch = "main",
    [switch]$configureMachine
)

$dotfilesTempDir = Join-Path $env:TEMP "dotfiles"
if (![System.IO.Directory]::Exists($dotfilesTempDir)) { [System.IO.Directory]::CreateDirectory($dotfilesTempDir) }
$sourceFile = Join-Path $dotfilesTempDir "dotfiles.zip"
$dotfilesInstallDir = Join-Path $dotfilesTempDir "$repo-$branch"

function Download-File {
    param (
        [string]$url,
        [string]$file
    )
    Write-Host "Downloading $url to $file"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
}

function Unzip-File {
    param (
        [string]$File,
        [string]$Destination = (Get-Location).Path
    )

    $filePath = Resolve-Path $File
    $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

    Write-Host "unpacking $file to $Destination"
    If (($PSVersionTable.PSVersion.Major -ge 3) -and
        (
            [version](Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -ge [version]"4.5" -or
            [version](Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -ge [version]"4.5"
        )) {
        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$filePath", "$destinationPath")
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
    else {
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destinationPath).copyhere(($shell.NameSpace($filePath)).items())
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
}

try {
    if (@(get-command 'git').count -eq 0) {
        Download-File "https://github.com/$account/$repo/archive/$branch.zip" $sourceFile
        if ([System.IO.Directory]::Exists($dotfilesInstallDir)) { [System.IO.Directory]::Delete($dotfilesInstallDir, $true) }
        Unzip-File $sourceFile $dotfilesTempDir

        Write-Host "moving $dotfilesInstallDir/* to $targetPath"
        if ([System.IO.Directory]::Exists($targetPath)) { [System.IO.Directory]::Delete($targetPath, $true) }
        Copy-Item -Path $dotfilesInstallDir -Destination $targetPath -recurse -Force

        $targetpath | set-content (join-path $env:USERPROFILE '.dotfileslocation')
    }
    else {
        if ([System.IO.Directory]::Exists($targetPath)) { remove-item -Path $targetPath -Recurse -Force }
        $url = "https://github.com/$account/$repo.git"
        Write-Host "cloning dotfiles from $url"
        Write-Host "Cloning into '$targetPath' ..."
        git clone $url "$targetPath" --branch $branch --quiet
    }
    Write-Host "Bootstrap DotFiles"
    & (join-path (join-path $targetpath 'scripts') 'bootstrap.ps1')

    if($configureMachine -or ($env:DOTFILES_CONFIGURE_MACHINE -eq $true)){
    Write-Host "Configure Machine"
    & (join-path (join-path $targetpath 'scripts') 'configure-machine.ps1')
    }
}
catch {
    $_
}
finally {

}

