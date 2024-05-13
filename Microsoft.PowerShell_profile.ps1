# ----------------- ALIASES -----------------
Set-Alias vs code
Set-Alias upip Upgrade-Pip
Set-Alias Start-Roop "cd P:\@ai\roop && venv && python run.py --execution-provider cuda"
New-Alias cz chezmoi
Set-Alias -Name nslookup -Value dnslookup

#----------------- Linux Aliases ---------------

Set-Alias -Name which -Value Get-Command
Set-Alias -Name grep -Value Select-String
Set-Alias -Name ifconfig -Value Get-NetIPAddress
Set-Alias -Name df -Value Get-PSDrive
Set-Alias -Name free -Value Get-ComputerInfo
Set-Alias -Name uname -Value $PSVersionTable
Set-Alias -Name bg -Value Start-Job
Set-Alias -Name fg -Value Receive-Job
Set-Alias -Name jobs -Value Get-Job

# ----------------- Key Bindings----------------
. "$PSScriptRoot\profile\psreadline_settings.ps1"

# ----------------- FUNCTIONS ------------------
. "$PSScriptRoot\profile\functions.ps1"

# ----------------- INITIALIZATION--------------
# Check for dnslookup
$dnslookupAvailable = Get-Command dnslookup -ErrorAction SilentlyContinue
if (-Not $dnslookupAvailable) {
    Write-Host "dnslookup not found. Installing via winget..."
    winget install ameshkov.dnslookup
}

# Check for pyenv
$pyenvAvailable = Get-Command pyenv -ErrorAction SilentlyContinue
if (-Not $pyenvAvailable) {
    Write-Host "pyenv not found. Installing..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
}

git config --global core.autocrlf input
git config --global core.eol lf
git config --global user.email "4395149+primeinc@users.noreply.github.com"
git config --global user.name "primeinc"
git config --global --add safe.directory C:/Users/will/Documents/PowerShell

function Invoke-Starship-PreCommand {
    $result = (Get-WinGetUpdatesCount).Trim()
    $env:WINGETUPDATESCOUNT = $result

    # $host.ui.Write("🚀 $result")
    SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
    # WINGETUPDATESCOUNT = Get-WinGetUpdatesCount
    # $env:WINGETUPDATESCOUNT = Get-WinGetUpdatesCount
}

# Starship Prompt Initialization
Invoke-Expression (&starship init powershell)

# ====================================
# End of Profile Script
# ====================================

# ====================================
# Notes
# ====================================

# trap DEBUG: Automatically executes the Set-LastCommanNameDynamicAlias and Set-LastCommandLineAlias functions when a command is executed in the console
# trap { Set-LastCommandNameDynamicAlias } 
# trap { Set-LastCommandLineAlias } 