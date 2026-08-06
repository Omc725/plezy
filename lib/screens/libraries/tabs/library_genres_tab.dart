import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/library_query.dart';
import '../../../media/media_item.dart';
import '../../../media/media_server_client.dart';
import 'base_library_tab.dart';

/// Spotify-style vibrant gradient color pairs
const List<List<Color>> _spotifyGradients = [
  [Color(0xFFE91E63), Color(0xFF9C27B0)], // Pink to Purple
  [Color(0xFF3F51B5), Color(0xFF2196F3)], // Indigo to Blue
  [Color(0xFF009688), Color(0xFF4CAF50)], // Teal to Green
  [Color(0xFFFF5722), Color(0xFFFF9800)], // Deep Orange to Orange
  [Color(0xFF673AB7), Color(0xFF3F51B5)], // Purple to Indigo
  [Color(0xFFF44336), Color(0xFFE91E63)], // Red to Pink
  [Color(0xFF00BCD4), Color(0xFF009688)], // Cyan to Teal
  [Color(0xFFFFC107), Color(0xFFFF5722)], // Amber to Deep Orange
  [Color(0xFF9C27B0), Color(0xFF673AB7)], // Purple to Dark Purple
  [Color(0xFF4CAF50), Color(0xFF8BC34A)], // Green to Light Green
  [Color(0xFF607D8B), Color(0xFF455A64)], // Blue Grey
  [Color(0xFFEC407A), Color(0xFFAB47BC)], // Bright Rose
];

/// Genres ("Türler") tab for Library Screen.
/// Displays Spotify-style colorful gradient cards with bold category names.
class LibraryGenresTab extends BaseLibraryTab<String> {
  final ValueChanged<String>? onGenreSelected;

  const LibraryGenresTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
    this.onGenreSelected,
  });

  @override
  State<LibraryGenresTab> createState() => _LibraryGenresTabState();
}

class _LibraryGenresTabState extends BaseLibraryTabState<String, LibraryGenresTab> {
  final Map<String, List<MediaItem>> _genrePosters = {};

  @override
  IconData get emptyIcon => Symbols.category_rounded;

  @override
  String get emptyMessage => t.libraries.filterCategories.genre;

  @override
  String get errorContext => t.libraries.filterCategories.genre;

  @override
  Future<List<String>> loadData() async {
    final client = getMediaClientForLibrary();
    final filterResult = await client.fetchLibraryFiltersWithValues(widget.library.id, libraryKind: widget.library.kind);
    final genreValues = filterResult.cachedValues['genre'] ?? [];
    final genreNames = genreValues.map((v) => v.title).toList();

    unawaited(_loadGenrePosters(client, genreNames));
    return genreNames;
  }

  Future<void> _loadGenrePosters(MediaServerClient client, List<String> genreNames) async {
    for (final genre in genreNames.take(24)) {
      try {
        final page = await client.fetchLibraryContent(
          widget.library.id,
          LibraryQuery(genres: [genre], limit: 2),
        );
        if (mounted && page.items.isNotEmpty) {
          setState(() {
            _genrePosters[genre] = page.items;
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget buildContent(List<String> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final genre = items[index];
            final sampleItems = _genrePosters[genre] ?? [];

            return _buildSpotifyCard(genre, index, sampleItems);
          },
        );
      },
    );
  }

  Widget _buildSpotifyCard(String genre, int index, List<MediaItem> items) {
    final colors = _spotifyGradients[index % _spotifyGradients.length];
    final samplePoster = items.isNotEmpty ? (items.first.thumbPath ?? items.first.artPath) : null;

    return FocusableWrapper(
      child: GestureDetector(
        onTap: () => widget.onGenreSelected?.call(genre),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],

          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Rotated poster thumbnail in bottom right (Spotify style)
              if (samplePoster != null && samplePoster.isNotEmpty)
                Positioned(
                  right: -14,
                  bottom: -14,
                  width: 85,
                  height: 115,
                  child: Transform.rotate(
                    angle: 0.35, // ~20 deg tilt
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(-2, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        samplePoster,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(color: Colors.black26),
                      ),
                    ),
                  ),
                ),

              // Title Text overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  genre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
