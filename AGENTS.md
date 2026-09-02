# KNN Commute

Flutter app for trip planning in Malaysia (Klang Valley). Compares transit vs driving using Google Directions API (primary) and GTFS static/realtime feeds from data.gov.my (fallback).

## Commands

| Command | Purpose |
|---------|---------|
| `flutter run` | Run on connected device |
| `dart run build_runner build --delete-conflicting-outputs` | Regenerate `.g.dart` files after editing `@JsonSerializable` models |
| `flutter analyze` | Lint + static analysis (uses `flutter_lints`) |

There are **no tests** yet (`test/` dir is empty). No CI config exists.

## Architecture

- **State management**: `provider` via `MultiProvider` in `lib/main.dart:24` — services as `Provider`, state as `ChangeNotifierProvider<TripProvider>`
- **Services** (injected, not singletons): `GTFSService`, `WeatherService`, `FuelPriceService`, `GoogleMapsService`, `NativePlacesService`, `LocationService`
- **Routing**: Named routes via `AppRoutes` constants + `onGenerateRoute`. ~8 routes are placeholders ("Coming Soon")
- **Barrel exports**: every directory has a `{dir}.dart` that re-exports all files — import the barrel, not individual files
- **Models**: `@JsonSerializable` with `fieldRename: FieldRename.snake` — requires `dart run build_runner build` after changes

## API & Config

- Google Maps API key is **hardcoded** in `lib/utils/constants.dart:63` (TODO says move to `--dart-define` — not done yet)
- GTFS agencies: `ktmb` (trains), `prasarana?category=rapid-bus-kl` (buses), `prasarana?category=rapid-bus-mrtfeeder` (feeder buses)
- `rapid-rail-kl` (LRT/MRT/Monorail) has **no stable realtime feeds** as of 2026
- Transit routing priority: Google Directions API → GTFS static parsing
- Realtime vehicle polling: every 30s on the ComparisonPage
- A helper Python script `test_transit.py` tests the Directions API independently (not part of the Flutter app)

## Quirks

- Running `build_runner` after model changes is mandatory (missing `.g.dart` = compilation error)
- Distance Matrix API does **not** return toll costs; `tolls` defaults to `0.0` in `DistanceMatrix`
- `flutter_polyline_points` is used only for polyline decoding in `GoogleMapsService._parseRoute`
- `http` client is injectable in every service constructor for testing — but no tests use this yet
