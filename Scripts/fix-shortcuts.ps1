function Edit-ShortcutPaths {
    param(
        [Parameter(Mandatory = $false, HelpMessage = "String to search for in target paths")]
        [string]$SearchString,

        [Parameter(Mandatory = $false, HelpMessage = "Replacement string (leave blank to just list unique paths)")]
        [string]$ReplaceString = "",

        [Parameter(Mandatory = $false, HelpMessage = "The directory to search for shortcuts (defaults to current directory)")]
        $Directory = $Directory ?? (Get-Location).Path

    )

    Write-Host "Searching in directory: $Directory"

    # Ensure directory exists
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        Write-Error "The specified directory '$Directory' does not exist."
        return
    }

    # Find all shortcuts (.lnk files)
    $shortcutFiles = Get-ChildItem -Path $Directory -Filter "*.lnk" -Recurse
    Write-Verbose "Found $($shortcutFiles.Count) shortcuts"

    # Escape special characters in the search string (e.g., +)
    $escapedSearchString = [regex]::Escape($SearchString)
    $searchRegex = "(?i)$escapedSearchString"

    # Extract target paths, remove the final destination, find unique matches
    $uniqueTargetPaths = $shortcutFiles | ForEach-Object {
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut($_.FullName)
        $targetPath = $shortcut.TargetPath
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null

        # Remove the final destination directory
        $targetPath = Split-Path $targetPath -Parent

        Write-Verbose "Processing shortcut: $($_.FullName) with target: $targetPath"

        $targetPath
    } | Where-Object { 
        $match = $_ -match $searchRegex  # Case-insensitive match using pre-escaped search string
        Write-Verbose "Checking path: $_ - Match: $match"
        $match
    } | Sort-Object | Get-Unique

    if ($uniqueTargetPaths.Count -eq 0) {
        Write-Output "No shortcuts with target paths matching '$SearchString' found in '$Directory'."
        return
    }

    # Handle multiple matching paths
    if ($uniqueTargetPaths.Count -gt 1) {
        Write-Output "Multiple matching paths found:"
        for ($i = 0; $i -lt $uniqueTargetPaths.Count; $i++) {
            Write-Output "$($i): $($uniqueTargetPaths[$i])" # Correct syntax for variable expansion
        }
        $choice = Read-Host "Enter the number of the path to modify (or 'a' for all):"

        if ($choice -eq "a") {
            # User wants to modify all paths
        }
        else {
            $index = [int]::TryParse($choice, [ref]$null)
            if ($index -and $index -ge 0 -and $index -lt $uniqueTargetPaths.Count) {
                $uniqueTargetPaths = $uniqueTargetPaths[$index] # Filter to the chosen path
            }
            else {
                Write-Output "Invalid choice. Aborting."
                return
            }
        }
    }
   
    Write-Output "Selected paths:"
    $uniqueTargetPaths | ForEach-Object { Write-Output $_ }

    # Prompt for confirmation if replacing a string
    if ($ReplaceString) {
        $confirmation = Read-Host "Do you want to replace '$SearchString' with '$ReplaceString' in these paths? (y/n)"
        if ($confirmation -ine "y") {
            Write-Output "Replacement cancelled."
            return
        }
    }

    # Update shortcuts (if replacement string provided)
    foreach ($shortcut in $shortcutFiles) {
        $WshShell = New-Object -ComObject WScript.Shell
        $lnk = $WshShell.CreateShortcut($shortcut.FullName)

        # Get the parent directory of the target path
        $parentTargetPath = Split-Path $lnk.TargetPath -Parent
       
        if ($parentTargetPath -match $searchRegex) {
            Write-Verbose "Updating shortcut: $($shortcut.FullName) - Old Path: $parentTargetPath"
            $newTargetPath = $parentTargetPath -replace $searchRegex, $ReplaceString
            
            # Recombine with the original file/folder name
            $newTargetPath = Join-Path $newTargetPath (Split-Path $lnk.TargetPath -Leaf)
            
            $lnk.TargetPath = $newTargetPath
            $lnk.Save()
            Write-Verbose "New Path: $newTargetPath"
        }
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null 
    }

    if ($ReplaceString) {
        Write-Output "Shortcut paths updated successfully."
    }
}
