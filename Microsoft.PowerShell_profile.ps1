# ====================================
# Aliases
# ====================================

# Visual Studio Code Aliases
Set-Alias vs "C:\Users\will\AppData\Local\Programs\Microsoft VS Code\Code.exe"
Set-Alias vc vs
Set-Alias vscode vs

# Other Aliases
New-Alias which Get-Command
New-Alias cz chezmoi
Set-Alias -Name nslookup -Value dnslookup
New-Alias tws Start-TrainingWebServer

# ====================================
# Key Bindings
# ====================================

# PSReadLine Configurations
Set-PSReadLineKeyHandler -Chord "Tab" -Function Complete
Set-PSReadLineKeyHandler -Chord "RightArrow" -Function ForwardWord
Set-PSReadLineKeyHandler -Chord "LeftArrow" -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+q -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key Ctrl+Q -Function AcceptNextSuggestionWord
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -PredictionViewStyle ListView

# Custom Key Bindings

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
    -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
    -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}

# ====================================
# Helper Functions
# ====================================

# Dynamic Aliases for Last Command
function Set-LastCommandNameDynamicAlias {
    Set-Alias da $(Get-LastCommandName)
}

function Get-LastCommandName {
    $cl = (Get-History | Select-Object -Last 1).CommandLine
    return $cl ? $cl.Split(" ")[0] : ""
}

# Set-LastCommandLineAlias: Creates a new alias for the full command line of the last command executed
function Set-LastCommandLineAlias {

    # Create a new alias for the full command line of the last command executed
    Set-Alias last $(Get-LastCommandLine) 2>$null
}

function Get-LastCommandLine {
    return (Get-History | Select-Object -Last 1).CommandLine
}

function Get-ShortCommandName($cmd = $(Get-LastCommandName)) {
    $scn = Get-Item -Path Alias:* | Where-Object { $_.Definition -eq "$cmd" } `
    | Select-Object -ExpandProperty Name | Get-Random

    return $scn
}

<#
.SYNOPSIS
This function updates text content in .txt files.

.DESCRIPTION
Searches for a specific string in all .txt files in the current directory and replaces it with another string.

.PARAMETER FindString
The string to find.

.PARAMETER ReplaceString
The string to replace FindString with.

.EXAMPLE
Update-TextContent -FindString "findMe" -ReplaceString "replaceWithMe"
#>
function Update-TextContent {
    param(
        [string]$FindString,
        [string]$ReplaceString
    )
    $files = Get-ChildItem -Path $PWD -Filter *.txt
    $totalChanges = 0
    foreach ($file in $files) {
        $content = Get-Content $file
        $newContent = $content -creplace $FindString, $ReplaceString
        $changes = (($newContent | Out-String) -split $FindString).Count - 1
        if ($changes -gt 0) {
            Write-Output "Replaced $changes instances of '$FindString' with '$ReplaceString' in $($file.FullName)"
            Set-Content $file.FullName $newContent
            $totalChanges += $changes
        }
    }
    Write-Output "Total changes: $totalChanges"
}

# Start Training WebServer
function Start-TrainingWebServer {
    param(
        [string]$directory,
        [string]$defaultIndexPage = "training.html",
        [string]$defaultDirectoryPrefix = "G:\My Drive\!ai\outputs",
        [int]$port = 8000
    )
    $processName = "python"
    $webServerProcess = Get-Process -Name $processName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match "http.server" }
    if ($null -ne $webServerProcess) {
        $webServerProcess | Stop-Process -Force
    }
    $defaultIndexPagePathFull = "G:\My Drive\!ai\$defaultIndexPage"
    Copy-Item $defaultIndexPagePathFull $directory
    Write-Host "Started! http://localhost:$port/$defaultIndexPage"
    python -m http.server --directory $directory $port
}

# Activate Python Virtual Environment
function venv {
    Get-ChildItem activate.ps1 -Recurse -Depth 2 | ForEach-Object { $_.FullName } | Invoke-Expression
}

# Filter Numbers by Prefix
function FilterNumbersByPrefix {
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $NumberList,

        [Parameter(Mandatory = $true)]
        [string] $Prefix
    )

    $PrefixLength = $Prefix.Length
    $FilteredNumbers = @()
    foreach ($number in $NumberList) {
        if ($number.Substring(0, $PrefixLength) -eq $Prefix) {
            $FilteredNumbers += $number
        }
    }
    $FilteredNumbers = $FilteredNumbers | Sort-Object
    return $FilteredNumbers
}

# ====================================
# Initialization
# ====================================


# Check for dnslookup
$dnslookupAvailable = Get-Command dnslookup -ErrorAction SilentlyContinue
if (-Not $dnslookupAvailable) {
    Write-Host "dnslookup not found. Installing via winget..."
    winget install ameshkov.dnslookup
}

function Invoke-Starship-PreCommand {
    # $host.ui.Write("🚀")
    SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
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