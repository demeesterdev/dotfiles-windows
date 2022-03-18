# windows .files demeesterdev

These are my dotfiles. This repository helps me to setup and maintain my windows installation. Feel free to explore, learn and copy for your own dotfiles.

> need dotfiles for linux? check out my [dotfiles](https://github.com/demeesterdev/dotfiles) repo

## Installation

### Fresh Installation

> Note: You must have your execution policy set to unrestricted (or at least in bypass) for this to work. To set this, run Set-ExecutionPolicy Unrestricted from a PowerShell running as Administrator.

To configure a new machine when git is not yet installed:

```powershell
Set-ExecutionPolicy 'Unrestricted' -Scope 'Process';
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/demeesterdev/dotfiles-windows/main/scripts/install-machine.ps1'))
```

to just install dotfiles without git installed

```powershell
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/demeesterdev/dotfiles-windows/main/scripts/install.ps1'))
```