param(
  [string]$Target = "$PWD\flight_experience_app"
)

$ErrorActionPreference = 'Stop'
$Source = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter is not on PATH. Install Flutter and run this script again.'
}

if (Test-Path $Target) {
  $items = Get-ChildItem -Force $Target
  if ($items.Count -gt 0) {
    throw "Target exists and is not empty: $Target"
  }
} else {
  New-Item -ItemType Directory -Path $Target | Out-Null
}

flutter create --platforms=android --project-name flight_experience $Target

Copy-Item "$Source\pubspec.yaml" "$Target\pubspec.yaml" -Force
Copy-Item "$Source\analysis_options.yaml" "$Target\analysis_options.yaml" -Force
Remove-Item "$Target\lib" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$Target\assets" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$Target\test" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$Source\lib" "$Target\lib" -Recurse -Force
Copy-Item "$Source\assets" "$Target\assets" -Recurse -Force
Copy-Item "$Source\test" "$Target\test" -Recurse -Force
Copy-Item "$Source\README.md" "$Target\README.md" -Force

$manifest = Join-Path $Target 'android\app\src\main\AndroidManifest.xml'
$text = Get-Content $manifest -Raw
if ($text -notmatch 'android.permission.ACCESS_FINE_LOCATION') {
  $text = $text -replace '(?m)(<manifest[^>]*>)', '$1`r`n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`r`n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />'
  Set-Content -Path $manifest -Value $text -Encoding UTF8
}

Push-Location $Target
try {
  flutter pub get
} finally {
  Pop-Location
}

Write-Host "`nFlight Experience app created at: $Target"
Write-Host "Run: cd `"$Target`"; flutter analyze; flutter test; flutter run"
