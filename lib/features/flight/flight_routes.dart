import '../../core/models/flight_route.dart';
import '../../core/models/geo_point.dart';

const demoRoutes = <FlightRoute>[
  FlightRoute(
    id: 'amd-del-demo',
    flightNumber: 'FX 482',
    origin: 'Ahmedabad',
    originCode: 'AMD',
    destination: 'Delhi',
    destinationCode: 'DEL',
    waypoints: [
      GeoPoint(23.0720, 72.6260),
      GeoPoint(24.5854, 73.7125),
      GeoPoint(26.9124, 75.7873),
      GeoPoint(28.6139, 77.2090),
    ],
  ),
  FlightRoute(
    id: 'bom-blr-demo',
    flightNumber: 'FX 201',
    origin: 'Mumbai',
    originCode: 'BOM',
    destination: 'Bengaluru',
    destinationCode: 'BLR',
    waypoints: [
      GeoPoint(19.0896, 72.8656),
      GeoPoint(18.5204, 73.8567),
      GeoPoint(16.5000, 76.0000),
      GeoPoint(12.9716, 77.5946),
    ],
  ),
  FlightRoute(
    id: 'del-ccu-demo',
    flightNumber: 'FX 317',
    origin: 'Delhi',
    originCode: 'DEL',
    destination: 'Kolkata',
    destinationCode: 'CCU',
    waypoints: [
      GeoPoint(28.6139, 77.2090),
      GeoPoint(27.1767, 78.0081),
      GeoPoint(25.3176, 82.9739),
      GeoPoint(22.5726, 88.3639),
    ],
  ),
  FlightRoute(
    id: 'amd-bom-demo',
    flightNumber: 'FX 108',
    origin: 'Ahmedabad',
    originCode: 'AMD',
    destination: 'Mumbai',
    destinationCode: 'BOM',
    waypoints: [
      GeoPoint(23.0720, 72.6260),
      GeoPoint(22.3072, 73.1812),
      GeoPoint(21.1702, 72.8311),
      GeoPoint(19.0896, 72.8656),
    ],
  ),
  FlightRoute(
    id: 'del-bom-demo',
    flightNumber: 'FX 221',
    origin: 'Delhi',
    originCode: 'DEL',
    destination: 'Mumbai',
    destinationCode: 'BOM',
    waypoints: [
      GeoPoint(28.6139, 77.2090),
      GeoPoint(26.9124, 75.7873),
      GeoPoint(24.0000, 74.8000),
      GeoPoint(19.0896, 72.8656),
    ],
  ),
  FlightRoute(
    id: 'hyd-del-demo',
    flightNumber: 'FX 512',
    origin: 'Hyderabad',
    originCode: 'HYD',
    destination: 'Delhi',
    destinationCode: 'DEL',
    waypoints: [
      GeoPoint(17.2403, 78.4294),
      GeoPoint(20.3170, 78.3660),
      GeoPoint(24.0000, 79.0000),
      GeoPoint(28.6139, 77.2090),
    ],
  ),
];
