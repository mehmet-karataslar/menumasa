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
    if (kIsWeb) {
      // CORS proxy ile Firebase Storage URL'lerini çöz
      String proxiedUrl = _getProxiedUrl(imageUrl);

      return Image.network(
        proxiedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder?.call(context, imageUrl) ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          print('🚨 Web image error for $imageUrl: $error');
          // Proxy başarısız olursa orijinal URL'i dene
          if (proxiedUrl != imageUrl) {
            return Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: fit ?? BoxFit.cover,
              errorBuilder: (context, error2, stackTrace2) {
                print('🚨 Original URL also failed for $imageUrl: $error2');
                return errorWidget?.call(context, imageUrl, error2) ??
                    Container(
                      width: width,
                      height: height,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
              },
            );
          }

          return errorWidget?.call(context, imageUrl, error) ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit ?? BoxFit.cover,
      width: width,
      height: height,
      placeholder: placeholder ??
          (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
      errorWidget: errorWidget ??
          (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
    );
  }

  /// CORS proxy URL'i oluştur
  String _getProxiedUrl(String originalUrl) {
    // Firebase Storage URL'leri için token'sız erişim dene
    if (originalUrl.contains('firebasestorage.googleapis.com')) {
      try {
        final uri = Uri.parse(originalUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty && pathSegments[0] == 'v0') {
          // /v0/b/bucket/o/path?alt=media&token=xxx formatındaki URL'yi
          // /v0/b/bucket/o/path?alt=media formatına çevir (token'sız)
          final newUri = Uri(
            scheme: uri.scheme,
            host: uri.host,
            pathSegments: pathSegments,
            queryParameters: {'alt': 'media'}, // Sadece alt=media, token kaldır
          );

          print('🔄 Trying tokenless URL: $newUri');
          return newUri.toString();
        }
      } catch (e) {
        print('🚨 URL parsing error: $e');
      }
    }

    // Orijinal URL'i kullan
    return originalUrl;
  }
}
