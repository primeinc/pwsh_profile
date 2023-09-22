# pwsh_profile

This repository contains PowerShell 7 profile configurations and modules to enhance the PowerShell experience, specifically tailored for use with Windows Terminal.

## Overview

- **Main Profile Script**: `Microsoft.PowerShell_profile.ps1` - This is the primary PowerShell 7 profile script that initializes the environment and loads necessary configurations.

- **Modules**: Contains custom and third-party modules to extend the functionality of PowerShell.
  - **ExchangeOnlineManagement**: Version 3.2.0 module for managing Exchange Online.
  - **VirtualDesktop**: Version 1.5.1 module for managing virtual desktops in Windows.

- **Configs**: Configuration files for various tools and settings.
  - `config.json`: General configuration file.
  - `starship.toml`: Configuration for the Starship prompt.
  - `windowsTerminalSettings.json`: Settings for the Windows Terminal.

- **Profile**: Contains additional scripts and settings for the PowerShell profile.
  - `functions.ps1`: Contains custom functions to be loaded into the PowerShell session.
  - `psreadline_settings.ps1`: Settings for the PSReadline module.

## Prerequisites

- **PowerShell 7**: This profile is designed for PowerShell 7 and not Windows PowerShell.
- **Windows Terminal**: This profile has been tested with and is recommended for use with Windows Terminal.
- **Winget**: Ensure you have Winget installed to facilitate the installation of other required tools.
- **Starship**: This profile uses the Starship prompt. Install it using Winget:
  ```bash
  winget install --id Starship.Starship
  ```

## Installation

1. Rename your existing PowerShell directory:
   ```powershell
   Rename-Item ~/Documents/Powershell ~/Documents/Powershell.old
   ```
2. Clone this repository into the `Powershell` directory:
   ```
   git clone https://github.com/primeinc/pwsh_profile ~/Documents/Powershell
   ```

3. **Using the Install-Configs Function**:
   
   The `Install-Configs` function is a part of the [functions.ps1](https://github.com/primeinc/pwsh_profile/blob/main/functions.ps1) script, which is loaded for you automatically. This function creates symbolic links for configuration files based on the `config.json` file present in the `configs` directory.

   To use the function:

   - Open PowerShell 7.
   - Run the `Install-Configs` function to set up the configurations. You can use the `-Force` switch to override confirmations if needed, otherwise you will be asked to confirm the renaming of existing configuration files.
     ```powershell
     Install-Configs
     ```

## Contributing

Feel free to submit pull requests or raise issues if you find any bugs or have suggestions for improvements.


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.