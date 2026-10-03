# Production checklist

## Maps and offline
- Choose a commercial/appropriate map tile provider.
- Keep OSM attribution where required.
- Create real offline packs using a licensed MBTiles/PMTiles dataset.
- Add richer POIs for the countries/routes you support.
- Define a maximum offline pack size and device storage check.

## GPS
- Add a smoothing/filtering layer for noisy cabin GPS.
- Display a data-quality indicator based on position accuracy.
- Handle `Position.timestamp`, mock locations and stale fixes.
- Do not market phone GPS as aircraft navigation.

## Privacy
- Ask only for foreground location.
- Explain why location is used.
- Keep flight history local by default.
- Provide a delete-history action.

## Experience
- Add airport pair selection.
- Add route corridor generation.
- Add “What's below me?” and “What's ahead?” with bearing-aware selection.
- Add optional 3D terrain as a separate renderer.
- Add accessibility labels and haptics.

## Release
- Test on Android physical devices in airplane mode with GPS enabled.
- Test weak GPS/no-fix behavior.
- Test long sessions for battery and memory.
- Replace demo route and sample POIs before production.
