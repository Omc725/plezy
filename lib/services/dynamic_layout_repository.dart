import 'dart:convert';
import '../models/dynamic_layout_models.dart';
import '../utils/app_logger.dart';

class DynamicLayoutRepository {
  /// Parse a JSON string payload into a [DynamicLayoutPayload].
  DynamicLayoutPayload parsePayload(String jsonRaw) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonRaw) as Map<String, dynamic>;
      return DynamicLayoutPayload.fromJson(data);
    } catch (e, st) {
      appLogger.e('DynamicLayoutRepository: Failed to parse dynamic layout payload', error: e, stackTrace: st);
      return getFallbackPayload();
    }
  }

  /// Provides a default fallback dynamic layout payload with sample Top 10 sections
  /// (both Portrait Poster & Landscape Backdrop variants).
  DynamicLayoutPayload getFallbackPayload() {
    return DynamicLayoutPayload(
      heroBanner: const HeroBannerItem(
        id: 'hero-1',
        title: 'Dune: Part Two',
        overview: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/xOMo8ScSp25Dq10b7L28xL197d.jpg',
        posterUrl: 'https://image.tmdb.org/t/p/w500/1pdfLPoL6VFi8z8Djh2LIYmgF21.jpg',
        rating: 8.6,
        year: '2024',
        genres: ['Sci-Fi', 'Adventure'],
      ),
      sections: [
        const DynamicSection(
          id: 'top-10-movies-portrait',
          title: 'Top 10 Movies Today',
          subtitle: 'Most watched movies this week',
          type: DynamicSectionType.top10,
          cardVariant: CardVariant.portrait,
          items: [
            Top10Item(
              rank: 1,
              id: 'top-1',
              title: 'Oppenheimer',
              mediaType: 'MOVIE',
              year: '2023',
              rating: 8.9,
              posterUrl: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
              backdropUrl: 'https://image.tmdb.org/t/p/w780/fm6K8Oi23Nm9vYTXu2hq5nf6Ymo.jpg',
            ),
            Top10Item(
              rank: 2,
              id: 'top-2',
              title: 'The Dark Knight',
              mediaType: 'MOVIE',
              year: '2008',
              rating: 9.0,
              posterUrl: 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
              backdropUrl: 'https://image.tmdb.org/t/p/w780/nMK2819TyqLnTawvR3hKV3hGgp.jpg',
            ),
            Top10Item(
              rank: 3,
              id: 'top-3',
              title: 'Interstellar',
              mediaType: 'MOVIE',
              year: '2014',
              rating: 8.7,
              posterUrl: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
              backdropUrl: 'https://image.tmdb.org/t/p/w780/xJHokMbljvjADYdit5fKSuV1Tja.jpg',
            ),
            Top10Item(
              rank: 4,
              id: 'top-4',
              title: 'Inception',
              mediaType: 'MOVIE',
              year: '2010',
              rating: 8.8,
              posterUrl: 'https://image.tmdb.org/t/p/w500/oYuLEydvwwbK1oJ8fu2p2y9FlM5.jpg',
              backdropUrl: 'https://image.tmdb.org/t/p/w780/8ZTVqvKDQ8emSGUEMjsS4yHAiE7.jpg',
            ),
            Top10Item(
              rank: 5,
              id: 'top-5',
              title: 'Spider-Man: Across the Spider-Verse',
              mediaType: 'MOVIE',
              year: '2023',
              rating: 8.6,
              posterUrl: 'https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj7sFm8.jpg',
              backdropUrl: 'https://image.tmdb.org/t/p/w780/4nM10T72061gQ9k59d4H12L249l.jpg',
            ),
          ],
        ),
        const DynamicSection(
          id: 'top-10-series-landscape',
          title: 'Top 10 Series (Backdrop Style)',
          subtitle: 'Trending TV shows around the world',
          type: DynamicSectionType.top10,
          cardVariant: CardVariant.landscape,
          items: [
            Top10Item(
              rank: 1,
              id: 'tv-1',
              title: 'Severance',
              mediaType: 'TV',
              year: '2022',
              rating: 8.7,
              backdropUrl: 'https://image.tmdb.org/t/p/w780/9faGSFi5jam6pUdFiLKGj2vB2io.jpg',
              posterUrl: 'https://image.tmdb.org/t/p/w500/lFzw43G1kE2g141441l42lGg2.jpg',
            ),
            Top10Item(
              rank: 2,
              id: 'tv-2',
              title: 'Breaking Bad',
              mediaType: 'TV',
              year: '2008',
              rating: 9.5,
              backdropUrl: 'https://image.tmdb.org/t/p/w780/tsRy63MuZvMuEgW8PxRi2P45ywo.jpg',
              posterUrl: 'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
            ),
            Top10Item(
              rank: 3,
              id: 'tv-3',
              title: 'Stranger Things',
              mediaType: 'TV',
              year: '2016',
              rating: 8.7,
              backdropUrl: 'https://image.tmdb.org/t/p/w780/56v2Kj1h7Q1vf9c2d1s7n8k3l4.jpg',
              posterUrl: 'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn88qEslhOH.jpg',
            ),
            Top10Item(
              rank: 4,
              id: 'tv-4',
              title: 'The Last of Us',
              mediaType: 'TV',
              year: '2023',
              rating: 8.8,
              backdropUrl: 'https://image.tmdb.org/t/p/w780/uDGyPhEpgWide2yUV7wR9GvStgZ.jpg',
              posterUrl: 'https://image.tmdb.org/t/p/w500/uKvVjOb12vGlKjxgIEDWvT7u7g.jpg',
            ),
          ],
        ),
        const DynamicSection(
          id: 'personalized-section',
          title: 'Because You Watched Inception',
          subtitle: 'Mind-bending sci-fi thrillers',
          type: DynamicSectionType.personalized,
          cardVariant: CardVariant.portrait,
          items: [
            Top10Item(
              rank: 1,
              id: 'rec-1',
              title: 'Shutter Island',
              mediaType: 'MOVIE',
              year: '2010',
              rating: 8.2,
              posterUrl: 'https://image.tmdb.org/t/p/w500/4GDy0PHYX3VRXUtwK5ysFvf33G.jpg',
            ),
            Top10Item(
              rank: 2,
              id: 'rec-2',
              title: 'Tenet',
              mediaType: 'MOVIE',
              year: '2020',
              rating: 7.3,
              posterUrl: 'https://image.tmdb.org/t/p/w500/aAC2cMVAtWFN2Zp3VNVrg1kgQHe.jpg',
            ),
            Top10Item(
              rank: 3,
              id: 'rec-3',
              title: 'Blade Runner 2049',
              mediaType: 'MOVIE',
              year: '2017',
              rating: 8.0,
              posterUrl: 'https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg',
            ),
          ],
        ),
      ],
    );
  }
}
