# install-profile.ps1 - Installs the PowerShell profile.

param(
    [switch]$Local,   # Use this switch for local installation (use file in the same directory).
    [switch]$Force    # Use this switch to avoid user confirmation.
)

Write-Host "=== PowerShell Profile Installer ===" -ForegroundColor Cyan

# Step 1: Validate PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ PowerShell 7 or higher is required. Please update PowerShell." -ForegroundColor Red
    return
}

# Step 2: Validate Execution Policy
$ExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($ExecutionPolicy -eq "Restricted") {
    Write-Host "❌ Execution policy is restricted. Run the following command to allow scripts:" -ForegroundColor Red
    Write-Host "`nSet-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`n" -ForegroundColor Yellow
    return
}

# Step 3: Determine the PowerShell directory and ensure it exists
$PowerShellDirectory = Join-Path -Path ([System.Environment]::GetFolderPath("MyDocuments")) -ChildPath "PowerShell"
if (-not (Test-Path $PowerShellDirectory)) {
    Write-Host "⚠️ PowerShell directory not found. Creating it now..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $PowerShellDirectory -Force | Out-Null
        Write-Host "✔️ PowerShell directory created: $PowerShellDirectory" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create PowerShell directory. Error: $_" -ForegroundColor Red
        return
    }
}

# Step 4: Define $PROFILE or fallback to a custom path
if (-not $PROFILE) {
    Write-Host "⚠️ $PROFILE variable is not set. Using a fallback path." -ForegroundColor Yellow
    $CustomProfilePath = Join-Path -Path $PowerShellDirectory -ChildPath "Microsoft.PowerShell_profile.ps1"
} else {
    $CustomProfilePath = $PROFILE
}

# Check that the fallback path is valid
if (-not (Test-Path (Split-Path -Path $CustomProfilePath -Parent))) {
    try {
        New-Item -ItemType Directory -Path (Split-Path -Path $CustomProfilePath -Parent) -Force | Out-Null
        Write-Host "✔️ Created fallback directory for profile: $CustomProfilePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create directory for fallback profile path. Error: $_" -ForegroundColor Red
        return
    }
}

# Step 5: Determine base directory and configuration paths
$Global:BaseDirectory = Split-Path -Path $CustomProfilePath -Parent
$Global:ConfigFile = Join-Path -Path $Global:BaseDirectory -ChildPath "EnvironmentConfig.json"

Write-Host "Configuration base directory set to: $Global:BaseDirectory" -ForegroundColor Green

# Step 6: Determine profile source
$ProfileSourcePath = ""
if ($Local) {
    # Local mode: Use the file in the same directory
    $ProfileSourcePath = Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition) -ChildPath "profile.ps1"

    if (-not (Test-Path $ProfileSourcePath)) {
        Write-Host "❌ profile.ps1 not found in the current directory. Please ensure the file is present." -ForegroundColor Red
        return
    }

    Write-Host "✔️ Using local profile.ps1 at $ProfileSourcePath" -ForegroundColor Green
} else {
    # Remote mode (default): Download the file from GitHub
    $ProfileUrl = "https://raw.githubusercontent.com/mdelacruzperu/oh-my-posh-powershell7/main/profile.ps1"
    $ProfileSourcePath = Join-Path -Path $Global:BaseDirectory -ChildPath "profile.ps1"

    Write-Host "Downloading profile.ps1 from GitHub..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $ProfileUrl -OutFile $ProfileSourcePath -ErrorAction Stop
        Write-Host "✔️ Profile downloaded successfully to $ProfileSourcePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download profile.ps1. Please check your internet connection or the URL." -ForegroundColor Red
        return
    }
}

# Step 7: Prepare the target path
$TargetProfilePath = $CustomProfilePath
$BackupProfilePath = "$TargetProfilePath.bak"

# Ensure the target directory exists
if (-not (Test-Path $PowerShellDirectory)) {
    Write-Host "⚠️ Target directory does not exist. Creating it now..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $PowerShellDirectory -Force | Out-Null
        Write-Host "✔️ Target directory created: $PowerShellDirectory" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create target directory. Error: $_" -ForegroundColor Red
        return
    }
}

# Step 8: Display summary and request confirmation
Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Source profile: $ProfileSourcePath" -ForegroundColor Cyan
Write-Host "Target profile: $TargetProfilePath" -ForegroundColor Cyan
if ($ProfileExists) {
    Write-Host "Backup will be created at: $BackupProfilePath" -ForegroundColor Yellow
}
if (-not $Force) {
    $response = Read-Host "Do you want to proceed with the installation? (yes/no)"
    if ($response -notin @("yes", "y")) {
        Write-Host "Installation canceled by user." -ForegroundColor Yellow
        return
    }
}

# Step 9: Backup existing profile (if any)
if ($ProfileExists) {
    Write-Host "Creating backup of the existing profile..." -ForegroundColor Cyan
    Copy-Item -Path $TargetProfilePath -Destination $BackupProfilePath -Force
    Write-Host "✔️ Backup created: $BackupProfilePath" -ForegroundColor Green
}

# Step 10: Install the new profile
Write-Host "Installing new profile..." -ForegroundColor Cyan
try {
    Copy-Item -Path $ProfileSourcePath -Destination $TargetProfilePath -Force
    Write-Host "✔️ Profile installed successfully at $TargetProfilePath" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install the profile. Error: $_" -ForegroundColor Red
    return
}

# Step 11: Create or update configuration file
if (-not (Test-Path $Global:ConfigFile)) {
    Write-Host "Creating initial configuration file..." -ForegroundColor Cyan
    $InitialConfig = [PSCustomObject]@{
        ThemeName        = "peru"
        IsConfigured     = $true
        ThemeDisabled    = $false
        FileExists       = $true
        LastUpdateCheck  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    }
    $InitialConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:ConfigFile -Encoding UTF8
    Write-Host "✔️ Configuration file created: $Global:ConfigFile" -ForegroundColor Green
} else {
    Write-Host "✔️ Configuration file already exists. Skipping creation." -ForegroundColor Yellow
}

Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "Restart PowerShell to apply the new profile." -ForegroundColor Green
