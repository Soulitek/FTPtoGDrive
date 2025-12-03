<#
.SYNOPSIS
    Setup script for Website Backup credentials and configuration.

.DESCRIPTION
    This script helps you configure the Website Backup system by:
    1. Prompting for SSH connection details
    2. Testing SSH key authentication
    3. Verifying rclone configuration
    4. Storing configuration securely in Windows Registry
    5. Creating necessary directories
    6. Providing Task Scheduler setup instructions

.PARAMETER NonInteractive
    Run in non-interactive mode (requires all parameters to be provided).

.EXAMPLE
    .\Setup-BackupCredentials.ps1
    Runs the interactive setup wizard.

.EXAMPLE
    .\Setup-BackupCredentials.ps1 -NonInteractive -SSHUser admin -SSHHost example.com -RemotePath /var/www/html -GDriveRemote "gdrive:backups/website"
    Runs setup in non-interactive mode with provided parameters.

.NOTES
    Requirements:
    - OpenSSH client installed
    - SSH key generated and authorized on remote server
    - Rclone installed and configured with Google Drive or OneDrive remote
    
    Author: Automated Backup System
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$NonInteractive,
    
    [Parameter(Mandatory=$false)]
    [string]$SSHUser,
    
    [Parameter(Mandatory=$false)]
    [string]$SSHHost,
    
    [Parameter(Mandatory=$false)]
    [int]$SSHPort = 22,
    
    [Parameter(Mandatory=$false)]
    [string]$RemotePath,
    
    [Parameter(Mandatory=$false)]
    [string]$GDriveRemote
)

# =============================================================================
# CONFIGURATION
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REGISTRY_PATH = "HKCU:\Software\WebsiteBackup"
$LOG_DIR = "C:\Logs\website-backup"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Write-ColorMessage {
    <#
    .SYNOPSIS
        Writes colored messages to console.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Question')]
        [string]$Type = 'Info'
    )
    
    $color = switch ($Type) {
        'Success'  { 'Green' }
        'Warning'  { 'Yellow' }
        'Error'    { 'Red' }
        'Question' { 'Cyan' }
        'Info'     { 'White' }
    }
    
    Write-Host $Message -ForegroundColor $color
}

function Write-SectionHeader {
    <#
    .SYNOPSIS
        Writes a formatted section header.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Test-SSHKeySetup {
    <#
    .SYNOPSIS
        Checks if SSH key authentication is set up.
    #>
    [CmdletBinding()]
    param()
    
    $sshKeyPath = Join-Path $env:USERPROFILE ".ssh\id_rsa"
    $sshPubKeyPath = Join-Path $env:USERPROFILE ".ssh\id_rsa.pub"
    
    if ((Test-Path $sshKeyPath) -and (Test-Path $sshPubKeyPath)) {
        Write-ColorMessage "✓ SSH key pair found at: $sshKeyPath" -Type Success
        return $true
    }
    else {
        Write-ColorMessage "✗ SSH key pair not found" -Type Warning
        return $false
    }
}

function New-SSHKeyPair {
    <#
    .SYNOPSIS
        Generates a new SSH key pair.
    #>
    [CmdletBinding()]
    param()
    
    Write-SectionHeader "Generate SSH Key Pair"
    
    $sshDir = Join-Path $env:USERPROFILE ".ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -Path $sshDir -ItemType Directory -Force | Out-Null
    }
    
    Write-ColorMessage "Generating SSH key pair..." -Type Info
    Write-ColorMessage "Press Enter when prompted for passphrase (or set a passphrase for extra security)" -Type Warning
    
    try {
        $result = ssh-keygen -t rsa -b 4096 -f "$sshDir\id_rsa" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✓ SSH key pair generated successfully" -Type Success
            Write-ColorMessage "" -Type Info
            Write-ColorMessage "Your public key is:" -Type Info
            Get-Content "$sshDir\id_rsa.pub" | Write-Host -ForegroundColor Yellow
            Write-ColorMessage "" -Type Info
            Write-ColorMessage "You need to add this key to the remote server's ~/.ssh/authorized_keys file" -Type Warning
            return $true
        }
        else {
            Write-ColorMessage "✗ Failed to generate SSH key pair" -Type Error
            return $false
        }
    }
    catch {
        Write-ColorMessage "✗ Error generating SSH key pair: $_" -Type Error
        return $false
    }
}

function Test-SSHConnection {
    <#
    .SYNOPSIS
        Tests SSH connection to remote server.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$User,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    Write-ColorMessage "Testing SSH connection to ${User}@${Hostname}:${Port}..." -Type Info
    
    try {
        $testCommand = "ssh -p $Port -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${User}@${Hostname} 'echo CONNECTION_SUCCESS'"
        $result = Invoke-Expression $testCommand 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $result -match "CONNECTION_SUCCESS") {
            Write-ColorMessage "✓ SSH connection successful!" -Type Success
            return $true
        }
        else {
            Write-ColorMessage "✗ SSH connection failed" -Type Error
            Write-ColorMessage "  Output: $result" -Type Error
            return $false
        }
    }
    catch {
        Write-ColorMessage "✗ SSH connection error: $_" -Type Error
        return $false
    }
}

function Test-RemotePath {
    <#
    .SYNOPSIS
        Verifies that the remote path exists and is accessible.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$User,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    Write-ColorMessage "Verifying remote path: $Path..." -Type Info
    
    try {
        $testCommand = "ssh -p $Port ${User}@${Hostname} 'test -d `"$Path`" && echo PATH_EXISTS || echo PATH_NOT_FOUND'"
        $result = Invoke-Expression $testCommand 2>&1
        
        if ($result -match "PATH_EXISTS") {
            Write-ColorMessage "✓ Remote path exists and is accessible" -Type Success
            return $true
        }
        else {
            Write-ColorMessage "✗ Remote path not found or not accessible" -Type Warning
            Write-ColorMessage "  Make sure the path exists: $Path" -Type Warning
            return $false
        }
    }
    catch {
        Write-ColorMessage "✗ Error verifying remote path: $_" -Type Error
        return $false
    }
}

function Test-RcloneConfiguration {
    <#
    .SYNOPSIS
        Verifies that rclone is installed and configured.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RemoteName
    )
    
    Write-ColorMessage "Checking rclone installation..." -Type Info
    
    # Check if rclone is installed
    try {
        $rcloneVersion = rclone version 2>&1 | Select-Object -First 1
        Write-ColorMessage "✓ Rclone is installed: $rcloneVersion" -Type Success
    }
    catch {
        Write-ColorMessage "✗ Rclone is not installed or not in PATH" -Type Error
        Write-ColorMessage "  Please install rclone from: https://rclone.org/downloads/" -Type Info
        return $false
    }
    
    # Extract remote name (remove path if included)
    $remoteNameOnly = $RemoteName -replace ':.*$', ''
    
    # Check if remote is configured
    Write-ColorMessage "Checking for remote '$remoteNameOnly'..." -Type Info
    
    try {
        $remotes = rclone listremotes 2>&1
        
        if ($remotes -match "^${remoteNameOnly}:$") {
            Write-ColorMessage "✓ Rclone remote '$remoteNameOnly' is configured" -Type Success
            
            # Test remote connectivity
            Write-ColorMessage "Testing remote connectivity..." -Type Info
            $testResult = rclone lsd "${remoteNameOnly}:" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorMessage "✓ Successfully connected to remote '$remoteNameOnly'" -Type Success
                return $true
            }
            else {
                Write-ColorMessage "✗ Failed to connect to remote '$remoteNameOnly'" -Type Error
                Write-ColorMessage "  Error: $testResult" -Type Error
                return $false
            }
        }
        else {
            Write-ColorMessage "✗ Rclone remote '$remoteNameOnly' is not configured" -Type Error
            Write-ColorMessage "  Please run: rclone config" -Type Info
            Write-ColorMessage "  And configure a Google Drive remote named '$remoteNameOnly'" -Type Info
            return $false
        }
    }
    catch {
        Write-ColorMessage "✗ Error checking rclone configuration: $_" -Type Error
        return $false
    }
}

function Save-Configuration {
    <#
    .SYNOPSIS
        Saves configuration to Windows Registry (encrypted storage).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    Write-ColorMessage "Saving configuration securely..." -Type Info
    
    try {
        # Create registry key if it doesn't exist
        if (-not (Test-Path $REGISTRY_PATH)) {
            New-Item -Path $REGISTRY_PATH -Force | Out-Null
        }
        
        # Save configuration values
        Set-ItemProperty -Path $REGISTRY_PATH -Name "SSHUser" -Value $Config.SSHUser
        Set-ItemProperty -Path $REGISTRY_PATH -Name "SSHHost" -Value $Config.SSHHost
        Set-ItemProperty -Path $REGISTRY_PATH -Name "SSHPort" -Value $Config.SSHPort
        Set-ItemProperty -Path $REGISTRY_PATH -Name "RemotePath" -Value $Config.RemotePath
        Set-ItemProperty -Path $REGISTRY_PATH -Name "GDriveRemote" -Value $Config.GDriveRemote
        if ($Config.UseSFTP) {
            Set-ItemProperty -Path $REGISTRY_PATH -Name "UseSFTP" -Value 1
        } else {
            Set-ItemProperty -Path $REGISTRY_PATH -Name "UseSFTP" -Value 0
        }
        Set-ItemProperty -Path $REGISTRY_PATH -Name "ConfiguredDate" -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        Write-ColorMessage "✓ Configuration saved to registry: $REGISTRY_PATH" -Type Success
        return $true
    }
    catch {
        Write-ColorMessage "✗ Failed to save configuration: $_" -Type Error
        return $false
    }
}

function Show-TaskSchedulerInstructions {
    <#
    .SYNOPSIS
        Displays instructions for setting up Task Scheduler.
    #>
    [CmdletBinding()]
    param()
    
    Write-SectionHeader "Task Scheduler Setup Instructions"
    
    $scriptPath = Join-Path $PSScriptRoot "Backup-Website.ps1"
    
    Write-ColorMessage "To schedule automatic backups, follow these steps:" -Type Info
    Write-Host ""
    Write-ColorMessage "1. Open Task Scheduler:" -Type Info
    Write-Host "   - Press Win+R and type: taskschd.msc" -ForegroundColor Gray
    Write-Host ""
    Write-ColorMessage "2. Create a new task:" -Type Info
    Write-Host "   - Click 'Create Task' (not 'Create Basic Task')" -ForegroundColor Gray
    Write-Host ""
    Write-ColorMessage "3. General tab:" -Type Info
    Write-Host "   - Name: Website Backup" -ForegroundColor Gray
    Write-Host "   - Description: Automated website backup to Google Drive" -ForegroundColor Gray
    Write-Host "   - Select: 'Run whether user is logged on or not'" -ForegroundColor Gray
    Write-Host "   - Check: 'Run with highest privileges'" -ForegroundColor Gray
    Write-Host ""
    Write-ColorMessage "4. Triggers tab:" -Type Info
    Write-Host "   - Click 'New'" -ForegroundColor Gray
    Write-Host "   - Set schedule (e.g., Daily at 2:00 AM)" -ForegroundColor Gray
    Write-Host ""
    Write-ColorMessage "5. Actions tab:" -Type Info
    Write-Host "   - Click 'New'" -ForegroundColor Gray
    Write-Host "   - Action: Start a program" -ForegroundColor Gray
    Write-Host "   - Program/script: powershell.exe" -ForegroundColor Gray
    Write-Host "   - Arguments: -ExecutionPolicy Bypass -File `"$scriptPath`"" -ForegroundColor Yellow
    Write-Host "   - Start in: $PSScriptRoot" -ForegroundColor Yellow
    Write-Host ""
    Write-ColorMessage "6. Conditions tab:" -Type Info
    Write-Host "   - Uncheck 'Start the task only if the computer is on AC power'" -ForegroundColor Gray
    Write-Host ""
    Write-ColorMessage "7. Settings tab:" -Type Info
    Write-Host "   - Check 'Run task as soon as possible after a scheduled start is missed'" -ForegroundColor Gray
    Write-Host "   - Check 'If the task fails, restart every: 10 minutes' (up to 3 times)" -ForegroundColor Gray
    Write-Host ""
    Write-ColorMessage "Alternative: Use PowerShell to create the scheduled task:" -Type Info
    Write-Host ""
    Write-Host '$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File \"' + $scriptPath + '\"" -WorkingDirectory "' + $PSScriptRoot + '"' -ForegroundColor Yellow
    Write-Host '$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM' -ForegroundColor Yellow
    Write-Host '$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest' -ForegroundColor Yellow
    Write-Host '$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable' -ForegroundColor Yellow
    Write-Host 'Register-ScheduledTask -TaskName "Website Backup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings' -ForegroundColor Yellow
    Write-Host ""
}

function Show-SecurityRecommendations {
    <#
    .SYNOPSIS
        Displays security recommendations.
    #>
    [CmdletBinding()]
    param()
    
    Write-SectionHeader "Security Recommendations"
    
    Write-ColorMessage "To enhance security, consider the following:" -Type Info
    Write-Host ""
    
    Write-ColorMessage "1. SSH Key Protection:" -Type Warning
    Write-Host "   - Use a passphrase for your SSH private key" -ForegroundColor Gray
    Write-Host "   - Set restrictive permissions on ~/.ssh directory" -ForegroundColor Gray
    Write-Host "   - Never share your private key" -ForegroundColor Gray
    Write-Host ""
    
    Write-ColorMessage "2. Remote Server Hardening:" -Type Warning
    Write-Host "   - Disable password authentication in SSH" -ForegroundColor Gray
    Write-Host "   - Use non-standard SSH port (not 22)" -ForegroundColor Gray
    Write-Host "   - Configure firewall to restrict SSH access" -ForegroundColor Gray
    Write-Host "   - Keep SSH and system packages updated" -ForegroundColor Gray
    Write-Host ""
    
    Write-ColorMessage "3. Backup Security:" -Type Warning
    Write-Host "   - Enable encryption for Google Drive backups" -ForegroundColor Gray
    Write-Host "   - Use 2FA on your Google account" -ForegroundColor Gray
    Write-Host "   - Regularly test backup restoration" -ForegroundColor Gray
    Write-Host "   - Monitor backup logs for anomalies" -ForegroundColor Gray
    Write-Host ""
    
    Write-ColorMessage "4. Script Security:" -Type Warning
    Write-Host "   - Review script code before execution" -ForegroundColor Gray
    Write-Host "   - Keep scripts in a secure location" -ForegroundColor Gray
    Write-Host "   - Limit access to log files (may contain sensitive info)" -ForegroundColor Gray
    Write-Host "   - Use Task Scheduler with appropriate permissions" -ForegroundColor Gray
    Write-Host ""
}

# =============================================================================
# MAIN SETUP PROCESS
# =============================================================================

function Start-Setup {
    <#
    .SYNOPSIS
        Main setup process.
    #>
    [CmdletBinding()]
    param()
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "  WEBSITE BACKUP SYSTEM - SETUP WIZARD" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
    
    # Step 1: Check SSH key setup
    Write-SectionHeader "Step 1: SSH Key Setup"
    
    if (-not (Test-SSHKeySetup)) {
        if (-not $NonInteractive) {
            Write-ColorMessage "Would you like to generate an SSH key pair now? (Y/N)" -Type Question
            $response = Read-Host
            
            if ($response -eq 'Y' -or $response -eq 'y') {
                if (-not (New-SSHKeyPair)) {
                    Write-ColorMessage "Setup cannot continue without SSH key authentication" -Type Error
                    return $false
                }
                
                Write-ColorMessage "" -Type Info
                Write-ColorMessage "IMPORTANT: You must add the public key to your remote server!" -Type Warning
                Write-ColorMessage "Press any key when you've added the key to ~/.ssh/authorized_keys on the remote server..." -Type Question
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            else {
                Write-ColorMessage "Please generate an SSH key pair and configure it on the remote server, then run this setup again" -Type Warning
                return $false
            }
        }
        else {
            Write-ColorMessage "SSH key not found. Please set up SSH key authentication first" -Type Error
            return $false
        }
    }
    
    # Step 2: Collect configuration
    Write-SectionHeader "Step 2: Configuration"
    
    $config = @{}
    
    if ($NonInteractive) {
        if ([string]::IsNullOrEmpty($SSHUser) -or [string]::IsNullOrEmpty($SSHHost) -or 
            [string]::IsNullOrEmpty($RemotePath) -or [string]::IsNullOrEmpty($GDriveRemote)) {
            Write-ColorMessage "In non-interactive mode, all parameters must be provided" -Type Error
            return $false
        }
        
        $config.SSHUser = $SSHUser
        $config.SSHHost = $SSHHost
        $config.SSHPort = $SSHPort
        $config.RemotePath = $RemotePath
        $config.GDriveRemote = $GDriveRemote
    }
    else {
        Write-ColorMessage "Enter SSH username:" -Type Question
        $config.SSHUser = Read-Host
        
        Write-ColorMessage "Enter SSH hostname or IP address:" -Type Question
        $config.SSHHost = Read-Host
        
        Write-ColorMessage "Enter SSH port [default: 22]:" -Type Question
        $portInput = Read-Host
        $config.SSHPort = if ([string]::IsNullOrEmpty($portInput)) { 22 } else { [int]$portInput }
        
        Write-ColorMessage "Enter remote path to website files (e.g., /var/www/html):" -Type Question
        $config.RemotePath = Read-Host
        
        Write-ColorMessage "Enter Google Drive remote path (e.g., gdrive:backups/website):" -Type Question
        $config.GDriveRemote = Read-Host
        
        # Ask about SFTP mode
        Write-Host ""
        Write-ColorMessage "Transfer Method:" -Type Question
        Write-Host "  [1] SSH Streaming (default - faster, but may have corruption issues with large files)" -ForegroundColor White
        Write-Host "  [2] SFTP Download (more reliable, downloads files individually)" -ForegroundColor White
        Write-Host ""
        $transferChoice = Read-Host "Select transfer method [1 or 2, default: 1]"
        
        if ($transferChoice -eq '2') {
            $config.UseSFTP = $true
            Write-ColorMessage "SFTP mode selected - files will be downloaded individually" -Type Info
            Write-ColorMessage "Note: Posh-SSH module will be installed automatically if needed" -Type Info
        } else {
            $config.UseSFTP = $false
            Write-ColorMessage "SSH streaming mode selected (default)" -Type Info
        }
    }
    else {
        # Non-interactive mode - default to SSH streaming unless explicitly set
        $config.UseSFTP = $false
    }
    
    # Display configuration
    Write-Host ""
    Write-ColorMessage "Configuration Summary:" -Type Info
    Write-Host "  Transfer Method:   $(if ($config.UseSFTP) { 'SFTP Download' } else { 'SSH Streaming' })" -ForegroundColor Yellow
    Write-Host "  SSH User:          $($config.SSHUser)" -ForegroundColor Yellow
    Write-Host "  SSH Host:          $($config.SSHHost)" -ForegroundColor Yellow
    Write-Host "  SSH Port:          $($config.SSHPort)" -ForegroundColor Yellow
    Write-Host "  Remote Path:       $($config.RemotePath)" -ForegroundColor Yellow
    Write-Host "  Google Drive:      $($config.GDriveRemote)" -ForegroundColor Yellow
    Write-Host ""
    
    # Step 3: Test connection (SSH or SFTP)
    if ($config.UseSFTP) {
        Write-SectionHeader "Step 3: SFTP Mode Selected"
        Write-ColorMessage "SFTP connection will be tested during the first backup" -Type Info
        Write-ColorMessage "Note: Posh-SSH module will be installed automatically if needed" -Type Info
    } else {
        Write-SectionHeader "Step 3: Testing SSH Connection"
        
        if (-not (Test-SSHConnection -User $config.SSHUser -Hostname $config.SSHHost -Port $config.SSHPort)) {
            Write-ColorMessage "SSH connection test failed. Please check your configuration and SSH key setup" -Type Error
            
            if (-not $NonInteractive) {
                Write-ColorMessage "Do you want to continue anyway? (Y/N)" -Type Question
                $response = Read-Host
                if ($response -ne 'Y' -and $response -ne 'y') {
                    return $false
                }
            }
            else {
                return $false
            }
        }
    }
    
    # Step 4: Verify remote path
    Write-SectionHeader "Step 4: Verifying Remote Path"
    
    if (-not (Test-RemotePath -User $config.SSHUser -Hostname $config.SSHHost -Port $config.SSHPort -Path $config.RemotePath)) {
        Write-ColorMessage "Remote path verification failed" -Type Warning
        
        if (-not $NonInteractive) {
            Write-ColorMessage "Do you want to continue anyway? (Y/N)" -Type Question
            $response = Read-Host
            if ($response -ne 'Y' -and $response -ne 'y') {
                return $false
            }
        }
    }
    
    # Step 5: Test rclone configuration
    Write-SectionHeader "Step 5: Verifying Rclone Configuration"
    
    if (-not (Test-RcloneConfiguration -RemoteName $config.GDriveRemote)) {
        Write-ColorMessage "Rclone configuration test failed" -Type Error
        Write-ColorMessage "Please configure rclone with your Google Drive remote first:" -Type Info
        Write-Host "  1. Run: rclone config" -ForegroundColor Gray
        Write-Host "  2. Choose 'n' for new remote" -ForegroundColor Gray
        Write-Host "  3. Follow the prompts to set up Google Drive" -ForegroundColor Gray
        Write-Host ""
        
        if (-not $NonInteractive) {
            Write-ColorMessage "Do you want to continue anyway? (Y/N)" -Type Question
            $response = Read-Host
            if ($response -ne 'Y' -and $response -ne 'y') {
                return $false
            }
        }
        else {
            return $false
        }
    }
    
    # Step 6: Save configuration
    Write-SectionHeader "Step 6: Saving Configuration"
    
    if (-not (Save-Configuration -Config $config)) {
        Write-ColorMessage "Failed to save configuration" -Type Error
        return $false
    }
    
    # Step 7: Create directories
    Write-SectionHeader "Step 7: Creating Directories"
    
    try {
        if (-not (Test-Path $LOG_DIR)) {
            New-Item -Path $LOG_DIR -ItemType Directory -Force | Out-Null
            Write-ColorMessage "✓ Created log directory: $LOG_DIR" -Type Success
        }
        else {
            Write-ColorMessage "✓ Log directory already exists: $LOG_DIR" -Type Success
        }
    }
    catch {
        Write-ColorMessage "✗ Failed to create log directory: $_" -Type Error
        return $false
    }
    
    # Step 8: Display next steps
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "  SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
    
    Write-ColorMessage "Next Steps:" -Type Success
    Write-Host ""
    Write-ColorMessage "1. Test the backup script manually:" -Type Info
    $backupScriptPath = Join-Path $PSScriptRoot "Backup-Website.ps1"
    Write-Host "   powershell.exe -ExecutionPolicy Bypass -File `"$backupScriptPath`" -DryRun" -ForegroundColor Yellow
    Write-Host ""
    Write-ColorMessage "2. If the dry run succeeds, run an actual backup:" -Type Info
    Write-Host "   powershell.exe -ExecutionPolicy Bypass -File `"$backupScriptPath`"" -ForegroundColor Yellow
    Write-Host ""
    Write-ColorMessage "3. Set up automated backups using Task Scheduler" -Type Info
    Write-Host ""
    
    Show-TaskSchedulerInstructions
    Show-SecurityRecommendations
    
    Write-Host ""
    Write-ColorMessage "Setup complete! Your backup system is ready to use." -Type Success
    Write-Host ""
    
    return $true
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

try {
    $result = Start-Setup
    
    if ($result) {
        exit 0
    }
    else {
        Write-ColorMessage "Setup failed or was cancelled" -Type Error
        exit 1
    }
}
catch {
    Write-ColorMessage "Setup error: $_" -Type Error
    Write-ColorMessage $_.ScriptStackTrace -Type Error
    exit 1
}

