import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/focusable_wrapper.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../models/dynamic_layout_models.dart';
import '../theme/mono_tokens.dart';
import '../utils/media_navigation_helper.dart' show navigateToMediaItem;
import 'app_icon.dart';
import 'optimized_media_image.dart';

/// Helper to convert a [MediaItem] into a [Top10Item] with rank.
Top10Item top10ItemFromMediaItem(MediaItem item, int rank) {
  return Top10Item(
    rank: rank,
    id: item.id,
    title: item.title ?? '',
    mediaType: item.kind == MediaKind.movie ? 'MOVIE' : 'TV',
    year: item.year?.toString() ?? '',
    rating: item.userRating ?? item.rating ?? 0.0,
    posterUrl: item.thumbPath,
    backdropUrl: item.artPath,
    overview: item.summary,
    serverId: item.serverId,
    mediaItemId: item.id,
  );
}

/// Specialized Top 10 section widget displaying rank numbers (1 to 10)
/// in either [CardVariant.landscape] (backdrop) or [CardVariant.portrait] (poster) format.
class Top10SectionWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final CardVariant cardVariant;
  final List<Top10Item> items;
  final List<MediaItem>? mediaItems;
  final void Function(Top10Item item)? onItemTap;
  final void Function(MediaItem item)? onMediaItemTap;

  const Top10SectionWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.cardVariant = CardVariant.portrait,
    this.items = const [],
    this.mediaItems,
    this.onItemTap,
    this.onMediaItemTap,
  });

  factory Top10SectionWidget.fromDynamicSection({
    Key? key,
    required DynamicSection section,
    void Function(Top10Item item)? onItemTap,
  }) {
    return Top10SectionWidget(
      key: key,
      title: section.title,
      subtitle: section.subtitle,
      cardVariant: section.cardVariant,
      items: section.items,
      onItemTap: onItemTap,
    );
  }

  factory Top10SectionWidget.fromMediaItems({
    Key? key,
    required String title,
    String? subtitle,
    CardVariant cardVariant = CardVariant.portrait,
    required List<MediaItem> mediaItems,
    void Function(MediaItem item)? onMediaItemTap,
  }) {
    final top10List = <Top10Item>[];
    for (var i = 0; i < mediaItems.length && i < 10; i++) {
      top10List.add(top10ItemFromMediaItem(mediaItems[i], i + 1));
    }
    return Top10SectionWidget(
      key: key,
      title: title,
      subtitle: subtitle,
      cardVariant: cardVariant,
      items: top10List,
      mediaItems: mediaItems,
      onMediaItemTap: onMediaItemTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);
    final isLandscape = cardVariant == CardVariant.landscape;
    final rowHeight = isLandscape ? 190.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(tokensRef.radiusSm),
                    ),
                    child: Text(
                      'TOP 10',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Horizontal Row
        SizedBox(
          height: rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final mediaItem = mediaItems != null && index < mediaItems!.length ? mediaItems![index] : null;

              void handleTap() {
                if (mediaItem != null) {
                  if (onMediaItemTap != null) {
                    onMediaItemTap!(mediaItem);
                  } else {
                    navigateToMediaItem(context, mediaItem);
                  }
                } else {
                  onItemTap?.call(item);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isLandscape
                    ? _Top10LandscapeCard(item: item, onTap: handleTap)
                    : _Top10PortraitCard(item: item, onTap: handleTap),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Style A: Landscape Backdrop Card
/// Large semi-transparent rank numbers placed at bottom-left inside backdrop image,
/// title, media type tag (MOVIE/TV), release year, and star rating.
class _Top10LandscapeCard extends StatelessWidget {
  final Top10Item item;
  final VoidCallback? onTap;

  const _Top10LandscapeCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);
    final width = 280.0;
    final borderRadius = BorderRadius.circular(tokensRef.radiusMd);

    return FocusableWrapper(
      borderRadii: borderRadius,
      onSelect: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Backdrop Image
            if (item.backdropUrl != null || item.posterUrl != null)
              Positioned.fill(
                child: OptimizedMediaImage(
                  imagePath: item.backdropUrl ?? item.posterUrl!,
                  fit: BoxFit.cover,
                ),
              ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Large Semi-Transparent Rank Overlay (Bottom-Left)
            Positioned(
              left: 8,
              bottom: 4,
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  color: Colors.white.withValues(alpha: 0.35),
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),

            // Card Bottom Metadata Details
            Positioned(
              left: item.rank >= 10 ? 90 : 64,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tag (MOVIE/TV), Year, Rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.mediaType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.year.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.year,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                      if (item.rating > 0) ...[
                        const Spacer(),
                        const AppIcon(Symbols.star_rounded, size: 13, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Style B: Vertical Poster Card
/// Stylized large rank numbers overlapping behind/beside each poster card,
/// with circular rating badges on the top-left corner of the poster.
class _Top10PortraitCard extends StatelessWidget {
  final Top10Item item;
  final VoidCallback? onTap;

  const _Top10PortraitCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);
    final posterWidth = 120.0;
    final borderRadius = BorderRadius.circular(tokensRef.radiusMd);

    return FocusableWrapper(
      borderRadii: borderRadius,
      onSelect: onTap,
      child: SizedBox(
        width: 170.0,
        height: 210.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Large Stylized Rank Number (Overlapping Left/Behind)
            Positioned(
              left: -4,
              bottom: 10,
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  fontSize: 110,
                  fontWeight: FontWeight.w900,
                  height: 0.85,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = theme.colorScheme.primary.withValues(alpha: 0.8),
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(3, 3)),
                  ],
                ),
              ),
            ),

            // Vertical Poster Card (Positioned Right)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: posterWidth,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: theme.colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (item.posterUrl != null || item.backdropUrl != null)
                      Positioned.fill(
                        child: OptimizedMediaImage(
                          imagePath: item.posterUrl ?? item.backdropUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),

                    // Top-Left Circular Rating Badge
                    if (item.rating > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.8), width: 1.5),
                          ),
                          child: Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
