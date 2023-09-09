# Set-Alias: Creates a new alias that launches Visual Studio Code
Set-Alias vs "C:\Users\will\AppData\Local\Programs\Microsoft VS Code\Code.exe"
Set-Alias vc vs
Set-Alias vscode vs
New-Alias which Get-Command
# New-Alias python310 "C:\Users\will\AppData\Local\Programs\Python\Python310\python.exe"
# New-Alias python37 "C:\Users\will\AppData\Local\Programs\Python\Python37\python.exe"
# New-Alias python39 "C:\Users\will\AppData\Local\Programs\Python\Python39\python.exe"
# New-Alias python3913 "C:\Users\will\AppData\Local\Programs\Python\Python39\python.exe"

New-Alias cz chezmoi

# Set-Alias ~ $home
#$~ = r\`
# Install-Module VirtualDesktop
Set-PSReadLineKeyHandler -Chord "Tab" -Function Complete
Set-PSReadLineKeyHandler -Chord "RightArrow" -Function ForwardWord
Set-PSReadLineKeyHandler -Chord "LeftArrow" -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+q -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key Ctrl+Q -Function AcceptNextSuggestionWord
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -PredictionViewStyle ListView

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


# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+V `
    -BriefDescription PasteAsHereString `
    -LongDescription "Paste the clipboard text as a here string" `
    -ScriptBlock {
    param($key, $arg)

    Add-Type -Assembly PresentationCore
    if ([System.Windows.Clipboard]::ContainsText()) {
        # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
        $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    }
}

# Check if dnslookup is available
$dnslookupAvailable = Get-Command dnslookup -ErrorAction SilentlyContinue

# If dnslookup is not available, install it using winget
if (-Not $dnslookupAvailable) {
    Write-Host "dnslookup not found. Installing via winget..."
    winget install ameshkov.dnslookup
}

# Create an alias for nslookup to dnslookup
Set-Alias -Name nslookup -Value dnslookup



# Set-LastCommandNameDynamicAlias: Creates a new alias for the name of the last command executed
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

function Replace-Text {
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

function Start-TrainingWebServer {
    param(
        [string]$directory,
        [string]$defaultIndexPage = "training.html",
        [string]$defaultDirectoryPrefix = "G:\My Drive\!ai\outputs",
        [int]$port = 8000
    )
    $processName = "python"
    $webServerProcess = Get-Process -Name $processName -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -match "http.server"}
    if ($webServerProcess -ne $null) {
        $webServerProcess | Stop-Process -Force
    }
    $defaultIndexPagePathFull = "G:\My Drive\!ai\$defaultIndexPage"
    Copy-Item $defaultIndexPagePathFull $directory
    Write-Host "Started! http://localhost:$port/$defaultIndexPage"
    python -m http.server --directory $directory $port
}

# order PRivacy Laptop filter

New-Alias tws Start-TrainingWebServer

Function venv {
    Get-ChildItem activate.ps1 -Recurse -Depth 2 | %{$_.FullName} | Invoke-Expression
}

function FilterNumbersByPrefix {
    param (
        [Parameter(Mandatory=$true)]
        [string[]] $NumberList,

        [Parameter(Mandatory=$true)]
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
# $numbers = @('2487459990', '2487459994', '2487459991', '1234567890', '9876543210')
# $prefix = '2487'

# $filteredNumbers = FilterNumbersByPrefix -NumberList $numbers -Prefix $prefix
# $filteredNumbers



# a function to update the prompt
# function prompt {

#     $short = "[$($PSStyle.Foreground.BrightCyan)$(Get-ShortCommandName)$($PSStyle.Reset)] "


#     "PS$short $PWD>"
# }
    
# $PS1 = prompt

# trap DEBUG: Automatically executes the Set-LastCommanNameDynamicAlias and Set-LastCommandLineAlias functions when a command is executed in the console
#trap { Set-LastCommandNameDynamicAlias } 
# trap { Set-LastCommandLineAlias } 
function Invoke-Starship-PreCommand {
    # $host.ui.Write("🚀")
    SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
}
Invoke-Expression (&starship init powershell)