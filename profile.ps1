### PowerShell Profile Script by MDL ###
### Organized Configuration for PowerShell Environment ###
### Developed collaboratively with OpenAI Assistant ###

# Define global debug mode
$DebugMode = $false

if ($DebugMode) {
    Write-Host "#######################################" -ForegroundColor Red
    Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
    Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
    Write-Host "#######################################" -ForegroundColor Red
}

# Define paths using consistent methods
$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$Global:BaseDirectory = if ($PROFILE -and (Test-Path (Split-Path -Path $PROFILE -Parent))) {
    Split-Path -Path $PROFILE -Parent
} else {
    Join-Path -Path $DocumentsPath -ChildPath "PowerShell"
}

# Define global paths relative to the base directory
$Global:BinaryPath       = Join-Path -Path $Global:BaseDirectory -ChildPath ".oh-my-posh\oh-my-posh.exe"
$Global:ConfigFile       = Join-Path -Path $Global:BaseDirectory -ChildPath "EnvironmentConfig.json"
$Global:CacheFile        = Join-Path -Path $Global:BaseDirectory -ChildPath "RemoteThemesCache.json"
$Global:ThemeDirectory   = Join-Path -Path $Global:BaseDirectory -ChildPath "Themes"
# Global Lists
$Global:DefaultThemes = @("jandedobbeleer","peru")
$Global:ModulesToInstall = @(
    @{ Name = "Terminal-Icons"; Description = "Adds file icons to terminal output" }
)
$Global:Fonts = @(
    @{ Name = "CaskaydiaCove"; Uri = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" },
    @{ Name = "FiraCode"; Uri = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" }
)


#######################################################
### SECTION 1: Oh My Posh User Management functions ###
#######################################################

# Function: Install-Environment
# Description: Installs or updates the Oh My Posh environment for PowerShell.
function Install-Environment {
    param (
        [switch]$Update   # Indicates whether the action is an update
    )

    # Step 0: Validate the operation and prepare the environment
    Write-Host "🔄 Starting operation..." -ForegroundColor Cyan

    if ($Update -and -not (Test-Path $Global:ConfigFile)) {
        Write-Host "⚠️ No existing installation found. Please run 'Install-Environment' to set up your environment." -ForegroundColor Yellow
        return
    }

    if (-not $Update -and (Test-Path $Global:ConfigFile)) {
        Write-Host "⚠️ An existing installation is detected. Did you mean to update? Use 'Update-Environment'." -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $PROFILE)) {
        Write-Host "⚠️ PowerShell profile script not found. Re-initialize your profile with the correct script." -ForegroundColor Yellow
        Write-Host "Hint: Check the documentation or ensure the profile script is properly loaded." -ForegroundColor Cyan
        return
    }

    # Step 1: Check and update the PowerShell profile if needed
    if ($Update) {
        # GitHub repository and file details
        $ApiUrl = "https://api.github.com/repos/mdelacruzperu/oh-my-posh-powershell7/contents/profile.ps1"

        # Temporary path for the downloaded profile
        $TempProfilePath = Join-Path -Path $env:TEMP -ChildPath "temp_profile.ps1"

        try {
            # Fetch file information from GitHub API
            $Headers = @{
                "Accept" = "application/vnd.github+json"
                "User-Agent" = "PowerShell"
            }
            $Response = Invoke-RestMethod -Uri $ApiUrl -Method GET -Headers $Headers -ErrorAction Stop

            # Extract the remote file's hash
            if ($Response -and $Response.sha) {
                $RemoteHash = $Response.sha
            } else {
                throw "Failed to retrieve the remote profile's hash."
            }

            # Calculate the local file's hash
            $LocalHash = if (Test-Path $PROFILE) {
                (Get-FileHash -Path $PROFILE -Algorithm SHA1).Hash
            } else {
                $null
            }

            # Compare the hashes
            if ($LocalHash -ne $RemoteHash) {
                Write-Host "🔄 A newer version of the PowerShell profile is available." -ForegroundColor Yellow
                Write-Host "   Applying the updated profile now..." -ForegroundColor Cyan

                # Download and replace the local profile
                Invoke-WebRequest -Uri $Response.download_url -OutFile $TempProfilePath -ErrorAction Stop
                Copy-Item -Path $TempProfilePath -Destination $PROFILE -Force

                # Reload the profile
                Debug-Log -Message "Reloading profile: $PROFILE" -Context "Configuration"
                & $PROFILE
                Write-Host "✔️ Profile updated and reloaded successfully." -ForegroundColor Green
                Write-Host "⚠️ Please re-execute your command to apply the new settings." -ForegroundColor Yellow
                return
            } else {
                Write-Host "✔️ The PowerShell profile is already up to date. No changes needed." -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Failed to verify or update the PowerShell profile. Error: $_" -ForegroundColor Red
            Debug-Log -Message "Error during profile update: $_" -Context "Error"
        } finally {
            # Clean up temporary file
            if (Test-Path $TempProfilePath) {
                Remove-Item -Path $TempProfilePath -Force
            }
        }
    }

    # Step 2: Load or initialize configuration
    try {
        $Global:Config = Get-Config

        if (-not $Global:Config) {
            Write-Host "Configuration not found. Initializing default configuration..." -ForegroundColor Yellow
            $Global:Config = [PSCustomObject]@{
                ThemeName       = $Global:DefaultThemes[0]
                IsConfigured    = $false
                ThemeDisabled   = $false
                FileExists      = $true
                LastUpdateCheck = (Get-Date).ToString("o")
            }
            Save-Config -Config $Global:Config -Silent
            Write-Host "✔️ Default configuration initialized and saved." -ForegroundColor Green
        } else {
            Write-Host "✔️ Configuration loaded successfully." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Critical error initializing configuration: $_" -ForegroundColor Red
        return
    }

    # Step 3: Update or install Oh My Posh binary
    try {
        $DownloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"

        if (-not (Test-Path $Global:BinaryPath)) {
            Write-Host "Downloading Oh My Posh binary for first-time installation..." -ForegroundColor Cyan
            New-Item -ItemType Directory -Path (Split-Path -Path $Global:BinaryPath -Parent) -Force | Out-Null
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $Global:BinaryPath -ErrorAction Stop
            Write-Host "✔️ Oh My Posh binary installed successfully." -ForegroundColor Green
        } else {
            Write-Host "Verifying and updating Oh My Posh binary if necessary..." -ForegroundColor Cyan
            $RemoteBinary = Invoke-WebRequest -Uri $DownloadUrl -Method HEAD -ErrorAction Stop
            $LocalBinary = Get-Item $Global:BinaryPath
            if ($RemoteBinary.Headers."Content-Length" -ne $LocalBinary.Length) {
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $Global:BinaryPath -ErrorAction Stop
                Write-Host "✔️ Oh My Posh binary updated successfully." -ForegroundColor Green
            } else {
                Write-Host "✔️ Oh My Posh binary is already up to date." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️ Failed to install or update Oh My Posh binary. Check your internet connection or permissions." -ForegroundColor Red
    }

    # Step 4: Update or install modules
    foreach ($Module in $Global:ModulesToInstall) {
        Write-Host "Installing or updating module $($Module.Name)..." -ForegroundColor Cyan
        try {
            if (Get-InstalledModule -Name $Module.Name -ErrorAction SilentlyContinue) {
                Write-Host "Module $($Module.Name) is already installed. Checking for updates..." -ForegroundColor Yellow
                Update-Module -Name $Module.Name -Scope CurrentUser -Force -ErrorAction SilentlyContinue
                Write-Host "✔️ Module $($Module.Name) is up to date." -ForegroundColor Green
            } else {
                Install-Module -Name $Module.Name -Scope CurrentUser -Force -ErrorAction Stop
                Write-Host "✔️ Module $($Module.Name) installed successfully." -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️ Failed to install or update module $($Module.Name). Error: $_" -ForegroundColor Red
        }
    }

    # Step 5: Install or update Nerd Fonts
    try {
        $FontDirectory = Join-Path -Path $Global:BaseDirectory -ChildPath "NerdFonts"
        Ensure-Directory -DirectoryPath $FontDirectory

        foreach ($Font in $Global:Fonts) {
            $FontZipPath = Join-Path -Path $FontDirectory -ChildPath "$($Font.Name).zip"
            $FontFolderPath = Join-Path -Path $FontDirectory -ChildPath "$($Font.Name)"

            if (-not (Test-Path $FontFolderPath)) {
                Write-Host "Downloading Nerd Font: $($Font.Name)..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $Font.Uri -OutFile $FontZipPath -ErrorAction Stop

                # Create a subdirectory for the font and extract files into it
                Ensure-Directory -DirectoryPath $FontFolderPath
                Expand-Archive -Path $FontZipPath -DestinationPath $FontFolderPath -Force

                # Remove the ZIP file after extraction
                Remove-Item $FontZipPath -Force
                Write-Host "✔️ Font $($Font.Name) installed successfully in $FontFolderPath." -ForegroundColor Green
            } else {
                Write-Host "Font $($Font.Name) is already installed in $FontFolderPath." -ForegroundColor Green
            }
        }

        Write-Host "ℹ️ To fully enable Nerd Fonts, follow these steps:" -ForegroundColor Yellow
        Write-Host "   1. Open the folder: $FontDirectory" -ForegroundColor Cyan
        Write-Host "   2. Open the subfolder of your desired font and double-click to install." -ForegroundColor Cyan
        Write-Host "   3. Update your terminal settings to use the installed font (e.g., 'CaskaydiaCove Nerd Font')." -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️ Failed to download or install Nerd Fonts. Error: $_" -ForegroundColor Red
    }

    # Step 6: Update or install themes
    try {
        Ensure-Directory -DirectoryPath $Global:ThemeDirectory

        foreach ($Theme in $Global:DefaultThemes) {
            $ThemePath = Join-Path -Path $Global:ThemeDirectory -ChildPath "$Theme.omp.json"
            if (-not (Test-Path $ThemePath)) {
                Write-Host "Downloading and setting up theme: $Theme..." -ForegroundColor Cyan
                $ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$Theme.omp.json"
                Invoke-WebRequest -Uri $ThemeUrl -OutFile $ThemePath -ErrorAction Stop
                Write-Host "✔️ Theme $Theme installed successfully." -ForegroundColor Green
            } else {
                Write-Host "Verifying theme: $Theme... Already installed." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️ Failed to install or update themes. Error: $_" -ForegroundColor Red
    }

    # Step 7: Finalize and save configuration
    try {
        $Global:Config.IsConfigured = $true
        Save-Config -Config $Global:Config -Silent
        Write-Host ($Update ? "✔️ Configuration updated successfully." : "✔️ Configuration initialized successfully.") -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Failed to save configuration. Some settings may not persist." -ForegroundColor Yellow
    }

    & $PROFILE

    Write-Host ($Update ? "🎉 Update of the Oh My Posh environment is complete!" : "🎉 Installation of the Oh My Posh environment is complete!") -ForegroundColor Green
}

# Function: Update-Environment
# Description: Updates the Oh My Posh environment
function Update-Environment {
    Install-Environment -Update
}

# Function: Uninstall-Environment
# Description: Uninstalls the Oh My Posh environment, including themes, fonts, and configuration files.
function Uninstall-Environment {
    Write-Host "🧹 Starting uninstallation of the Oh My Posh environment..." -ForegroundColor Yellow

    # Step 1: Uninstall modules
    foreach ($Module in $Global:ModulesToInstall) {
        try {
            if (Get-InstalledModule -Name $Module.Name -ErrorAction SilentlyContinue) {
                Write-Host "Uninstalling module: $($Module.Name) - $($Module.Description)" -ForegroundColor Yellow
                Uninstall-Module -Name $Module.Name -AllVersions -Force -ErrorAction Stop
                Write-Host "✔️ Module $($Module.Name) uninstalled successfully." -ForegroundColor Green
            } else {
                Write-Host "ℹ️ Module $($Module.Name) is not installed." -ForegroundColor Cyan
            }
        } catch {
            Write-Host "❌ Failed to uninstall module $($Module.Name). Error: $_" -ForegroundColor Red
        }
    }

    # Step 2: Remove fonts
    $FontDirectory = Join-Path -Path $Global:BaseDirectory -ChildPath "NerdFonts"
    $FontsRemoved = $false
    try {
        if (Test-Path $FontDirectory) {
            Write-Host "Removing Nerd Fonts..." -ForegroundColor Cyan
            Remove-Item -Path $FontDirectory -Recurse -Force
            Write-Host "✔️ Fonts removed successfully." -ForegroundColor Green
            $FontsRemoved = $true
        } else {
            Write-Host "ℹ️ No fonts found to remove." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Failed to remove fonts. Error: $_" -ForegroundColor Red
    }

    # Step 3: Remove themes
    $ThemesRemoved = $false
    try {
        if (Test-Path $Global:ThemeDirectory) {
            Write-Host "Removing themes directory..." -ForegroundColor Cyan
            Remove-Item -Path $Global:ThemeDirectory -Recurse -Force
            Write-Host "✔️ Themes directory removed successfully." -ForegroundColor Green
            $ThemesRemoved = $true
        } else {
            Write-Host "ℹ️ Themes directory not found. Nothing to remove." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Failed to remove themes directory. Error: $_" -ForegroundColor Red
    }

    # Step 4: Remove configuration
    $ConfigRemoved = $false
    try {
        if (Test-Path $Global:ConfigFile) {
            Write-Host "Removing configuration file..." -ForegroundColor Cyan
            Remove-Item -Path $Global:ConfigFile -Force
            Write-Host "✔️ Configuration file removed successfully." -ForegroundColor Green
            $ConfigRemoved = $true
        } else {
            Write-Host "ℹ️ No configuration file found to remove." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Failed to remove configuration file. Error: $_" -ForegroundColor Red
    }

    # Step 5: Remove cache
    $CacheRemoved = $false
    try {
        if (Test-Path $Global:CacheFile) {
            Write-Host "Removing cache file..." -ForegroundColor Cyan
            Remove-Item -Path $Global:CacheFile -Force
            Write-Host "✔️ Cache file removed successfully." -ForegroundColor Green
            $CacheRemoved = $true
        } else {
            Write-Host "ℹ️ No cache file found to remove." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Failed to remove cache file. Error: $_" -ForegroundColor Red
    }

    # Step 6: Remove Oh My Posh binary
    $BinaryRemoved = $false
    if (Test-Path $Global:BinaryPath) {
        $response = Read-Host "Do you want to remove the Oh My Posh binary? (yes/no)"
        if ($response -in @("yes", "y")) {
            try {
                Remove-Item -Path $Global:BinaryPath -Force -ErrorAction Stop
                Write-Host "✔️ Oh My Posh binary removed successfully." -ForegroundColor Green
                $BinaryRemoved = $true

                # Check if the folder is empty and remove it
                $BinaryDirectory = Split-Path -Path $Global:BinaryPath -Parent
                if ((Get-ChildItem -Path $BinaryDirectory -Recurse -Force).Count -eq 0) {
                    Remove-Item -Path $BinaryDirectory -Force -ErrorAction Stop
                    Write-Host "✔️ Oh My Posh directory removed as it was empty." -ForegroundColor Green
                }
            } catch {
                Write-Host "❌ Failed to remove the Oh My Posh binary or directory. Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "ℹ️ Oh My Posh binary was not removed. You can delete it manually if needed." -ForegroundColor Cyan
        }
    } else {
        Write-Host "ℹ️ Oh My Posh binary not found." -ForegroundColor Cyan
        $BinaryRemoved = $true
    }

    # Final Summary
    Write-Host "`n🧹 Uninstallation Summary:" -ForegroundColor Cyan
    Write-Host "  - Fonts removed: $(if ($FontsRemoved) { '✅' } else { '✖️' })" -ForegroundColor Green
    Write-Host "  - Themes removed: $(if ($ThemesRemoved) { '✅' } else { '✖️' })" -ForegroundColor Green
    Write-Host "  - Configuration file removed: $(if ($ConfigRemoved) { '✅' } else { '✖️' })" -ForegroundColor Green
    Write-Host "  - Cache file removed: $(if ($CacheRemoved) { '✅' } else { '✖️' })" -ForegroundColor Green
    Write-Host "  - Binary removed: $(if ($BinaryRemoved) { '✅' } else { '✖️' })" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️ If you want to completely remove the PowerShell profile script, delete the following file manually:" -ForegroundColor Yellow
    Write-Host "   $PROFILE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "`nThe terminal will now close to avoid inconsistencies. Please reopen to start fresh." -ForegroundColor Red
    Write-Host "Press any key to continue and close the terminal..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)
    exit
}

# Function: Set-Theme
# Description: Applies a specified Oh My Posh theme using the binary and saves it to the configuration.
function Set-Theme {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ThemeName,
        [switch]$Silent
    )

    # Validate the environment
    if (-not (Validate-Environment -RequiredComponent "Binary") -or -not (Validate-Environment -RequiredComponent "Themes")) {
        return
    }

    # Ensure the themes directory exists
    Ensure-Directory -DirectoryPath $Global:ThemeDirectory

    # Skip applying if the theme is already active
    if ($Global:CurrentTheme -eq $ThemeName) {
        if (-not $Silent) {
            Write-Host "Theme '$ThemeName' is already active." -ForegroundColor Yellow
        }
        Debug-Log "Theme '$ThemeName' is already active. Skipping application." -Context "Configuration"
        return
    }

    # Ensure the theme file exists
    $ThemePath = Join-Path -Path $Global:ThemeDirectory -ChildPath "$ThemeName.omp.json"
    if (-not (Test-Path $ThemePath)) {
        try {
            $ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$ThemeName.omp.json"
            Invoke-WebRequest -Uri $ThemeUrl -OutFile $ThemePath -ErrorAction Stop
            Debug-Log "Theme downloaded: $ThemePath" -Context "Configuration"
        } catch {
            Write-Host "❌ Failed to download theme '$ThemeName'. Error: $_" -ForegroundColor Red
            return
        }
    }

    # Apply the theme using Oh My Posh binary
    try {
        & $Global:BinaryPath init pwsh --config $ThemePath | Invoke-Expression
        $Global:CurrentTheme = $ThemeName
        Debug-Log "Theme applied successfully: $ThemeName" -Context "Configuration"

        if (-not $Silent) {
            Write-Host "✔️ Theme '$ThemeName' applied successfully." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed to apply theme '$ThemeName'. Error: $_" -ForegroundColor Red
        return
    }

    # Save the theme to configuration
    try {
        $Global:Config.ThemeName = $ThemeName
        Save-Config -Silent -Config $Global:Config
        Debug-Log "Theme configuration saved: $ThemeName" -Context "Configuration"
    } catch {
        Write-Host "❌ Failed to save theme configuration. Error: $_" -ForegroundColor Red
    }
}

# Function: List-Themes
# Description: Lists all available Oh My Posh themes (local or remote with optional cache refresh).
function List-Themes {
    param (
        [switch]$Remote,     # Show remote themes if specified
        [switch]$Force       # Force refresh of remote themes cache
    )

    # Validate the environment
    if (-not (Validate-Environment -RequiredComponent "Binary") -or -not (Validate-Environment -RequiredComponent "Themes")) {
        return
    }

    # Ensure the themes directory exists
    Ensure-Directory -DirectoryPath $Global:ThemeDirectory

    if ($Remote) {
        try {
            $ThemesUrl = "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes"
            $CacheExpired = $false

            # Check if the cache file exists and if it's older than 7 days
            if (Test-Path $Global:CacheFile) {
                $CacheLastModified = (Get-Item $Global:CacheFile).LastWriteTime
                if ((Get-Date) - $CacheLastModified -gt [TimeSpan]::FromDays(7)) {
                    $CacheExpired = $true
                }
            } else {
                $CacheExpired = $true
            }

            # Fetch new themes if forced or cache is expired
            if ($Force -or $CacheExpired) {
                Write-Host "Fetching remote themes from GitHub..." -ForegroundColor Cyan

                # Fetch the list of theme files from the repository
                $RemoteThemes = Invoke-RestMethod -Uri $ThemesUrl -Headers @{ "User-Agent" = "PowerShell" }
                $ThemeNames = $RemoteThemes | Where-Object { $_.name -like "*.omp.json" } | ForEach-Object { $_.name -replace ".omp.json", "" }

                # Cache the remote themes
                $ThemeNames | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:CacheFile -Encoding UTF8 -Force
                Debug-Log "Remote themes cached successfully." -Context "Network"
            } else {
                Write-Host "Using cached remote themes list..." -ForegroundColor Green
                $ThemeNames = Get-Content -Path $Global:CacheFile | ConvertFrom-Json
            }

            # Display the themes
            if ($ThemeNames.Count -gt 0) {
                Write-Host "Available remote themes:" -ForegroundColor Green
                ($ThemeNames | Sort-Object -Unique -CaseSensitive) -join "  " | Write-Host -ForegroundColor Magenta
            } else {
                Write-Host "No remote themes found or unable to fetch the list." -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Failed to fetch remote themes. Error: $_" -ForegroundColor Red
        }
    } else {
        # List local themes
        try {
            $LocalThemes = Get-ChildItem -Path $Global:ThemeDirectory -Filter *.omp.json | ForEach-Object { $_.BaseName -replace "\.omp$", "" }
            if ($LocalThemes.Count -gt 0) {
                Write-Host "Available local themes:" -ForegroundColor Green
                ($LocalThemes | Sort-Object -Unique -CaseSensitive) -join "  " | Write-Host -ForegroundColor Magenta
            } else {
                Write-Host "No local themes found." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ Failed to list local themes. Error: $_" -ForegroundColor Red
        }
    }
}

# Function: Edit-Custom-Profile
# Description: Ensures the existence of a CustomProfile.ps1 file and opens it for the user to edit or create personal customizations.
function Edit-Custom-Profile {
    param (
        [string]$CustomProfilePath = (Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "CustomProfile.ps1")
    )

    # Validate the environment
    if (-not (Validate-Environment -RequiredComponent "Binary") -or -not (Validate-Environment -RequiredComponent "Themes")) {
        return
    }

    try {
        if (-not (Test-Path $CustomProfilePath)) {
            # Create the custom profile with basic instructions
            @"
# ============================================
# Custom PowerShell Profile
# ============================================
# Add your personal customizations and functions here.
# This file is automatically loaded after the main profile.

# Example Function:
function Greet-Me {
    Write-Host "Hello, $env:USERNAME! Welcome to your custom PowerShell environment!" -ForegroundColor Cyan
}

# Remember: Save your changes and reload the profile with `. $PROFILE` or restart PowerShell.
"@ | Set-Content -Path $CustomProfilePath -Force

            Write-Host "✔️ Custom profile created at: $CustomProfilePath" -ForegroundColor Green
        } else {
            Write-Host "ℹ️ Custom profile already exists at: $CustomProfilePath" -ForegroundColor Yellow
        }

        # Open the custom profile for editing
        if ($env:EDITOR) {
            Write-Host "Opening custom profile with default editor: $env:EDITOR" -ForegroundColor Cyan
            & $env:EDITOR $CustomProfilePath
        } else {
            Write-Host "Opening custom profile with Notepad..." -ForegroundColor Cyan
            Start-Process notepad.exe $CustomProfilePath
        }

        Write-Host "✔️ Remember to save your changes and reload the profile with '. $PROFILE' or restart PowerShell." -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create or open the custom profile. Error: $_" -ForegroundColor Red
    }
}

# Function: Show-Help
# Description: Displays detailed information about the available commands and their functionality.
function Show-Help {
    Write-Host "`n=== Help: PowerShell Environment Commands ===`n" -ForegroundColor Cyan

    Write-Host "Commands available for managing your PowerShell environment:" -ForegroundColor Green
    Write-Host "1. Install-Environment     : Installs the Oh My Posh environment, including binary, modules, and themes." -ForegroundColor Cyan
    Write-Host "2. Update-Environment      : Updates the environment if already installed." -ForegroundColor Cyan
    Write-Host "3. Set-Theme               : Applies a specific Oh My Posh theme. Example: 'Set-Theme -ThemeName peru'." -ForegroundColor Cyan
    Write-Host "4. List-Themes             : Lists available themes. Use '-Remote' for remote themes, and '-Force' to refresh cache." -ForegroundColor Cyan
    Write-Host "5. Uninstall-Environment   : Uninstalls the environment, removing binary, modules, themes, and configurations." -ForegroundColor Cyan
    Write-Host "6. Edit-Custom-Profile     : Creates or edits a custom profile script for user-defined functions." -ForegroundColor Cyan

    Write-Host "`nExamples of usage:" -ForegroundColor Green
    Write-Host "  Install-Environment" -ForegroundColor Yellow
    Write-Host "  Update-Environment" -ForegroundColor Yellow
    Write-Host "  Set-Theme -ThemeName peru" -ForegroundColor Yellow
    Write-Host "  List-Themes -Remote -Force" -ForegroundColor Yellow
    Write-Host "  Edit-Custom-Profile" -ForegroundColor Yellow

    Write-Host "`nAdditional Tips:" -ForegroundColor Green
    Write-Host "✔️ Ensure the environment is installed before running commands like 'Set-Theme' or 'List-Themes'." -ForegroundColor Magenta
    Write-Host "✔️ Use 'Edit-Custom-Profile' to define your own functions without risking conflicts during updates." -ForegroundColor Magenta

    Write-Host "`nTip: For a fresh setup, start with 'Install-Environment'. If already installed, use 'Update-Environment'." -ForegroundColor Magenta
    Write-Host "`n=== End of Help ===`n" -ForegroundColor Cyan
}

############################################
### SECTION 2: Private Support Functions ###
############################################

# Function: Debug-Log
# Description: Logs messages to the console with context and color coding if DebugMode is enabled.
function Debug-Log {
    param (
        [string]$Message,
        [string]$Context = "General" # Default context is "General".
    )

    # Define color mappings for each context
    $ContextColors = @{
        "Configuration" = "Green"
        "Error"         = "Red"
        "FileSystem"    = "Yellow"
        "General"       = "DarkGray"
        "Network"       = "Blue"
        "Performance"   = "Magenta"
        "Startup"       = "Cyan"
    }

    # Get the color for the provided context, fallback to "DarkGray" if not found
    $Color = $ContextColors[$Context] ? $ContextColors[$Context] : "DarkGray"

    if ($DebugMode) {
        $LineNumber = $MyInvocation.ScriptLineNumber
        Write-Host "[DEBUG][$Context] (Line $LineNumber) $Message" -ForegroundColor $Color
    }
}

# Function: Measure-Time [ Measure-Time -OperationName "Identifier" -Action { ... code to measure execution time ... } ]
# Description: Helper to Measure Execution Time
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

# Function: Validate-Environment
# Description: Checks if the Oh My Posh environment is correctly installed and configured.
function Validate-Environment {
    # Initialize a flag to track validation status
    $IsValid = $true

    # Check if the configuration exists
    if (-not (Test-Path $Global:ConfigFile)) {
        Write-Host "⚠️ The environment is not installed. Please run 'Install-Environment' to set up the environment." -ForegroundColor Yellow
        $IsValid = $false
    }

    # Check for binary
    if (-not (Test-Path $Global:BinaryPath)) {
        Write-Host "⚠️ The Oh My Posh binary is missing. Please run 'Install-Environment' to set up the environment." -ForegroundColor Yellow
        $IsValid = $false
    }

    # Check for themes directory
    if (-not (Test-Path $Global:ThemeDirectory)) {
        Write-Host "⚠️ The Themes directory is missing. Please run 'Install-Environment' to set up the environment." -ForegroundColor Yellow
        $IsValid = $false
    }

    # Provide a summary and return the validation status
    if (-not $IsValid) {
        Write-Host "ℹ️ Some components are missing or not configured. Please address the issues above by running 'Install-Environment'." -ForegroundColor Cyan
    }

    return $IsValid
}

# Function: Ensure-Directory
# Description: Function to ensure a directory exists
function Ensure-Directory {
    param ([string]$DirectoryPath)
    if (-not (Test-Path $DirectoryPath)) {
        try {
            New-Item -ItemType Directory -Path $DirectoryPath -Force | Out-Null
            Debug-Log "Created directory: $DirectoryPath" -Context "FileSystem"
        } catch {
            Write-Host "❌ Failed to create directory: $DirectoryPath. Error: $_" -ForegroundColor Red
            throw
        }
    }
}

# Function: Get-Config
# Description: Loads the configuration from a JSON file.
function Get-Config {
    Debug-Log "Attempting to load configuration from: $Global:ConfigFile" -Context "Configuration"

    try {
        $Config = Get-Content -Path $Global:ConfigFile -ErrorAction Stop | ConvertFrom-Json
        $Config.FileExists = $true
        Debug-Log "Configuration loaded successfully: $Config" -Context "Configuration"
        return $Config
    } catch {
        Debug-Log "Configuration file missing or invalid: $_" -Context "Error"
        return $null
    }
}

# Function: Save-Config
# Description: Saves configuration to JSON file, ensuring a readable format. Creates directories if needed.
function Save-Config {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [switch]$Silent # If specified, suppresses success messages
    )

    try {
        Ensure-Directory -DirectoryPath (Split-Path -Path $Global:ConfigFile -Parent)
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:ConfigFile -Encoding UTF8 -Force
        if (-not $Silent) {
            Write-Host "✔️ Configuration saved successfully to: $Global:ConfigFile" -ForegroundColor Green
        }
        Debug-Log "Configuration saved: $Config" -Context "Configuration"
    } catch {
        Write-Host "❌ Failed to save configuration. Error: $_" -ForegroundColor Red
        Debug-Log "Failed to save configuration. Error: $_" -Context "Error"
    }
}

#################################
### SECTION 3: User Utilities ###
#################################

# Function: touch
# Description: Creates an empty file (similar to the Unix `touch` command).
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

# Function: Get-Public-IP
# Description: Retrieves the public IP address of the system using OpenDNS servers.
function Get-Public-IP {
    try {
        (Resolve-DnsName myip.opendns.com -Server resolver1.opendns.com).IPAddress
    } catch {
        Write-Error "Unable to retrieve public IP. Please check your internet connection or firewall settings."
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
        Write-Error "Unable to retrieve system uptime. Ensure you have the necessary permissions."
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
# Use Get-Alias to check for existents aliases
# ------------------------------------

Set-Alias -Name ip -Value Get-Public-IP
Set-Alias -Name sos -Value Show-Help
Set-Alias -Name sysinfo -Value Get-System-Info


############################
### SECTION 4: Startup ###
############################

try {
    Debug-Log "Starting profile setup..." -Context "Startup"

    # Validate or create base directory
    Ensure-Directory -DirectoryPath $Global:BaseDirectory

    # Load configuration
    $Global:Config = Get-Config
    if (-not $Global:Config) {
        Write-Host ""
        Write-Host "👋 Welcome to your enhanced PowerShell experience!" -ForegroundColor Cyan
        Write-Host "⚡ To unlock the full potential of this profile, please run:" -ForegroundColor Green
        Write-Host "   Install-Environment" -ForegroundColor Yellow
        Write-Host "This will set up themes, icons, and additional features." -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "✔️ Profile successfully loaded and ready to use." -ForegroundColor Green
        Debug-Log "Configuration loaded successfully: $Global:Config" -Context "Configuration"

        # Apply the theme if configured and not disabled
        if (-not $Global:Config.ThemeDisabled -and $Global:Config.ThemeName) {
            Set-Theme -ThemeName $Global:Config.ThemeName -Silent
        }
    }

    # Import modules only if they are marked as installed in the configuration
    if ($Global:Config -and $Global:Config.IsConfigured) {
        foreach ($Module in $Global:ModulesToInstall) {
            try {
                Import-Module -Name $Module.Name -ErrorAction Stop
                Debug-Log "Module '$($Module.Name)' imported successfully." -Context "Startup"
            } catch {
                Debug-Log "Failed to import module '$($Module.Name)'. Error: $_" -Context "Error"
                Write-Host "⚠️ Failed to import module '$($Module.Name)'. It may not be installed." -ForegroundColor Yellow
            }
        }
    }

    # Load custom profile if exists
    $CustomProfilePath = Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "CustomProfile.ps1"
    if (Test-Path $CustomProfilePath) {
        Write-Host "✔️ Loading custom profile: $CustomProfilePath" -ForegroundColor Green
        & $CustomProfilePath
    }
} catch {
    Write-Host "❌ Error during profile setup: $_" -ForegroundColor Red
    Debug-Log "Error during profile setup: $_" -Context "Error"
}
