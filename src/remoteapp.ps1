
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [string]$Alias,
    [string]$Exe,
    [string]$DisplayName
)

$ErrorActionPreference = "Stop"

function Show-Help {
    @"
remoteapp - RemoteApp command-line management

Usage:
  remoteapp publish -Alias <name> -Exe <path> [-DisplayName <name>]
  remoteapp --help
  remoteapp --version

Examples:
  remoteapp publish -Alias Notepad -Exe "C:\Windows\System32\notepad.exe"
  remoteapp publish -Alias MyApp -Exe "C:\Apps\MyApp.exe" -DisplayName "My App"

Run administrative commands in an elevated PowerShell session.
"@
}

function Publish-RemoteApp {
    param(
        [Parameter(Mandatory)]
        [string]$Alias,

        [Parameter(Mandatory)]
        [string]$Exe,

        [string]$DisplayName
    )

    if (-not [Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )) {
        throw "Administrator privileges are required. Run an elevated terminal."
    }

    if ($Alias -match '[\\/:*?"<>|]') {
        throw "Alias contains invalid registry key characters: $Alias"
    }

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = $Alias
    }

    $Exe = [Environment]::ExpandEnvironmentVariables($Exe)

    if (-not (Test-Path -LiteralPath $Exe -PathType Leaf)) {
        throw "Executable not found: $Exe"
    }

    $base = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications"
    $key = Join-Path $base $Alias

    $properties = @{
        Name               = $DisplayName
        Path               = $Exe
        VPath              = $Exe
        IconPath           = $Exe
        IconIndex          = 0
        CommandLineSetting = 1
        RequiredCommandLine = ""
        ShowInTSWA         = 0
    }

    New-Item -Path $key -Force | Out-Null

    foreach ($entry in $properties.GetEnumerator()) {
        $type = if ($entry.Key -in @(
            "IconIndex", "CommandLineSetting", "ShowInTSWA"
        )) {
            "DWord"
        } else {
            "String"
        }

        New-ItemProperty -Path $key `
            -Name $entry.Key `
            -Value $entry.Value `
            -PropertyType $type `
            -Force | Out-Null
    }

    Write-Host "RemoteApp published successfully: $DisplayName" `
        -ForegroundColor Green

    Get-ItemProperty -Path $key
}

try {
    switch ($Command.ToLowerInvariant()) {
        "publish" {
            if (-not $Alias -or -not $Exe) {
                throw "Usage: remoteapp publish -Alias <name> -Exe <path> [-DisplayName <name>]"
            }

            Publish-RemoteApp -Alias $Alias -Exe $Exe `
                -DisplayName $DisplayName
        }

        "--help" { Show-Help }
        "-h"     { Show-Help }
        "help"   { Show-Help }
        "--version" { Write-Output "remoteapp 0.1.0" }
        default  { throw "Unknown command: $Command. Run 'remoteapp --help'." }
    }
}
catch {
    [Console]::Error.WriteLine("Error: $($_.Exception.Message)")
    exit 1
}
