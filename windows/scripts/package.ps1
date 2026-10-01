# Publishes a self-contained unpackaged Release build. No MSIX, no signing, no Store.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $root
$version = (Get-Content (Join-Path $repo "VERSION") -Raw).Trim()
$dist = Join-Path $root "dist"
$out = Join-Path $dist "PeekMemo-Windows-x64"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
dotnet publish (Join-Path $root "src\PeekMemo.Windows\PeekMemo.Windows.csproj") `
    --configuration Release `
    --runtime win-x64 `
    --self-contained true `
    --output $out
if (-not (Test-Path (Join-Path $out "PeekMemo.exe"))) {
    throw "PeekMemo.exe was not published."
}
$forbidden = Get-ChildItem $out -Recurse -File | Where-Object {
    $_.Name -eq "settings.json" -or $_.Extension -in ".sqlite", ".sqlite-shm", ".sqlite-wal"
}
if ($forbidden) {
    throw "The package contains user data: $($forbidden.Name -join ', ')"
}
Compress-Archive -Path (Join-Path $out "*") -DestinationPath (Join-Path $dist "PeekMemo-Windows-x64.zip")
Compress-Archive -Path (Join-Path $out "*") -DestinationPath (Join-Path $dist "PeekMemo-Windows-x64-$version.zip")
Write-Host "Published to $out"
