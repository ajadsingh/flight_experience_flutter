import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/flight_state.dart';
import '../../core/models/gps_status.dart';
import '../../core/models/flight_record.dart';
import '../../core/models/geo_point.dart';
import '../flight/widgets/flight_map.dart';
import '../../shared/utils/formatters.dart';

class FlightReplayScreen extends StatefulWidget {
  const FlightReplayScreen({super.key, required this.record});

  final FlightRecord record;

  @override
  State<FlightReplayScreen> createState() => _FlightReplayScreenState();
}

class _FlightReplayScreenState extends State<FlightReplayScreen> {
  Timer? _timer;
  int _index = 0;
  bool _playing = false;

  int get _lastIndex => widget.record.track.length - 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    if (widget.record.track.length < 2) return;

    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }

    setState(() => _playing = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (_index >= _lastIndex) {
        _timer?.cancel();
        if (mounted) {
          setState(() => _playing = false);
        }
        return;
      }
      setState(() => _index++);
    });
  }

  void _seek(double value) {
    if (_lastIndex < 0) return;
    setState(() => _index = value.round().clamp(0, _lastIndex));
  }

  FlightState _state() {
    final route = widget.record.toRoute();
    final track = widget.record.track;
    final position = track.isEmpty
        ? route.start
        : track[_index.clamp(0, track.length - 1)];

    var heading = 0.0;
    if (_index + 1 < track.length) {
      heading = GeoPoint.bearingDegrees(track[_index], track[_index + 1]);
    } else if (_index > 0) {
      heading = GeoPoint.bearingDegrees(track[_index - 1], track[_index]);
    }

    final progress =
        track.length <= 1 ? 0.0 : _index / (track.length - 1);

    return FlightState(
      mode: FlightMode.demo,
      route: route,
      started: _playing,
      currentPosition: position,
      track: List.unmodifiable(track.take(_index + 1)),
      progress: progress,
      speedKmh: widget.record.maxSpeedKmh,
      altitudeFt: widget.record.maxAltitudeFt,
      heading: heading,
      nearby: const [],
      below: null,
      ahead: null,
      elapsed: widget.record.duration,
      mapLayer: MapLayer.street,
      message: 'Flight replay',
      gpsAvailable: false,
      gpsQuality: GpsQuality.noFix,
      gpsAccuracyM: 0,
      lastFixAt: null,
      isMockLocation: false,
      routeDeviationKm: 0,
      routeConfidence: 1,
      satelliteAvailable: false,
      mapDownloadProgress: 0,
      isMapDownloading: false,
      isMapOfflineReady: false,
      downloadedTiles: 0,
      totalTiles: 0,
      downloadedBytes: 0,
      failedTiles: 0,
      mapDownloadCancelled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state();
    final routeName =
        widget.record.originCode + ' → ' + widget.record.destinationCode;

    return Scaffold(
      appBar: AppBar(title: Text(routeName + ' Replay')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Stat(label: 'Distance', value: widget.record.distanceKm.toStringAsFixed(0) + ' km'),
                _Stat(label: 'Max speed', value: widget.record.maxSpeedKmh.toStringAsFixed(0) + ' km/h'),
                _Stat(label: 'Max altitude', value: widget.record.maxAltitudeFt.toStringAsFixed(0) + ' ft'),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: FlightMap(state: state)),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Column(
                        children: [
                          Slider(
                            min: 0,
                            max: _lastIndex > 0 ? _lastIndex.toDouble() : 1,
                            value: _lastIndex > 0 ? _index.toDouble() : 0,
                            onChanged: _lastIndex > 0 ? _seek : null,
                          ),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                tooltip: _playing ? 'Pause replay' : 'Play replay',
                                onPressed: _togglePlayback,
                                icon: Icon(
                                  _playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  durationLabel(widget.record.duration) +
                                      '  •  Point ' +
                                      (_index + 1).toString() +
                                      ' / ' +
                                      widget.record.track.length.toString(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.analytics_outlined, size: 16),
      label: Text(label + ': ' + value),
    );
  }
}
