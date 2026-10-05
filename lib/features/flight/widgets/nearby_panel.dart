import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';

class NearbyPanel extends StatelessWidget {
  const NearbyPanel({
    super.key,
    required this.items,
    this.below,
    this.ahead,
  });

  final List<NearbyPoi> items;
  final NearbyPoi? below;
  final NearbyPoi? ahead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Passenger view',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'Approx.',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.vertical_align_bottom,
                    title: 'Below me',
                    item: below,
                    emptyText: 'No nearby place',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.navigation,
                    title: 'Ahead',
                    item: ahead,
                    emptyText: 'Nothing ahead',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No bundled places are close enough. Add a richer offline POI pack for wider coverage.',
                ),
              )
            else
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      width: 170,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            child: Icon(_icon(item.poi.type), size: 15),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.poi.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.distanceKm.toStringAsFixed(0) + ' km',
                            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  },
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

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.item,
    required this.emptyText,
  });

  final IconData icon;
  final String title;
  final NearbyPoi? item;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: item == null
                ? Text(
                    emptyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item!.poi.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        item!.distanceKm.toStringAsFixed(0) + ' km',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
