### PowerShell Profile Script by MDL ###
### Organized Configuration for PowerShell Environment ###
### Developed collaboratively with OpenAI Assistant ###

$DebugMode = $false

### Debugging Functions:
### - Debug-Log "Any message you need to log for debugging purposes."
### - Measure-Time -OperationName "Identifier" -Action { ... code to measure execution time ... }

if ($DebugMode) {
    Write-Host "#######################################" -ForegroundColor Red
    Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
    Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
    Write-Host "#######################################" -ForegroundColor Red
}

# Determine base directory for configuration files based on $PROFILE
$Global:BaseDirectory = Split-Path -Path $PROFILE -Parent
# Define global paths relative to the base directory
$Global:BinaryPath       = "$HOME\.oh-my-posh\oh-my-posh.exe" # Fixed binary location
$Global:ConfigFile       = Join-Path -Path $Global:BaseDirectory -ChildPath "EnvironmentConfig.json"
$Global:CacheFile        = Join-Path -Path $Global:BaseDirectory -ChildPath "RemoteThemesCache.json"
$Global:ThemeDirectory   = Join-Path -Path $Global:BaseDirectory -ChildPath "Themes"
# Global Lists
$Global:DefaultThemes = @("peru", "agnoster")
# Define global modules list
$Global:ModulesToInstall = @(
    @{ Name = "Terminal-Icons"; Description = "Adds file icons to terminal output" }
)

#############################################
### SECTION 1: Oh My Posh User Management ###
#############################################

# Function: Install-Environment
# Description: Installs and configures the Oh My Posh environment for PowerShell.
function Install-Environment {
    Write-Host "Starting installation of Oh My Posh environment..." -ForegroundColor Cyan

    # Step 1: Load configuration (or create default)
    $Global:Config.IsConfigured = $true
    $Global:Config.ThemeDisabled = $false
    $Global:Config.ThemeName = "peru" 

    # Step 2: Install Oh-My-Posh binay
    Install-OhMyPoshBinary

    # Step 3: Install required modules
    Install-Modules

    # Step 4: Download and setup Nerd Fonts
    Install-NerdFonts

    # Step 5: Download default themes
    Install-Themes

    # Step 6: Apply the default theme
    Set-Theme -ThemeName $Global:Config.ThemeName

    # Step 7: Save configuration
    $Global:Config.IsConfigured = $true
    Save-Config -Config $Config

    Write-Host "Oh My Posh environment installation complete!" -ForegroundColor Green

    Write-Host "Apply the installed theme with: 'Set-Theme -ThemeName peru' if not active." -ForegroundColor Cyan    
    Write-Host "To use the custom fonts, please install them manually by navigating to the font folder:" -ForegroundColor Cyan
    Write-Host "  C:\Users\<YourUser>\Documents\PowerShell\NerdFonts" -ForegroundColor Yellow
    Write-Host "After installing the fonts, open your terminal settings and set the font to 'CascadyaCove Nerd Font' or another Nerd Font." -ForegroundColor Cyan
    Write-Host "This will enable icons and additional visual enhancements in the terminal." -ForegroundColor Green

    Write-Host "`nTip: Run 'Show-Help' to explore available commands and start familiarizing yourself with the features." -ForegroundColor Magenta
}


# Function: Cleanup-Environment
# Description: Removes the Oh My Posh environment, uninstalls required modules, and resets configurations.
function Cleanup-Environment {
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

    if (Test-Path $Global:ThemeDirectory) {
        Write-Host "Removing downloaded themes..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $Global:ThemeDirectory -Recurse -Force -ErrorAction Stop
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
    Write-Host "  - Themes removed: $((Test-Path $Global:ThemeDirectory) -eq $false)" -ForegroundColor Green
    Write-Host "  - Configuration file removed: $((Test-Path $Global:ConfigFile) -eq $false)" -ForegroundColor Green
    Write-Host "⚠️  Note: Oh My Posh binary was not removed. Use 'Remove-Posh-Binary' if needed." -ForegroundColor Yellow

    # Notify user and wait for confirmation
    Write-Host "`nThe terminal will now close to avoid inconsistencies. Please reopen to start fresh." -ForegroundColor Red
    Write-Host "Press any key to continue and close the terminal..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)  # Wait for any key press
    exit
}

# Function: Set-Theme
# Description: Applies a specified Oh My Posh theme using the binary and saves it to the configuration.
function Set-Theme {
    param (
        [string]$ThemeName,
        [switch]$Silent
    )

    # Ensure the themes directory exists using try-catch
    try {
        New-Item -ItemType Directory -Path $Global:ThemeDirectory -Force | Out-Null
        Debug-Log "Themes directory ensured: $Global:ThemeDirectory"
    } catch {
        Debug-Log "Themes directory already exists or could not be created: $Global:ThemeDirectory"
    }

    # Skip applying if the theme is already active
    if ($Global:CurrentTheme -eq $ThemeName) {
        Debug-Log "Theme '$ThemeName' is already active. Skipping binary execution."
        return
    }

    # Ensure the theme file exists using try-catch
    $ThemePath = "$Global:ThemeDirectory\$ThemeName.omp.json"
    try {
        if (-not (Test-Path $ThemePath)) {
            $ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$ThemeName.omp.json"
            Invoke-WebRequest -Uri $ThemeUrl -OutFile $ThemePath -ErrorAction Stop
            Debug-Log "Theme downloaded: $ThemePath"
        }
    } catch {
        Debug-Log "Theme '$ThemeName' already exists or download failed: $ThemePath"
    }
    if (-not $Global:CachedThemes) { $Global:CachedThemes = @() }
    $Global:CachedThemes += $ThemeName

    Debug-Log "Theme directory: $Global:ThemeDirectory"
    Debug-Log "Theme path: $ThemePath"

    # Apply the theme using Oh My Posh binary
    & $Global:BinaryPath init pwsh --config $ThemePath | Invoke-Expression
    $Global:CurrentTheme = $ThemeName
    Debug-Log "Theme applied successfully: $ThemeName"

    # Save the theme to configuration
    $Global:Config.ThemeName = $ThemeName
    Save-Config -Silent -Config $Config
    Debug-Log "Theme configuration saved: $ThemeName"
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
        $Global:Config.ThemeDisabled = $true
        Debug-Log "Disabling theme in configuration."
        Save-Config -Silent -Config $Config
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
    if (-not $Global:Config.ThemeName) {
        Write-Host "No theme was previously configured. Use 'Set-Theme' to apply a new theme." -ForegroundColor Yellow
        return
    }

    # Enable the theme in the configuration
    $Global:Config.ThemeDisabled = $false
    Save-Config -Silent -Config $Config
    Write-Host "Theme configuration updated to enabled state." -ForegroundColor Green

    # Apply the last configured theme
    Set-Theme -ThemeName $Global:Config.ThemeName
}

# Function: List-Themes
# Description: Lists all available Oh My Posh themes (local or remote with caching).
function List-Themes {
    param (
        [switch]$Remote # Show remote themes if specified
    )

    # Local themes directory
    if (-not (Test-Path $Global:ThemeDirectory)) {
        New-Item -ItemType Directory -Path $Global:ThemeDirectory | Out-Null
    }

    if ($Remote) {
        # Fetch remote themes using the cache function
        $RemoteThemes = Get-Remote-Themes-Cache
        if ($RemoteThemes.Count -gt 0) {
            Write-Host "Available remote themes:" -ForegroundColor Green
            # Display the list of remote themes
            ($RemoteThemes | Sort-Object -Unique -CaseSensitive) -join "  " | Write-Host -ForegroundColor Magenta
        } else {
            Write-Host "No remote themes found or unable to fetch the list." -ForegroundColor Red
        }
    } else {
        # List local themes
        if (Test-Path $Global:ThemeDirectory) {
            $LocalThemes = Get-ChildItem -Path $Global:ThemeDirectory -Filter *.omp.json | ForEach-Object { $_.BaseName }
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

# Function: Self-Update
# Description: Updates the PowerShell profile to the latest version from GitHub if there are changes.
function Self-Update {
    param (
        [string]$ProfileUrl = "https://raw.githubusercontent.com/mdelacruzperu/oh-my-posh-powershell7/main/profile.ps1"
    )

    Write-Host "Checking for updates..." -ForegroundColor Cyan

    # Path to the current profile
    $CurrentProfilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $TempProfilePath = "$HOME\Downloads\profile-temp.ps1"

    # Step 1: Download the latest profile from GitHub
    try {
        Invoke-WebRequest -Uri $ProfileUrl -OutFile $TempProfilePath -ErrorAction Stop
        Write-Host "✔️ Latest profile downloaded to $TempProfilePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download the latest profile. Please check your internet connection." -ForegroundColor Red
        return
    }

    # Step 2: Check if the current profile exists
    if (-not (Test-Path $CurrentProfilePath)) {
        Write-Host "⚠️ No existing profile detected. Installing the latest profile..." -ForegroundColor Yellow
        Copy-Item -Path $TempProfilePath -Destination $CurrentProfilePath -Force
        Write-Host "✔️ Profile installed successfully at $CurrentProfilePath" -ForegroundColor Green
        Remove-Item -Path $TempProfilePath -Force
        return
    }

    # Step 3: Compare file hashes
    $CurrentHash = Get-FileHash -Path $CurrentProfilePath -Algorithm SHA256
    $TempHash = Get-FileHash -Path $TempProfilePath -Algorithm SHA256

    if ($CurrentHash.Hash -eq $TempHash.Hash) {
        Write-Host "✔️ Profile is already up to date. No update needed." -ForegroundColor Green
        Remove-Item -Path $TempProfilePath -Force
        return
    }

    # Step 4: Update the profile
    Write-Host "Updating the profile..." -ForegroundColor Cyan
    try {
        Copy-Item -Path $TempProfilePath -Destination $CurrentProfilePath -Force
        Write-Host "✔️ Profile updated successfully at $CurrentProfilePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to update the profile. Error: $_" -ForegroundColor Red
    } finally {
        Remove-Item -Path $TempProfilePath -Force
    }
}

# Function: Check-Requirements
# Description: Validates that the script is running in the required environment.
function Check-Requirements {
    param (
        [switch]$Force, # If specified, forces the display of validation messages.
        [switch]$Silent
    )

    # Step 1: Check PowerShell version
    if ($Force -or $PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "❌ This script requires PowerShell 7 or higher to function correctly." -ForegroundColor Red
        Show-Installation-Instructions
        if (-not $Force) {
            exit
        }
    }

    # Step 2: Validate other critical components (future requirements can go here)
    if (-not $Silent) { Write-Host "✔️  Environment requirements validated successfully." -ForegroundColor Green }
}

# Function: Remove-Posh-Binary
# Description: Removes the Oh My Posh binary and its containing folder if empty from the user's environment.
function Remove-Posh-Binary {
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

# Function: Update-Posh-Binary
# Description: Checks for the latest Oh My Posh binary and updates it if a new version is available.
function Update-Posh-Binary {
    $DownloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"

    try {
        if (-not (Test-Path $Global:BinaryPath)) {
            Write-Host "Oh My Posh binary not found. Use 'Install-Environment' to set up the environment." -ForegroundColor Red
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
# Description: Displays a detailed list of user-invocable commands for Oh My Posh management.
function Show-Help {
    Write-Host "`n=== Help: PowerShell Environment Commands ===`n" -ForegroundColor Cyan

    Write-Host "Environment Setup and Installation:" -ForegroundColor Yellow
    Write-Host "  Install-Environment           - Installs or updates Oh My Posh, required modules, fonts, and themes."
    Write-Host "  Update-Posh-Binary            - Checks for the latest Oh My Posh binary and updates it if available."
    Write-Host "  Cleanup-Environment           - Removes Oh My Posh and resets the configuration."

    Write-Host "`nTheme Management:" -ForegroundColor Yellow
    Write-Host "  Set-Theme -ThemeName <name>   - Applies a specified Oh My Posh theme. Downloads the theme if missing."
    Write-Host "  Reset-Theme                   - Resets to the default PowerShell prompt (disables Oh My Posh)."
    Write-Host "  Reactivate-Theme              - Reactivates the last configured Oh My Posh theme."
    Write-Host "  List-Themes [-Remote]         - Lists available themes. Use '-Remote' to fetch remote themes from GitHub."
    
    Write-Host "`nConfiguration Management:" -ForegroundColor Yellow
    Write-Host "  Self-Update                   - Updates the PowerShell profile to the latest version from GitHub."
    Write-Host "  Remove-Posh-Binary            - Removes the Oh My Posh binary from the system."
    Write-Host "  Check-Requirements            - Validates that the environment meets all prerequisites for installation."

    Write-Host "`nUtilities:" -ForegroundColor Yellow
    Write-Host "  Show-Help                     - Displays this help message.  (Alias: SOS)"
    Write-Host "  Touch                         - Creates an empty file (similar to the Unix `touch` command)."
    Write-Host "  ll                            - Lists directory contents with icons (excludes hidden files by default)."
    Write-Host "  Get-Public-IP                 - Retrieves the public IP address of your system. (Alias: IP)"
    Write-Host "  Uptime                        - Displays the system's Uptime and last boot time."
    Write-Host "  Get-System-Info               - Displays basic system information, such as OS version and memory. (Alias: sysinfo)"

    Write-Host "`n=== Quick Start Guide ===`n" -ForegroundColor Cyan
    Write-Host "1. Install PowerShell 7 or higher from https://github.com/PowerShell/PowerShell." -ForegroundColor Green
    Write-Host "2. Run 'Install-Environment' to set up Oh My Posh, fonts, and themes." -ForegroundColor Green
    Write-Host "3. Apply a theme with 'Set-Theme -ThemeName <theme>'. Example: 'Set-Theme -ThemeName peru'." -ForegroundColor Green
    Write-Host "4. List available themes with 'List-Themes' or 'List-Themes -Remote'." -ForegroundColor Green
    Write-Host "5. Update the profile anytime using 'Self-Update'." -ForegroundColor Green

    Write-Host "`n=== End of Help ===`n" -ForegroundColor Cyan
}

############################################
### SECTION 2: Private Support Functions ###
############################################


# Function: Debug-Log
# Description: Logs messages to the console if DebugMode is enabled.
function Debug-Log {
    param (
        [string]$Message
    )
    if ($DebugMode) {
        $LineNumber = $MyInvocation.ScriptLineNumber
        Write-Host "[DEBUG] (Line $LineNumber) $Message" -ForegroundColor DarkGray
    }
}

# Function: Test-Binary
# Description: Validates that the Oh My Posh binary is functional.
function Test-Binary {
    if (-not $Global:BinaryValidated) {
        try {
            # Try executing the binary to check its functionality
            & $Global:BinaryPath --version | Out-Null
            $Global:BinaryValidated = $true
            Debug-Log "Binary validated successfully: $Global:BinaryPath"
        } catch {
            Write-Host "❌ Oh My Posh binary is missing or not functional!" -ForegroundColor Red
            Write-Host "Run 'Install-Environment' to reinstall the environment." -ForegroundColor Yellow
            throw
        }
    }
}

# Validate and create necessary directories and files during initialization
function Initialize-Environment {
    param (
        [switch]$Silent # If specified, suppresses success messages
    )

    # Ensure the base directory exists
    if (-not (Test-Path -Path $Global:BaseDirectory)) {
        New-Item -ItemType Directory -Path $Global:BaseDirectory -Force | Out-Null
    }

    # Ensure theme directory exists
    if (-not (Test-Path -Path $Global:ThemeDirectory)) {
        New-Item -ItemType Directory -Path $Global:ThemeDirectory -Force | Out-Null
    }

    # Ensure configuration file exists
    if (-not (Test-Path -Path $Global:ConfigFile)) {
        $DefaultConfig = [PSCustomObject]@{
            ThemeName     = "peru"
            IsConfigured  = $false
            ThemeDisabled = $true
            FileExists    = $false
        }
        $DefaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:ConfigFile -Encoding UTF8
    }

    if (-not $Silent) {
        Write-Host "Environment initialized successfully." -ForegroundColor Green
    }
}

# Function: Get-Config
# Description: Loads the configuration from a JSON file.
function Get-Config {
    Debug-Log "Attempting to load configuration from: $Global:ConfigFile"

    if (Test-Path $Global:ConfigFile) {
        try {
            $Config = Get-Content -Path $Global:ConfigFile | ConvertFrom-Json
            $Config.FileExists = $true
            Debug-Log "Configuration loaded successfully: $Config"
            return $Config
        } catch {
            Write-Host "Failed to load configuration. Error: $_" -ForegroundColor Red
        }
    } else {
        Debug-Log "Configuration file not found at: $Global:ConfigFile"
    }

    # Return default configuration if the file is missing or fails to load
    $DefaultConfig = [PSCustomObject]@{
        ThemeName       = "peru"
        IsConfigured    = $false
        ThemeDisabled   = $true
        FileExists      = $false
        LastUpdateCheck = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK") # ISO 8601 format
    }
    Debug-Log "Using default configuration: $DefaultConfig"
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

# Function: Import-Required-Modules
# Description: Ensures all required modules are imported into the session.
function Import-Required-Modules {
    param (
        [switch]$Silent
    )

    if ($Global:ModulesImported) {
        return
    }
    
    foreach ($Module in $Global:ModulesToInstall) {
        try {
            # Attempt to import the module directly
            Import-Module -Name $Module.Name -ErrorAction Stop
            if (-not $Silent -or $DebugMode) {
                Write-Host "Module '$($Module.Name)' imported successfully." -ForegroundColor Green
            }
        } catch {
            # Handle the error gracefully and inform the user
            if (-not $Silent -or $DebugMode) {
                Write-Host "Failed to import module '$($Module.Name)'. Ensure it is installed or accessible." -ForegroundColor Red
            }
        }
    }
    
    $Global:ModulesImported = $true
}

# Function: Install-Themes
# Description: Ensures themes are available by downloading missing ones.
function Install-Themes {
    if (-not (Test-Path $Global:ThemeDirectory)) {
        New-Item -ItemType Directory -Path $Global:ThemeDirectory | Out-Null
    }

    foreach ($Theme in $Global:DefaultThemes) {
        $ThemePath = "$Global:ThemeDirectory\$Theme.omp.json"
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

# Function: Show-Installation-Instructions
# Description: Provides instructions to install or update PowerShell 7 or later.
function Show-Installation-Instructions {
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

# Function: Get-Remote-Themes-Cache
# Description: Retrieves the cached list of remote themes or updates the cache if outdated.
function Get-Remote-Themes-Cache {
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

# Function: Test-For-Update
# Description: Checks for updates based on a configurable interval and prompts the user to confirm the update.
function Test-For-Update {
    param (
        [int]$IntervalInDays = 1 # Default interval is 1 day (daily)
    )

    Debug-Log "Starting Test-For-Update..."

    try {
        # Load the existing configuration
        Debug-Log "Loading configuration..."

        # Ensure the field for last update check exists in the configuration
        Debug-Log "Verifying LastUpdateCheck field..."
        if (-not $Global:Config.PSObject.Properties.Match("LastUpdateCheck") -or -not $Global:Config.LastUpdateCheck) {
            Debug-Log "LastUpdateCheck missing or null. Initializing with a default value..."
            $DefaultDate = (Get-Date).AddYears(-1).Date
            $Config | Add-Member -MemberType NoteProperty -Name LastUpdateCheck -Value $DefaultDate -Force
        }

        # Parse dates
        $LastUpdateCheck = [datetime]$Global:Config.LastUpdateCheck
        $NextUpdateCheck = $LastUpdateCheck.AddDays($IntervalInDays)
        $Today = (Get-Date).Date

        Debug-Log "LastUpdateCheck: $LastUpdateCheck"
        Debug-Log "NextUpdateCheck: $NextUpdateCheck"
        Debug-Log "Today's Date: $Today"

        if ($Today -lt $NextUpdateCheck) {
            Debug-Log "Update check not needed. Skipping..."
            return # No need to check yet
        }

        # Prompt the user to confirm the update
        Debug-Log "Prompting user for update confirmation..."
        Write-Host "Checking for updates to the PowerShell profile script..." -ForegroundColor Cyan
        $Response = Read-Host "Do you want to check for and apply updates? (y/n)"
        if ($Response -match "^(y|yes)$") {
            Debug-Log "User confirmed update. Running Self-Update..."
            Self-Update
        } else {
            Debug-Log "User declined update. Skipping..."
            Write-Host "Skipping update check." -ForegroundColor Yellow
        }

        # Update the configuration with today's date
        Debug-Log "Updating configuration with today's date..."
        $Global:Config.LastUpdateCheck = $Today
        Save-Config -Silent -Config $Config
        Debug-Log "Configuration updated successfully."
        Write-Host "Configuration updated with the latest check date." -ForegroundColor Green
    } catch {
        Debug-Log "Error in Test-For-Update: $_"
        Write-Host "⚠️  Failed to check for updates. Please verify your configuration or internet connection." -ForegroundColor Red
        throw $_  # Re-throw the exception for further handling
    }
}

# Helper: Measure Execution Time
function Measure-Time {
    param (
        [string]$OperationName,
        [ScriptBlock]$Action
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        &$Action
    } catch {
        Write-Host "Error in operation '$OperationName': $_" -ForegroundColor Red
    } finally {
        $stopwatch.Stop()
        if ($DebugMode) {
            Write-Host "[MEASURE] Operation '$OperationName' completed in $($stopwatch.ElapsedMilliseconds)ms." -ForegroundColor DarkGray
        }
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

# Function: Get-Public-IP
# Description: Retrieves the public IP address of the system using OpenDNS servers.
function Get-Public-IP {
    try {
        (Resolve-DnsName myip.opendns.com -Server resolver1.opendns.com).IPAddress
    } catch {
        Write-Error "Unable to retrieve public IP. Please check your internet connection."
    }
}

# Function: Uptime
# Description: Displays the system's uptime and the last boot time.
function Uptime {
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

# Function: Get-System-Info
# Description: Displays basic system information, such as OS version, architecture, and memory.
function Get-System-Info {
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

Set-Alias -Name ip -Value Get-Public-IP
Set-Alias -Name sos -Value Show-Help
Set-Alias -Name sysinfo -Value Get-System-Info


############################
### SECTION 4: Startup
############################

# Measure overall startup time
Measure-Time -OperationName "Startup-Process" -Action {
    # Ensure the script is running on PowerShell 7 or later
    Check-Requirements -Silent

    # Load configuration
    $Global:Config = Get-Config

    # Check if the environment is configured
    if (-not $Global:Config.IsConfigured) {
        Write-Host "Oh My Posh is not configured. Run 'Install-Environment' to set up the environment." -ForegroundColor Yellow
        return
    }

    # Initialize environment and directories
    Initialize-Environment -Silent

    # Case 1: No configuration, guide user to install
    if (-not $Global:Config.FileExists) {
        Write-Host "Welcome to the default PowerShell profile." -ForegroundColor Cyan
        Write-Host "Oh My Posh has not been configured." -ForegroundColor Yellow
        Write-Host "Run 'Install-Environment' to set up the environment." -ForegroundColor Green
        return # Termina aquí porque no hay nada más que hacer sin configuración
    }

    # Validate binary existence only if configuration exists
    try {
        Test-Binary
    } catch {
        Write-Host "❌ This script requires PowerShell 7 or higher to function correctly." -ForegroundColor Red
        Write-Host "`n⚠️  Oh My Posh binary is missing or not functional!" -ForegroundColor Red
        Write-Host "Run 'Install-Environment' to reinstall the environment." -ForegroundColor Yellow
        return # Termina aquí porque el binario es crítico
    }

    # Case 2: Configuration exists but theme is disabled
    if ($Global:Config.ThemeDisabled -eq $true) {
        Write-Host "Theme is currently disabled. Use 'Reactivate-Theme' to enable it again." -ForegroundColor Yellow
        return
    }

    # Case 3: Valid configuration, attempt to load the theme
    if (-not $Global:Config.ThemeName) {
        Write-Host "No theme configured. Using default PowerShell prompt." -ForegroundColor Yellow
    } else {
        try {
            # Load the theme using the existing configuration
            Set-Theme -ThemeName $Global:Config.ThemeName -Silent
            Write-Host "Oh My Posh environment loaded successfully." -ForegroundColor Green
        } catch {
            Write-Host "`n⚠️  Failed to load the configured theme '$($Global:Config.ThemeName)'." -ForegroundColor Red
            Write-Host "Ensure the theme exists or run 'Install-Environment' to reconfigure." -ForegroundColor Yellow
            # Exit here since the theme is critical
            return
        }
    }

    # Attempt to run update checks
    try {
        Test-For-Update -IntervalInDays 7 -Config $Config
    } catch {
        Write-Host "`n⚠️  Failed to check for updates. Please verify your configuration or internet connection." -ForegroundColor Red
    }

    # Loading Required Modules
    Import-Required-Modules -Silent
}
