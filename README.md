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
- Persistent corridor tile cache stored in the app support directory
- Automatic route tile preparation with progress reporting
- Offline-first tile provider: cached tiles are loaded from local storage before network
- Optional licensed satellite tile source via --dart-define
- OpenStreetMap attribution for the street-map layer

## Offline behavior

The app is designed around a simple passenger workflow:

1. While online, select the route and let the corridor cache finish.
2. Start the Flight Experience.
3. During the flight, GPS continues to update the aircraft marker and breadcrumb trail.
4. Cached map tiles and bundled POIs remain available without internet access.

The offline cache covers zoom levels 6–10 around the planned corridor, using sampled route points plus a one-tile buffer. This keeps the download practical for a phone instead of attempting to cache an entire region.

## Important limitations

1. GPS-only mode does not know the airline's real flight plan. The planned corridor is an app estimate; the solid trail is the observed phone GPS path.
2. Phone GPS position, speed and altitude can be degraded inside an aircraft cabin and should not be treated as aviation-navigation data.
3. The included POI dataset is intentionally small for the MVP.
4. The default street map URL points to OpenStreetMap's public tile service. Bulk/offline downloading should only be used in accordance with the tile provider's usage policy. For production, use a provider/data source that explicitly permits offline caching or ship a licensed offline map pack.
5. Satellite imagery is disabled by default. To enable it, provide a licensed provider URL and its required attribution at build time.
6. Background tracking while the app is fully suspended is not enabled in this MVP. The flight screen is designed to remain active.
7. This repository contains the Flutter source pack and generated Android project. The bootstrap scripts can recreate an Android project from the source on a machine with Flutter installed.

## Run

    flutter pub get
    flutter analyze
    flutter test
    flutter run

## Android location permissions

The Android manifest includes foreground and background location permissions. For the current MVP, foreground location is the primary requirement; background tracking is not implemented.

## Satellite provider configuration

Do not ship an unlicensed satellite endpoint. Example:

    flutter run --dart-define=SATELLITE_TILE_URL="https://your-provider/{z}/{y}/{x}.jpg" --dart-define=SATELLITE_ATTRIBUTION="© Your Provider"

## Bootstrap a fresh Android project

On Windows PowerShell:

    .\bootstrap.ps1 -Target .\flight_experience_app

On macOS/Linux:

    ./bootstrap.sh ./flight_experience_app

The bootstrap script runs flutter create --platforms=android, copies the source and assets, adds location permissions, and runs flutter pub get.

## Suggested production next steps

- Replace route tile downloads with a licensed MBTiles/PMTiles/offline map pack.
- Expand the airport and POI datasets for nationwide coverage.
- Add GPS accuracy indicators and smoothing for noisy cabin fixes.
- Add an explicit Delete flight history privacy control.
- Add a foreground service only after validating Android battery behavior.