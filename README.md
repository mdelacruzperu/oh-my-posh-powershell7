
# 🚀 PowerShell 7 Profile Setup with Oh My Posh 🎨

---

⚠️ **Global Testing Phase** ⚠️  
We are currently in a global testing phase. If you encounter any issues, please report them in the [Issues Section](https://github.com/mdelacruzperu/oh-my-posh-powershell7/issues). Your feedback is invaluable and will help us improve!

---

Transform your PowerShell experience with this streamlined script! Designed to automate the setup and management of **Oh My Posh**, this project provides a highly customized terminal experience. Save time while enjoying a clean, functional environment.

---

## 📋 Features

- **Automated Setup**: Installs and configures **Oh My Posh** with a single command.
- **Custom Themes**: Manage local and remote themes effortlessly.
- **Module Management**: Includes popular modules like **Terminal-Icons**.
- **Performance Optimized**: Ensures startup times stay under 500ms.
- **Easy Cleanup**: Fully reversible with `Uninstall-Environment`.
- **Custom Profile Support**: Add personal customizations with `Edit-CustomProfile`.

---

## 🚦 Requirements

1. **PowerShell 7 or higher**  
   - Download from [PowerShell GitHub](https://github.com/PowerShell/PowerShell).

2. **Nerd Fonts**  
   - Required for enhanced visuals. Fonts are downloaded during installation.

3. **Execution Policy**  
   - Set your PowerShell execution policy:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
     ```

---

## 🔧 Installation

### **Option 1: Run the script directly**
Run this one-liner in PowerShell 7 to download and execute the script:

```powershell
irm "https://raw.githubusercontent.com/mdelacruzperu/oh-my-posh-powershell7/main/install-profile.ps1" | iex
```

### **Option 2: Clone and run**
If you prefer to review the script before running it:

1. Clone the repository:
   ```bash
   git clone https://github.com/mdelacruzperu/oh-my-posh-powershell7.git
   cd oh-my-posh-powershell7
   ```

2. Run the script:
   ```powershell
   ./install-profile.ps1 -Local
   ```

---

## 🛠 What the script does

1. **Checks requirements:** Ensures PowerShell 7 or higher is installed.  
2. **Downloads and installs Oh My Posh:** Fetches the latest binary.  
3. **Sets up Nerd Fonts:** Downloads and prepares fonts for use in your terminal.  
4. **Installs PowerShell modules:** Includes tools like **Terminal-Icons**.  
5. **Manages themes:** Downloads default themes and lets you apply or reset them easily.  
6. **Customizes the environment:** Configures a personalized PowerShell profile.
7. **Supports Custom Profiles:** Edit your own `CustomProfile.ps1` for personalized commands.

---

## 🖼 Preview

![Terminal Example #1](images/image-1.png "Example 1")
![Terminal Example #2](images/image-2.png "Example 2")

---

## 💡 Usage

### **Key Commands**
- `Install-Environment`: Installs or updates Oh My Posh and related components.
- `Uninstall-Environment`: Removes all customizations and resets to default.
- `Set-Theme -ThemeName <name>`: Applies a specific theme (e.g., `Set-Theme -ThemeName peru`).
- `List-Themes [-Remote]`: Lists available themes. Use `-Remote` to fetch remote themes from GitHub.
- `Edit-CustomProfile`: Opens `CustomProfile.ps1` for editing custom commands.

---

## 📚 Advanced Utilities

This script includes additional utilities for daily productivity:

- `ll`: Lists directory contents with file icons.
- `sysinfo`: Displays system information.
- `uptime`: Shows system uptime and last boot time.
- `ip`: Retrieves the public IP address of your system.

---

## 🤝 Contributing

Feel free to fork this repository, make improvements, and submit a pull request. We welcome your ideas and contributions to make this project even better!

---

## Support the Project
If you find this project useful, consider supporting it by [donating via PayPal](https://paypal.me/mdelacruzperu). Your support helps keep this project alive! 💙

[![PayPal](https://img.shields.io/badge/💰-Donate%20via%20PayPal-blue?style=flat&logo=paypal)](https://paypal.me/mdelacruzperu)

---

## 🔗 More Resources

- **Oh My Posh Documentation:** [https://ohmyposh.dev/](https://ohmyposh.dev/)
- **PowerShell Documentation:** [https://learn.microsoft.com/en-us/powershell/](https://learn.microsoft.com/en-us/powershell/)
