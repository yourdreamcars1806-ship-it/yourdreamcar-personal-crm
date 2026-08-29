import 'package:flutter/material.dart';

import '../theme/market_colors.dart';
import '../theme/market_theme.dart';
import 'car_network_image.dart';
import 'car_photo_lightbox.dart';

enum _GalleryTab { exterior, interior }

/// Premium multi-photo gallery — exterior & interior tabs, swipe, thumbnails, fullscreen.
class CarGallerySection extends StatefulWidget {
  const CarGallerySection({
    super.key,
    required this.exteriorImages,
    required this.interiorImages,
    this.onImageChanged,
    this.heroHeight = 320,
  });

  final List<String> exteriorImages;
  final List<String> interiorImages;
  final ValueChanged<String>? onImageChanged;
  final double heroHeight;

  @override
  State<CarGallerySection> createState() => _CarGallerySectionState();
}

class _CarGallerySectionState extends State<CarGallerySection> {
  _GalleryTab _tab = _GalleryTab.exterior;
  late final PageController _pageController;
  late final ScrollController _thumbScroll;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _thumbScroll = ScrollController();
    if (_exterior.isEmpty && _interior.isNotEmpty) {
      _tab = _GalleryTab.interior;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyImageChanged();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScroll.dispose();
    super.dispose();
  }

  List<String> get _exterior =>
      widget.exteriorImages.where((u) => u.trim().isNotEmpty).toList();

  List<String> get _interior =>
      widget.interiorImages.where((u) => u.trim().isNotEmpty).toList();

  List<String> get _activeImages =>
      _tab == _GalleryTab.exterior ? _exterior : _interior;

  String get _tabLabel => _tab == _GalleryTab.exterior ? 'Exterior' : 'Interior';

  IconData get _tabIcon => _tab == _GalleryTab.exterior
      ? Icons.directions_car_filled_rounded
      : Icons.weekend_rounded;

  Color get _tabAccent => _tab == _GalleryTab.exterior
      ? MarketColors.primary
      : const Color(0xFF7C3AED);

  void _notifyImageChanged() {
    final images = _activeImages;
    if (images.isEmpty || _index >= images.length) return;
    widget.onImageChanged?.call(images[_index]);
  }

  void _switchTab(_GalleryTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _index = 0;
    });
    _pageController.jumpToPage(0);
    _notifyImageChanged();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _activeImages.length) return;
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _scrollThumbIntoView(i);
  }

  void _scrollThumbIntoView(int i) {
    if (!_thumbScroll.hasClients || _activeImages.length <= 1) return;
    const itemWidth = 86.0;
    const gap = 10.0;
    final offset = (itemWidth + gap) * i - 48;
    _thumbScroll.animateTo(
      offset.clamp(0.0, _thumbScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openFullscreen() {
    final images = _activeImages;
    if (images.isEmpty) return;
    CarPhotoLightbox.open(
      context,
      images: images,
      initialIndex: _index,
      title: _tabLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExterior = _exterior.isNotEmpty;
    final hasInterior = _interior.isNotEmpty;
    if (!hasExterior && !hasInterior) return const SizedBox.shrink();

    final totalPhotos = _exterior.length + _interior.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MarketColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180056D2),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GalleryHeader(totalPhotos: totalPhotos),
          _PremiumTabBar(
            exteriorCount: _exterior.length,
            interiorCount: _interior.length,
            active: _tab,
            onChanged: _switchTab,
          ),
          const SizedBox(height: 12),
          if (_activeImages.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: _EmptyGallery(interior: _tab == _GalleryTab.interior),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: widget.heroHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220056D2),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _activeImages.length,
                      onPageChanged: (i) {
                        setState(() => _index = i);
                        _scrollThumbIntoView(i);
                        _notifyImageChanged();
                      },
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: _openFullscreen,
                        child: Hero(
                          tag: 'car_photo_${_tab.name}_$i',
                          child: ColoredBox(
                            color: const Color(0xFF0F172A),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CarNetworkImage(
                                  url: _activeImages[i],
                                  fit: BoxFit.contain,
                                  cacheWidth: 900,
                                  thumbnail: false,
                                  placeholderIcon: _tabIcon,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.35),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.45),
                                      ],
                                      stops: const [0, 0.45, 1],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _GlassBadge(
                        icon: _tabIcon,
                        label: _tabLabel,
                        accent: _tabAccent,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_activeImages.length > 1)
                            _GlassBadge(
                              label: '${_index + 1} / ${_activeImages.length}',
                            ),
                          const SizedBox(width: 8),
                          _GlassIconButton(
                            icon: Icons.fullscreen_rounded,
                            onTap: _openFullscreen,
                          ),
                        ],
                      ),
                    ),
                    if (_activeImages.length > 1) ...[
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _GlassIconButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: _index > 0 ? () => _goTo(_index - 1) : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _GlassIconButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: _index < _activeImages.length - 1
                                ? () => _goTo(_index + 1)
                                : null,
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to zoom · Swipe for more',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const Spacer(),
                          if (_activeImages.length > 1)
                            _DotIndicator(
                              count: _activeImages.length,
                              index: _index,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _tabAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_tabIcon, size: 14, color: _tabAccent),
                            const SizedBox(width: 6),
                            Text(
                              _activeImages.length == 1
                                  ? '1 $_tabLabel photo'
                                  : '${_activeImages.length} $_tabLabel photos',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: _tabAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.hd_rounded,
                        size: 18,
                        color: MarketColors.muted,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'HD gallery',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: MarketColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 82,
                    child: Stack(
                      children: [
                        ListView.separated(
                          controller: _thumbScroll,
                          scrollDirection: Axis.horizontal,
                          itemCount: _activeImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final selected = i == _index;
                            return GestureDetector(
                              onTap: () => _goTo(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                width: selected ? 92 : 78,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? _tabAccent
                                        : MarketColors.line,
                                    width: selected ? 2.5 : 1,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: _tabAccent.withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : const [],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: const Color(0xFF0F172A),
                                      child: CarNetworkImage(
                                        url: _activeImages[i],
                                        fit: BoxFit.contain,
                                        cacheWidth: 120,
                                        placeholderIcon: _tabIcon,
                                      ),
                                    ),
                                    if (selected)
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      left: 6,
                                      bottom: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 18,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 18,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({required this.totalPhotos});

  final int totalPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFF), Color(0xFFEEF4FF)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MarketColors.primary, MarketColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x400056D2),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: MarketColors.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalPhotos high-res photos · Exterior & interior',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: MarketColors.muted,
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

class _PremiumTabBar extends StatelessWidget {
  const _PremiumTabBar({
    required this.exteriorCount,
    required this.interiorCount,
    required this.active,
    required this.onChanged,
  });

  final int exteriorCount;
  final int interiorCount;
  final _GalleryTab active;
  final ValueChanged<_GalleryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MarketColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              Expanded(
                child: _TabChip(
                  label: 'Exterior',
                  count: exteriorCount,
                  icon: Icons.directions_car_filled_rounded,
                  accent: MarketColors.primary,
                  selected: active == _GalleryTab.exterior,
                  onTap: () => onChanged(_GalleryTab.exterior),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TabChip(
                  label: 'Interior',
                  count: interiorCount,
                  icon: Icons.weekend_rounded,
                  accent: const Color(0xFF7C3AED),
                  selected: active == _GalleryTab.interior,
                  onTap: () => onChanged(_GalleryTab.interior),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.85)],
              )
            : null,
        color: selected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? Colors.white : MarketColors.muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: selected ? Colors.white : MarketColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _CountPill(count: count, active: selected, onAccent: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
    required this.active,
    required this.onAccent,
  });

  final int count;
  final bool active;
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: onAccent
            ? Colors.white.withValues(alpha: 0.22)
            : active
                ? MarketColors.primary.withValues(alpha: 0.14)
                : MarketColors.line,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: onAccent ? Colors.white : MarketColors.muted,
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    this.icon,
    required this.label,
    this.accent,
  });

  final IconData? icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent ?? Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: onTap == null ? 0.25 : 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: onTap == null ? 0.45 : 1),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count.clamp(0, 6), (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 16 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.interior});

  final bool interior;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MarketColors.chipBg,
            MarketColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MarketColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: MarketTheme.cardShadow,
            ),
            child: Icon(
              interior ? Icons.weekend_outlined : Icons.directions_car_outlined,
              size: 34,
              color: MarketColors.primary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            interior ? 'No interior photos yet' : 'No exterior photos yet',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: MarketColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              interior
                  ? 'Dashboard, seats & cabin shots appear here once uploaded'
                  : 'Front, side, rear & detail shots appear here once uploaded',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: MarketColors.muted,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
