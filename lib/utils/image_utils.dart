import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Pre-caches a list of image URLs.
  /// Use this when data is first loaded (e.g., initialization of Home Screen).
  static void preCacheImages(BuildContext context, List<String> urls) {
    for (final url in urls) {
      if (url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }
}
