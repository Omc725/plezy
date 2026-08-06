import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/focusable_wrapper.dart';
import '../models/dynamic_layout_models.dart';
import '../services/dynamic_layout_repository.dart';
import '../theme/mono_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/optimized_media_image.dart';
import '../widgets/top10_section_widget.dart';

/// Dynamic Home Screen widget rendering Netflix-style modular UI sections driven
/// by API payloads. Supports hero spotlight banner, Top 10 rank rows, and D-Pad focus.
class DynamicHomeScreen extends StatefulWidget {
  final String? jsonPayload;

  const DynamicHomeScreen({
    super.key,
    this.jsonPayload,
  });

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  final DynamicLayoutRepository _repository = DynamicLayoutRepository();
  late DynamicLayoutPayload _payload;

  @override
  void initState() {
    super.initState();
    _loadPayload();
  }

  @override
  void didUpdateWidget(covariant DynamicHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonPayload != widget.jsonPayload) {
      _loadPayload();
    }
  }

  void _loadPayload() {
    if (widget.jsonPayload != null && widget.jsonPayload!.isNotEmpty) {
      _payload = _repository.parsePayload(widget.jsonPayload!);
    } else {
      _payload = _repository.getFallbackPayload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: const Text('Dynamic Home'),
      slivers: [
        // Hero Spotlight Banner
        if (_payload.heroBanner != null)
          SliverToBoxAdapter(
            child: _HeroSpotlightBanner(heroItem: _payload.heroBanner!),
          ),

        // Dynamic Section Rows
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final section = _payload.sections[index];
              if (section.type == DynamicSectionType.top10) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Top10SectionWidget(section: section),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _StandardDynamicSectionRow(section: section),
              );
            },
            childCount: _payload.sections.length,
          ),
        ),
      ],
    );
  }
}

/// Hero Spotlight Banner at top of Home Screen
class _HeroSpotlightBanner extends StatelessWidget {
  final HeroBannerItem heroItem;

  const _HeroSpotlightBanner({
    required this.heroItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);

    return Container(
      height: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokensRef.radiusLg),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Backdrop Image
          if (heroItem.backdropUrl != null)
            Positioned.fill(
              child: OptimizedMediaImage(
                imagePath: heroItem.backdropUrl!,
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
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Hero Metadata & Action Button
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  heroItem.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Genres & Rating
                Row(
                  children: [
                    if (heroItem.rating > 0) ...[
                      const AppIcon(Symbols.star_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        heroItem.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (heroItem.year.isNotEmpty) ...[
                      Text(heroItem.year, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      heroItem.genres.join(' • '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Overview
                Text(
                  heroItem.overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),

                // Play Button
                FocusableWrapper(
                  borderRadii: BorderRadius.circular(tokensRef.radiusMd),
                  onSelect: () {},
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const AppIcon(Symbols.play_arrow_rounded, color: Colors.black),
                    label: const Text('Play Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard Horizontal Section Row (Personalized / Trending / Genre-Based)
class _StandardDynamicSectionRow extends StatelessWidget {
  final DynamicSection section;

  const _StandardDynamicSectionRow({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokensRef = tokens(context);
    final isLandscape = section.cardVariant == CardVariant.landscape;
    final cardWidth = isLandscape ? 220.0 : 130.0;
    final rowHeight = isLandscape ? 150.0 : 200.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (section.subtitle != null && section.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  section.subtitle!,
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
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              final borderRadius = BorderRadius.circular(tokensRef.radiusMd);

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FocusableWrapper(
                  borderRadii: borderRadius,
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if (item.posterUrl != null || item.backdropUrl != null)
                          Positioned.fill(
                            child: OptimizedMediaImage(
                              imagePath: (isLandscape ? item.backdropUrl : item.posterUrl) ?? item.posterUrl ?? item.backdropUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),

                        // Title Overlay Gradient
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Title
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
