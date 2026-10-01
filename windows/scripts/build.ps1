$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
dotnet restore (Join-Path $root "PeekMemo.Windows.sln")
dotnet build (Join-Path $root "PeekMemo.Windows.sln") --configuration Release --no-restore
dotnet test (Join-Path $root "PeekMemo.Windows.sln") --configuration Release --no-build
