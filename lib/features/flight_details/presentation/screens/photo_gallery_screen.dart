import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/flight_details/data/services/photo_gallery_service.dart';

/// Full-screen aircraft photo gallery with swipe + thumbnail strip.
///
/// <p>Mirrors the web frontend's `PhotoGallery.tsx` modal:
/// <ul>
///   <li>full-screen black backdrop;</li>
///   <li>main photo with left/right chevrons;</li>
///   <li>thumbnail strip at the bottom (tap to jump);</li>
///   <li>"Photo by … · planespotters.net" attribution line.</li>
/// </ul>
///
/// <p>Swipe is a [PageView] which feels native on phones; the web's
/// keyboard arrow handling isn't relevant on mobile. Tapping outside
/// the photo or the close icon dismisses the route.
class PhotoGalleryScreen extends StatefulWidget {
  /// Aircraft ICAO24 hex used to fetch the planespotters.net photos.
  final String icao24;

  const PhotoGalleryScreen({super.key, required this.icao24});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final _service = PhotoGalleryService();
  final _pageCtl = PageController();
  List<AircraftPhoto> _photos = const [];
  bool _loading = true;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photos = await _service.fetchPhotos(widget.icao24);
    if (!mounted) return;
    setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (_photos.isEmpty) return;
    final n = _photos.length;
    final next = (i + n) % n;
    _pageCtl.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: _loading
              ? const Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white24,
                    size: 36,
                  ),
                )
              : _photos.isEmpty
              ? _Empty(onClose: () => Navigator.of(context).maybePop())
              : _Gallery(
                  photos: _photos,
                  pageCtl: _pageCtl,
                  currentIndex: _index,
                  onIndexChanged: (i) => setState(() => _index = i),
                  onPrev: () => _go(_index - 1),
                  onNext: () => _go(_index + 1),
                  onClose: () => Navigator.of(context).maybePop(),
                ),
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.photos,
    required this.pageCtl,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
  });

  final List<AircraftPhoto> photos;
  final PageController pageCtl;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final photo = photos[currentIndex];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(
                '${currentIndex + 1} / ${photos.length}',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main photo (PageView for swipe)
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: pageCtl,
                itemCount: photos.length,
                onPageChanged: onIndexChanged,
                itemBuilder: (_, i) => GestureDetector(
                  // Swallow taps inside the photo so the outer dismiss
                  // gesture only fires when the user taps the backdrop.
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: photos[i].fullUrl,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white24,
                        size: 48,
                      ),
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white24,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (photos.length > 1) ...[
                Positioned(
                  left: 8,
                  child: _NavButton(icon: Icons.chevron_left, onTap: onPrev),
                ),
                Positioned(
                  right: 8,
                  child: _NavButton(icon: Icons.chevron_right, onTap: onNext),
                ),
              ],
            ],
          ),
        ),

        // Footer: photographer credit + thumbnails.
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (photo.photographer != null && photo.photographer!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Photo by ${photo.photographer} · planespotters.net',
                    style: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              if (photos.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final active = i == currentIndex;
                      return GestureDetector(
                        onTap: () {
                          pageCtl.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: active ? 1.0 : 0.45,
                          child: Container(
                            width: 60,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: active
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: CachedNetworkImage(
                                imageUrl: photos[i].thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No photos available',
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                'CLOSE',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
