enum DynamicSectionType {
  personalized,
  trending,
  popular,
  genreBased,
  top10,
}

enum CardVariant {
  portrait,
  landscape,
}

class HeroBannerItem {
  final String id;
  final String title;
  final String overview;
  final String? backdropUrl;
  final String? posterUrl;
  final double rating;
  final String year;
  final List<String> genres;
  final String? serverId;
  final String? mediaItemId;

  const HeroBannerItem({
    required this.id,
    required this.title,
    required this.overview,
    this.backdropUrl,
    this.posterUrl,
    this.rating = 0.0,
    this.year = '',
    this.genres = const [],
    this.serverId,
    this.mediaItemId,
  });

  factory HeroBannerItem.fromJson(Map<String, dynamic> json) {
    return HeroBannerItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      backdropUrl: json['backdropUrl'] as String?,
      posterUrl: json['posterUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      year: json['year'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      serverId: json['serverId'] as String?,
      mediaItemId: json['mediaItemId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'backdropUrl': backdropUrl,
        'posterUrl': posterUrl,
        'rating': rating,
        'year': year,
        'genres': genres,
        'serverId': serverId,
        'mediaItemId': mediaItemId,
      };
}

class Top10Item {
  final int rank;
  final String id;
  final String title;
  final String mediaType; // 'MOVIE' or 'TV'
  final String year;
  final double rating;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
  final String? serverId;
  final String? mediaItemId;

  const Top10Item({
    required this.rank,
    required this.id,
    required this.title,
    this.mediaType = 'MOVIE',
    this.year = '',
    this.rating = 0.0,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.serverId,
    this.mediaItemId,
  });

  factory Top10Item.fromJson(Map<String, dynamic> json) {
    return Top10Item(
      rank: json['rank'] as int? ?? 1,
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'MOVIE',
      year: json['year'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      posterUrl: json['posterUrl'] as String?,
      backdropUrl: json['backdropUrl'] as String?,
      overview: json['overview'] as String?,
      serverId: json['serverId'] as String?,
      mediaItemId: json['mediaItemId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'id': id,
        'title': title,
        'mediaType': mediaType,
        'year': year,
        'rating': rating,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'overview': overview,
        'serverId': serverId,
        'mediaItemId': mediaItemId,
      };
}

class DynamicSection {
  final String id;
  final String title;
  final String? subtitle;
  final DynamicSectionType type;
  final CardVariant cardVariant;
  final List<Top10Item> items;

  const DynamicSection({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.cardVariant = CardVariant.portrait,
    required this.items,
  });

  factory DynamicSection.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? '').toUpperCase();
    DynamicSectionType parsedType;
    switch (typeStr) {
      case 'TOP_10':
      case 'TOP10':
        parsedType = DynamicSectionType.top10;
        break;
      case 'PERSONALIZED':
        parsedType = DynamicSectionType.personalized;
        break;
      case 'TRENDING':
        parsedType = DynamicSectionType.trending;
        break;
      case 'POPULAR':
        parsedType = DynamicSectionType.popular;
        break;
      case 'GENRE_BASED':
      default:
        parsedType = DynamicSectionType.genreBased;
        break;
    }

    final variantStr = (json['cardVariant'] as String? ?? '').toLowerCase();
    final parsedVariant = variantStr == 'landscape' ? CardVariant.landscape : CardVariant.portrait;

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((e) => Top10Item.fromJson(e as Map<String, dynamic>)).toList();

    return DynamicSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      type: parsedType,
      cardVariant: parsedVariant,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type.name,
        'cardVariant': cardVariant.name,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class DynamicLayoutPayload {
  final HeroBannerItem? heroBanner;
  final List<DynamicSection> sections;

  const DynamicLayoutPayload({
    this.heroBanner,
    required this.sections,
  });

  factory DynamicLayoutPayload.fromJson(Map<String, dynamic> json) {
    HeroBannerItem? hero;
    if (json['heroBanner'] != null && json['heroBanner'] is Map<String, dynamic>) {
      hero = HeroBannerItem.fromJson(json['heroBanner'] as Map<String, dynamic>);
    }

    final rawSections = json['sections'] as List<dynamic>? ?? [];
    final parsedSections = rawSections.map((e) => DynamicSection.fromJson(e as Map<String, dynamic>)).toList();

    return DynamicLayoutPayload(
      heroBanner: hero,
      sections: parsedSections,
    );
  }

  Map<String, dynamic> toJson() => {
        if (heroBanner != null) 'heroBanner': heroBanner!.toJson(),
        'sections': sections.map((e) => e.toJson()).toList(),
      };
}
