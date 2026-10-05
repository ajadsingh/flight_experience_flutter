# Phase 1–4 implementation checklist

## Phase 1 — Reliability
- [x] GPS permission/service readiness handling
- [x] GPS accuracy quality classification
- [x] Stale GPS fix detection
- [x] Mock-location detection
- [x] GPS smoothing
- [x] Implausible GPS jump rejection
- [x] Route deviation and confidence metrics
- [x] Reduced GPS sensor churn for longer sessions
- [x] Automated analyze/test CI

## Phase 2 — Passenger intelligence
- [x] Airport-pair route catalog
- [x] Indexed offline POI search
- [x] “Below” nearest-place insight
- [x] “Ahead” bearing-aware insight
- [x] Nearby POI cards
- [x] Importance ranking for major landmarks

## Phase 3 — Offline experience
- [x] Persistent route-scoped tile cache
- [x] Offline-first tile provider
- [x] Corridor tile generation
- [x] Download progress
- [x] Download-size estimate
- [x] Resume by reusing existing tiles
- [x] Cancel/pause workflow
- [x] Retry through subsequent downloads
- [x] Delete route cache
- [x] Persisted cache manifest
- [x] Offline map manager UI

### Learning-mode limitation
The current implementation intentionally uses raster OSM tiles for learning/demo use. Before commercial distribution, replace bulk tile caching with a map/data source whose terms explicitly support the intended offline and commercial use.

## Phase 4 — Premium experience
- [x] Local flight history
- [x] Delete all local history
- [x] Flight replay
- [x] Recorded per-point telemetry
- [x] Altitude replay profile
- [x] Recenter aircraft
- [x] Follow-aircraft control
- [x] Better GPS/offline status badges
- [x] Location-purpose explanation before permission request
- [x] Production Android application ID

## Still required for a commercial release
- [ ] Production map/offline data licensing
- [ ] Production release signing/keystore
- [ ] Privacy policy and Play Store Data Safety declarations
- [ ] Physical-device testing across Android versions
- [ ] Long-flight battery/memory profiling
- [ ] Nationwide POI/data quality validation
- [ ] Crash/telemetry strategy
