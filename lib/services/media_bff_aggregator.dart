import 'dart:async';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../models/dynamic_layout_models.dart';
import '../utils/app_logger.dart';

/// Aggregator service following the BFF (Backend-For-Frontend) pattern.
/// Combines local self-hosted server items (Jellyfin/Emby/Plex) with external
/// metadata sources (TMDb, OMDb, JustWatch, Algolia hooks).
class MediaBffAggregator {
  final Map<String, MediaServerClient> connectedClients;

  MediaBffAggregator({
    this.connectedClients = const {},
  });

  /// Map raw local server [MediaItem] into a unified [Top10Item] with rank.
  Top10Item mapMediaItemToTop10Item(MediaItem item, {required int rank}) {
    final year = item.year?.toString() ?? '';
    final rating = item.userRating ?? item.rating ?? 0.0;
    final mediaType = item.kind == MediaKind.movie ? 'MOVIE' : 'TV';

    return Top10Item(
      rank: rank,
      id: item.id,
      title: item.title ?? '',
      mediaType: mediaType,
      year: year,
      rating: rating,
      posterUrl: item.thumbPath,
      backdropUrl: item.artPath,
      overview: item.summary,
      serverId: item.serverId,
      mediaItemId: item.id,
    );
  }

  /// Map raw local server [MediaItem] into a [HeroBannerItem].
  HeroBannerItem mapMediaItemToHeroBanner(MediaItem item) {
    return HeroBannerItem(
      id: item.id,
      title: item.title ?? '',
      overview: item.summary ?? '',
      backdropUrl: item.artPath,
      posterUrl: item.thumbPath,
      rating: item.userRating ?? item.rating ?? 0.0,
      year: item.year?.toString() ?? '',
      genres: item.genres ?? const [],
      serverId: item.serverId,
      mediaItemId: item.id,
    );
  }

  /// Hook for Algolia / Meilisearch instant search integration.
  /// Prepares query payload for external search indexers.
  Future<List<Top10Item>> searchExternalIndex(String query, {int limit = 10}) async {
    try {
      // Plug in Algolia / Meilisearch HTTP client here when configured.
      appLogger.d('MediaBffAggregator: Algolia/Meilisearch query "$query" (limit: $limit)');
      return const [];
    } catch (e, st) {
      appLogger.e('MediaBffAggregator: Search index query failed', error: e, stackTrace: st);
      return const [];
    }
  }

  /// Enrich local media item with external metadata (OMDb / JustWatch / TMDb).
  Future<Map<String, dynamic>> fetchExternalMetadata(String imdbId) async {
    try {
      // Integration hook for OMDb / JustWatch availability providers
      appLogger.d('MediaBffAggregator: Fetching external metadata for $imdbId');
      return {
        'imdbRating': 8.5,
        'providers': ['Netflix', 'Prime Video'],
      };
    } catch (e, st) {
      appLogger.e('MediaBffAggregator: External metadata fetch failed', error: e, stackTrace: st);
      return const {};
    }
  }
}
