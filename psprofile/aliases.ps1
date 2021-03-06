# Easier Navigation: .., ..., ...., ....., and ~
${function:~} = { Set-Location ~ }
# PoSh won't allow ${function:..} because of an invalid path error, so...
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:...} = { Set-Location ../.. }
${function:....} = { Set-Location ../../.. }
${function:.....} = { Set-Location ../../../.. }
${function:......} = { Set-Location ../../../../.. }

#navigation
${function:dt} = { Set-Location ~/Desktop }
${function:docs} = { Set-Location ~/Documents }
${function:dl} = { Set-Location ~/Downloads }

# http://xkcd.com/530/
Set-Alias mute Set-SoundMute
Set-Alias unmute Set-SoundUnmute