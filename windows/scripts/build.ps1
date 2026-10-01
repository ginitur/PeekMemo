$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
dotnet restore (Join-Path $root "PeekMeow.Windows.sln")
dotnet build (Join-Path $root "PeekMeow.Windows.sln") --configuration Release --no-restore
dotnet test (Join-Path $root "PeekMeow.Windows.sln") --configuration Release --no-build
