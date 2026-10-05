# Production checklist

## Maps and offline
- Choose a commercial/appropriate map tile provider.
- Keep OSM attribution where required.
- Learning build: use route-scoped directory offline packs; production: replace with a licensed MBTiles/PMTiles dataset or equivalent offline provider.
- Learning build: generate route-specific POI packs from bundled data; expand source data for supported regions.
- Done for learning build: max tile guard, route storage accounting, pack delete action, failed-tile retry.

## GPS
- Add a smoothing/filtering layer for noisy cabin GPS.
- Display a data-quality indicator based on position accuracy.
- Handle `Position.timestamp`, mock locations and stale fixes.
- Keep passenger positioning clearly informational; do not market phone GPS as aircraft navigation.

## Privacy
- Ask only for foreground location.
- Explain why location is used.
- Flight history is local-only by default.
- Provide a delete-history action.

## Experience
- Airport pair selection is implemented.
- Route corridor generation and route-scoped offline packs are implemented.
- “What's below me?” and “What's ahead?” bearing-aware passenger intelligence is implemented.
- 3D-style replay perspective is implemented; true terrain elevation rendering remains a future renderer.
- Add accessibility labels and haptics.

## Release
- Test on Android physical devices in airplane mode with GPS enabled.
- Test weak GPS/no-fix behavior.
- Test long sessions for battery and memory.
- Replace demo route and sample POIs before production.
