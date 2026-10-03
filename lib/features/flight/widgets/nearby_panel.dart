import 'package:flutter/material.dart';
import '../../../core/models/poi.dart';

class NearbyPanel extends StatelessWidget {
  const NearbyPanel({super.key, required this.items});
  final List<NearbyPoi> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('What’s below / nearby', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('No bundled places are close enough to show. Add a richer offline POI pack for wider coverage.'),
              )
            else
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 17,
                    child: Icon(_icon(item.poi.type), size: 18),
                  ),
                  title: Text(item.poi.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.poi.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('${item.distanceKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'airport':
        return Icons.flight;
      case 'mountain':
        return Icons.terrain;
      case 'landmark':
        return Icons.place;
      default:
        return Icons.location_city;
    }
  }
}

