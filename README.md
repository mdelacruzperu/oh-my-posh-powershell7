# 🚀 PowerShell 7 Profile Setup with Oh My Posh 🎨

Transform your PowerShell experience with this comprehensive script, designed to set up **Oh My Posh** and customize your terminal environment like a pro! Whether you're a developer, system administrator, or just a terminal enthusiast, this script automates the process to save you time and effort.

---

## 📋 Features

- Automatically installs and configures **Oh My Posh**.
- Validates that you have **PowerShell 7** or higher installed.
- Downloads and applies **Nerd Fonts** for a stunning terminal look.
- Installs useful PowerShell modules like **Terminal-Icons**.
- Manages themes, including downloading and caching from remote sources.
- Allows easy customization and resetting of your PowerShell prompt.
- Offers user-friendly utilities like system info, uptime, and more.

---

## 🚦 Requirements

Before using this script, ensure you meet the following requirements:

1. **PowerShell 7 or higher**  
   - Download from [PowerShell GitHub](https://github.com/PowerShell/PowerShell).  
   - Follow the instructions for your operating system.

2. **Internet Connection**  
   - Required for downloading Oh My Posh, themes, and fonts.

3. **Execution Policy**  
   - Ensure your PowerShell execution policy allows running scripts:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
     ```

---

## 🔧 Installation

### **Option 1: Run the script directly**
Run this one-liner in PowerShell 7 to download and execute the script:

```powershell
irm "https://raw.githubusercontent.com/mdelacruzperu/oh-my-posh-powershell7/main/install-profile.ps1" | iex
