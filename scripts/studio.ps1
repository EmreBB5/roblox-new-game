# Run on the Windows computer that has Roblox Studio installed.
# Downloads are pinned to official Rojo 7.7.1 release SHA-256 digests.
[CmdletBinding()]
param(
    [switch]$SetupOnly,
    [string]$PluginDirectory = (Join-Path $env:LOCALAPPDATA 'Roblox\Plugins')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Run this helper on your Windows computer with Roblox Studio.' }
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ToolsRoot = Join-Path $RepoRoot '.tools\rojo\7.7.1'
$ReleaseRoot = 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.1'
$CliDigest = 'd4dfa3493a1613a43fc87312d6dac660d7c8bf38e6a99aa5dcd0d26154ba0b82'
$PluginDigest = '50a8d83db87deab4d65fd6100eb74396de232355b1ae89c641035d02c49db6f4'
New-Item -ItemType Directory -Force -Path $ToolsRoot | Out-Null
# Keep certificate validation enabled; Windows PowerShell needs TLS 1.2 for GitHub.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Get-VerifiedArtifact {
    param([string]$Name, [string]$Digest)
    $Destination = Join-Path $ToolsRoot $Name
    if (Test-Path -LiteralPath $Destination) {
        if ((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -eq $Digest) { return $Destination }
        throw "Checksum mismatch for cached $Name. Remove only '$Destination' and retry."
    }
    $Temporary = Join-Path $ToolsRoot ([Guid]::NewGuid().ToString() + '.download')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$ReleaseRoot/$Name" -OutFile $Temporary
        if ((Get-FileHash -LiteralPath $Temporary -Algorithm SHA256).Hash -ne $Digest) {
            throw "Checksum mismatch for $Name; refusing to install."
        }
        Move-Item -LiteralPath $Temporary -Destination $Destination
    } finally {
        if (Test-Path -LiteralPath $Temporary) { Remove-Item -LiteralPath $Temporary }
    }
    return $Destination
}

$ArchivePath = Get-VerifiedArtifact 'rojo-7.7.1-windows-x86_64.zip' $CliDigest
$PluginSource = Get-VerifiedArtifact 'Rojo.rbxm' $PluginDigest
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
try {
    $Entries = @($Archive.Entries | Where-Object { $_.Name -eq 'rojo.exe' })
    if ($Entries.Count -ne 1) { throw 'Expected exactly one rojo.exe in the verified archive.' }
    $Stream = $Entries[0].Open()
    $Memory = New-Object IO.MemoryStream
    try { $Stream.CopyTo($Memory); $ExecutableBytes = $Memory.ToArray() }
    finally { $Stream.Dispose(); $Memory.Dispose() }
} finally { $Archive.Dispose() }
$Executable = Join-Path $ToolsRoot 'rojo.exe'
# Keep an identical executable in place, including while another Rojo is running.
$Hasher = [Security.Cryptography.SHA256]::Create()
try { $ExpectedExecutableHash = [BitConverter]::ToString($Hasher.ComputeHash($ExecutableBytes)).Replace('-', '') }
finally { $Hasher.Dispose() }
if (-not (Test-Path -LiteralPath $Executable) -or (Get-FileHash -LiteralPath $Executable -Algorithm SHA256).Hash -ne $ExpectedExecutableHash) {
    [IO.File]::WriteAllBytes($Executable, $ExecutableBytes)
}
$Version = (& $Executable --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $Version -ne 'Rojo 7.7.1') { throw "Unexpected Rojo version: $Version" }

# `rojo plugin install` overwrites existing files. Install the release plugin
# explicitly instead, refusing to replace a different installed Rojo.rbxm.
$PluginDirectory = [IO.Path]::GetFullPath($PluginDirectory)
$PluginTarget = Join-Path $PluginDirectory 'Rojo.rbxm'
if (Test-Path -LiteralPath $PluginTarget) {
    if ((Get-FileHash -LiteralPath $PluginTarget -Algorithm SHA256).Hash -ne $PluginDigest) {
        throw "A different Rojo plugin already exists at '$PluginTarget'. Close Studio, move that file to a backup outside the Plugins folder, then retry. No plugin was overwritten."
    }
    Write-Host 'Rojo 7.7.1 plugin already installed and verified.'
} else {
    New-Item -ItemType Directory -Force -Path $PluginDirectory | Out-Null
    # Copy completely before an atomic, non-overwriting move into the plugin path.
    $PluginTemporary = Join-Path $PluginDirectory ([Guid]::NewGuid().ToString() + '.tmp')
    try {
        [IO.File]::Copy($PluginSource, $PluginTemporary, $false)
        [IO.File]::Move($PluginTemporary, $PluginTarget)
    } finally {
        if (Test-Path -LiteralPath $PluginTemporary) { Remove-Item -LiteralPath $PluginTemporary }
    }
    Write-Host "Installed Rojo 7.7.1 plugin into $PluginDirectory. Restart Studio to load it."
}
if ($SetupOnly) { Write-Host 'Setup complete. No repository sources were changed.'; return }
Write-Host 'In Roblox Studio, open the Rojo plugin and connect to localhost:34872.'
Write-Host 'Keep this terminal running. Press Ctrl+C to stop syncing.'
Push-Location $RepoRoot
try {
    & $Executable serve default.project.json --address 127.0.0.1 --port 34872
    if ($LASTEXITCODE -ne 0) { throw "Rojo serve exited with code $LASTEXITCODE." }
} finally { Pop-Location }
