# install-profile.ps1 - Installs the PowerShell profile.

param(
    [switch]$Local   # Use this switch for local installation (use file in the same directory).
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

# Step 3: Determine profile source
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
    $ProfileSourcePath = "$HOME\Downloads\profile.ps1"

    Write-Host "Downloading profile.ps1 from GitHub..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $ProfileUrl -OutFile $ProfileSourcePath -ErrorAction Stop
        Write-Host "✔️ Profile downloaded successfully to $ProfileSourcePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download profile.ps1. Please check your internet connection or the URL." -ForegroundColor Red
        return
    }
}

# Step 4: Prepare the target path
$TargetProfilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$BackupProfilePath = "$TargetProfilePath.bak"
$TargetDirectory = Split-Path -Path $TargetProfilePath -Parent

# Ensure the target directory exists
if (-not (Test-Path $TargetDirectory)) {
    Write-Host "⚠️ Target directory does not exist. Creating it now..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
        Write-Host "✔️ Target directory created: $TargetDirectory" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create target directory. Error: $_" -ForegroundColor Red
        return
    }
}

# Step 5: Check for existing profile
$ProfileExists = Test-Path $TargetProfilePath
if ($ProfileExists) {
    Write-Host "⚠️ Existing profile detected at $TargetProfilePath." -ForegroundColor Yellow
    Write-Host "This profile will be backed up to $BackupProfilePath." -ForegroundColor Cyan
} else {
    Write-Host "✔️ No existing profile detected. A new profile will be installed." -ForegroundColor Green
}

# Step 6: Display summary and request confirmation
Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Source profile: $ProfileSourcePath" -ForegroundColor Cyan
Write-Host "Target profile: $TargetProfilePath" -ForegroundColor Cyan
if ($ProfileExists) {
    Write-Host "Backup will be created at: $BackupProfilePath" -ForegroundColor Yellow
}
$response = Read-Host "Do you want to proceed with the installation? (yes/no)"
if ($response -notin @("yes", "y")) {
    Write-Host "Installation canceled by user." -ForegroundColor Yellow
    return
}

# Step 7: Backup existing profile (if any)
if ($ProfileExists) {
    Write-Host "Creating backup of the existing profile..." -ForegroundColor Cyan
    Copy-Item -Path $TargetProfilePath -Destination $BackupProfilePath -Force
    Write-Host "✔️ Backup created: $BackupProfilePath" -ForegroundColor Green
}

# Step 8: Install the new profile
Write-Host "Installing new profile..." -ForegroundColor Cyan
try {
    Copy-Item -Path $ProfileSourcePath -Destination $TargetProfilePath -Force
    Write-Host "✔️ Profile installed successfully at $TargetProfilePath" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install the profile. Error: $_" -ForegroundColor Red
    return
}

Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "Restart PowerShell to apply the new profile." -ForegroundColor Green
