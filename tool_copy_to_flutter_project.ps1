param(
  [Parameter(Mandatory=$true)]
  [string]$Target
)

$Source = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $Target)) { throw "Target does not exist: $Target" }

Copy-Item "$Source\pubspec.yaml" "$Target\pubspec.yaml" -Force
Copy-Item "$Source\analysis_options.yaml" "$Target\analysis_options.yaml" -Force
Copy-Item "$Source\lib" "$Target\lib" -Recurse -Force
Copy-Item "$Source\assets" "$Target\assets" -Recurse -Force
Copy-Item "$Source\test" "$Target\test" -Recurse -Force
Copy-Item "$Source\README.md" "$Target\README.md" -Force
Write-Host "Copied Flight Experience source into $Target"
Write-Host "Next: add the Android permissions from README.md, then run: flutter pub get; flutter analyze; flutter test"
