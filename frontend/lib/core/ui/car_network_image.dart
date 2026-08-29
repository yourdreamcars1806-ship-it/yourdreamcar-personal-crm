import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../format/car_image_url.dart';
import 'car_image_placeholder.dart';

/// Fast car image with disk cache, CDN thumbnails, and lightweight placeholder.
class CarNetworkImage extends StatefulWidget {
  const CarNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.thumbnail = true,
    this.placeholderIcon = Icons.directions_car_filled_rounded,
    this.placeholderLabel,
  });

  final String url;
  final BoxFit fit;
  final int? cacheWidth;
  final bool thumbnail;
  final IconData placeholderIcon;
  final String? placeholderLabel;

  @override
  State<CarNetworkImage> createState() => _CarNetworkImageState();
}

class _CarNetworkImageState extends State<CarNetworkImage> {
  bool _useLimitFallback = false;

  @override
  void didUpdateWidget(CarNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _useLimitFallback = false;
    }
  }

  String _resolveUrl(String trimmed, int decodeWidth) {
    if (_useLimitFallback) {
      return carThumbnailUrl(
        trimmed,
        width: decodeWidth,
        quality: widget.thumbnail ? 'eco' : 'good',
        crop: false,
      );
    }
    if (widget.thumbnail) {
      return carListImageUrl(trimmed, width: decodeWidth);
    }
    return carDetailImageUrl(trimmed, width: decodeWidth);
  }

  Widget _placeholder({bool loading = false}) {
    return CarImagePlaceholder(
      icon: widget.placeholderIcon,
      label: widget.placeholderLabel,
      fit: widget.fit,
      loading: loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.url.trim();
    if (trimmed.isEmpty) return _placeholder();

    final decodeWidth = widget.cacheWidth ?? (widget.thumbnail ? 320 : 900);
    final src = _resolveUrl(trimmed, decodeWidth);

    return CachedNetworkImage(
      key: ValueKey('$src#$_useLimitFallback'),
      imageUrl: src,
      fit: widget.fit,
      memCacheWidth: decodeWidth,
      maxWidthDiskCache: decodeWidth,
      maxHeightDiskCache: widget.thumbnail ? (decodeWidth * 0.62).round() : null,
      filterQuality: widget.thumbnail ? FilterQuality.low : FilterQuality.medium,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => _placeholder(loading: true),
      errorWidget: (_, _, _) {
        if (!_useLimitFallback && trimmed.contains('/upload/')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useLimitFallback = true);
          });
          return _placeholder(loading: true);
        }
        return _placeholder();
      },
    );
  }
}
