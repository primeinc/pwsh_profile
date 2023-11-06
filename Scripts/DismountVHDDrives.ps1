$diskpartOutput = echo 'list vdisk' | diskpart

$diskpartOutput
# Initialize an empty array to store the results
$vdiskInfoArray = @()

# Split the output into lines and skip the first 2 header lines
$lines = $diskpartOutput -split "`n" | Select-Object -Skip 9

# Initialize an empty HashSet to store unique File values
$uniqueFiles = @{}

foreach ($line in $lines) {
    if ($line -match "VDisk") {
        $values = $line -split '\s{2,}' | Where-Object { $_.Trim() -ne '' }

        $vdiskObj = New-Object PSObject -Property @{
            "VDisk"  = $values[0]
            "Disk"   = $values[1]
            "State"  = $values[2]
            "Type"   = $values[3]
            "File"   = $values[4]
        }

        # Check if File is unique
        if (-not $uniqueFiles.ContainsKey($vdiskObj.File)) {
            $vdiskInfoArray += $vdiskObj
            $uniqueFiles[$vdiskObj.File] = $true

            # Dismount the VHD
            $vhdPath = $vdiskObj.File
            try {
                Dismount-VHD -Path $vhdPath -Confirm:$false
                Write-Host "Successfully dismounted VHD at $vhdPath"
            }
            catch {
                Write-Host "Failed to dismount VHD at $vhdPath. Error: $_"
            }
        }
    }
}

# Display the parsed information
$vdiskInfoArray | Format-Table -AutoSize
# Read-Host -Prompt "Press Enter to exit"
