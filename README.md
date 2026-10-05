# Flight Experience — Flutter Android MVP

A passenger-focused Android application that turns a flight into an interactive location experience without requiring a flight-data API.

## What is implemented

- Flutter / Dart app with Material 3 and Riverpod
- GPS mode using geolocator
- Demo flight mode: Ahmedabad → Udaipur → Jaipur → Delhi
- Moving aircraft marker
- Actual GPS breadcrumb trail
- Estimated route corridor
- Altitude, speed and heading HUD
- Nearby POIs from a bundled offline JSON dataset
- Route-scoped offline map packs stored in the app support directory
- Automatic route map + POI pack preparation with progress reporting
- Offline-first tile provider: route-scoped cached tiles are loaded from local storage before network
- Optional licensed satellite tile source via --dart-define
- Local flight history with automatic save and replay
- OpenStreetMap attribution for the street-map layer

## Offline behavior

The app is designed around a simple passenger workflow:

1. While online, select the route and tap `Prepare Offline Pack`.
2. Start the Flight Experience.
3. During the flight, GPS continues to update the aircraft marker and breadcrumb trail.
4. Route-scoped cached map tiles and the prepared POI pack remain available without internet access.
5. Completed sessions are saved locally and can be replayed with play/pause, timeline scrubbing, and a 3D-style perspective view.

The learning-build offline pack covers zoom levels 6–10 around the planned corridor, uses sampled route points plus a one-tile buffer, stores a versioned manifest, and writes a route-specific POI pack beside the tiles.

## Important limitations

1. GPS-only mode does not know the airline's real flight plan. The planned corridor is an app estimate; the solid trail is the observed phone GPS path.
2. Phone GPS position, speed and altitude can be degraded inside an aircraft cabin and should not be treated as aviation-navigation data.
3. The included POI dataset is intentionally small for the MVP.
4. The learning build uses a directory-based raster tile pack. Bulk/offline downloading should only be used in accordance with the tile provider's usage policy. For production, replace this adapter with a licensed offline map pack such as an appropriate MBTiles/PMTiles-based dataset.
5. Satellite imagery is disabled by default. To enable it, provide a licensed provider URL and its required attribution at build time.
6. Background tracking while the app is fully suspended is not enabled in this MVP. The flight screen is designed to remain active.
7. This repository contains the Flutter source pack and generated Android project. The bootstrap scripts can recreate an Android project from the source on a machine with Flutter installed.

## Run

    flutter pub get
    flutter analyze
    flutter test
    flutter run

## Android location permissions

The Android manifest requests foreground location. Background tracking is not implemented in this build.

## Satellite provider configuration

Do not ship an unlicensed satellite endpoint. Example:

    flutter run --dart-define=SATELLITE_TILE_URL="https://your-provider/{z}/{y}/{x}.jpg" --dart-define=SATELLITE_ATTRIBUTION="© Your Provider"

## Bootstrap a fresh Android project

On Windows PowerShell:

    .\bootstrap.ps1 -Target .\flight_experience_app

On macOS/Linux:

    ./bootstrap.sh ./flight_experience_app

The bootstrap script runs flutter create --platforms=android, copies the source and assets, adds location permissions, and runs flutter pub get.

## Offline pack management

The Home screen includes route-specific pack status, storage size, retry feedback, and delete controls. During a flight, the Offline Only button disables network fallback for map tiles; missing tiles are rendered as placeholders instead of attempting network access.

## Android release artifacts

GitHub Actions now runs analyze/tests and builds a release APK and AAB artifact when a `v*` tag is pushed or the workflow is manually dispatched. The current learning Android project still uses the debug signing config in `android/app/build.gradle.kts`; production distribution requires a real keystore and GitHub secrets before publishing.

## Suggested production next steps

- Replace route tile downloads with a licensed MBTiles/PMTiles/offline map pack.
- Expand the airport and POI datasets for nationwide coverage.
- Add GPS accuracy indicators and smoothing for noisy cabin fixes.
- Add a foreground service only after validating Android battery behavior.