$global:timerPoints = @()

function Initialize-Timer {
  $global:timerPoints = @(Get-Date)
  Write-Output "Timer initialized."
}

function Show-Timer {
  if ($global:timerPoints.Count -eq 0) {
    Write-Output "Timer not started, use Initialize-Timer to start it."
    return
  }
    
  $currentPoint = Get-Date
  $initialTime = $global:timerPoints[0]
  $lastPoint = $global:timerPoints[-1]

  $elapsedFromStart = $currentPoint - $initialTime
  $elapsedFromLast = $currentPoint - $lastPoint

  $global:timerPoints += $currentPoint

  Write-Output "Time since initialization: $($elapsedFromStart.TotalSeconds) seconds."
  Write-Output "Time since last check: $($elapsedFromLast.TotalSeconds) seconds."
}

function Stop-Timer {
  $global:timerPoints = @()
  Write-Output "Timer stopped and reset."
}

function env {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string] $specificEnv = ""
  )

  process {
    if ($specificEnv -ne "") {
      $specificEnv = $specificEnv.ToUpper()  # Convert the argument to uppercase
      $envValue = Get-ChildItem "Env:$specificEnv" -ErrorAction SilentlyContinue
      
      if ($envValue) {
        if ($specificEnv = "PATH") {
          Write-Output "Paths:"
          $paths = $envValue.Value -split ";" | ForEach-Object { $_.Trim() }
          $paths | ForEach-Object { Write-Output "`e]8;;$_`e`\`e[1;36m$(Show-ClickablePath($_))`e[0m`e]8;;`e`\" }
          return
        }
        Write-Output "$($envValue.Name) = $($envValue.Value)"
      }
      else {
        Write-Output "Environment variable '$specificEnv' not found."
      }
    }
    else {
      # Output all environment variables when no specificEnv is provided
      Get-ChildItem Env:
    }
  }
}

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

<#
.SYNOPSIS
Selects numbers from a list based on a specified prefix.

.DESCRIPTION
The Select-NumbersByPrefix function takes a list of numbers and a prefix as input and selects the numbers that start with the specified prefix. The selected numbers are sorted in ascending order and returned as a list.

.PARAMETER NumberList
Specifies an array of numbers that you want to select from.

.PARAMETER Prefix
Specifies the prefix used for selecting the numbers.

.NOTES
This function is useful when you need to filter and retrieve numbers based on a specific prefix.

.EXAMPLE
Select-NumbersByPrefix -NumberList @("12345", "56789", "98765", "45678") -Prefix "56"
This command selects and returns the numbers "56765" and "56789" because they start with the prefix "56."

.EXAMPLE
$myNumbers = @("12345", "56789", "98765", "45678")
$selected = Select-NumbersByPrefix -NumberList $myNumbers -Prefix "98"
This example selects numbers from a custom list stored in the variable $myNumbers and stores the selected result in the variable $selected.

#>
function Select-NumbersByPrefix {
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

<#
.SYNOPSIS
Activates virtual environments using the 'activate.ps1' script found within the current directory and its subdirectories.

.DESCRIPTION
The venv function searches for 'activate.ps1' scripts within the current directory and its subdirectories and activates the virtual environments they belong to. When activated, a virtual environment isolates Python dependencies and configurations, allowing you to work within a specific environment.

This function is useful for quickly activating virtual environments when you have multiple projects with different dependencies.

.NOTES
Make sure you have Python and virtualenv installed on your system to use this function.

.EXAMPLE
venv
This command searches for and activates virtual environments using 'activate.ps1' scripts within the current directory and its subdirectories.

#>
function venv {
  Get-ChildItem activate.ps1 -Recurse -Depth 2 | ForEach-Object { $_.FullName } | Invoke-Expression
}

<#
.SYNOPSIS
Updates all Git repositories in the current directory and its subdirectories.

.DESCRIPTION
The Update-AllGitRepos function recursively searches for Git repositories within the current directory and its subdirectories. It then performs the following actions for each Git repository found:
1. Stashes any local changes.
2. Pulls the latest changes from the remote repository.

This function is useful for quickly updating multiple Git repositories in one go.

.NOTES
Make sure that Git is installed and configured on your system to use this function.

.EXAMPLE
Update-AllGitRepos
This command updates all Git repositories found within the current directory and its subdirectories.

#>
function Update-AllGitRepos {
  Get-ChildItem -Directory | ForEach-Object {
    Set-Location $_.FullName
    Write-Output "Updating git repo in $($_.FullName)"
    git stash
    git pull
    Set-Location ..
  }
}

<#
.SYNOPSIS
Converts a symbolic link (symlink) to a real file.

.DESCRIPTION
The Convert-SymlinkToRealFile function takes a symbolic link (symlink) path as input and replaces it with the actual file it points to. This function is useful when you want to work with the real file rather than the symlink.

.PARAMETER Path
Specifies the path to the symbolic link that should be converted to a real file.

.NOTES
This function replaces a symbolic link with the actual file it points to. Ensure that the target file exists; otherwise, the conversion will fail.

.EXAMPLE
Convert-SymlinkToRealFile -Path "C:\MyFolder\MySymlink.lnk"
This command converts the symbolic link "C:\MyFolder\MySymlink.lnk" to a real file.

#>
function Convert-SymlinkToRealFile {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $linkType = (Get-Item $Path).Attributes

  if ($linkType -band [System.IO.FileAttributes]::ReparsePoint) {
    $target = Get-Item $Path | Select-Object -ExpandProperty Target
    Remove-Item $Path
    Copy-Item -Path $target -Destination $Path
  }
}

<#
.SYNOPSIS
Converts symbolic links within a folder and its subfolders to real files.

.DESCRIPTION
The Convert-FolderSymlinksToRealFiles function scans a specified folder and its subfolders for symbolic links (symlinks) and replaces them with the actual files they point to. This is useful when you want to eliminate symlinks and work with the real files.

.PARAMETER FolderPath
Specifies the path to the folder where symbolic links should be converted to real files.

.NOTES
Symbolic links (symlinks) are replaced with their target files. The target files should exist; otherwise, the symlink removal will fail.

.EXAMPLE
Convert-FolderSymlinksToRealFiles -FolderPath "C:\MyFolder"
This command converts symbolic links within the "C:\MyFolder" directory and its subfolders to real files.

#>
function Convert-FolderSymlinksToRealFiles {
  param (
    [Parameter(Mandatory = $true)]
    [string]$FolderPath
  )

  $symlinks = Get-ChildItem -Path $FolderPath -Recurse | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }

  foreach ($symlink in $symlinks) {
    Convert-SymlinkToRealFile -Path $symlink.FullName
  }
}

<#
.SYNOPSIS
Updates the Python package manager pip to the latest version.

.DESCRIPTION
The Update-Pip function checks if Python is installed and upgrades the pip package manager to the latest version using the Python -m command. It ensures that you have the latest version of pip for managing Python packages.

.PARAMETER None
This function does not accept any parameters.

.NOTES
File System Requirements:
- Python must be installed on the system for this function to work.
- This function uses Python's -m command to upgrade pip.

.EXAMPLE
Update-Pip
This command updates the pip package manager to the latest version.

.EXAMPLE
Update-Pip
This command checks if Python is installed and upgrades pip if it's available.

#>
function Update-Pip {
  # Check if Python is installed
  if (Test-Path (Join-Path $env:ProgramFiles 'Python' 'python.exe')) {
    try {
      # Upgrade pip using Python's -m command
      python -m pip install --upgrade pip

      # Check if the upgrade was successful
      if ($LASTEXITCODE -eq 0) {
        Write-Host "pip has been updated successfully."
      }
      else {
        Write-Host "Failed to update pip."
      }
    }
    catch {
      Write-Host "An error occurred while updating pip: $_"
    }
  }
  else {
    Write-Host "Python is not installed. Please install Python before updating pip."
  }
}

<#
.SYNOPSIS
This script finds and restores missing Topaz image files.

.DESCRIPTION
This script searches for missing Topaz image files (JPEG format) and restores them. If the '-RestoreTopazFiles' switch is used, it will restore the missing files from the 'missing' directory. If the directory structure and symbolic links are used, this script will create symbolic links to the original JPEG files.

.PARAMETER RestoreTopazFiles
Use this switch to restore missing Topaz files from the 'missing' directory.

.NOTES
File System Requirements:
- This script does not support ReFS file systems due to symbolic link limitations.

.EXAMPLE
FindMissingTopazFiles -RestoreTopazFiles
This command restores missing Topaz files from the 'missing' directory.

.EXAMPLE
FindMissingTopazFiles
This command searches for missing Topaz files and creates symbolic links in the 'missing' directory.

#>
function Find-MissingTopazFiles {
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
        }
        catch {
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

<#
.SYNOPSIS
Creates a video slideshow from image files in the current directory.

.DESCRIPTION
The Convert-ImagesToVideo function renames image files in the current directory sequentially and combines them into a video slideshow. You can specify the output video name and frame rate for the slideshow.

.PARAMETER OutputVideoName
Specifies the name of the output video file. The default is "slideshow.mp4."

.PARAMETER FrameRate
Specifies the frame rate at which the images should be played in the video. The default is 30 frames per second.

.EXAMPLE
Convert-ImagesToVideo -OutputVideoName "myslideshow.mp4"

This command renames and combines image files from the current directory into a video slideshow named "myslideshow.mp4" with a default frame rate of 30 frames per second.

.EXAMPLE
Convert-ImagesToVideo -FrameRate 24

This command renames and combines image files from the current directory into a video slideshow named "slideshow.mp4" with a frame rate of 24 frames per second.

.NOTES
File Name      : Convert-ImagesToVideo.ps1
Author         : [Your Name]
Prerequisite   : FFmpeg installed and added to system PATH
Copyright 2023 - [Your Company Name]

#>
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

<#
.SYNOPSIS
Converts a video file into a sequence of image frames.

.DESCRIPTION
The Convert-VideoToFrames function extracts individual image frames from a video file and saves them in a specified subdirectory. If the frame rate is not provided by the user, it will be calculated using ffprobe.

.PARAMETER InputVideoFile
Specifies the path to the input video file that you want to extract frames from.

.PARAMETER OutputSubDirectory
Specifies the name of the subdirectory where the extracted frames will be saved. The default is "extracted_frames."

.PARAMETER FrameRate
Specifies the frame rate at which frames should be extracted from the video. If not provided, it will be calculated using ffprobe.

.EXAMPLE
Convert-VideoToFrames -InputVideoFile "myvideo.mp4"

This command extracts frames from the "myvideo.mp4" video file and saves them in the "extracted_frames" subdirectory with the calculated frame rate.

.EXAMPLE
Convert-VideoToFrames -InputVideoFile "myvideo.mp4" -OutputSubDirectory "myframes"

This command extracts frames from the "myvideo.mp4" video file and saves them in the "myframes" subdirectory with the calculated frame rate.

.NOTES
Prerequisite   : FFmpeg and ffprobe installed and added to system PATH

#>
function Convert-VideoToFrames {
  [CmdletBinding()]
  param (
    [string]$InputVideoFile,
    [string]$OutputSubDirectory = "extracted_frames",
    [int]$FrameRate
  )

  Write-Host "Extracting frames from video: $InputVideoFile..."

  # Create the subdirectory if it doesn't exist
  if (!(Test-Path -Path $OutputSubDirectory -PathType Container)) {
    New-Item -Path $OutputSubDirectory -ItemType Directory
  }

  # Calculate frame rate using ffprobe if not provided
  if (-not $FrameRate) {
    $FrameRate = & ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 $InputVideoFile
    $FrameRate = [math]::Ceiling($FrameRate)
    Write-Host "Calculated frame rate: $FrameRate frames per second."
  }

  # Extract frames from the video using FFmpeg
  # The frames will be saved in the specified subdirectory
  & ffmpeg -i $InputVideoFile -vf "fps=$($FrameRate)" "$OutputSubDirectory/frame%03d.png"

  Write-Host "Frames extracted successfully to subdirectory: $OutputSubDirectory"
}

<#
.SYNOPSIS
Removes empty directories recursively from the specified path.

.DESCRIPTION
The Remove-EmptyDirectories function scans the specified path recursively and removes empty directories. It ensures that directories without any files or subdirectories are deleted.

.PARAMETER None

This function does not have any parameters.

.EXAMPLE
Remove-EmptyDirectories

This command searches for and removes empty directories starting from the current location.

#>
function Remove-EmptyDirs {
  [CmdletBinding(
    SupportsShouldProcess,
    ConfirmImpact = 'High'
  )]
  param(
    [Switch]$Force
  )

  if ($Force -and -not $Confirm) {
    $ConfirmPreference = 'None'
  }

  $emptyDirs = [System.Collections.Generic.List[String]]@()
  $rootPath = (Get-Location).Path

  function Test-IsEmpty($dir) {
    $items = [System.IO.Directory]::GetFileSystemEntries($dir, "*", [System.IO.SearchOption]::TopDirectoryOnly)
    return ($items.Length -eq 0)
  }

  Get-ChildItem -Path $rootPath -Recurse -Directory | ForEach-Object {
    if (Test-IsEmpty $_.FullName) {
      $emptyDirs.Add($_.FullName)
    }
  }

  foreach ($dir in $emptyDirs) {
    if ($PSCmdlet.ShouldProcess("$(Show-ClickablePath($dir))", $dir, "Remove directory")) {
      Remove-Item -Path $dir -Force
      Write-Host "Removed directory: $($dir)"
    }
  }
  Write-Output "Empty directories found: $($emptyDirs.Count)"

  Write-Host "Operation completed."
}

<#
.SYNOPSIS
Creates symbolic links to files in subdirectories within a "flat" directory while ensuring unique filenames.

.DESCRIPTION
The New-FlatFolder function creates symbolic links to files in subdirectories within a "flat" directory, ensuring that filenames remain unique. It appends the subdirectory name as a prefix to the filenames to maintain uniqueness.

.PARAMETER None

This function does not have any parameters.

.EXAMPLE
New-FlatFolder

This command searches for files in subdirectories of the current location, creates symbolic links to them in a "flat" directory, and appends the subdirectory name as a prefix to each filename to ensure uniqueness.

Currently it just copies the files instead of creating symlinks.

#>
function New-FlatFolder {
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

<#
.SYNOPSIS
Copies files from subdirectories into a flat directory while ensuring unique filenames.

.DESCRIPTION
The Copy-FilesToFlatDirectory function copies files from subdirectories into a flat directory, ensuring that filenames remain unique. It appends the subdirectory name as a prefix to the filenames to maintain uniqueness.

.PARAMETER None

This function does not have any parameters.

.EXAMPLE
Copy-FilesToFlatDirectory

This command searches for files in subdirectories of the current location, copies them into a "flat" directory, and appends the subdirectory name as a prefix to each filename to ensure uniqueness.

.NOTES
File Name      : Copy-FilesToFlatDirectory.ps1
Author         : [Your Name]
Prerequisite   : PowerShell 3.0
Copyright 2023 - [Your Company Name]

#>
function Copy-FilesToFlatDirectory {
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

<#
.SYNOPSIS
Retrieves information about symbolic links in the specified directory and optionally exports it to a CSV file.

.DESCRIPTION
The Get-Symlinks function retrieves information about symbolic links located within the specified directory and its subdirectories. It can display the symlink information on the console or export it to a CSV file for further analysis.

.PARAMETER Path
Specifies the path to the directory where symbolic links should be searched. By default, it searches in the current location.

.PARAMETER Csv
Indicates whether to export the symbolic link information to a CSV file. If this switch is present, the function will export the data to a file named "Symlinks.csv" in the current directory.

.EXAMPLE
Get-Symlinks -Path "C:\MyDirectory"

This command searches for symbolic links in the "C:\MyDirectory" directory and its subdirectories and displays the symlink information on the console.

.EXAMPLE
Get-Symlinks -Path "D:\AnotherDirectory" -Csv

This command searches for symbolic links in the "D:\AnotherDirectory" directory and its subdirectories, and exports the symlink information to a CSV file named "Symlinks.csv" in the current directory.

#>
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

<#
.SYNOPSIS
Creates symbolic links based on the information provided in a CSV file.

.DESCRIPTION
The New-SymlinkFromCSV function reads a CSV file containing information about symbolic links to create and their target locations. It then iterates through each row in the CSV file and creates symbolic links if the specified target exists and the symbolic link doesn't already exist.

.PARAMETER CsvPath
Specifies the path to the CSV file containing symlink information.

.EXAMPLE
New-SymlinkFromCSV -CsvPath "C:\Path\To\Links.csv"

This command reads the "Links.csv" file located at "C:\Path\To\" and creates symbolic links based on the information in the file.

#>
function New-SymlinksFromCsv {
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
      }
      else {
        Write-Host "Symlink already exists: $symlink"
      }
    }
    else {
      Write-Host "Target does not exist: $target"
    }
  }
}

<#
.SYNOPSIS
    Compares the files in two directories and optionally copies missing files from one directory to the other.

.DESCRIPTION
    This function compares the list of files in two directories, Directory1 and Directory2. 
    It identifies files that are missing in each directory and displays them.
    It also has the option to copy the missing files from one directory to the other.

.PARAMETER Directory1
    The first directory to compare. This parameter is mandatory.

.PARAMETER Directory2
    The second directory to compare. This parameter is optional, defaulting to the current location.

.PARAMETER TransformFilename1
    A string transformation applied to filenames in Directory1 before comparison. 
    The format should be 'oldString|newString'.

.PARAMETER TransformFilename2
    A string transformation applied to filenames in Directory2 before comparison.
    The format should be 'oldString|newString'.

.PARAMETER CopyTo
    Specifies which directory to copy missing files to. Accepts "1" to copy to Directory1 or "2" to copy to Directory2.

.EXAMPLE
    Compare-Directories -Directory1 "C:\Folder1" -Directory2 "C:\Folder2" -CopyTo "1"
    Compares Folder1 and Folder2 and copies any missing files from Folder2 to Folder1.

.NOTES
    Ensure both directories exist and you have the appropriate permissions before running this function.

#>
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
    }
    elseif ($CopyTo -eq "2") {
      $Directory2 = $Directory2.Replace('[', '``[').Replace(']', '``]')
      Write-Host "Copying missing files from Directory1 to Directory2..."
      $MissingInDirectory2 | ForEach-Object { Copy-Item -LiteralPath (Join-Path $Directory1 $_) -Destination $Directory2 }
    }
  }
}

<#
.SYNOPSIS
    Retrieves the full history of PowerShell commands.

.DESCRIPTION
    This function reads the full history of PowerShell commands from the PSReadLine history file. 
    It uses the PSReadLineOption to dynamically determine the location of the history file.

.EXAMPLE
    Get-History-Full
    This example shows how to call the function to retrieve your full PowerShell command history.

.NOTES
    Make sure PSReadLine is loaded for this function to work as expected.

#>
function Get-History-Full {
  $historyPath = (Get-PSReadlineOption).HistorySavePath
  if (Test-Path $historyPath) {
    Get-Content $historyPath
  }
  else {
    Write-Host "History file not found."
  }
}

# Note:
#  * Accepts input only via the pipeline, either line by line, 
#    or as a single, multi-line string.
#  * The input is assumed to have a header line whose column names
#    mark the start of each field
#    * Column names are assumed to be *single words* (must not contain spaces).
#  * The header line is assumed to be followed by a separator line
#    (its format doesn't matter).
function ConvertFrom-FixedColumnTable {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)] [string] $InputObject
  )
  
  begin {
    Set-StrictMode -Version 1
    $lineNdx = 0
  }
  
  process {
    $lines = 
    if ($InputObject.Contains("`n")) { $InputObject.TrimEnd("`r", "`n") -split '\r?\n' }
    else { $InputObject }
    foreach ($line in $lines) {
      ++$lineNdx
      if ($lineNdx -eq 1) { 
        # header line
        $headerLine = $line 
      }
      elseif ($lineNdx -eq 2) { 
        # separator line
        # Get the indices where the fields start.
        $fieldStartIndices = [regex]::Matches($headerLine, '\b\S').Index
        # Calculate the field lengths.
        $fieldLengths = foreach ($i in 1..($fieldStartIndices.Count - 1)) { 
          $fieldStartIndices[$i] - $fieldStartIndices[$i - 1] - 1
        }
        # Get the column names
        $colNames = foreach ($i in 0..($fieldStartIndices.Count - 1)) {
          if ($i -eq $fieldStartIndices.Count - 1) {
            $headerLine.Substring($fieldStartIndices[$i]).Trim()
          }
          else {
            $headerLine.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
          }
        } 
      }
      else {
        # data line
        $oht = [ordered] @{} # ordered helper hashtable for object constructions.
        $i = 0
        foreach ($colName in $colNames) {
          $oht[$colName] = 
          if ($fieldStartIndices[$i] -lt $line.Length) {
            if ($fieldLengths[$i] -and $fieldStartIndices[$i] + $fieldLengths[$i] -le $line.Length) {
              $line.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
            }
            else {
              $line.Substring($fieldStartIndices[$i]).Trim()
            }
          }
          ++$i
        }
        # Convert the helper hashable to an object and output it.
        [pscustomobject] $oht
      }
    }
  }
  
}

function Format-WinGet {
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() 
  # Helper function: Convert fixed column widths to objects.
  (winget list --upgrade-available) -match '^(\p{L}|-)' | ConvertFrom-FixedColumnTable
}


function Get-WinGetUpdates {
  Format-WinGet | Where-Object {
    $_.Source -eq 'winget' -and $_.Available -ne ''
  }
}

# function Get-WinGetUpdatesCount {
#   $count = Format-WinGet | Where-Object {
#       $_.Source -eq 'winget' -and $_.Available -ne ''
#   }
#   Write-Host $count.Count
# }

function Update-WinGetUpdatesCount {
  $updateCount = (Format-WinGet | Where-Object { $_.Source -eq 'winget' -and $_.Available -ne '' }).Count
  Set-Content -Path "$home\.cache\winget-updates-count.txt" -Value $updateCount
}

function Get-WinGetUpdatesCount {
  param(
    [Parameter()]
    [switch]$Force
  )

  $cacheFile = "$home\.cache\winget-updates-count.txt"
  $currentTime = Get-Date

  # If -Force is not provided, check the cache file's age
  if (-not $Force) {
    # Check if the file exists and is less than 1 hour old
    if (Test-Path $cacheFile) {
      $fileTime = (Get-Item $cacheFile).LastWriteTime
      $timeDifference = $currentTime - $fileTime

      if ($timeDifference.TotalHours -lt 1) {
        # If the file is less than 1 hour old, read and return the count
        return (Get-Content $cacheFile)
      }
    }
  }

  # If the file is older than 1 hour, doesn't exist, or -Force is provided, create a background job to update the file
  Start-Process -NoNewWindow -FilePath "pwsh.exe" -ArgumentList "-command & {Update-WinGetUpdatesCount}"

  # Return the hourglass symbol indicating the job is in progress
  return ""
}

function Update-WinGetPackages {
  param(
    [Parameter()]
    [switch]$Interactive,

    [Parameter()]
    [switch]$Silent
  )

  # Check for admin privileges
  $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  if (-not $isElevated) {
    Write-Host "This function requires administrator privileges. Please run as an administrator." -ForegroundColor Red
    return
  }

  # Get the list of pinned packages
  $pinnedPackages = winget pin list | Where-Object { $_ -match '^\S+' } | ForEach-Object {
      ($_ -split '\s+')[1]
  }

  $wingetSwitches = @()
  $wingetSwitches += '--verbose'
  if ($Interactive) { $wingetSwitches += '--interactive' }
  if ($Silent) { 
    $wingetSwitches += '--disable-interactivity' 
    $wingetSwitches += '--silent' 
  }

  $packagesToUpdate = Get-WinGetUpdates | Where-Object { $_.Id -notin $pinnedPackages }
  $packagesToUpdate | Format-Table | Write-Output

  foreach ($package in $packagesToUpdate) {
    Write-Host "Updating $($package.Name) from version $($package.Version) to $($package.Available)"
    winget upgrade $package.Id $wingetSwitches
  }

  Write-Host "Packages remaining:"
  Get-WinGetUpdates | Format-Table
}

<#
.SYNOPSIS
Generates a clickable display string for a given path, optionally displaying only the leaf.

.DESCRIPTION
The Show-ClickablePath function takes a path and generates a terminal hyperlink to that path. 
The displayed text can be either the full path or just the leaf (e.g., the file or folder name), 
highlighted in bright cyan. 

.PARAMETER Path
The full path that you want to generate a clickable display string for.

.PARAMETER UseLeaf
A switch to determine if only the leaf of the path (e.g., the file or folder name) should be displayed. 
By default, it's set to $false, meaning the full path will be shown.

.EXAMPLE
Show-ClickablePath -Path "C:\Users\Admin"
This will generate a string that's a terminal hyperlink to "C:\Users\Admin" with the same path displayed in bright cyan.

.EXAMPLE
Show-ClickablePath -Path "C:\Users\Admin" -UseLeaf $true
This will generate a string that's a terminal hyperlink to "C:\Users\Admin", but only "Admin" will be displayed in bright cyan.
#>

function Show-ClickablePath {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [bool]$UseLeaf = $false
  )

  $displayPath = if ($UseLeaf) { Split-Path $Path -Leaf } else { $Path }


  return "`e]8;;$Path`e`\`e[1;36m$displayPath`e[0m`e]8;;`e`\"

}
