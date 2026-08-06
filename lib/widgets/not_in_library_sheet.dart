import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../screens/search_screen.dart';
import '../theme/mono_tokens.dart';
import 'app_icon.dart';
import 'optimized_media_image.dart';

/// Bottom sheet shown when tapping an item that is NOT currently in the user's local server library.
class NotInLibrarySheet extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final double rating;
  final String year;
  final String mediaType;
  final String? overview;

  const NotInLibrarySheet({
    super.key,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.rating = 0.0,
    this.year = '',
    this.mediaType = 'MOVIE',
    this.overview,
  });

  static void show(
    BuildContext context, {
    required String title,
    String? posterUrl,
    String? backdropUrl,
    double rating = 0.0,
    String year = '',
    String mediaType = 'MOVIE',
    String? overview,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NotInLibrarySheet(
        title: title,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        rating: rating,
        year: year,
        mediaType: mediaType,
        overview: overview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokensRef.radiusLg)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              if (posterUrl != null || backdropUrl != null)
                Container(
                  width: 90,
                  height: 135,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokensRef.radiusSm),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: OptimizedMediaImage(
                    imagePath: posterUrl ?? backdropUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 16),

              // Title and badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(tokensRef.radiusSm),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(Symbols.info_rounded, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Kütüphanenizde Bulunmuyor',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          mediaType == 'MOVIE' ? 'Film' : 'Dizi',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                        ),
                        if (year.isNotEmpty) ...[
                          Text(' • $year', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                        ],
                        if (rating > 0) ...[
                          const SizedBox(width: 8),
                          const AppIcon(Symbols.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (overview != null && overview!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              overview!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  icon: const AppIcon(Symbols.search_rounded),
                  label: const Text('Kütüphanede Ara'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
