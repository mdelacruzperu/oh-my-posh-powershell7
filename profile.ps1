### PowerShell Profile Script by MDL ###
### Organized Configuration for PowerShell Environment ###
### Developed collaboratively with OpenAI Assistant ###

### Casos de Prueba para el Script Oh My Posh

$DebugMode = $false

if ($DebugMode) {
    Write-Host "#######################################" -ForegroundColor Red
    Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
    Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
    Write-Host "#######################################" -ForegroundColor Red
}

# Global Files Paths
$Global:BinaryPath = "$HOME\.oh-my-posh\oh-my-posh.exe"
$Global:ConfigFile = [System.Environment]::GetFolderPath("MyDocuments") + "\PowerShell\EnvironmentConfig.json"
$Global:CacheFile = [System.Environment]::GetFolderPath("MyDocuments") + "\PowerShell\RemoteThemesCache.json"
# Global Lists
$Global:DefaultThemes = @("peru", "agnoster")
$Global:ModulesToInstall = @(
    @{ Name = "Terminal-Icons"; Description = "Adds file icons to terminal output" }
)

#############################################
### SECTION 1: Oh My Posh User Management ###
#############################################

# Function: CheckRequirements
# Description: Validates that the script is running in the required environment.
function CheckRequirements {
    param (
        [switch]$Force, # If specified, forces the display of validation messages.
        [switch]$Silent
    )

    # Step 1: Check PowerShell version
    if ($Force -or $PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "❌ This script requires PowerShell 7 or higher to function correctly." -ForegroundColor Red
        Show-InstallationInstructions
        if (-not $Force) {
            exit
        }
    }

    # Step 2: Validate other critical components (future requirements can go here)
    if (-not $Silent) { Write-Host "✔️  Environment requirements validated successfully." -ForegroundColor Green }
}

# Function: Install-OhMyPoshEnvironment
# Description: Installs and configures the Oh My Posh environment for PowerShell.
function Install-OhMyPoshEnvironment {
    Write-Host "Starting installation of Oh My Posh environment..." -ForegroundColor Cyan

    # Step 1: Load configuration (or create default)
    $Config = Load-Config
    $Config.IsConfigured = $true
    $Config.ThemeDisabled = $false
    $Config.ThemeName = "peru" 

    # Step 2: Install Oh-My-Posh binay
    Install-OhMyPoshBinary

    # Step 3: Install required modules
    Install-Modules

    # Step 4: Download and setup Nerd Fonts
    Install-NerdFonts

    # Step 5: Download default themes
    Setup-Themes

    # Step 6: Apply the default theme
    Set-Theme -ThemeName $Config.ThemeName

    # Step 7: Save configuration
    $Config.IsConfigured = $true
    Save-Config -Config $Config

    Write-Host "Oh My Posh environment installation complete!" -ForegroundColor Green
    Write-Host "To use the custom fonts, navigate to the font folder and install them manually:" -ForegroundColor Cyan
    Write-Host "  C:\Users\<YourUser>\Documents\PowerShell\NerdFonts" -ForegroundColor Yellow
    Write-Host "Apply the installed theme with: 'Set-Theme -ThemeName peru' if not active." -ForegroundColor Cyan
}

# Function: Set-Theme
# Description: Applies a specified Oh My Posh theme using the binary and saves it to the configuration.
function Set-Theme {
    param (
        [string]$ThemeName,
        [switch]$Silent
    )

    Import-RequiredModules -Silent

    $ThemeDirectory = [System.Environment]::GetFolderPath("MyDocuments") + "\PowerShell\Themes"
    $ThemePath = "$ThemeDirectory\$ThemeName.omp.json"

    if (-not (Test-Path $Global:BinaryPath)) {
        Write-Host "Oh My Posh binary not found. Run 'Install-OhMyPoshEnvironment' to install it." -ForegroundColor Red
        return
    }

    # Ensure Themes directory exists
    if (-not (Test-Path $ThemeDirectory)) {
        Write-Host "Themes directory not found. Creating it now..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Path $ThemeDirectory -Force | Out-Null
            Write-Host "Themes directory created successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to create Themes directory. Error: $_" -ForegroundColor Red
            return
        }
    }

    # Check if the theme file exists
    if (-not (Test-Path $ThemePath)) {
        Write-Host "Theme '$ThemeName' not found locally. Attempting to download it..." -ForegroundColor Yellow
        try {
            $ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$ThemeName.omp.json"
            Invoke-WebRequest -Uri $ThemeUrl -OutFile $ThemePath -ErrorAction Stop
            Write-Host "Theme '$ThemeName' downloaded successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download theme '$ThemeName'. Ensure the theme name is correct and check your internet connection." -ForegroundColor Red
            Write-Host "`nHelpful Resources:" -ForegroundColor Cyan
            Write-Host "  - Visit the Oh My Posh Theme Gallery to explore available themes:" -ForegroundColor Green
            Write-Host "    https://ohmyposh.dev/docs/themes" -ForegroundColor Yellow
            Write-Host "  - List local themes with: 'List-Themes'" -ForegroundColor Green
            Write-Host "  - List remote themes with: 'List-Themes -Remote'" -ForegroundColor Green
            return
        }
    }

    # Apply the theme
    try {
        & $Global:BinaryPath init pwsh --config $ThemePath | Invoke-Expression
        if (-not $Silent) {
            Write-Host "Theme '$ThemeName' applied successfully." -ForegroundColor Green
        }
    } catch {
        if (-not $Silent) {
            Write-Host "Failed to apply theme '$ThemeName'. Error: $_" -ForegroundColor Red
            return
        }
    }

    # Save the theme to the configuration
    try {
        $Config = Load-Config
        $Config.ThemeName = $ThemeName
        Save-Config -Config $Config
        if (-not $Silent) {
            Write-Host "Theme '$ThemeName' saved to configuration." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed to save theme '$ThemeName' to configuration. Error: $_" -ForegroundColor Red
    }
}

# Function: Reset-Theme
# Description: Resets the theme to the default PowerShell prompt and marks the theme as disabled in the configuration.
function Reset-Theme {
    Write-Host "Resetting to default PowerShell prompt..." -ForegroundColor Yellow
    Debug-Log "Entering Reset-Theme function."

    try {
        # Step 1: Remove the current prompt customization
        Debug-Log "Checking if custom prompt exists."
        if (Get-Command prompt -ErrorAction SilentlyContinue) {
            Remove-Item Function:prompt -ErrorAction SilentlyContinue
            Write-Host "Custom prompt removed. Default PowerShell prompt restored." -ForegroundColor Green
            Debug-Log "Custom prompt successfully removed."
        } else {
            Write-Host "No custom prompt was active." -ForegroundColor Cyan
            Debug-Log "No custom prompt to remove."
        }

        # Step 2: Update configuration to disable themes
        Debug-Log "Loading configuration for update."
        $Config = Load-Config
        $Config.ThemeDisabled = $true
        Debug-Log "Disabling theme in configuration."
        Save-Config -Config $Config
        Write-Host "Configuration updated: Theme is now disabled." -ForegroundColor Green
        Debug-Log "Configuration saved successfully."
    } catch {
        # Catch any errors and notify the user
        Write-Host "An error occurred while resetting the theme: $_" -ForegroundColor Red
        Debug-Log "Error in Reset-Theme: $_"
    } finally {
        # Notify user and close session
        Write-Host "`nThe terminal will now close to avoid inconsistencies. Please reopen to start fresh." -ForegroundColor Red
        Write-Host "Press any key to continue and close the terminal..." -ForegroundColor Yellow
        [void][System.Console]::ReadKey($true)  # Wait for any key press
        exit
    }
}

# Function: Reactivate-Theme
# Description: Reapplies the last configured theme and enables themes in the configuration.
function Reactivate-Theme {
    Write-Host "Reactivating the last configured theme..." -ForegroundColor Cyan

    # Load configuration and ensure it's valid
    $Config = Load-Config
    if (-not $Config.ThemeName) {
        Write-Host "No theme was previously configured. Use 'Set-Theme' to apply a new theme." -ForegroundColor Yellow
        return
    }

    # Enable the theme in the configuration
    $Config.ThemeDisabled = $false
    Save-Config -Config $Config
    Write-Host "Theme configuration updated to enabled state." -ForegroundColor Green

    # Apply the last configured theme
    Set-Theme -ThemeName $Config.ThemeName
}

# Function: List-Themes
# Description: Lists all available Oh My Posh themes (local or remote with caching).
function List-Themes {
    param (
        [switch]$Remote # Show remote themes if specified
    )

    # Local themes directory
    $ThemeDirectory = [System.Environment]::GetFolderPath("MyDocuments") + "\PowerShell\Themes"
    if (-not (Test-Path $ThemeDirectory)) {
        New-Item -ItemType Directory -Path $ThemeDirectory | Out-Null
    }

    if ($Remote) {
        # Fetch remote themes using the cache function
        $RemoteThemes = Get-RemoteThemesCache
        if ($RemoteThemes.Count -gt 0) {
            Write-Host "Available remote themes:" -ForegroundColor Green
            # Display the list of remote themes
            ($RemoteThemes | Sort-Object -Unique -CaseSensitive) -join "  " | Write-Host -ForegroundColor Magenta
        } else {
            Write-Host "No remote themes found or unable to fetch the list." -ForegroundColor Red
        }
    } else {
        # List local themes
        if (Test-Path $ThemeDirectory) {
            $LocalThemes = Get-ChildItem -Path $ThemeDirectory -Filter *.omp.json | ForEach-Object { $_.BaseName }
            if ($LocalThemes.Count -gt 0) {
                Write-Host "Available local themes:" -ForegroundColor Green
                # Display the list of local themes
                ($LocalThemes | Sort-Object -Unique -CaseSensitive) -join "  " | Write-Host -ForegroundColor Magenta
            } else {
                Write-Host "No local themes found." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Themes directory not found. No local themes available." -ForegroundColor Yellow
        }
    }
}

# Function: SelfUpdate
# Description: Updates the script to the latest version from GitHub.
function SelfUpdate {
    param (
        [string]$ScriptUrl = "https://raw.githubusercontent.com/mdelacruzperu/oh-my-posh-powershell7/main/install-profile.ps1"
    )

    Write-Host "Checking for updates..." -ForegroundColor Cyan

    # Get the path to the current script
    $CurrentScriptPath = (Get-Command -Name $MyInvocation.MyCommand.Name).Source

    # Temporary path for the downloaded script
    $TempScriptPath = "$HOME\Downloads\install-profile.ps1"

    try {
        # Download the latest version from GitHub
        Invoke-WebRequest -Uri $ScriptUrl -OutFile $TempScriptPath -ErrorAction Stop
        Write-Host "✔️ Latest version downloaded to $TempScriptPath" -ForegroundColor Green

        # Replace the current script with the downloaded version
        Write-Host "Updating the current script..." -ForegroundColor Cyan
        Copy-Item -Path $TempScriptPath -Destination $CurrentScriptPath -Force
        Write-Host "✔️ Script updated successfully. Please restart the script to apply changes." -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to update the script. Error: $_" -ForegroundColor Red
    } finally {
        # Cleanup: Remove the temporary file
        if (Test-Path $TempScriptPath) {
            Remove-Item -Path $TempScriptPath -Force
        }
    }
}

# Function: Cleanup-OhMyPoshEnvironment
# Description: Removes the Oh My Posh environment, uninstalls required modules, and resets configurations.
function Cleanup-OhMyPoshEnvironment {
    Write-Host "Cleaning up the Oh My Posh environment..." -ForegroundColor Yellow

    # Step 1: Uninstall each module
    foreach ($Module in $Global:ModulesToInstall) {
        $ModuleName = $Module.Name
        $ModuleDescription = $Module.Description

        Write-Host "Checking module: $ModuleName - $ModuleDescription" -ForegroundColor Cyan
        try {
            if (Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue) {
                Write-Host "Uninstalling module: $ModuleName..." -ForegroundColor Yellow
                Uninstall-Module -Name $ModuleName -AllVersions -Force -ErrorAction Stop
                Write-Host "Module $ModuleName uninstalled successfully." -ForegroundColor Green
            } else {
                Write-Host "Module $ModuleName is not installed." -ForegroundColor Cyan
            }
        } catch {
            Write-Host "Failed to uninstall module $ModuleName. Error: $_" -ForegroundColor Red
        }
    }

    # Step 2: Remove fonts and themes
    $FontDirectory = "$HOME\Documents\PowerShell\NerdFonts"
    $ThemeDirectory = [System.Environment]::GetFolderPath("MyDocuments") + "\PowerShell\Themes"

    if (Test-Path $FontDirectory) {
        Write-Host "Removing downloaded fonts..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $FontDirectory -Recurse -Force -ErrorAction Stop
            Write-Host "Fonts removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove fonts. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No fonts found to remove." -ForegroundColor Cyan
    }

    if (Test-Path $ThemeDirectory) {
        Write-Host "Removing downloaded themes..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $ThemeDirectory -Recurse -Force -ErrorAction Stop
            Write-Host "Themes removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove themes. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No themes found to remove." -ForegroundColor Cyan
    }

    # Step 3: Reset configuration
    if (Test-Path $Global:ConfigFile) {
        Write-Host "Removing configuration file..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $Global:ConfigFile -Force -ErrorAction Stop
            Write-Host "Configuration file removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove configuration file. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No configuration file found to remove." -ForegroundColor Cyan
    }

    # Step 4: Remove cache file
    if (Test-Path $Global:CacheFile) {
        Write-Host "Removing theme cache file..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $Global:CacheFile -Force -ErrorAction Stop
            Write-Host "Theme cache file removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove theme cache file. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No theme cache file found to remove." -ForegroundColor Cyan
    }

    # Final cleanup message
    Write-Host "`nCleanup Summary:" -ForegroundColor Cyan
    Write-Host "  - Fonts removed: $((Test-Path $FontDirectory) -eq $false)" -ForegroundColor Green
    Write-Host "  - Themes removed: $((Test-Path $ThemeDirectory) -eq $false)" -ForegroundColor Green
    Write-Host "  - Configuration file removed: $((Test-Path $Global:ConfigFile) -eq $false)" -ForegroundColor Green
    Write-Host "⚠️  Note: Oh My Posh binary was not removed. Use 'Remove-OhMyPoshBinary' if needed." -ForegroundColor Yellow

    # Notify user and wait for confirmation
    Write-Host "`nThe terminal will now close to avoid inconsistencies. Please reopen to start fresh." -ForegroundColor Red
    Write-Host "Press any key to continue and close the terminal..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)  # Wait for any key press
    exit
}

# Function: Remove-OhMyPoshBinary
# Description: Removes the Oh My Posh binary and its containing folder if empty from the user's environment.
function Remove-OhMyPoshBinary {
    $BinaryFolder = Split-Path -Path $Global:BinaryPath -Parent  # Get the folder path

    if (Test-Path $Global:BinaryPath) {
        Write-Host "Removing Oh My Posh binary..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $Global:BinaryPath -Force -ErrorAction Stop
            Write-Host "Oh My Posh binary removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove the Oh My Posh binary. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Oh My Posh binary not found. Nothing to remove." -ForegroundColor Yellow
    }

    # Check if the folder exists and is empty
    if (Test-Path $BinaryFolder) {
        if ((Get-ChildItem -Path $BinaryFolder | Measure-Object).Count -eq 0) {
            Write-Host "Binary folder is empty. Removing folder: $BinaryFolder..." -ForegroundColor Cyan
            try {
                Remove-Item -Path $BinaryFolder -Force -ErrorAction Stop
                Write-Host "Binary folder removed successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to remove the binary folder. Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Binary folder is not empty. Skipping folder removal." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Binary folder does not exist. Nothing to remove." -ForegroundColor Yellow
    }

    Write-Host "Binary cleanup action completed." -ForegroundColor Green

    # Notify user and wait for confirmation
    Write-Host "`nThe terminal will now close to avoid inconsistencies. Please reopen to start fresh." -ForegroundColor Red
    Write-Host "Press any key to continue and close the terminal..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)  # Wait for any key press
    exit
}

# Function: Update-OhMyPoshBinary
# Description: Checks for the latest Oh My Posh binary and updates it if a new version is available.
function Update-OhMyPoshBinary {
    $DownloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"

    try {
        if (-not (Test-Path $Global:BinaryPath)) {
            Write-Host "Oh My Posh binary not found. Use 'Install-OhMyPoshEnvironment' to set up the environment." -ForegroundColor Red
            return
        }

        if ($DebugMode) {
            Write-Host "[DEBUG] Current binary path: $Global:BinaryPath" -ForegroundColor DarkGray
            Write-Host "[DEBUG] Fetching latest version from: $DownloadUrl" -ForegroundColor DarkGray
        }

        # Step 1: Check the existing file size (to compare post-download)
        $ExistingFileSize = (Get-Item $Global:BinaryPath).Length
        if ($DebugMode) {
            Write-Host "[DEBUG] Existing binary size: $ExistingFileSize bytes" -ForegroundColor DarkGray
        }

        # Step 2: Download the new binary to a temporary location
        $TempBinaryPath = "$HOME\.oh-my-posh\oh-my-posh-temp.exe"
        Write-Host "Downloading latest Oh My Posh binary..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempBinaryPath -ErrorAction Stop

        # Step 3: Compare file sizes
        $NewFileSize = (Get-Item $TempBinaryPath).Length
        if ($DebugMode) {
            Write-Host "[DEBUG] New binary size: $NewFileSize bytes" -ForegroundColor DarkGray
        }

        if ($ExistingFileSize -eq $NewFileSize) {
            Write-Host "The Oh My Posh binary is already up to date. No action taken." -ForegroundColor Green
        } else {
            # Step 4: Replace the existing binary
            Write-Host "Updating Oh My Posh binary to the latest version..." -ForegroundColor Yellow
            Move-Item -Path $TempBinaryPath -Destination $Global:BinaryPath -Force
            Write-Host "Oh My Posh binary updated successfully. Consider restarting the terminal to apply changes." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to update the Oh My Posh binary. Error: $_" -ForegroundColor Red
        if ($DebugMode) {
            Write-Host "[DEBUG] Error details: $_" -ForegroundColor DarkGray
        }
    } finally {
        # Clean up temporary file if it exists
        if (Test-Path $TempBinaryPath) {
            Remove-Item -Path $TempBinaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function: Show-Help
# Description: Displays a list of user-invocable commands for Oh My Posh management.
function Show-Help {
    Write-Host "`n### Available Commands for PowerShell Environment ###`n" -ForegroundColor Cyan

    Write-Host "Oh My Posh Management:" -ForegroundColor Yellow
    Write-Host "  Install-OhMyPoshEnvironment   - Installs or updates Oh My Posh and related components."
    Write-Host "  Cleanup-OhMyPoshEnvironment   - Removes Oh My Posh and resets the environment."
    Write-Host "  Set-Theme                    - Sets a specified Oh My Posh theme. Downloads if missing."
    Write-Host "  Reset-Theme                  - Resets to the default PowerShell prompt."
    Write-Host "  Reactivate-Theme             - Reactivates the last configured Oh My Posh theme."
    Write-Host "  List-Themes                  - Lists local or remote Oh My Posh themes."
    Write-Host "  Remove-OhMyPoshBinary        - Removes the Oh My Posh binary."

    Write-Host "`n### End of Help ###`n" -ForegroundColor Cyan
}

####################################
### SECTION 2: Support Functions ###
####################################

# Function: Test-OhMyPoshBinary
# Description: Verifies if the Oh My Posh binary exists and is functional by executing it.
function Test-OhMyPoshBinary {
    param (
        [switch]$Silent # Suppress messages if specified
    )

    try {
        & $Global:BinaryPath --version | Out-Null # Test binary functionality
        if (-not $Silent) {
            Write-Host "Oh My Posh binary is functional." -ForegroundColor Green
        }
        return $true
    } catch {
        if (-not $Silent) {
            Write-Host "⚠️  Oh My Posh binary not found or not functional!" -ForegroundColor Red
            Write-Host "Run 'Install-OhMyPoshEnvironment' to set up the environment again." -ForegroundColor Yellow
        }
        return $false
    }
}

# Function: Debug-Log
# Description: Logs messages to the console if DebugMode is enabled.
function Debug-Log {
    param (
        [string]$Message
    )
    if ($DebugMode) {
        Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
    }
}

# Function: Load-Config
# Description: Loads the configuration from a JSON file or returns a default configuration with a flag indicating file existence.
function Load-Config {

    # If the configuration file exists, load it
    if (Test-Path $Global:ConfigFile) {
        try {
            $Config = Get-Content -Path $Global:ConfigFile | ConvertFrom-Json
            $Config | Add-Member -MemberType NoteProperty -Name FileExists -Value $true -Force
            return $Config
        } catch {
            Write-Host "Failed to load configuration. Using default configuration." -ForegroundColor Red
        }
    } else {
        # If the file doesn't exist or fails to load, return a default configuration
        $DefaultConfig = [PSCustomObject]@{
            ThemeName     = "peru"
            IsConfigured  = $false
            ThemeDisabled = $true
            FileExists    = $false
        }
    }

    return $DefaultConfig
}

# Function: Save-Config
# Description: Saves configuration to JSON file, ensuring a readable format.
function Save-Config {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [switch]$Silent # If specified, suppresses success messages
    )

    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:ConfigFile -Encoding UTF8
        if (-not $Silent) {
            Write-Host "Configuration saved successfully." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to save configuration. Error: $_" -ForegroundColor Red
    }
}

# Function: Install-Modules
# Description: Installs all required modules listed in $Global:ModulesToInstall.
function Install-Modules {
    param (
        [switch]$Silent
    )

    foreach ($Module in $Global:ModulesToInstall) {
        if (-not (Get-InstalledModule -Name $Module.Name -ErrorAction SilentlyContinue)) {
            if (-not $Silent) {
                Write-Host "Installing module: $($Module.Name) - $($Module.Description)" -ForegroundColor Yellow
            }
            try {
                Install-Module -Name $Module.Name -Scope CurrentUser -Force -ErrorAction Stop
                if (-not $Silent) {
                    Write-Host "Module $($Module.Name) installed successfully." -ForegroundColor Green
                }
            } catch {
                Write-Host "Failed to install module $($Module.Name). Please check your internet connection or permissions." -ForegroundColor Red
            }
        } elseif (-not $Silent) {
            Write-Host "Module $($Module.Name) is already installed." -ForegroundColor Green
        }
    }
}

# Function: Install-OhMyPoshBinary
# Description: Downloads and installs the Oh My Posh binary in the user's environment.
function Install-OhMyPoshBinary {
    $DownloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"

    if (-not (Test-Path $Global:BinaryPath)) {
        Write-Host "Downloading Oh My Posh binary..." -ForegroundColor Cyan
        try {
            $BinaryDirectory = Split-Path -Path $Global:BinaryPath
            if (-not (Test-Path $BinaryDirectory)) {
                New-Item -ItemType Directory -Path $BinaryDirectory | Out-Null
            }
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $Global:BinaryPath -ErrorAction Stop
            Write-Host "Oh My Posh binary downloaded successfully to $Global:BinaryPath." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download Oh My Posh binary. Check your internet connection." -ForegroundColor Red
            return
        }
    } else {
        Write-Host "Oh My Posh binary is already installed." -ForegroundColor Green
    }
}

# Function: Install-NerdFonts
# Description: Downloads and installs Nerd Fonts for PowerShell.
function Install-NerdFonts {
    $FontDirectory = "$HOME\Documents\PowerShell\NerdFonts"
    if (-not (Test-Path $FontDirectory)) {
        New-Item -ItemType Directory -Path $FontDirectory | Out-Null
    }

    $Fonts = @(
        @{ Name = "CascadiaCode"; Uri = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" },
        @{ Name = "CascadiaMono"; Uri = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip" }
    )

    foreach ($Font in $Fonts) {
        $FontPath = "$FontDirectory\$($Font.Name)"
        if (-not (Test-Path $FontPath)) {
            Write-Host "Downloading Nerd Font: $($Font.Name)..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri $Font.Uri -OutFile "$FontDirectory\$($Font.Name).zip" -ErrorAction Stop
                Expand-Archive -Path "$FontDirectory\$($Font.Name).zip" -DestinationPath $FontPath
                Remove-Item "$FontDirectory\$($Font.Name).zip"
                Write-Host "$($Font.Name) installed successfully at $FontPath." -ForegroundColor Green
            } catch {
                Write-Host "Failed to install $($Font.Name). Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Font $($Font.Name) is already installed." -ForegroundColor Green
        }
    }
}

# Function: Import-RequiredModules
# Description: Ensures all required modules are imported into the session.
function Import-RequiredModules {
    param (
        [switch]$Silent
    )

    foreach ($Module in $Global:ModulesToInstall) {
        if (-not (Get-Module -Name $Module.Name)) {
            try {
                Import-Module -Name $Module.Name -ErrorAction Stop
                if (-not $Silent) {
                    Write-Host "Module '$($Module.Name)' imported successfully." -ForegroundColor Green
                }
            } catch {
                if (-not $Silent) {
                    Write-Host "Failed to import module '$($Module.Name)'. Ensure it is installed correctly." -ForegroundColor Red
                }
            }
        } elseif (-not $Silent) {
            Write-Host "Module '$($Module.Name)' is already imported." -ForegroundColor Green
        }
    }
}

# Function: Setup-Themes
# Description: Ensures themes are available by downloading missing ones.
function Setup-Themes {
    $ThemeDirectory = [System.Environment]::GetFolderPath("MyDocuments") + "\PowerShell\Themes"
    if (-not (Test-Path $ThemeDirectory)) {
        New-Item -ItemType Directory -Path $ThemeDirectory | Out-Null
    }

    foreach ($Theme in $Global:DefaultThemes) {
        $ThemePath = "$ThemeDirectory\$Theme.omp.json"
        if (-not (Test-Path $ThemePath)) {
            Write-Host "Downloading theme: $Theme..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$Theme.omp.json" -OutFile $ThemePath
                Write-Host "Theme $Theme downloaded successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to download theme $Theme. Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Theme $Theme is already present." -ForegroundColor Green
        }
    }
}

# Function: Show-InstallationInstructions
# Description: Provides instructions to install or update PowerShell 7 or later.
function Show-InstallationInstructions {
    Write-Host "" # Blank line for spacing
    Write-Host "⚠️  Please follow these steps to install or update PowerShell:" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  🔧 Step 1: Visit the official PowerShell GitHub page:" -ForegroundColor Cyan
    Write-Host "      👉 https://github.com/PowerShell/PowerShell" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  🔧 Step 2: Download the appropriate installer for your operating system:" -ForegroundColor Cyan
    Write-Host "      - Windows: MSI Installer" -ForegroundColor Yellow
    Write-Host "      - macOS: PKG or Homebrew" -ForegroundColor Yellow
    Write-Host "      - Linux: DEB, RPM, or Snap package" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  🔧 Step 3: Follow the installation instructions provided on the page." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  🔧 Step 4: Open a new terminal and rerun the script." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "💡 Need help? Consult the documentation on the GitHub page or ask for support." -ForegroundColor Cyan
}

# Function: Get-RemoteThemesCache
# Description: Retrieves the cached list of remote themes or updates the cache if outdated.
function Get-RemoteThemesCache {
    param (
        [switch]$Silent
    )

    $CacheExpiry = (Get-Date).AddHours(-24)

    # Step 1: Check if the cache file exists and is valid
    if (Test-Path $Global:CacheFile) {
        $CacheInfo = Get-Item $CacheFile
        if ($CacheInfo.LastWriteTime -gt $CacheExpiry) {
            try {
                return Get-Content -Path $Global:CacheFile | ConvertFrom-Json
            } catch {
                if (-not $Silent) {
                    Write-Host "Failed to load theme cache. Refreshing..." -ForegroundColor Red
                }
            }
        }
    }

    # Step 2: Fetch the latest themes from the remote repository
    if (-not $Silent) {
        Write-Host "Fetching the latest list of themes from Oh My Posh repository..." -ForegroundColor Cyan
    }
    try {
        $Themes = Invoke-RestMethod -Uri "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes" |
                  ForEach-Object { $_.name -replace '\.omp\.json$', '' }
        $Themes | ConvertTo-Json -Depth 1 | Set-Content -Path $Global:CacheFile -Encoding UTF8
        return $Themes
    } catch {
        if (-not $Silent) {
            Write-Host "Failed to retrieve remote themes. Please check your internet connection." -ForegroundColor Red
        }
        return @()
    }
}

#################################
### SECTION 3: User Utilities ###
#################################

# Function: touch
# Description: Creates an empty file (similar to the Unix `touch` command).
# Parameters:
#   $file - The name or path of the file to be created.
function touch($file) {
    "" | Out-File $file -Encoding ASCII
}

# Function: ll
# Description: Lists directory contents with icons (excludes hidden files by default).
function ll {
    param (
        [string]$Path = ".",
        [switch]$ShowHidden
    )

    try {
        Get-ChildItem -Path $Path -Force:$ShowHidden | Sort-Object -Property Name | ForEach-Object {
            if ($_.Attributes -match "Hidden") {
                Write-Host $_.Name -ForegroundColor DarkGray
            } else {
                $_
            }
        }
    } catch {
        Write-Error "Unable to list items in $Path. Ensure the path exists."
    }
}

# Function: la
# Description: Lists all directory contents (including hidden files) with icons.
function la {
    param (
        [string]$Path = "."
    )

    try {
        Get-ChildItem -Path $Path -Force | Sort-Object -Property Name | ForEach-Object {
            $_
        }
    } catch {
        Write-Error "Unable to list items in $Path. Ensure the path exists."
    }
}

# Function: Get-PubIP
# Description: Retrieves the public IP address of the system using OpenDNS servers.
function Get-PubIP {
    try {
        (Resolve-DnsName myip.opendns.com -Server resolver1.opendns.com).IPAddress
    } catch {
        Write-Error "Unable to retrieve public IP. Please check your internet connection."
    }
}

# Function: flushdns
# Description: Clears the DNS cache on the system.
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Function: uptime
# Description: Displays the system's uptime and the last boot time.
function uptime {
    try {
        # Get the last boot time directly
        $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

        # Calculate uptime
        $uptime = (Get-Date) - $bootTime

        # Display results
        Write-Host "System started on: $bootTime" -ForegroundColor DarkGray
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes) -ForegroundColor Blue
    } catch {
        Write-Error "Unable to retrieve system uptime. Ensure you are running PowerShell with sufficient permissions."
    }
}

# Function: sysinfo
# Description: Displays basic system information, such as OS version, architecture, and memory.
function sysinfo {
    try {
        if (-not (Get-Module -Name CimCmdlets)) {
            Import-Module -Name CimCmdlets -ErrorAction Stop
        }

        $info = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Host "Computer Name: $(hostname)" -ForegroundColor Cyan
        Write-Host "Operating System: $($info.Caption)" -ForegroundColor Cyan
        Write-Host "Version: $($info.Version)" -ForegroundColor Cyan
        Write-Host "Architecture: $($info.OSArchitecture)" -ForegroundColor Cyan
        Write-Host "System Boot Time: $($info.LastBootUpTime)" -ForegroundColor Cyan
        Write-Host "Total Physical Memory: $([math]::Round($info.TotalVisibleMemorySize / 1MB, 2)) GB" -ForegroundColor Cyan
    } catch {
        Write-Error "Unable to retrieve system information. Ensure the CimCmdlets module is available."
    }
}

# ------------------------------------
# Define your aliases from here
# Uset Get-Alias to check for existents aliases
# ------------------------------------

Set-Alias -Name ip -Value Get-PubIP
Set-Alias -Name sos -Value Show-Help


############################
### SECTION 4: Startup
############################

# Ensure the script is running on PowerShell 7 or later
#CheckRequirements -Force
CheckRequirements -Silent

# Load configuration file
$Config = Load-Config

# Caso 1: No hay configuración, guía al usuario a instalar
if (-not $Config.FileExists) {
    Write-Host "Welcome to the default PowerShell profile." -ForegroundColor Cyan
    Write-Host "Oh My Posh has not been configured." -ForegroundColor Yellow
    Write-Host "Run 'Install-OhMyPoshEnvironment' to set up the environment." -ForegroundColor Green
    return # Termina aquí porque no hay nada más que hacer sin configuración
}

# Validar existencia del binario solo si hay configuración
try {
    & "$HOME\.oh-my-posh\oh-my-posh.exe" --version | Out-Null
} catch {
    Write-Host "❌ This script requires PowerShell 7 or higher to function correctly." -ForegroundColor Red
    Write-Host "`n⚠️  Oh My Posh binary is missing or not functional!" -ForegroundColor Red
    Write-Host "Run 'Install-OhMyPoshEnvironment' to reinstall the environment." -ForegroundColor Yellow
    return # Termina aquí porque el binario es crítico
}

# Caso 2: Configuración existente pero tema deshabilitado
if ($Config.ThemeDisabled -eq $true) {
    Write-Host "Theme is currently disabled. Use 'Reactivate-Theme' to enable it again." -ForegroundColor Yellow
    return
}

# Caso 3: Configuración válida, intenta cargar el tema
if (-not $Config.ThemeName) {
    Write-Host "No theme configured. Using default PowerShell prompt." -ForegroundColor Yellow
} else {
    try {
        Set-Theme -ThemeName $Config.ThemeName -Silent
        Write-Host "Oh My Posh environment loaded successfully." -ForegroundColor Green
    } catch {
        Write-Host "`n⚠️  Failed to load the configured theme '$($Config.ThemeName)'." -ForegroundColor Red
        Write-Host "Ensure the theme exists or run 'Install-OhMyPoshEnvironment' to reconfigure." -ForegroundColor Yellow
    }
}
