<#
.SYNOPSIS
    Adds your SSH public key to the remote server's authorized_keys file.

.DESCRIPTION
    This script helps you add your SSH public key to the remote server
    to enable passwordless SSH authentication.

.PARAMETER SSHUser
    Remote server username.

.PARAMETER SSHHost
    Remote server hostname or IP address.

.PARAMETER SSHPort
    SSH port number. Default is 22.

.PARAMETER PublicKeyPath
    Path to your public key file. Default is ~/.ssh/id_rsa.pub

.EXAMPLE
    .\Add-SSHKeyToServer.ps1 -SSHUser your_username -SSHHost your-server.com

.EXAMPLE
    .\Add-SSHKeyToServer.ps1 -SSHUser your_username -SSHHost your-server.com -SSHPort 22
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SSHUser,
    
    [Parameter(Mandatory=$true)]
    [string]$SSHHost,
    
    [Parameter(Mandatory=$false)]
    [int]$SSHPort = 22,
    
    [Parameter(Mandatory=$false)]
    [string]$PublicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
)

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  SSH Key Setup - Add Public Key to Remote Server" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if public key file exists
if (-not (Test-Path $PublicKeyPath)) {
    Write-Host "Error: Public key file not found: $PublicKeyPath" -ForegroundColor Red
    Write-Host "Please generate an SSH key first:" -ForegroundColor Yellow
    Write-Host "  ssh-keygen -t rsa -b 4096 -f `"$env:USERPROFILE\.ssh\id_rsa`"" -ForegroundColor Gray
    exit 1
}

# Read the public key
$publicKey = Get-Content $PublicKeyPath -Raw
$publicKey = $publicKey.Trim()

if ([string]::IsNullOrEmpty($publicKey)) {
    Write-Host "Error: Public key file is empty: $PublicKeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "Public key found:" -ForegroundColor Green
Write-Host $publicKey -ForegroundColor Gray
Write-Host ""

# Test SSH connection first
Write-Host "Testing SSH connection..." -ForegroundColor Cyan
$testResult = ssh -p $SSHPort -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${SSHUser}@${SSHHost}" 'echo "Connection test successful"' 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: SSH connection test failed. You may need to enter your password." -ForegroundColor Yellow
    Write-Host "Continuing anyway..." -ForegroundColor Yellow
    Write-Host ""
}

# Method 1: Try using ssh-copy-id (if available)
Write-Host "Attempting to add key using ssh-copy-id..." -ForegroundColor Cyan
$copyIdResult = ssh-copy-id -p $SSHPort "${SSHUser}@${SSHHost}" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success! Key added using ssh-copy-id." -ForegroundColor Green
    Write-Host ""
    Write-Host "Testing passwordless SSH..." -ForegroundColor Cyan
    $testResult = ssh -p $SSHPort -o ConnectTimeout=10 "${SSHUser}@${SSHHost}" 'echo "Passwordless SSH works!"' 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS! Passwordless SSH is now configured." -ForegroundColor Green
        exit 0
    }
}
else {
    Write-Host "ssh-copy-id not available or failed. Using manual method..." -ForegroundColor Yellow
    Write-Host ""
}

# Method 2: Manual method
Write-Host "Using manual method to add key..." -ForegroundColor Cyan
Write-Host ""

# Create the command to add the key
$addKeyCommand = @"
mkdir -p ~/.ssh && chmod 700 ~/.ssh && 
if ! grep -Fxq '$publicKey' ~/.ssh/authorized_keys 2>/dev/null; then
    echo '$publicKey' >> ~/.ssh/authorized_keys && 
    chmod 600 ~/.ssh/authorized_keys && 
    echo 'KEY_ADDED'
else
    echo 'KEY_EXISTS'
fi
"@

Write-Host "Adding public key to remote server..." -ForegroundColor Cyan
Write-Host "You may be prompted for your password." -ForegroundColor Yellow
Write-Host ""

$result = ssh -p $SSHPort "${SSHUser}@${SSHHost}" $addKeyCommand 2>&1

if ($LASTEXITCODE -eq 0) {
    if ($result -match "KEY_ADDED") {
        Write-Host "SUCCESS! Public key added to remote server." -ForegroundColor Green
    }
    elseif ($result -match "KEY_EXISTS") {
        Write-Host "Key already exists on remote server." -ForegroundColor Yellow
    }
    else {
        Write-Host "Warning: Could not verify if key was added. Output:" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Gray
    }
}
else {
    Write-Host "Error: Failed to add key. Output:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Gray
    Write-Host ""
    Write-Host "You can manually add the key by:" -ForegroundColor Yellow
    Write-Host "1. SSH to the server: ssh -p $SSHPort ${SSHUser}@${SSHHost}" -ForegroundColor Gray
    Write-Host "2. Run these commands:" -ForegroundColor Gray
    Write-Host "   mkdir -p ~/.ssh" -ForegroundColor Gray
    Write-Host "   chmod 700 ~/.ssh" -ForegroundColor Gray
    Write-Host "   nano ~/.ssh/authorized_keys" -ForegroundColor Gray
    Write-Host "3. Paste this key and save:" -ForegroundColor Gray
    Write-Host $publicKey -ForegroundColor Cyan
    Write-Host "4. Set permissions: chmod 600 ~/.ssh/authorized_keys" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Testing passwordless SSH connection..." -ForegroundColor Cyan
$testResult = ssh -p $SSHPort -o ConnectTimeout=10 "${SSHUser}@${SSHHost}" 'echo "Passwordless SSH test successful"' 2>&1

if ($LASTEXITCODE -eq 0 -and $testResult -match "Passwordless SSH test successful") {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "  SUCCESS! Passwordless SSH is now configured!" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run the backup script without password prompts." -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "Warning: Passwordless SSH test failed." -ForegroundColor Yellow
    Write-Host "You may still be prompted for a password." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Verify the key was added: ssh -p $SSHPort ${SSHUser}@${SSHHost} 'cat ~/.ssh/authorized_keys'" -ForegroundColor Gray
    Write-Host "2. Check file permissions on server:" -ForegroundColor Gray
    Write-Host "   ssh -p $SSHPort ${SSHUser}@${SSHHost} 'ls -la ~/.ssh/'" -ForegroundColor Gray
    Write-Host "3. Check SSH server configuration allows key authentication" -ForegroundColor Gray
    Write-Host ""
}

