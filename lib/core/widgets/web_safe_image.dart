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
    // Web platformunda Image.network kullan (HTML renderer ile çalışır)
    if (kIsWeb) {
      return Container(
        width: width,
        height: height,
        child: Image.network(
          imageUrl,
          fit: fit ?? BoxFit.cover,
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
            return errorWidget?.call(context, imageUrl, error) ??
                Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                );
          },
        ),
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
}
