import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

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

    // HTML img elementi oluştur ve kaydet
    final String viewType = 'web-safe-img-${processedUrl.hashCode}';

    // HTML img elementini oluştur ve platformViewRegistry'ye kaydet
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final html.ImageElement imageElement = html.ImageElement()
          ..src = processedUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..crossOrigin = 'anonymous'; // CORS için

        // Hata durumunda placeholder göster
        imageElement.onError.listen((event) {
          imageElement.src =
              'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPk5vIEltYWdlPC90ZXh0Pjwvc3ZnPg==';
        });

        return imageElement;
      },
    );

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }

  /// CORS proxy URL'i oluştur
  String _getCorsProxyUrl(String originalUrl) {
    // Firebase Storage URL'lerini doğrudan kullan
    // Web renderer HTML kullandığı için CORS sorunu olmamalı
    return originalUrl;
  }
}
