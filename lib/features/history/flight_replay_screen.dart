import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/flight_record.dart';
import '../../core/models/flight_sample.dart';
import '../../core/models/flight_state.dart';
import '../../core/models/gps_status.dart';
import '../../shared/utils/formatters.dart';
import '../flight/widgets/flight_map.dart';

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

  late final List<FlightSample> _samples;

  @override
  void initState() {
    super.initState();
    if (widget.record.samples.isNotEmpty) {
      _samples = widget.record.samples;
    } else {
      _samples = widget.record.track
          .map(
            (point) => FlightSample(
              position: point,
              timestamp: widget.record.startedAt,
              speedKmh: widget.record.maxSpeedKmh,
              altitudeFt: widget.record.maxAltitudeFt,
              heading: 0,
              accuracyM: 0,
            ),
          )
          .toList(growable: false);
    }
  }

  int get _lastIndex => _samples.length - 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    if (_samples.length < 2) return;

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
    setState(() => _index = value.round().clamp(0, _lastIndex).toInt());
  }

  FlightState _state() {
    final route = widget.record.toRoute();
    final track = _samples.map((sample) => sample.position).toList();
    final sample = _samples.isEmpty
        ? null
        : _samples[_index.clamp(0, _lastIndex)];

    var heading = sample?.heading ?? 0;
    if (sample != null && heading <= 0 && _index + 1 < _samples.length) {
      heading = GeoPoint.bearingDegrees(
        sample.position,
        _samples[_index + 1].position,
      );
    }

    final progress =
        _samples.length <= 1 ? 0.0 : _index / (_samples.length - 1);

    var elapsed = Duration.zero;
    if (_samples.length > 1 && sample != null) {
      elapsed = sample.timestamp.difference(_samples.first.timestamp);
      if (elapsed.isNegative) elapsed = Duration.zero;
    }

    return FlightState(
      mode: FlightMode.demo,
      route: route,
      started: _playing,
      currentPosition: sample?.position ?? route.start,
      track: List.unmodifiable(track.take(_index + 1)),
      progress: progress,
      speedKmh: sample?.speedKmh ?? widget.record.maxSpeedKmh,
      altitudeFt: sample?.altitudeFt ?? widget.record.maxAltitudeFt,
      heading: heading,
      nearby: const [],
      below: null,
      ahead: null,
      elapsed: elapsed,
      mapLayer: MapLayer.street,
      message: 'Flight replay',
      gpsAvailable: false,
      gpsQuality: GpsQuality.noFix,
      gpsAccuracyM: sample?.accuracyM ?? 0,
      lastFixAt: sample?.timestamp,
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
                _Stat(
                  label: 'Distance',
                  value:
                      widget.record.distanceKm.toStringAsFixed(0) + ' km',
                ),
                _Stat(
                  label: 'Max speed',
                  value:
                      widget.record.maxSpeedKmh.toStringAsFixed(0) +
                          ' km/h',
                ),
                _Stat(
                  label: 'Max altitude',
                  value:
                      widget.record.maxAltitudeFt.toStringAsFixed(0) +
                          ' ft',
                ),
              ],
            ),
          ),
          if (_samples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _FlightProfile(
                samples: _samples,
                currentIndex: _index,
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
                            max: _lastIndex > 0
                                ? _lastIndex.toDouble()
                                : 1,
                            value: _lastIndex > 0
                                ? _index.toDouble()
                                : 0,
                            onChanged: _lastIndex > 0 ? _seek : null,
                          ),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                tooltip: _playing
                                    ? 'Pause replay'
                                    : 'Play replay',
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
                                  durationLabel(state.elapsed) +
                                      '  •  Point ' +
                                      (_samples.isEmpty
                                          ? '0'
                                          : (_index + 1).toString()) +
                                      ' / ' +
                                      _samples.length.toString(),
                                ),
                              ),
                              Text(
                                state.altitudeFt.round().toString() + ' ft',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
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

class _FlightProfile extends StatelessWidget {
  const _FlightProfile({
    required this.samples,
    required this.currentIndex,
  });

  final List<FlightSample> samples;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 82,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flight altitude profile',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: CustomPaint(
                  painter: _ProfilePainter(
                    samples: samples,
                    currentIndex: currentIndex,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  const _ProfilePainter({
    required this.samples,
    required this.currentIndex,
  });

  final List<FlightSample> samples;
  final int currentIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final values =
        samples.map((sample) => sample.altitudeFt).toList();
    var minValue = values.first;
    var maxValue = values.first;
    for (final value in values.skip(1)) {
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }
    final range = math.max(1.0, maxValue - minValue).toDouble();

    final line = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final progressLine = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Path buildPath(int count) {
      final path = Path();
      for (var i = 0; i < count; i++) {
        final x = i / (values.length - 1) * size.width;
        final normalized = (values[i] - minValue) / range;
        final y = size.height - normalized * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    canvas.drawPath(buildPath(values.length), line);

    final count = (currentIndex + 1).clamp(1, values.length);
    canvas.drawPath(buildPath(count), progressLine);

    final markerX =
        currentIndex / (values.length - 1) * size.width;
    final markerY =
        size.height -
        ((values[currentIndex] - minValue) / range * size.height);

    canvas.drawCircle(markerX, markerY, 4, Paint());
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.samples != samples;
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
