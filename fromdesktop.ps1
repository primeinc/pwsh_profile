# Set-Alias: Creates a new alias that launches Visual Studio Code
Set-Alias vs "C:\Program Files\Microsoft VS Code\Code.exe"
Set-Alias vc vs
Set-Alias vscode vs
New-Alias which Get-Command
New-Alias python310 "C:\Users\will\AppData\Local\Programs\Python\Python310\python.exe"
New-Alias python37 "C:\Users\will\AppData\Local\Programs\Python\Python37\python.exe"
New-Alias upip Upgrade-Pip
New-Alias Run-Roop "cd  P:\@ai\roop && venv && python run.py --execution-provider cuda"

# Set-Alias ~ $home
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
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+V `
                         -BriefDescription PasteAsHereString `
                         -LongDescription "Paste the clipboard text as a here string" `
                         -ScriptBlock {
    param($key, $arg)

    Add-Type -Assembly PresentationCore
    if ([System.Windows.Clipboard]::ContainsText())
    {
        # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
        $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n","`n").TrimEnd()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    }
}



# Set-LastCommandNameDynamicAlias: Creates a new alias for the name of the last command executed
# function Set-LastCommandNameDynamicAlias {

#     Set-Alias da $(Get-LastCommandName)

# }

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


New-Alias tws Start-TrainingWebServer

Function venv {
    Get-ChildItem activate.ps1 -Recurse -Depth 2 | %{$_.FullName} | Invoke-Expression
}

function Update-GitRepos {
    Get-ChildItem -Directory | ForEach-Object {
        Set-Location $_.FullName
        Write-Output "Updating git repo in $($_.FullName)"
        git stash
        git pull
        Set-Location ..
    }
}

# Function to convert a symlink to a real file
function Convert-SymlinkToRealFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $linkType = (Get-Item $Path).Attributes

    if ($linkType -band [System.IO.FileAttributes]::ReparsePoint) {
        $target = Get-Item $Path | Select-Object -ExpandProperty Target
        Remove-Item $Path
        Copy-Item -Path $target -Destination $Path
    }
}

# Function to convert all symlinks in a folder and subdirectories
function Convert-FolderSymlinksToRealFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    $symlinks = Get-ChildItem -Path $FolderPath -Recurse | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }

    foreach ($symlink in $symlinks) {
        Convert-SymlinkToRealFile -Path $symlink.FullName
    }
}

function Upgrade-Pip {
    python.exe -m pip install --upgrade pip
}

function FeedImages {
    param (
        [string]$Face = "D:\Master - RL\Hannah\!AI headshots\!!!PXL_20210824_184523592 - Copy.jpg",
        [string]$ImageFolder = $PWD.Path
    )


    # Create the fSwap folder if it doesn't exist
    $targetFolder = Join-Path -Path $ImageFolder -ChildPath "fSwap"
    if (-not (Test-Path -Path $targetFolder)) {
        New-Item -ItemType Directory -Path $targetFolder | Out-Null
    }

    # Get all the image files in the specified folder
    $imageFiles = Get-ChildItem -Path $ImageFolder -Filter "*.JPG"

    # Iterate through each image file
    foreach ($imageFile in $imageFiles) {
        $imagePath = $imageFile.FullName
        $outputPath = Join-Path -Path $targetFolder -ChildPath $imageFile.Name

        # Run the command with the image path as an argument
        # $command = "cd P:\@ai\roop && venv && python run.py --execution-provider cuda --source '$Face' --target '$imagePath' --output '$outputPath'"
        # Start-Process -FilePath powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command `"$command`"" -Wait
        # Run the command with the image path as an argument
        # $command = "cd P:\@ai\roop; venv; python run.py --execution-provider cuda --source '$Face' --target '$imagePath' --output '$outputPath'"
        # Start-Process -FilePath powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command `"$command`"" -Wait
        # Run the command with the image path as an argument
        $venvCommand = "P:\@ai\roop-unlocked\venv\Scripts\Activate.ps1"
        $command = "cd P:\@ai\roop-unlocked; $venvCommand; python run.py --execution-provider cuda --source '$Face' --target '$imagePath' --output '$outputPath'"
        Start-Process -FilePath powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command `"$command`"" -Wait
    }
}

function FindMissingTopazFiles {
    param (
        [switch]$RestoreTopazFiles
    )
    Write-Host "Starting process..."
    $volumeInfo = Get-Volume -DriveLetter (Get-Location).Drive.Name
    if ($volumeInfo.FileSystem -eq "ReFS") {
        Write-Host "ReFS file system detected. Symbolic links are not supported. Exiting."
        return
    }
    # Create the missing directory if it doesn't exist
    $missingDir = "missing"

    if ($RestoreTopazFiles) {
        Write-Host "Restoring topaz files from 'missing' directory..."
        if (-not (Test-Path $missingDir)) {
            Write-Host "No 'missing' directory found. Exiting."
            return
        }
        Get-ChildItem -Path $missingDir -Recurse -File | Where-Object { $_.Extension -eq '.jpeg' } | ForEach-Object {
            $originalPath = $_.DirectoryName.Replace($missingDir, '').TrimEnd('\')
            $originalPath = $originalPath.Replace('\\', '\')
            $destinationPath = Join-Path $originalPath $_.Name
            $symlinkPath = Join-Path $_.DirectoryName $_.Name.Replace('topaz-', '').Replace('.jpeg', '.jpg')
            $relativePath = Resolve-Path -Path ([WildcardPattern]::Escape($_.FullName)) -Relative
            write-host "Restoring file: $relativePath"
            # write-host "Original path: $originalPath"
            # write-host "Destination path: $destinationPath" 
            Move-Item -Path ([WildcardPattern]::Escape($_.FullName)) -Destination ([WildcardPattern]::Escape($destinationPath)) -Force
            Remove-Item -Path ([WildcardPattern]::Escape($symlinkPath)) -Force
        }
        Write-Host "Restoration completed successfully!"
        # Delete empty folders after restoring files
        Get-ChildItem -Path $missingDir -Recurse | Where-Object { $_.PSIsContainer -and @(Get-ChildItem -Path ([WildcardPattern]::Escape($_.FullName))).Count -eq 0 } | Remove-Item -Force
        return

    }

    if (-not (Test-Path $missingDir)) {
        Write-Host "Creating 'missing' directory..."
        New-Item -ItemType Directory -Force -Path $missingDir | Out-Null
    }

    # Recursive function to process the current directory and subdirectories
    function ProcessDirectory {
        param (
            [string]$path,
            [string]$relativePath = ''
        )
        Write-Host "Processing directory: $path"
        $escapedPath = [WildcardPattern]::Escape($path)
        $currentMissingDir = Join-Path $missingDir $relativePath
        New-Item -ItemType Directory -Force -Path $currentMissingDir | Out-Null

        Get-ChildItem -Path $escapedPath -File | Where-Object { $_.Extension -match 'jpg|JPG' } | ForEach-Object {
            $jpgFile = $_
            $topazFilename = "topaz-$($jpgFile.BaseName).jpeg"
            $topazPath = Join-Path $escapedPath $topazFilename
            if (-not (Test-Path $topazPath)) {
                # Write-Host "Missing topaz file found: $topazFilename. Creating symlink..."
                # $linkPath = Join-Path $currentMissingDir $topazFilename
                $linkPath = Join-Path $currentMissingDir $jpgFile.Name
                try {
                    New-Item -ItemType SymbolicLink -Path ([WildcardPattern]::Escape($linkPath)) -Target ([WildcardPattern]::Escape($jpgFile.FullName)) | Out-Null
                } catch {
                    Write-Host "Failed to create symlink using New-Item. Falling back to mklink..."
                    # Write-Host "Command: mklink `"$linkPath`" `"$($jpgFile.FullName)`""
                    $command = "cmd /c mklink `"$linkPath`" `"$($jpgFile.FullName)`""
                    Invoke-Expression $command
                }
            }
        }

        Get-ChildItem -Path $escapedPath -Directory | Where-Object { $_.Name -ne $missingDir } | ForEach-Object {
            $newRelativePath = if ($relativePath) { Join-Path $relativePath $_.Name } else { $_.Name }
            ProcessDirectory -path $_.FullName -relativePath $newRelativePath
        }
    }

    # Start processing from the current directory
    ProcessDirectory -path (Get-Location)
    Write-Host "Process completed successfully!"

    # Delete empty folders after creating symlinks
    $escapedMissingDir = [WildcardPattern]::Escape($missingDir)
    Get-ChildItem -Path $escapedMissingDir -Recurse | Where-Object { $_.PSIsContainer -and @(Get-ChildItem -Path ([WildcardPattern]::Escape($_.FullName))).Count -eq 0 } | Remove-Item -Force

}

# To call the function
# FindMissingTopazFiles

function Convert-ImagesToVideo {
    [CmdletBinding()]
    param (
        [string]$OutputVideoName = "slideshow.mp4",
        [int]$FrameRate = 30
    )

    Write-Host "Creating video slideshow from images in the current directory..."

    # Rename images to follow a sequential pattern
    $images = Get-ChildItem  -Filter *.png | Sort-Object Name
    $count = 1
    $images | ForEach-Object {
        $newName = "image{0}$($_.Extension)"
        Rename-Item -Path $_.FullName -NewName ($newName -f $count)
        $count++
    }

    if ($count -eq 1) {
        Write-Host "No image files found in the current directory. Operation aborted."
        return
    }

    # Combine images into a video slideshow using FFmpeg
    & ffmpeg -i "image%d.png" -c:v libx264 -r $FrameRate -pix_fmt yuv420p $OutputVideoName

    Write-Host "Video slideshow created successfully: $OutputVideoName"
}




function Extract-FramesFromVideo {
    [CmdletBinding()]
    param (
        [string]$InputVideoFile,
        [string]$OutputSubDirectory = "extracted_frames",
        [int]$FrameRate = 30
    )

    Write-Host "Extracting frames from video: $InputVideoFile..."

    # Create the subdirectory if it doesn't exist
    if (!(Test-Path -Path $OutputSubDirectory -PathType Container)) {
        New-Item -Path $OutputSubDirectory -ItemType Directory
    }

    # Extract frames from the video using FFmpeg
    # The frames will be saved in the specified subdirectory
    & ffmpeg -i $InputVideoFile -vf "fps=$($FrameRate)" "$OutputSubDirectory/frame%03d.png"

    Write-Host "Frames extracted successfully to subdirectory: $OutputSubDirectory"
}

# Example usage:
# Convert-ImagesToVideo -OutputVideoName "myslideshow.mp4"
# Extract-FramesFromVideo -InputVideoFile "myslideshow.mp4" -OutputSubDirectory "frames"


# Usage example: convert symlinks in a specific folder
# $folderPath = "C:\Path\To\Folder"
# Convert-FolderSymlinksToRealFiles -FolderPath $folderPath

function Remove-EmptyDirectories {
    Get-ChildItem -Path . -Recurse -Directory | Where-Object { @(Get-ChildItem -Path ([WildcardPattern]::Escape($_.FullName)) -Force).Count -eq 0 } | Remove-Item -Force
    Write-Host "Empty directories removed successfully."
}
function CreateFlatSymlinks {
    # Create a directory called "flat" if it doesn't exist
    $flatFolder = "flat"
    if (!(Test-Path -Path $flatFolder)) {
        New-Item -ItemType Directory -Path $flatFolder
    }

    # Get a list of all files in the current directory, excluding the "flat" folder
    $files = Get-ChildItem -Recurse -File | Where-Object { $_.DirectoryName -notmatch $flatFolder }

    # Escape the "flat" folder path for wildcard matching
    $escapedFlatFolder = [WildcardPattern]::Escape((Resolve-Path $flatFolder))


    # Create a hashtable to track filenames and ensure uniqueness
    $fileNames = @{}

    foreach ($file in $files) {
        $fileName = $file.Name
        $originalName = $fileName

        # Check if filename is unique
        if ($fileNames.ContainsKey($fileName)) {
            # Prompt the user for an option
            $option = Read-Host "File name '$fileName' is not unique. Choose an option: 'cancel' or 'continue and rename'"
            if ($option -eq 'cancel') {
                Write-Host "Operation canceled."
                return
            } elseif ($option -eq 'continue and rename') {
                # Rename the file with the subfolder name
                $subFolder = ($file.DirectoryName -split '\\')[-1]
                $fileName = "$subFolder-$fileName"
            } else {
                Write-Host "Invalid option. Operation canceled."
                return
            }
        }

        # Create a symlink in the "flat" folder
        $symlinkPath = Join-Path -Path (Resolve-Path $flatFolder) -ChildPath $fileName
        $command = "cmd /c mklink `"$symlinkPath`" `"$($file.FullName)`""
        Invoke-Expression $command

        # Add the filename to the hashtable
        $fileNames[$originalName] = $true

        # Write-Host "Created symlink for '$fileName'"

    }
}

function CreateFlatDir {
    # Create a directory called "flat" if it doesn't exist
    $flatFolder = "flat"
    if (!(Test-Path -Path $flatFolder)) {
        New-Item -ItemType Directory -Path $flatFolder
    }

    # Get a list of all files in the current directory, excluding the "flat" folder
    $files = Get-ChildItem -Recurse -File | Where-Object { $_.DirectoryName -notmatch $flatFolder }

    # Create a hashtable to track filenames and ensure uniqueness
    $fileNames = @{}

    foreach ($file in $files) {
        $fileName = $file.Name
        $originalName = $fileName

        # # Check if filename is unique
        # if ($fileNames.ContainsKey($fileName)) {
        #     # Prompt the user for an option
        #     $option = Read-Host "File name '$fileName' is not unique. Choose an option: '(1) cancel' or '(2) continue and rename'"
        #     if ($option -eq '1') {
        #         Write-Host "Operation canceled."
        #         return
        #     } elseif ($option -eq '2') {
        #         # Rename the file with the subfolder name
        #         $subFolder = ($file.DirectoryName -split '\\')[-1]
        #         $fileName = "$subFolder-$fileName"
        #     } else {
        #         Write-Host "Invalid option. Operation canceled."
        #         return
        #     }
        # }

        $subFolder = ($file.DirectoryName -split '\\')[-1]
        $fileName = "$subFolder-$fileName"

        # Create a symlink in the "flat" folder
        $symlinkPath = Join-Path -Path (Resolve-Path $flatFolder) -ChildPath $fileName
        $command = "cmd /c copy `"$($file.FullName)`" `"$symlinkPath`""
        Invoke-Expression $command

        # Add the filename to the hashtable
        $fileNames[$originalName] = $true

        # Write-Host "Created symlink for '$fileName'"

    }
}

function Get-Symlinks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location),

        [Parameter(Mandatory = $false)]
        [switch]$Csv
    )

    $symlinks = @()

    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } | ForEach-Object {
        $symlink = $_
        $target = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($symlink.PSParentPath, ($symlink | Get-Item).Target))
        Write-Host "Symlink: $($symlink.FullName) -> Target: $target"

        if ($Csv) {
            # Adding to array for CSV export
            $symlinks += [PSCustomObject]@{
                'Symlink' = $symlink.Name
                'Target'  = $target
            }
        }
    }

    if ($Csv) {
        # Exporting to CSV
        $csvPath = "Symlinks.csv"
        $symlinks | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Exported to CSV at $csvPath"
    }
}

function Create-Symlinks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    # Import the CSV file
    $symlinks = Import-Csv -Path $CsvPath

    # Iterate through each row and create the symlinks
    foreach ($link in $symlinks) {
        $symlink = $link.Symlink
        $target = $link.Target

        # Check if the target exists
        if (Test-Path -LiteralPath $target) {
            # Create the symlink if it does not already exist
            if (-Not (Test-Path -Path $symlink)) {
                $command = "cmd /c mklink /j `"$symlink`" `"$target`""
                Invoke-Expression $command
                Write-Host "$command"
            } else {
                Write-Host "Symlink already exists: $symlink"
            }
        } else {
            Write-Host "Target does not exist: $target"
        }
    }
}

function Compare-Directories {
    param (
        [Parameter(Position = 0, Mandatory = $true)][string]$Directory1,
        [Parameter(Position = 1, Mandatory = $false)][string]$Directory2 = (Get-Location),
        [string]$TransformFilename1,
        [string]$TransformFilename2,
        [ValidateSet("1", "2")][string]$CopyTo
    )

    if ($TransformFilename1) {
        $split1 = $TransformFilename1.Split('|')
        if ($split1.Length -ne 2) {
            Write-Host "Invalid transformation for TransformFilename1. Use the format 'oldString|newString'."
            return
        }
    }

    if ($TransformFilename2) {
        $split2 = $TransformFilename2.Split('|')
        if ($split2.Length -ne 2) {
            Write-Host "Invalid transformation for TransformFilename2. Use the format 'oldString|newString'."
            return
        }
    }

    if (-Not (Test-Path -LiteralPath $Directory1)) {
        Write-Host "Directory1 does not exist."
        return
    }

    if (-Not (Test-Path -LiteralPath $Directory2)) {
        Write-Host "Directory2 does not exist."
        return
    }

    $Files1 = Get-ChildItem -LiteralPath $Directory1 | Where-Object { !$_.PSIsContainer } | ForEach-Object { if ($TransformFilename1) { $_.Name.Replace($split1[0], $split1[1]) } else { $_.Name } }
    $Files2 = Get-ChildItem -LiteralPath $Directory2 | Where-Object { !$_.PSIsContainer } | ForEach-Object { if ($TransformFilename2) { $_.Name.Replace($split2[0], $split2[1]) } else { $_.Name } }

    $MissingInDirectory1 = $Files2 | Where-Object { $Files1 -NotContains $_ }
    $MissingInDirectory2 = $Files1 | Where-Object { $Files2 -NotContains $_ }

    Write-Host "Files missing in Directory1 ($Directory1):"
    $MissingInDirectory1 | ForEach-Object { Write-Host $_ }

    Write-Host "Files missing in Directory2 ($Directory2):"
    $MissingInDirectory2 | ForEach-Object { Write-Host $_ }
   
    if ($CopyTo) {
        if ($CopyTo -eq "1") {
            
            $Directory1 = $Directory1.Replace('[', '``[').Replace(']', '``]')
            Write-Host "Copying missing files from Directory2 to Directory1..."
            $MissingInDirectory1 | ForEach-Object { Copy-Item -LiteralPath (Join-Path $Directory2 $_) -Destination $Directory1 }
        } elseif ($CopyTo -eq "2") {
            $Directory2 = $Directory2.Replace('[', '``[').Replace(']', '``]')
            Write-Host "Copying missing files from Directory1 to Directory2..."
            $MissingInDirectory2 | ForEach-Object { Copy-Item -LiteralPath (Join-Path $Directory1 $_) -Destination $Directory2 }
        }
    }
}




# $linkPath = Join-Path $currentMissingDir $jpgFile.Name
# try {
#     New-Item -ItemType SymbolicLink -Path $linkPath -Target ([WildcardPattern]::Escape($jpgFile.FullName)) | Out-Null
# } catch {
#     Write-Host "Failed to create symlink using New-Item. Falling back to mklink..."
#     # Write-Host "Command: mklink `"$linkPath`" `"$($jpgFile.FullName)`""
#     $command = "cmd /c mklink `"$linkPath`" `"$($jpgFile.FullName)`""
#     Invoke-Expression $command
# }

# a function to update the prompt
# function prompt {

#     $short = "[$($PSStyle.Foreground.BrightCyan)$(Get-ShortCommandName)$($PSStyle.Reset)] "


#     "PS$short $PWD>"
# }

# $PS1 = prompt

# trap DEBUG: Automatically executes the Set-LastCommanNameDynamicAlias and Set-LastCommandLineAlias functions when a command is executed in the console
trap { Set-LastCommandNameDynamicAlias }
# trap { Set-LastCommandLineAlias }
function Invoke-Starship-PreCommand {
    # $host.ui.Write("🚀")
}
#Invoke-Expression (&starship init powershell)