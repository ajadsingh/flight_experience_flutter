import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/constants/app_config.dart';
import '../../core/models/flight_history_item.dart';
import '../../core/services/offline_cached_tile_provider.dart';

class FlightReplayScreen extends StatefulWidget {
  const FlightReplayScreen({super.key, required this.item});

  final FlightHistoryItem item;

  @override
  State<FlightReplayScreen> createState() => _FlightReplayScreenState();
}

class _FlightReplayScreenState extends State<FlightReplayScreen> {
  Timer? _timer;
  int _index = 0;
  bool _playing = false;
  bool _perspective = false;
  late final OfflineCachedTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = OfflineCachedTileProvider(
      routeId: widget.item.route.id,
      layerName: 'street',
      offlineOnly: false,
      headers: {'User-Agent': AppConfig.userAgent},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tileProvider.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (widget.item.track.length < 2) return;
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) return;
      if (_index >= widget.item.track.length - 1) {
        _timer?.cancel();
        setState(() => _playing = false);
        return;
      }
      setState(() => _index += 1);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _playing = false;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.item.track;
    final point = track.isEmpty
        ? widget.item.route.start.toLatLng()
        : track[_index].toLatLng();
    final visibleTrack = track
        .take(track.isEmpty ? 0 : _index + 1)
        .map((p) => p.toLatLng())
        .toList(growable: false);
    final planned = widget.item.route.waypoints
        .map((p) => p.toLatLng())
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.item.route.originCode} → ${widget.item.route.destinationCode} Replay',
        ),
        actions: [
          IconButton(
            tooltip: _perspective ? 'Flat map' : '3D perspective',
            onPressed: () => setState(() => _perspective = !_perspective),
            icon: Icon(
              _perspective ? Icons.view_in_ar : Icons.threed_rotation,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(_perspective ? -0.42 : 0),
                    child: ClipRect(
                      child: FlutterMap(
                        options: MapOptions(
                      initialCenter: point,
                      initialZoom: 6.2,
                      minZoom: 3,
                      maxZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConfig.defaultTileUrl,
                        userAgentPackageName: AppConfig.userAgent,
                        tileProvider: _tileProvider,
                        maxNativeZoom: AppConfig.offlineMaxZoom,
                      ),
                      PolylineLayer(
                        polylines: [
                          if (planned.length >= 2)
                            Polyline(
                              points: planned,
                              strokeWidth: 2.5,
                              color: Theme.of(context)
                                  .colorScheme.primary
                                  .withValues(alpha: 0.28),
                              pattern: StrokePattern.dotted(),
                            ),
                          if (visibleTrack.length >= 2)
                            Polyline(
                              points: visibleTrack,
                              strokeWidth: 5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 52,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context)
                                    .colorScheme.primaryContainer,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.flight,
                                color: Theme.of(context).colorScheme.primary,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _ReplayStat(label: 'Duration', value: widget.item.durationLabel),
                          _ReplayStat(
                            label: 'Distance',
                            value: '${widget.item.distanceKm.toStringAsFixed(0)} km',
                          ),
                          _ReplayStat(
                            label: 'Max altitude',
                            value: '${widget.item.maxAltitudeFt.round()} ft',
                          ),
                          _ReplayStat(
                            label: 'Max speed',
                            value: '${widget.item.maxSpeedKmh.round()} km/h',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  Slider(
                    value: track.isEmpty
                        ? 0
                        : math.min(_index.toDouble(), (track.length - 1).toDouble()),
                    min: 0,
                    max: math.max(1, track.length - 1).toDouble(),
                    onChanged: track.length < 2
                        ? null
                        : (value) {
                            _timer?.cancel();
                            setState(() {
                              _playing = false;
                              _index = value.round();
                            });
                          },
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: _playing ? 'Pause replay' : 'Play replay',
                        onPressed: track.length < 2 ? null : _togglePlayback,
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Restart replay',
                        onPressed: track.isEmpty ? null : _reset,
                        icon: const Icon(Icons.replay),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          track.isEmpty
                              ? 'No GPS/demo track was recorded.'
                              : 'Point ${_index + 1} of ${track.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(widget.item.mode == 'demo' ? 'Demo' : 'GPS'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayStat extends StatelessWidget {
  const _ReplayStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
