# Publishes an unpackaged Release build. No MSIX, no signing, no Store.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "dist"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
dotnet publish (Join-Path $root "src\PeekMemo.Windows\PeekMemo.Windows.csproj") `
    --configuration Release `
    --output $out
Write-Host "Published to $out"
