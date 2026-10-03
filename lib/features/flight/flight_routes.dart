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
      GeoPoint(17.3850, 78.4867),
      GeoPoint(15.3173, 75.7139),
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
];
