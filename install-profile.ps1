# install-profile.ps1 - Installs the PowerShell profile.

param(
    [switch]$Local,  # Use this switch for local installation (use file in the same directory).
    [switch]$Force   # Use this switch to avoid user confirmation.
)

Write-Host "=== PowerShell Profile Installer ===" -ForegroundColor Cyan

$DebugMode = $false

### Debugging Functions:
function Debug-Log {
    param (
        [string]$Message
    )
    if ($DebugMode) {
        $LineNumber = $MyInvocation.ScriptLineNumber
        Write-Host "[DEBUG] (Line $LineNumber) $Message" -ForegroundColor DarkGray
    }
}

if ($DebugMode) {
    Write-Host "#######################################" -ForegroundColor Red
    Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
    Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
    Write-Host "#######################################" -ForegroundColor Red
}

# Define paths
$DownloadsPath = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path
$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")

Debug-Log "Downloads path: $DownloadsPath"
Debug-Log "Documents path: $DocumentsPath"

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
try {
    if ($Local) {
        # Local mode: Use the file in the same directory
        $ProfileSourcePath = Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition) -ChildPath "profile.ps1"
        if (-not (Test-Path $ProfileSourcePath)) {
            throw "Local profile.ps1 not found at $ProfileSourcePath"
        }
        Write-Host "✔️ Using local profile.ps1 at $ProfileSourcePath" -ForegroundColor Green
    } else {
        # Remote mode (default): Download the file from GitHub
        $ProfileUrl = "https://raw.githubusercontent.com/mdelacruzperu/oh-my-posh-powershell7/main/profile.ps1"
        $ProfileSourcePath = Join-Path -Path $DownloadsPath -ChildPath "profile.ps1"

        Write-Host "Downloading profile.ps1 from GitHub..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ProfileUrl -OutFile $ProfileSourcePath -ErrorAction Stop
        Write-Host "✔️ Profile downloaded successfully to $ProfileSourcePath" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to determine or download profile.ps1. Error: $_" -ForegroundColor Red
    return
}

# Step 4: Prepare the target path
$TargetProfilePath = Join-Path -Path $DocumentsPath -ChildPath "PowerShell\Microsoft.PowerShell_profile.ps1"
$BackupProfilePath = "$TargetProfilePath.bak"
$TargetDirectory = Split-Path -Path $TargetProfilePath -Parent

try {
    if (-not (Test-Path $TargetDirectory)) {
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
        Write-Host "✔️ Target directory ensured: $TargetDirectory" -ForegroundColor Green
    } else {
        Write-Host "✔️ Target directory already exists: $TargetDirectory" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Failed to create or access target directory: $TargetDirectory. Error: $_" -ForegroundColor Red
    return
}

# Step 5: Backup existing profile
$ProfileExists = Test-Path $TargetProfilePath
if ($ProfileExists) {
    try {
        Copy-Item -Path $TargetProfilePath -Destination $BackupProfilePath -Force
        Write-Host "✔️ Backup created at $BackupProfilePath" -ForegroundColor Green
    } catch {
        Debug-Log "Failed to back up profile. Error: $_"
    }
} else {
    Debug-Log "No existing profile to back up."
}

# Step 6: Display summary and request confirmation
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

# Step 7: Install the new profile
try {
    Copy-Item -Path $ProfileSourcePath -Destination $TargetProfilePath -Force
    Write-Host "✔️ Profile installed successfully at $TargetProfilePath" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install the profile. Error: $_" -ForegroundColor Red
    return
}

Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "Restart PowerShell to apply the new profile." -ForegroundColor Green
