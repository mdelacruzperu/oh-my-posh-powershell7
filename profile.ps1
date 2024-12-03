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
$Global:DefaultThemes = @("peru")
# Define global modules list
$Global:ModulesToInstall = @(
    @{ Name = "Terminal-Icons"; Description = "Adds file icons to terminal output" }
)


#######################################################
### SECTION 1: Oh My Posh User Management functions ###
#######################################################

# Function: Install-Environment
# Description: Installs or updates the Oh My Posh environment for PowerShell.
function Install-Environment {
    Write-Host "🔄 Starting installation or update of the Oh My Posh environment..." -ForegroundColor Cyan

    # Step 1: Load or initialize configuration
    try {
        $Global:Config = Get-Config

        if (-not $Global:Config) {
            Write-Host "Configuration not found. Initializing default configuration..." -ForegroundColor Yellow

            # Define default configuration
            $Global:Config = [PSCustomObject]@{
                ThemeName       = $Global:DefaultThemes[0]
                IsConfigured    = $false
                ThemeDisabled   = $false
                FileExists      = $true
                LastUpdateCheck = (Get-Date).ToString("o")
            }

            # Save the newly initialized configuration
            Save-Config -Config $Global:Config -Silent
            Write-Host "✔️ Default configuration initialized and saved." -ForegroundColor Green
        } else {
            # Mark as configured and save any changes
            $Global:Config.IsConfigured = $true
            Save-Config -Config $Global:Config -Silent
        }
    } catch {
        Write-Host "❌ Critical error initializing configuration: $_" -ForegroundColor Red
        return
    }

    # Step 2: Update or install Oh My Posh binary
    try {
        $DownloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"

        if (-not (Test-Path $Global:BinaryPath)) {
            Write-Host "Downloading Oh My Posh binary..." -ForegroundColor Cyan
            New-Item -ItemType Directory -Path (Split-Path -Path $Global:BinaryPath -Parent) -Force | Out-Null
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $Global:BinaryPath -ErrorAction Stop
            Write-Host "✔️ Oh My Posh binary installed successfully." -ForegroundColor Green
        } else {
            # Check for updates
            Write-Host "Checking for updates to the Oh My Posh binary..." -ForegroundColor Cyan
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

    # Step 3: Update or install modules
    foreach ($Module in $Global:ModulesToInstall) {
        try {
            if (Get-InstalledModule -Name $Module.Name -ErrorAction SilentlyContinue) {
                Write-Host "Module $($Module.Name) is already installed. Checking for updates..." -ForegroundColor Yellow
                Update-Module -Name $Module.Name -Scope CurrentUser -Force -ErrorAction SilentlyContinue
                Write-Host "✔️ Module $($Module.Name) is up to date." -ForegroundColor Green
            } else {
                Write-Host "Installing module: $($Module.Name) - $($Module.Description)" -ForegroundColor Cyan
                Install-Module -Name $Module.Name -Scope CurrentUser -Force -ErrorAction Stop
                Write-Host "✔️ Module $($Module.Name) installed successfully." -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️ Failed to install or update module $($Module.Name). Error: $_" -ForegroundColor Red
        }
    }

    # Step 4: Update or install themes
    try {
        Ensure-Directory -DirectoryPath $Global:ThemeDirectory

        foreach ($Theme in $Global:DefaultThemes) {
            $ThemePath = Join-Path -Path $Global:ThemeDirectory -ChildPath "$Theme.omp.json"
            if (-not (Test-Path $ThemePath)) {
                Write-Host "Downloading theme: $Theme..." -ForegroundColor Cyan
                $ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$Theme.omp.json"
                Invoke-WebRequest -Uri $ThemeUrl -OutFile $ThemePath -ErrorAction Stop
                Write-Host "✔️ Theme $Theme installed successfully." -ForegroundColor Green
            } else {
                Write-Host "Theme $Theme is already installed." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️ Failed to install or update themes. Error: $_" -ForegroundColor Red
    }

    # Step 5: Finalize and save configuration
    try {
        $Global:Config.IsConfigured = $true
        Save-Config -Config $Global:Config -Silent
        Write-Host "✔️ Configuration saved successfully." -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Failed to save configuration. Some settings may not persist." -ForegroundColor Yellow
    }

    Write-Host "🎉 Installation or update of the Oh My Posh environment is complete!" -ForegroundColor Green
    Write-Host "Tip: Run 'Show-Help' to explore available commands and features." -ForegroundColor Magenta
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
            Write-Host "Removing themes..." -ForegroundColor Cyan
            Remove-Item -Path $Global:ThemeDirectory -Recurse -Force
            Write-Host "✔️ Themes removed successfully." -ForegroundColor Green
            $ThemesRemoved = $true
        } else {
            Write-Host "ℹ️ No themes found to remove." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Failed to remove themes. Error: $_" -ForegroundColor Red
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

# Function: Show-Help
# Description: Displays a detailed list of user-invocable commands for Oh My Posh management.
function Show-Help {
    Write-Host "`n=== Help: PowerShell Environment Commands ===`n" -ForegroundColor Cyan

    Write-Host "Commands available for managing your PowerShell environment:" -ForegroundColor Green
    Write-Host "1. Install-Environment     : Installs or updates the Oh My Posh environment, including binary, modules, and themes." -ForegroundColor Cyan
    Write-Host "2. Uninstall-Environment   : Uninstalls the environment, removing binary, modules, themes, and configurations." -ForegroundColor Cyan
    Write-Host "3. Set-Theme               : Applies a specific Oh My Posh theme. Example: 'Set-Theme -ThemeName peru'." -ForegroundColor Cyan
    Write-Host "4. List-Themes             : Lists available themes. Use '-Remote' for remote themes, and '-Force' to refresh cache." -ForegroundColor Cyan

    Write-Host "`nExamples of usage:" -ForegroundColor Green
    Write-Host "  Install-Environment" -ForegroundColor Yellow
    Write-Host "  Uninstall-Environment" -ForegroundColor Yellow
    Write-Host "  Set-Theme -ThemeName peru" -ForegroundColor Yellow
    Write-Host "  List-Themes -Remote -Force" -ForegroundColor Yellow

    Write-Host "`nAdditional Tips:" -ForegroundColor Green
    Write-Host "✔️ To fully experience the customization, install Nerd Fonts from the Fonts directory generated during installation." -ForegroundColor Magenta
    Write-Host "✔️ Explore available themes with 'List-Themes' and apply your favorite using 'Set-Theme'." -ForegroundColor Magenta

    Write-Host "`nTip: Check the full README for more details and examples." -ForegroundColor Magenta
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
# Function to ensure a directory exists
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

    # Ensure theme directory exists
    Ensure-Directory -DirectoryPath $Global:ThemeDirectory

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

    Debug-Log "Base Directory: $Global:BaseDirectory" -Context "Configuration"
    Debug-Log "Theme Directory: $Global:ThemeDirectory" -Context "Configuration"
} catch {
    Write-Host "❌ Error during profile setup: $_" -ForegroundColor Red
    Debug-Log "Error during profile setup: $_" -Context "Error"
}
