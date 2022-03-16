# Make vscode the default editor
$env:EDITOR =  "code"
$env:GIT_EDITOR = $Env:EDITOR

# Disable the Progress Bar
$ProgressPreference='SilentlyContinue'