# Website Backup System

A comprehensive, secure PowerShell-based solution for automated website backups with Google Drive integration.

## 🚀 Quick Start

### First Time Setup - Single Command!

Just run the backup script and it will guide you through everything:

```powershell
.\Backup-Website.ps1
```

That's it! The script will automatically:
- ✅ Check for required tools (OpenSSH, Rclone)
- ✅ Generate SSH keys if needed
- ✅ Guide you through server connection setup
- ✅ Help configure Google Drive
- ✅ Save your configuration securely
- ✅ Optionally run your first backup

**Estimated setup time: 15-20 minutes**

### Prerequisites

The script will check for these (and guide you to install if missing):
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or newer
- OpenSSH Client
- Rclone

### What You'll Need

Before running the script, have ready:
1. **SSH credentials** for your web server (username, hostname/IP, port)
2. **Google Account** for backup storage
3. **~15 minutes** for the guided setup

### Advanced: Manual Installation

If you prefer to install prerequisites manually before running the script:

1. **Install OpenSSH Client:**
   ```powershell
   # Run as Administrator
   Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
   ```

2. **Install Rclone:**
   - Download from [rclone.org/downloads](https://rclone.org/downloads/)
   - Extract to `C:\Program Files\rclone`
   - Add to PATH

3. **Run the interactive setup:**
   ```powershell
   .\Backup-Website.ps1
   ```
   
The setup wizard will guide you through the rest!

## 📖 Usage

### First Run

When you run the script for the first time, you'll see:

```
================================================================================
  WEBSITE BACKUP SYSTEM - FIRST TIME SETUP
================================================================================

Welcome! It looks like this is your first time running this backup.

I'll guide you through a quick setup process that will configure:
  ✓ SSH connection to your server
  ✓ Website files location
  ✓ Google Drive backup storage
  ✓ Automated backup schedule (optional)

Estimated time: 15-20 minutes

The setup wizard walks you through 8 simple steps to get everything configured.

Ready to begin? [Y/n]:
```

Just follow the prompts - the script will:
1. Check prerequisites (OpenSSH, Rclone)
2. Set up SSH keys and test connection
3. Discover your website directory
4. Configure Google Drive
5. Save everything securely
6. Optionally run your first backup

### Subsequent Runs

After initial setup, running the script shows your configuration:

```
================================================================================
  CURRENT BACKUP CONFIGURATION
================================================================================
  SSH Server: username@server.com:22
  Website Path: /home/user/app/public_html
  Google Drive: gdrive:backups/website
  
Options:
  [1] Run backup now (default)
  [2] Reconfigure settings
  [3] Run in dry-run mode
  [4] Manage schedule
  [Q] Quit

Choice [1]:
```

Just press Enter to run the backup! Select option 4 to create, update, or remove automatic scheduling.

### Manual Backup (Skip Confirmation)

Run a backup without prompts (useful for scheduled tasks):

```powershell
.\Backup-Website.ps1 -SkipConfirmation
```

Or for non-interactive mode (fails if not configured):

```powershell
.\Backup-Website.ps1 -NonInteractive
```

### Reconfiguration

Need to change settings? Run the script and select option 2, or force the setup wizard:

```powershell
.\Backup-Website.ps1 -ForceSetup
```

### Dry-Run Mode

Test without making changes:

```powershell
.\Backup-Website.ps1 -DryRun
```

Or select option 3 when prompted.

### Custom Parameters

Override stored configuration for a one-time backup:

```powershell
.\Backup-Website.ps1 `
    -SSHUser "your_username" `
    -SSHHost "your-server.com" `
    -RemotePath "/home/your_user/applications/your_app/public_html" `
    -GDriveRemote "gdrive:backups/website" `
    -SkipConfirmation
```

### Scheduled Backups

**NEW: Built-in Scheduling!**

During the initial setup, you'll be asked if you want to schedule automatic backups with these options:

- **Daily** - Every day at your chosen time
- **Weekly** - Every Monday at your chosen time  
- **Monthly** - First day of each month
- **Quarterly** - First day of Jan, Apr, Jul, Oct

You can also manage schedules anytime by running the script and selecting option [4] Manage schedule.

**Manual Scheduling (Alternative):**

If you prefer to set up scheduling manually:

```powershell
$scriptPath = "$PWD\Backup-Website.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -NonInteractive"
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "Website Backup - Automated" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
```

**Note:** The `-NonInteractive` flag ensures the script runs unattended and won't prompt for user input.

## ✨ Features

- ✅ **Secure SSH Key Authentication** - No passwords stored
- ✅ **Automated Compression** - Creates tar.gz archives on remote server
- ✅ **Google Drive Upload** - Automatic upload via rclone
- ✅ **Backup Rotation** - Keeps last 7 backups (configurable)
- ✅ **Comprehensive Logging** - Color-coded console output and log files
- ✅ **Error Handling** - Graceful failure recovery
- ✅ **Progress Tracking** - Real-time progress indicators
- ✅ **Dry-Run Mode** - Test without making changes
- ✅ **Task Scheduler Ready** - Fully automated execution
- ✅ **Encrypted Credentials** - Secure storage in Windows Registry
- ✅ **Email Notifications** - Optional alert system

## 📂 Project Structure

```
WebsiteBackup/
├── Backup-Website.ps1           # Main backup script
├── Setup-BackupCredentials.ps1  # Initial setup wizard
├── README.md                     # This file
├── docs/
│   └── backup-system.md         # Complete documentation
└── .gitignore
```

## 🔒 Security Features

### SSH Security
- SSH key authentication only (no passwords)
- Configurable SSH port
- Connection timeout protection

### Credential Storage
- Windows Registry (per-user) for configuration
- No hardcoded passwords
- Encrypted credential storage

### Google Drive Security
- OAuth2 authentication via rclone
- Optional backup encryption (rclone crypt)
- Secure token storage

## 📋 What Gets Backed Up

The script backs up:
- All files in the specified remote directory
- Subdirectories and their contents
- File permissions preserved in tar.gz archive

## 🔄 Backup Process

1. **Initialize** - Set up logging and environment
2. **Connect** - Test SSH connection to remote server
3. **Archive** - Create compressed tar.gz on remote server
4. **Download** - Transfer archive to local machine via SCP
5. **Upload** - Push to Google Drive using rclone
6. **Rotate** - Delete old backups (keep last 7)
7. **Cleanup** - Remove temporary files
8. **Report** - Generate summary with timing

## 📊 Logging

Logs are saved to: `C:\Logs\website-backup\backup-YYYYMMDD.log`

**Color Coding:**
- 🟢 Green = Success
- 🟡 Yellow = Warning
- 🔴 Red = Error
- 🔵 Cyan = Info

## 🛠️ Configuration

Configuration is stored in Windows Registry: `HKCU:\Software\WebsiteBackup`

**Parameters:**
- `SSHUser` - Remote server username
- `SSHHost` - Remote server hostname/IP
- `SSHPort` - SSH port (default: 22)
- `RemotePath` - Path to website files (e.g., /var/www/html)
- `GDriveRemote` - Google Drive destination (e.g., gdrive:backups/website)

View configuration:
```powershell
Get-ItemProperty -Path "HKCU:\Software\WebsiteBackup"
```

Update configuration:
```powershell
.\Setup-BackupCredentials.ps1
```

## 🔧 Troubleshooting

### Common Issues

**SSH Connection Failed**
```powershell
# Test SSH manually
ssh -v -p 22 user@host
# Verify key permissions on server
```

**Rclone Not Configured**
```powershell
# List remotes
rclone listremotes
# Configure if missing
rclone config
```

**Task Doesn't Run**
```powershell
# Check task status
Get-ScheduledTask -TaskName "Website Backup"
# Run manually to test
Start-ScheduledTask -TaskName "Website Backup"
```

See [complete documentation](docs/backup-system.md#troubleshooting) for more solutions.

## 📚 Documentation

- **Quick Start:** This README
- **Complete Guide:** [docs/backup-system.md](docs/backup-system.md)
- **Setup Instructions:** Run `.\Setup-BackupCredentials.ps1`

## 🔄 Backup Restoration

To restore a backup:

1. **List available backups:**
   ```powershell
   rclone ls gdrive:backups/website
   ```

2. **Download backup:**
   ```powershell
   rclone copy gdrive:backups/website/website-20241123-140000.tar.gz C:\Restore\
   ```

3. **Extract:**
   ```powershell
   tar -xzf C:\Restore\website-20241123-140000.tar.gz -C C:\Restore\extracted
   ```

## 🔐 Best Practices

1. **Test regularly** - Run backups in dry-run mode after configuration changes
2. **Monitor logs** - Review backup logs weekly
3. **Verify backups** - Test restoration monthly
4. **Keep multiple copies** - Follow 3-2-1 backup rule
5. **Secure access** - Use strong passphrases on SSH keys
6. **Update software** - Keep rclone and OpenSSH updated

## 📝 Requirements

### Windows System
- OS: Windows 10/11 or Server 2016+
- PowerShell: 5.1 or newer
- Disk Space: Sufficient for temporary backup storage

### Remote Server
- SSH server (OpenSSH or compatible)
- tar and gzip utilities
- Read access to website files
- Write access to /tmp directory

### Software Dependencies
- OpenSSH Client
- Rclone (with Google Drive configured)

## 🤝 Support

For issues, questions, or contributions:
1. Check [complete documentation](docs/backup-system.md)
2. Review troubleshooting section
3. Check script comments for inline help

## 📄 License

This project is provided as-is for backup automation purposes.

## ⚙️ Advanced Features

### Multiple Sites
Create separate scheduled tasks for different sites:
```powershell
.\Backup-Website.ps1 -SSHHost site1.com -RemotePath /var/www/site1 -GDriveRemote gdrive:backups/site1
.\Backup-Website.ps1 -SSHHost site2.com -RemotePath /var/www/site2 -GDriveRemote gdrive:backups/site2
```

### Email Notifications
Edit `Backup-Website.ps1` and uncomment email configuration in `Send-BackupNotification` function.

### Encrypted Backups
Use rclone crypt for encrypted backups:
```powershell
rclone config  # Create encrypted remote
.\Backup-Website.ps1 -GDriveRemote "encrypted:backups/website"
```

### Custom Retention
Edit `$BACKUP_RETENTION_COUNT` variable in script to change retention policy (default: 7 days).

## 📊 Script Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `SSHUser` | String | From config | SSH username |
| `SSHHost` | String | From config | SSH hostname/IP |
| `SSHPort` | Int | 22 | SSH port |
| `RemotePath` | String | From config | Remote directory path |
| `GDriveRemote` | String | From config | Google Drive destination |
| `DryRun` | Switch | False | Test mode (no changes) |
| `SkipRotation` | Switch | False | Skip deletion of old backups |
| `SkipConfirmation` | Switch | False | Skip config confirmation screen |
| `ForceSetup` | Switch | False | Force re-run of setup wizard |
| `NonInteractive` | Switch | False | Fail if not configured (for scheduled tasks) |

## 🎯 Exit Codes

- `0` - Success
- `1` - Failure (check logs for details)

## 📦 Backup File Format

Backups are named: `website-YYYYMMDD-HHMMSS.tar.gz`

Example: `website-20241123-143045.tar.gz`
- Date: November 23, 2024
- Time: 2:30:45 PM

## 🚦 Status Indicators

The script provides real-time status updates:
- Operation names and descriptions
- File sizes and transfer speeds
- Duration of each step
- Success/failure indicators
- Total execution time

## 🔄 Maintenance

### Weekly
- Review backup logs
- Verify completion status
- Check disk space

### Monthly
- Test backup restoration
- Review Google Drive storage
- Update software dependencies

### Quarterly
- Security audit
- Update SSH keys if needed
- Test disaster recovery

---

**Version:** 1.0.0  
**Last Updated:** November 23, 2024

For detailed documentation, see [docs/backup-system.md](docs/backup-system.md)



