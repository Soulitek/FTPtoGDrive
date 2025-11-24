# Deployment Guide for Customers

## Overview

This guide helps you deploy the Website Backup System for your specific environment.

## 🚀 Quick Start (Recommended)

**NEW: Interactive Setup Mode!**

The easiest way to get started is to simply run the backup script:

```powershell
cd C:\Path\To\WebsiteBackup
.\Backup-Website.ps1
```

The script will automatically:
- ✅ Check for prerequisites (OpenSSH, Rclone)
- ✅ Guide installation if tools are missing
- ✅ Generate SSH keys if needed
- ✅ Help you add the key to your server
- ✅ Test the connection
- ✅ Discover your website directories
- ✅ Configure Google Drive
- ✅ Save all settings securely
- ✅ Optionally run your first backup

**Estimated time: 15-20 minutes**

### What You Need Before Starting

1. **SSH access to your web server** (username, hostname, port)
2. **Google account** for backup storage
3. **15-20 minutes** of your time

That's it! The interactive wizard handles the rest.

---

## 📚 Advanced: Manual Installation

If you prefer to install everything manually before running the script, or need more control, follow the detailed steps below.

## Pre-Deployment Planning

### 1. Identify Your Paths

**Important:** The backup system needs to know where your website files are located.

Common path structures:

**Cloudways:**
```
/home/master/applications/YOUR_APP_ID/public_html
```

**cPanel:**
```
/home/username/public_html
```

**Plesk:**
```
/var/www/vhosts/yourdomain.com/httpdocs
```

**Custom:**
```
/var/www/html
/usr/share/nginx/html
/opt/application/public
```

**How to find your path:**
```bash
# SSH to your server
ssh your_username@your-server.com

# Check current directory
pwd

# List your application directories
ls -la /home/your_username/applications/

# Find your website files
find /home -name "index.html" -o -name "index.php" 2>/dev/null
```

### 2. Determine Backup Storage Location

The backup file (`backup.tgz`) should be stored separately from the files being backed up.

**Recommended structure:**
```
/home/user/applications/YOUR_APP/
├── public_html/          ← Website files (BACKUP THIS)
├── private_html/
├── logs/
└── local_backups/        ← Store backup.tgz HERE
```

**Key point:** The `local_backups` directory should be at the same level as (sibling to) your website directory, NOT inside it.

### 3. Configuration Values You'll Need

Before running setup, gather:

| Information | Example | Your Value |
|------------|---------|------------|
| SSH Username | `master_app123` | `___________` |
| SSH Hostname/IP | `your-server.com` | `___________` |
| SSH Port | `22` (default) | `___________` |
| Website Path | `/home/master/applications/app123/public_html` | `___________` |
| Google Drive Path | `gdrive:backups/website` | `___________` |

## Deployment Steps

### Step 1: Download and Extract

1. Download the backup system files
2. Extract to a permanent location:
   ```powershell
   # Recommended location
   C:\Scripts\WebsiteBackup\
   ```

### Step 2: Install Prerequisites

#### A. OpenSSH Client

```powershell
# Check if installed
ssh -V

# Install if needed (Run as Administrator)
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

#### B. Rclone

1. Download from [rclone.org/downloads](https://rclone.org/downloads/)
2. Extract to `C:\Program Files\rclone`
3. Add to system PATH:
   ```powershell
   # Run as Administrator
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\rclone", "Machine")
   ```
4. Verify:
   ```powershell
   rclone version
   ```

### Step 3: Generate SSH Key

```powershell
# Generate 4096-bit RSA key
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa"

# When prompted:
# - Enter passphrase (recommended) or press Enter for no passphrase
# - Confirm passphrase
```

### Step 4: Add SSH Key to Server

```powershell
# Navigate to backup system directory
cd C:\Scripts\WebsiteBackup

# Use helper script
.\Add-SSHKeyToServer.ps1 -SSHUser YOUR_USERNAME -SSHHost YOUR_SERVER

# You'll be prompted for your password ONCE
# After this, SSH will be passwordless
```

**Verify it works:**
```powershell
ssh -p 22 YOUR_USERNAME@YOUR_SERVER 'echo "Success!"'
# Should NOT ask for password
```

## Using the Interactive Setup

### First Run Experience

When you run `.\Backup-Website.ps1` for the first time, you'll see:

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

Prerequisites that will be checked:
  • OpenSSH Client
  • Rclone (for Google Drive)
  • SSH key pair

Ready to begin? [Y/n]:
```

Just answer the prompts! The wizard will:

1. **Check Prerequisites** - Verify OpenSSH and Rclone are installed
2. **SSH Key Setup** - Generate keys if needed and show you how to add to server
3. **Server Connection** - Collect and test SSH details
4. **Path Discovery** - Find your website directories automatically
5. **Google Drive** - Launch rclone config and create backup folders
6. **Save Configuration** - Store everything securely
7. **First Backup** - Optionally run your first backup immediately

### Subsequent Runs

After setup, running the script shows:

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
  [Q] Quit

Choice [1]:
```

Just press Enter to run the backup!

### Reconfiguring

Need to change settings? Options:
- Select option 2 when running the script
- Or force setup wizard: `.\Backup-Website.ps1 -ForceSetup`

### Automated/Scheduled Runs

For Task Scheduler, use:
```powershell
.\Backup-Website.ps1 -NonInteractive
```

This skips all prompts and fails if configuration is missing (ensuring automated tasks don't hang).

---

## 📚 Advanced: Manual Installation Steps

### Step 1: Download and Extract

1. Download the backup system files
2. Extract to a permanent location:
   ```powershell
   # Recommended location
   C:\Scripts\WebsiteBackup\
   ```

### Step 2: Install Prerequisites

#### A. OpenSSH Client

```powershell
# Check if installed
ssh -V

# Install if needed (Run as Administrator)
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

#### B. Rclone

1. Download from [rclone.org/downloads](https://rclone.org/downloads/)
2. Extract to `C:\Program Files\rclone`
3. Add to system PATH:
   ```powershell
   # Run as Administrator
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\rclone", "Machine")
   ```
4. Verify:
   ```powershell
   rclone version
   ```

### Step 3: Generate SSH Key

```powershell
# Generate 4096-bit RSA key
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa"

# When prompted:
# - Enter passphrase (recommended) or press Enter for no passphrase
# - Confirm passphrase
```

### Step 4: Add SSH Key to Server

```powershell
# Navigate to backup system directory
cd C:\Scripts\WebsiteBackup

# Use helper script
.\Add-SSHKeyToServer.ps1 -SSHUser YOUR_USERNAME -SSHHost YOUR_SERVER

# You'll be prompted for your password ONCE
# After this, SSH will be passwordless
```

**Verify it works:**
```powershell
ssh -p 22 YOUR_USERNAME@YOUR_SERVER 'echo "Success!"'
# Should NOT ask for password
```

### Step 5: Configure Rclone for Google Drive

```powershell
rclone config
```

Follow these prompts:
```
n) New remote
name> gdrive
Storage> 15 (Google Drive - number may vary)
client_id> (press Enter)
client_secret> (press Enter)
scope> 1 (Full access)
root_folder_id> (press Enter)
service_account_file> (press Enter)
Edit advanced config? n
Use auto config? y
(Browser will open - sign in to Google)
Configure this as a team drive? n
y) Yes this is OK
q) Quit config
```

**Test it:**
```powershell
rclone lsd gdrive:
# Should list your Google Drive folders
```

### Step 6: Create Google Drive Backup Folder

```powershell
rclone mkdir gdrive:backups
rclone mkdir gdrive:backups/website
```

### Step 7: Run Setup Wizard

```powershell
cd C:\Scripts\WebsiteBackup
.\Setup-BackupCredentials.ps1
```

**You'll be prompted for:**
1. SSH username
2. SSH hostname/IP
3. SSH port (22 is default)
4. Remote path to website files (e.g., `/home/master/applications/YOUR_APP/public_html`)
5. Google Drive remote path (e.g., `gdrive:backups/website`)

The script will:
- Test SSH connection
- Verify the remote path exists
- Test rclone connectivity
- Save configuration securely

### Step 8: Test the Backup

#### Dry-Run Test (Recommended First)
```powershell
.\Backup-Website.ps1 -DryRun
```

This simulates the backup without making changes. Review the output for any issues.

#### First Real Backup
```powershell
.\Backup-Website.ps1
```

**What should happen:**
1. SSH connection test ✓
2. Create archive on server (~30-120 seconds depending on size)
3. Download archive to local machine
4. Upload to Google Drive (time varies by size and speed)
5. Rotate old backups (keep last 7)
6. Cleanup temporary files
7. Display summary

**Check the results:**
```powershell
# View log
Get-Content "C:\Logs\website-backup\backup-$(Get-Date -Format 'yyyyMMdd').log"

# Check Google Drive
rclone ls gdrive:backups/website
```

### Step 9: Schedule Automatic Backups

#### Option A: PowerShell Command (Recommended)

```powershell
# Run this in PowerShell (as Administrator)
$scriptPath = "C:\Scripts\WebsiteBackup\Backup-Website.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "Website Backup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
```

#### Option B: Task Scheduler GUI

1. Open Task Scheduler (`taskschd.msc`)
2. Create Task (not Basic Task)
3. **General tab:**
   - Name: Website Backup
   - Run whether user is logged on or not
   - Run with highest privileges
4. **Triggers tab:**
   - New → Daily at 2:00 AM
5. **Actions tab:**
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\Scripts\WebsiteBackup\Backup-Website.ps1"`
6. **Conditions tab:**
   - Uncheck "Start only if on AC power"
7. **Settings tab:**
   - Run task as soon as possible after missed start
   - If task fails, restart every 10 minutes (3 attempts)

**Test the scheduled task:**
```powershell
Start-ScheduledTask -TaskName "Website Backup"
Get-ScheduledTask -TaskName "Website Backup" | Get-ScheduledTaskInfo
```

## Customization

### Change Backup Schedule

Edit the trigger in Task Scheduler or re-run the PowerShell command with different time:
```powershell
$trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
# ... rest of command
```

### Change Backup Retention

Edit `Backup-Website.ps1`, line 97:
```powershell
$BACKUP_RETENTION_COUNT = 14  # Keep 14 days instead of 7
```

### Backup Multiple Sites

Create separate scheduled tasks for each site:
```powershell
.\Backup-Website.ps1 `
    -SSHHost site1.com `
    -RemotePath /var/www/site1 `
    -GDriveRemote "gdrive:backups/site1"
```

## Troubleshooting

### "SSH connection failed"
- Verify SSH key is configured: `ssh -p 22 user@host 'echo test'`
- Check firewall allows SSH
- Verify username and hostname are correct

### "Remote path not found"
- SSH to server and verify path: `ssh user@host 'ls -la /your/path'`
- Check permissions: `ssh user@host 'test -r /your/path && echo OK'`

### "Rclone remote not found"
- List remotes: `rclone listremotes`
- Reconfigure if needed: `rclone config`

### "Upload failed"
- Check Google Drive quota: `rclone about gdrive:`
- Test connectivity: `rclone lsd gdrive:backups/website`
- Re-authenticate if needed: `rclone config reconnect gdrive:`

### Small backup file (< 1MB)
- Verify correct path is being backed up
- Check directory isn't empty: `ssh user@host 'du -sh /your/path'`

## Support

### Log Files
All operations are logged to:
```
C:\Logs\website-backup\backup-YYYYMMDD.log
```

### Common Commands
```powershell
# View today's log
Get-Content "C:\Logs\website-backup\backup-$(Get-Date -Format 'yyyyMMdd').log"

# Check configuration
Get-ItemProperty -Path "HKCU:\Software\WebsiteBackup"

# Test SSH
ssh -p 22 user@host 'whoami && pwd'

# List Google Drive backups
rclone ls gdrive:backups/website

# Manual backup
.\Backup-Website.ps1

# Dry-run test
.\Backup-Website.ps1 -DryRun
```

## Security Checklist

- [ ] SSH key authentication configured (no password prompts)
- [ ] SSH keys have proper permissions
- [ ] 2FA enabled on Google account
- [ ] Backup logs are reviewed regularly
- [ ] Test restoration performed at least once
- [ ] Scheduled task is running successfully
- [ ] Firewall configured appropriately

## Maintenance

### Weekly
- Review backup logs for errors
- Verify backups completing successfully

### Monthly
- Test backup restoration
- Review Google Drive storage usage
- Check scheduled task status

### Quarterly
- Update rclone if new version available
- Review and update documentation
- Security audit (see SECURITY.md)

---

**Need Help?** See:
- `README.md` - Quick start guide
- `docs/backup-system.md` - Complete documentation
- `docs/ssh-key-setup.md` - SSH setup details
- `SECURITY.md` - Security best practices

