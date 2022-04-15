# this profile can be used if you are simply copying the psprofile filed to your machine.
# you can also use the bootstrap script in the scripts folder of this repo.
# this will create a line in your psprofile wich dotsources the profile loader.

# group dotfiles autoloader
# loads the psprofile from a managed dotfiles repository at C:\Users\tdemeester\dotfiles\dotfiles
Invoke-Expression ". '$(join-path $PSScriptRoot 'profile.loader.ps1')'"
#endgroup dotfiles autoloader
