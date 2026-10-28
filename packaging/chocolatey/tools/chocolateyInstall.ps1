
$ErrorActionPreference = 'Stop'

$installDir = Join-Path $env:ProgramData 'remoteapp-cli'

$packageTools = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Create a stable installation directory.
New-Item -ItemType Directory -Path $installDir -Force |
    Out-Null

# Install the CLI files.
Copy-Item `
    -Path (Join-Path $packageTools 'remoteapp.ps1') `
    -Destination (Join-Path $installDir 'remoteapp.ps1') `
    -Force

Copy-Item `
    -Path (Join-Path $packageTools 'remoteapp.cmd') `
    -Destination (Join-Path $installDir 'remoteapp.cmd') `
    -Force

# Add the installation directory to the machine PATH.
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$pathEntries = @($machinePath -split ';' | Where-Object { $_ })

if ($pathEntries -notcontains $installDir) {
    $newPath = (@($pathEntries) + $installDir) -join ';'

    [Environment]::SetEnvironmentVariable(
        'Path',
        $newPath,
        'Machine'
    )
}

Write-Host "remoteapp CLI installed to $installDir"
Write-Host "Open a new terminal to use the remoteapp command."
