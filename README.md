# Flight Experience — Flutter Android MVP

A passenger-focused Android application that turns a flight into an interactive location experience without requiring a flight-data API.

## What is implemented

- Flutter 3.47+ / Dart 3.9+
- Material 3 UI
- Riverpod state management
- GPS mode using `geolocator`
- Demo flight mode: Ahmedabad → Udaipur → Jaipur → Delhi (app-estimated demo corridor)
- Moving aircraft marker
- Actual GPS breadcrumb trail
- Estimated route corridor
- Altitude, speed and heading HUD
- Nearby POIs from a bundled offline JSON dataset
- “What's below / nearby” panel
- Optional licensed satellite tile source via `--dart-define`
- Map attribution for OpenStreetMap tiles

## Current scope / honest limitations

1. GPS-only mode does not know the airline's real flight plan. The pre-flight corridor is an app estimate and the solid trail is the observed device GPS path.
2. The phone's GPS is not an aircraft navigation instrument. Position, speed and altitude can be degraded in a cabin.
3. The included POI dataset is intentionally small for the MVP. Replace it with a licensed/open geographic dataset for nationwide coverage.
4. Street map tiles use OpenStreetMap's public tile endpoint for development/demo use. For production, use a map tile provider and comply with its terms and attribution requirements.
5. Satellite mode is intentionally configurable and disabled until you provide a licensed satellite tile URL. Example:
   `flutter run --dart-define=SATELLITE_TILE_URL=https://your-provider/{z}/{x}/{y}.jpg`
6. Background tracking while the app is fully suspended is not enabled in this MVP. The flight screen is designed to remain active.

## Create a runnable Android project

The source pack intentionally lets your installed Flutter SDK generate the Android/Gradle boilerplate, which keeps the platform layer aligned with your local Flutter toolchain.

On Windows PowerShell:

```powershell
.\bootstrap.ps1 -Target .\flight_experience_app
```

On macOS/Linux:

```bash
./bootstrap.sh ./flight_experience_app
```

The bootstrap script runs `flutter create`, copies the app source, adds foreground Android location permissions, and runs `flutter pub get`.

## Android location permission

Add the following to `android/app/src/main/AndroidManifest.xml` directly under `<manifest ...>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

For this MVP, foreground location is sufficient.

## Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Satellite provider configuration

Do not ship an unlicensed satellite tile endpoint. Supply a provider URL at build/run time:

```bash
flutter run --dart-define=SATELLITE_TILE_URL="https://provider.example/{z}/{x}/{y}.jpg"
```

The app switches from street to satellite only when that value exists.

## Suggested production next steps

- Replace sample POIs with a structured offline pack (MBTiles/PMTiles + local POI index).
- Add route corridor packs per airport pair.
- Add a local airport database and richer “What's below me?” classifications.
- Add aircraft bearing smoothing / Kalman filtering for noisy phone GPS.
- Add optional online reverse geocoding only when the user explicitly enables it.
- Add a true 3D terrain view as a separate module.
- Add background/foreground service handling for longer flights after validating Android battery behavior.
- Add privacy controls and a one-tap “Delete flight history” option before release.
