# install-windows.ps1
# Configures Claude Desktop with in-app AWS SSO. Run as Administrator / SYSTEM.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Resolve-Path (Join-Path $ScriptDir "..\config")
$Tpl       = Join-Path $ConfigDir "claude-desktop-config.json"

# IT must edit these or pass as env vars before deployment
$SSO_START_URL   = if ($env:SSO_START_URL)   { $env:SSO_START_URL }   else { "https://d-1234567890.awsapps.com/start" }
$SSO_REGION      = if ($env:SSO_REGION)      { $env:SSO_REGION }      else { "us-east-1" }
$ACCOUNT_ID      = if ($env:ACCOUNT_ID)      { $env:ACCOUNT_ID }      else { "123456789012" }
$ROLE_NAME       = if ($env:ROLE_NAME)       { $env:ROLE_NAME }       else { "BedrockInference" }
# Auto-generate one UUID per install run; override by setting $env:DEPLOYMENT_UUID.
$DEPLOYMENT_UUID = if ($env:DEPLOYMENT_UUID) { $env:DEPLOYMENT_UUID } else { [guid]::NewGuid().ToString().ToUpper() }

Write-Host "[claude-desktop-deploy] Windows install — in-app SSO mode"

Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Public","Default","Default User","All Users","WDAGUtilityAccount")
} | ForEach-Object {
    $UserHome    = $_.FullName
    $UserName    = $_.Name
    $DesktopDir  = Join-Path $UserHome "AppData\Roaming\Claude"
    $DesktopFile = Join-Path $DesktopDir "inference-config.json"

    Write-Host "  -> user: $UserName"
    New-Item -ItemType Directory -Force -Path $DesktopDir | Out-Null

    $content = (Get-Content $Tpl -Raw) `
        -replace '\{\{SSO_START_URL\}\}',   $SSO_START_URL `
        -replace '\{\{SSO_REGION\}\}',      $SSO_REGION `
        -replace '\{\{ACCOUNT_ID\}\}',      $ACCOUNT_ID `
        -replace '\{\{ROLE_NAME\}\}',       $ROLE_NAME `
        -replace '\{\{DEPLOYMENT_UUID\}\}', $DEPLOYMENT_UUID

    Set-Content -Path $DesktopFile -Value $content -Encoding UTF8
    Write-Host "     wrote $DesktopFile"
}

Write-Host "[claude-desktop-deploy] Done."
Write-Host "Users: open Claude -> Settings -> Connection -> click 'Sign in with AWS SSO'."
