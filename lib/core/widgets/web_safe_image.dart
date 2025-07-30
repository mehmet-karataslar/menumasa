import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Web platformunda güvenli görüntü yükleme widget'ı
/// CORS sorunlarını çözmek için platform kontrolü yapar
class WebSafeImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const WebSafeImage({
    Key? key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Web platformunda CORS sorununu çözmek için özel yaklaşım
    if (kIsWeb) {
      return Container(
        width: width,
        height: height,
        child: _buildWebImage(),
      );
    }

    // Mobil platformlarda normal CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit ?? BoxFit.cover,
      width: width,
      height: height,
      placeholder: placeholder ??
          (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      errorWidget: errorWidget ??
          (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
    );
  }

  /// Web için CORS güvenli görüntü oluştur
  Widget _buildWebImage() {
    // Firebase Storage URL'lerini CORS proxy ile çözme
    String processedUrl = _getCorsProxyUrl(imageUrl);

    return Image.network(
      processedUrl,
      fit: fit ?? BoxFit.cover,
      headers: {
        'Cache-Control': 'no-cache',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder?.call(context, imageUrl) ??
            Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        // Hata durumunda alternatif yöntemler dene
        return _buildFallbackImage(context, error);
      },
    );
  }

  /// CORS proxy URL'i oluştur
  String _getCorsProxyUrl(String originalUrl) {
    // Firebase Storage URL'lerini doğrudan kullan
    // Web renderer HTML kullandığı için CORS sorunu olmamalı
    return originalUrl;
  }

  /// Yedek görüntü widget'ı
  Widget _buildFallbackImage(BuildContext context, dynamic error) {
    if (kDebugMode) {
      print('WebSafeImage error for $imageUrl: $error');
    }

    return errorWidget?.call(context, imageUrl, error) ??
        Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 32,
          ),
        );
  }
}
