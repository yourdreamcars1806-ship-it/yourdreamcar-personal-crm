/// Cloudinary-optimized image URLs for fast list/detail loading.
String carThumbnailUrl(
  String url, {
  int width = 360,
  String quality = 'eco',
  bool progressive = true,
  bool crop = true,
}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  const marker = '/upload/';
  final markerIndex = trimmed.indexOf(marker);
  if (markerIndex == -1) return trimmed;

  final afterUpload = trimmed.substring(markerIndex + marker.length);
  if (RegExp(r'^(w_|c_|h_|f_|q_|g_|fl_)').hasMatch(afterUpload)) {
    return trimmed;
  }

  final size = crop
      ? 'w_$width,h_${(width * 0.62).round()},c_fill'
      : 'w_$width,c_limit';
  final parts = <String>[
    size,
    'q_auto:$quality',
    'f_auto',
    if (progressive) 'fl_progressive:steep',
  ];
  final transform = parts.join(',');
  return '${trimmed.substring(0, markerIndex + marker.length)}$transform/$afterUpload';
}

/// Small list/card thumbnails — smallest bytes.
String carListImageUrl(String url, {int width = 320}) =>
    carThumbnailUrl(url, width: width, quality: 'eco', progressive: true);

/// Detail hero / gallery — full car visible, no crop.
String carDetailImageUrl(String url, {int width = 900}) =>
    carThumbnailUrl(url, width: width, quality: 'good', progressive: true, crop: false);
