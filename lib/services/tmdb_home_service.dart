import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../models/dynamic_layout_models.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';


/// TMDb Home Content Service
/// Fetches trending movies/shows, Top 10 items, and genre categories from TMDb API
/// with curated fallback datasets to ensure the home screen is always rich and full of content.
class TmdbHomeService {
  static const String _apiKey = '3aec63790d50f3b9fc2efb4c15a8cf99'; // TMDb public read key
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';

  static String? posterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$_imageBase/$size$path';
  }

  static String? backdropUrl(String? path, {String size = 'w1280'}) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$_imageBase/$size$path';
  }


  /// Search TMDB for a poster image for [title].
  Future<String?> fetchPosterForTitle(String title, {int? year, bool isMovie = true}) async {
    try {
      final typeStr = isMovie ? 'movie' : 'tv';
      final yearParam = year != null ? '&${isMovie ? "primary_release_year" : "first_air_date_year"}=$year' : '';
      final url = Uri.parse('$_baseUrl/search/$typeStr?api_key=$_apiKey&query=${Uri.encodeComponent(title)}$yearParam&language=tr-TR');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final posterPath = first['poster_path'] as String?;
          if (posterPath != null && posterPath.isNotEmpty) {
            return posterUrl(posterPath);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Match TMDB Trending & Popular results with [localItems] to construct Top 10 row.
  Future<List<MediaItem>> matchLocalItemsWithTmdbTop10(List<MediaItem> localItems) async {
    if (localItems.isEmpty) return [];

    final matched = <MediaItem>[];
    final tmdbCandidates = <Map<String, dynamic>>[];

    // Fetch TMDB Trending Day (Movies & TV, page 1 & 2) and Popular
    final endpoints = [
      '$_baseUrl/trending/movie/day?api_key=$_apiKey&language=tr-TR&page=1',
      '$_baseUrl/trending/movie/day?api_key=$_apiKey&language=tr-TR&page=2',
      '$_baseUrl/trending/tv/day?api_key=$_apiKey&language=tr-TR&page=1',
      '$_baseUrl/trending/tv/day?api_key=$_apiKey&language=tr-TR&page=2',
      '$_baseUrl/movie/popular?api_key=$_apiKey&language=tr-TR&page=1',
      '$_baseUrl/tv/popular?api_key=$_apiKey&language=tr-TR&page=1',
    ];

    for (final ep in endpoints) {
      try {
        final res = await http.get(Uri.parse(ep)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final results = data['results'] as List<dynamic>? ?? [];
          for (final item in results) {
            tmdbCandidates.add(item as Map<String, dynamic>);
          }
        }
      } catch (_) {}
    }

    // Match candidates with localItems
    for (final tmdbJson in tmdbCandidates) {
      if (matched.length >= 10) break;

      final tmdbId = tmdbJson['id']?.toString();
      final titles = <String>{
        if (tmdbJson['title'] != null) tmdbJson['title'].toString(),
        if (tmdbJson['name'] != null) tmdbJson['name'].toString(),
        if (tmdbJson['original_title'] != null) tmdbJson['original_title'].toString(),
        if (tmdbJson['original_name'] != null) tmdbJson['original_name'].toString(),
      };

      final normalizedTmdbTitles = titles.map(_normalize).where((t) => t.isNotEmpty).toList();
      if (normalizedTmdbTitles.isEmpty) continue;

      final match = localItems.firstWhereOrNull((item) {
        if (matched.contains(item)) return false;

        // 1. External Provider ID Match (tmdb/imdb)
        final extIds = ExternalIds.fromMediaItem(item);
        if (extIds.tmdb != null && tmdbId != null) {
          if (extIds.tmdb.toString() == tmdbId) return true;
        }


        // 2. Title matching
        final itemNorm = _normalize(item.title);
        for (final tmdbNorm in normalizedTmdbTitles) {
          if (itemNorm == tmdbNorm) return true;
          if (itemNorm.length >= 4 && tmdbNorm.length >= 4) {
            if (itemNorm.contains(tmdbNorm) || tmdbNorm.contains(itemNorm)) return true;
          }
        }
        return false;
      });

      if (match != null) {
        matched.add(match);
      }
    }

    // Fallback: If library matches < 10, fill remaining slots from highest rated local items
    if (matched.length < 10 && localItems.length > matched.length) {
      final remainingLocal = localItems.where((i) => !matched.contains(i)).toList();
      remainingLocal.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      for (final extra in remainingLocal) {
        if (matched.length >= 10) break;
        matched.add(extra);
      }
    }

    return matched.take(10).toList();
  }

  static String _normalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Re-order [localItems] guided by TMDB popular recommendations for a genre.
  Future<List<MediaItem>> orderLocalItemsByTmdbGenre(
    List<MediaItem> localItems,
    String genreName, {
    required bool isMovie,
  }) async {
    if (localItems.isEmpty) return localItems;

    try {
      final typeStr = isMovie ? 'movie' : 'tv';
      final url = Uri.parse('$_baseUrl/search/$typeStr?api_key=$_apiKey&query=${Uri.encodeComponent(genreName)}&language=tr-TR');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final tmdbTitles = results
            .map((r) => (r[isMovie ? 'title' : 'name'] ?? r['original_title'] ?? '') as String)
            .where((t) => t.isNotEmpty)
            .map(_normalize)
            .toList();

        final matched = <MediaItem>[];
        final remaining = List<MediaItem>.from(localItems);

        for (final tmdbNorm in tmdbTitles) {
          final found = remaining.firstWhereOrNull((item) => _normalize(item.title) == tmdbNorm);
          if (found != null) {
            matched.add(found);
            remaining.remove(found);
          }
        }

        return [...matched, ...remaining];
      }
    } catch (_) {}
    return localItems;
  }





  /// Fetch hero trending items (Movies & Shows) for the top rotating banner.
  Future<List<MediaItem>> fetchHeroTrendingItems() async {
    try {
      final url = Uri.parse('$_baseUrl/trending/all/day?api_key=$_apiKey&language=tr-TR');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final items = <MediaItem>[];
        for (final json in results) {
          final item = _parseTmdbToMediaItem(json as Map<String, dynamic>);
          if (item != null && (item.artPath != null || item.thumbPath != null)) {
            items.add(item);
          }
        }
        if (items.isNotEmpty) return items.take(8).toList();
      }
    } catch (e) {
      appLogger.w('TmdbHomeService: Hero fetch error, using curated fallback: $e');
    }
    return _getFallbackHeroItems();
  }

  /// Fetch Top 10 Movies Today for Top 10 row.
  Future<List<Top10Item>> fetchTop10Movies() async {
    try {
      final url = Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey&language=tr-TR');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final top10 = <Top10Item>[];
        for (var i = 0; i < results.length && i < 10; i++) {
          final m = results[i] as Map<String, dynamic>;
          top10.add(Top10Item(
            rank: i + 1,
            id: 'tmdb-m-${m['id']}',
            title: (m['title'] ?? m['original_title'] ?? '') as String,
            mediaType: 'MOVIE',
            year: ((m['release_date'] as String?)?.split('-').firstOrNull) ?? '',
            rating: (m['vote_average'] as num?)?.toDouble() ?? 0.0,
            posterUrl: posterUrl(m['poster_path'] as String?),
            backdropUrl: backdropUrl(m['backdrop_path'] as String?),
            overview: m['overview'] as String?,
          ));
        }
        if (top10.isNotEmpty) return top10;
      }
    } catch (e) {
      appLogger.w('TmdbHomeService: Top 10 Movies fetch error: $e');
    }
    return _getFallbackTop10Movies();
  }

  /// Fetch Top 10 TV Shows Today for Top 10 row.
  Future<List<Top10Item>> fetchTop10TvShows() async {
    try {
      final url = Uri.parse('$_baseUrl/trending/tv/day?api_key=$_apiKey&language=tr-TR');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final top10 = <Top10Item>[];
        for (var i = 0; i < results.length && i < 10; i++) {
          final m = results[i] as Map<String, dynamic>;
          top10.add(Top10Item(
            rank: i + 1,
            id: 'tmdb-tv-${m['id']}',
            title: (m['name'] ?? m['original_name'] ?? '') as String,
            mediaType: 'TV',
            year: ((m['first_air_date'] as String?)?.split('-').firstOrNull) ?? '',
            rating: (m['vote_average'] as num?)?.toDouble() ?? 0.0,
            posterUrl: posterUrl(m['poster_path'] as String?),
            backdropUrl: backdropUrl(m['backdrop_path'] as String?),
            overview: m['overview'] as String?,
          ));
        }
        if (top10.isNotEmpty) return top10;
      }
    } catch (e) {
      appLogger.w('TmdbHomeService: Top 10 TV fetch error: $e');
    }
    return _getFallbackTop10TvShows();
  }

  /// Fetch Category Rows (Action, Sci-Fi, Top Rated, Comedy, Animation, etc.)
  Future<List<DynamicSection>> fetchCategorySections() async {
    final sections = <DynamicSection>[];
    try {
      // 1. Action & Adventure
      final actionItems = await _fetchGenreItems(28, isMovie: true);
      if (actionItems.isNotEmpty) {
        sections.add(DynamicSection(
          id: 'cat-action',
          title: 'Aksiyon & Macera',
          subtitle: 'Nefes kesen aksiyon ve heyecan dolu filmler',
          type: DynamicSectionType.genreBased,
          cardVariant: CardVariant.portrait,
          items: actionItems,
        ));
      }

      // 2. Sci-Fi & Fantasy
      final scifiItems = await _fetchGenreItems(878, isMovie: true);
      if (scifiItems.isNotEmpty) {
        sections.add(DynamicSection(
          id: 'cat-scifi',
          title: 'Bilim Kurgu & Fantastik',
          subtitle: 'Sınırları zorlayan zihin açıcı dünyalar',
          type: DynamicSectionType.genreBased,
          cardVariant: CardVariant.landscape,
          items: scifiItems,
        ));
      }

      // 3. Top Rated Movies
      final topRated = await _fetchTopRatedMovies();
      if (topRated.isNotEmpty) {
        sections.add(DynamicSection(
          id: 'cat-toprated',
          title: 'Tüm Zamanların En Yüksek Puanlıları',
          subtitle: 'Sinema tarihinin başyapıtları',
          type: DynamicSectionType.popular,
          cardVariant: CardVariant.portrait,
          items: topRated,
        ));
      }

      // 4. Comedy
      final comedyItems = await _fetchGenreItems(35, isMovie: true);
      if (comedyItems.isNotEmpty) {
        sections.add(DynamicSection(
          id: 'cat-comedy',
          title: 'Komedi & Eğlence',
          subtitle: 'Kahkaha dolu unutulmaz filmler',
          type: DynamicSectionType.genreBased,
          cardVariant: CardVariant.portrait,
          items: comedyItems,
        ));
      }
    } catch (e) {
      appLogger.w('TmdbHomeService: Category fetch error: $e');
    }

    if (sections.isEmpty) {
      return _getFallbackCategorySections();
    }
    return sections;
  }

  Future<List<Top10Item>> _fetchGenreItems(int genreId, {bool isMovie = true}) async {
    final typeStr = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_baseUrl/discover/$typeStr?api_key=$_apiKey&with_genres=$genreId&sort_by=popularity.desc&language=tr-TR');
    final res = await http.get(url).timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      final list = <Top10Item>[];
      for (var i = 0; i < results.length && i < 12; i++) {
        final m = results[i] as Map<String, dynamic>;
        list.add(Top10Item(
          rank: i + 1,
          id: 'tmdb-g-$genreId-${m['id']}',
          title: (m[isMovie ? 'title' : 'name'] ?? '') as String,
          mediaType: isMovie ? 'MOVIE' : 'TV',
          year: ((m[isMovie ? 'release_date' : 'first_air_date'] as String?)?.split('-').firstOrNull) ?? '',
          rating: (m['vote_average'] as num?)?.toDouble() ?? 0.0,
          posterUrl: posterUrl(m['poster_path'] as String?),
          backdropUrl: backdropUrl(m['backdrop_path'] as String?),
          overview: m['overview'] as String?,
        ));
      }
      return list;
    }
    return [];
  }

  Future<List<Top10Item>> _fetchTopRatedMovies() async {
    final url = Uri.parse('$_baseUrl/movie/top_rated?api_key=$_apiKey&language=tr-TR');
    final res = await http.get(url).timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      final list = <Top10Item>[];
      for (var i = 0; i < results.length && i < 12; i++) {
        final m = results[i] as Map<String, dynamic>;
        list.add(Top10Item(
          rank: i + 1,
          id: 'tmdb-tr-${m['id']}',
          title: (m['title'] ?? '') as String,
          mediaType: 'MOVIE',
          year: ((m['release_date'] as String?)?.split('-').firstOrNull) ?? '',
          rating: (m['vote_average'] as num?)?.toDouble() ?? 0.0,
          posterUrl: posterUrl(m['poster_path'] as String?),
          backdropUrl: backdropUrl(m['backdrop_path'] as String?),
          overview: m['overview'] as String?,
        ));
      }
      return list;
    }
    return [];
  }

  MediaItem? _parseTmdbToMediaItem(Map<String, dynamic> m) {
    final isMovie = m['media_type'] == 'movie' || m.containsKey('title');
    final title = (m[isMovie ? 'title' : 'name'] ?? m['original_title'] ?? m['original_name'] ?? '') as String;
    if (title.isEmpty) return null;

    final backdrop = backdropUrl(m['backdrop_path'] as String?);
    final poster = posterUrl(m['poster_path'] as String?);
    final rating = (m['vote_average'] as num?)?.toDouble() ?? 0.0;
    final yearStr = (m[isMovie ? 'release_date' : 'first_air_date'] as String?)?.split('-').firstOrNull;
    final year = int.tryParse(yearStr ?? '');

    return MediaItem(
      id: 'tmdb-${m['id']}',
      backend: MediaBackend.jellyfin,
      kind: isMovie ? MediaKind.movie : MediaKind.show,
      title: title,
      summary: m['overview'] as String?,
      year: year,
      rating: rating,
      userRating: rating,
      thumbPath: poster,
      artPath: backdrop,
      backdropPaths: backdrop != null && backdrop.isNotEmpty ? [backdrop] : null,
      genres: const ['Trend', 'Önerilen'],

    );
  }

  // Fallback Datasets (Curated TMDb Media)
  List<MediaItem> _getFallbackHeroItems() {
    return [
      MediaItem(
        id: 'hero-fallback-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Dune: Çöl Gezegeni Bölüm İki',
        summary: 'Paul Atreides, ailesini yok eden komplo ortaklarına karşı intikam mücadelesi verirken Chani ve Fremenler ile birleşir.',
        year: 2024,
        rating: 8.6,
        userRating: 8.6,
        artPath: 'https://image.tmdb.org/t/p/w1280/xOMo8ScSp25Dq10b7L28xL197d.jpg',
        thumbPath: 'https://image.tmdb.org/t/p/w500/1pdfLPoL6VFi8z8Djh2LIYmgF21.jpg',
        backdropPaths: const ['https://image.tmdb.org/t/p/w1280/xOMo8ScSp25Dq10b7L28xL197d.jpg'],
        genres: const ['Bilim Kurgu', 'Macera'],
      ),
      MediaItem(
        id: 'hero-fallback-2',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.show,
        title: 'Severance',
        summary: 'Lumon Industries çalışanları iş ve özel hayat anılarını cerrahi olarak ayıran bir prosedürden geçer.',
        year: 2022,
        rating: 8.7,
        userRating: 8.7,
        artPath: 'https://image.tmdb.org/t/p/w1280/9faGSFi5jam6pUdFiLKGj2vB2io.jpg',
        thumbPath: 'https://image.tmdb.org/t/p/w500/lFzw43G1kE2g141441l42lGg2.jpg',
        backdropPaths: const ['https://image.tmdb.org/t/p/w1280/9faGSFi5jam6pUdFiLKGj2vB2io.jpg'],
        genres: const ['Gizem', 'Gerilim'],
      ),
      MediaItem(
        id: 'hero-fallback-3',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Oppenheimer',
        summary: 'Amerikalı bilim insanı J. Robert Oppenheimer ve atom bombasını geliştirme sürecindeki rolünün hikayesi.',
        year: 2023,
        rating: 8.9,
        userRating: 8.9,
        artPath: 'https://image.tmdb.org/t/p/w1280/fm6K8Oi23Nm9vYTXu2hq5nf6Ymo.jpg',
        thumbPath: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        backdropPaths: const ['https://image.tmdb.org/t/p/w1280/fm6K8Oi23Nm9vYTXu2hq5nf6Ymo.jpg'],
        genres: const ['Biyografi', 'Tarih', 'Dram'],
      ),
    ];
  }

  List<Top10Item> _getFallbackTop10Movies() {
    return const [
      Top10Item(
        rank: 1,
        id: 'fb-m-1',
        title: 'Oppenheimer',
        mediaType: 'MOVIE',
        year: '2023',
        rating: 8.9,
        posterUrl: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w780/fm6K8Oi23Nm9vYTXu2hq5nf6Ymo.jpg',
      ),
      Top10Item(
        rank: 2,
        id: 'fb-m-2',
        title: 'Kara Şövalye',
        mediaType: 'MOVIE',
        year: '2008',
        rating: 9.0,
        posterUrl: 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w780/nMK2819TyqLnTawvR3hKV3hGgp.jpg',
      ),
      Top10Item(
        rank: 3,
        id: 'fb-m-3',
        title: 'Interstellar',
        mediaType: 'MOVIE',
        year: '2014',
        rating: 8.7,
        posterUrl: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w780/xJHokMbljvjADYdit5fKSuV1Tja.jpg',
      ),
      Top10Item(
        rank: 4,
        id: 'fb-m-4',
        title: 'Başlangıç (Inception)',
        mediaType: 'MOVIE',
        year: '2010',
        rating: 8.8,
        posterUrl: 'https://image.tmdb.org/t/p/w500/oYuLEydvwwbK1oJ8fu2p2y9FlM5.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w780/8ZTVqvKDQ8emSGUEMjsS4yHAiE7.jpg',
      ),
      Top10Item(
        rank: 5,
        id: 'fb-m-5',
        title: 'Spider-Man: Örümcek Evrenine Geçiş',
        mediaType: 'MOVIE',
        year: '2023',
        rating: 8.6,
        posterUrl: 'https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj7sFm8.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w780/4nM10T72061gQ9k59d4H12L249l.jpg',
      ),
    ];
  }

  List<Top10Item> _getFallbackTop10TvShows() {
    return const [
      Top10Item(
        rank: 1,
        id: 'fb-tv-1',
        title: 'Severance',
        mediaType: 'TV',
        year: '2022',
        rating: 8.7,
        backdropUrl: 'https://image.tmdb.org/t/p/w780/9faGSFi5jam6pUdFiLKGj2vB2io.jpg',
        posterUrl: 'https://image.tmdb.org/t/p/w500/lFzw43G1kE2g141441l42lGg2.jpg',
      ),
      Top10Item(
        rank: 2,
        id: 'fb-tv-2',
        title: 'Breaking Bad',
        mediaType: 'TV',
        year: '2008',
        rating: 9.5,
        backdropUrl: 'https://image.tmdb.org/t/p/w780/tsRy63MuZvMuEgW8PxRi2P45ywo.jpg',
        posterUrl: 'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
      ),
      Top10Item(
        rank: 3,
        id: 'fb-tv-3',
        title: 'Stranger Things',
        mediaType: 'TV',
        year: '2016',
        rating: 8.7,
        backdropUrl: 'https://image.tmdb.org/t/p/w780/56v2Kj1h7Q1vf9c2d1s7n8k3l4.jpg',
        posterUrl: 'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn88qEslhOH.jpg',
      ),
      Top10Item(
        rank: 4,
        id: 'fb-tv-4',
        title: 'The Last of Us',
        mediaType: 'TV',
        year: '2023',
        rating: 8.8,
        backdropUrl: 'https://image.tmdb.org/t/p/w780/uDGyPhEpgWide2yUV7wR9GvStgZ.jpg',
        posterUrl: 'https://image.tmdb.org/t/p/w500/uKvVjOb12vGlKjxgIEDWvT7u7g.jpg',
      ),
    ];
  }

  List<DynamicSection> _getFallbackCategorySections() {
    return [
      DynamicSection(
        id: 'fb-cat-action',
        title: 'Aksiyon & Macera',
        subtitle: 'Nefes kesen aksiyon ve heyecan dolu filmler',
        type: DynamicSectionType.genreBased,
        cardVariant: CardVariant.portrait,
        items: _getFallbackTop10Movies(),
      ),
      DynamicSection(
        id: 'fb-cat-scifi',
        title: 'Bilim Kurgu & Fantastik',
        subtitle: 'Sınırları zorlayan zihin açıcı dünyalar',
        type: DynamicSectionType.genreBased,
        cardVariant: CardVariant.landscape,
        items: _getFallbackTop10Movies(),
      ),
    ];
  }
}
