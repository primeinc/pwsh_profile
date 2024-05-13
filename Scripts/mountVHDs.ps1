# Define the paths to the VHD files
$vhdPaths = @(
    "V:\Collective.vhdx",
    "\\data01.corp.prime.ms\dolar$\liberi.vhdx",
    "\\data01.corp.prime.ms\Dolar$\oSpill.vhdx",
    "\\data01.corp.prime.ms\dolar$\provokeProvocation.vhdx"
)

foreach ($vhdPath in $vhdPaths) {
    # Mount the VHD silently without assigning a drive letter
    Mount-VHD -Path $vhdPath -Passthru | Out-Null
}
