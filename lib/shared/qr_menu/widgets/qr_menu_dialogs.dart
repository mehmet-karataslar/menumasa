import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

/// Enhanced dialog system for QR Menu
class QRMenuDialogs {
  QRMenuDialogs._();

  /// Show guest cart dialog with registration encouragement
  static void showGuestCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.shopping_cart_rounded, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sepete Erişim',
                    style:
                        AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Daha iyi deneyim için kayıt olun',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Kayıtlı Kullanıcı Avantajları',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                      '🛒', 'Sepetinizi kaydedin ve istediğiniz zaman erişin'),
                  _buildAdvantageItem('❤️', 'Favori ürünlerinizi hatırlayın'),
                  _buildAdvantageItem('📋', 'Geçmiş siparişlerinizi görün'),
                  _buildAdvantageItem(
                      '🔔', 'Sipariş durumu bildirimlerini alın'),
                  _buildAdvantageItem(
                      '🎁', 'Özel kampanya ve indirimleri kaçırmayın'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Misafir modunda sepete eklediğiniz ürünler kaydedilmez ve sipariş veremezsiniz.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Misafir Olarak Devam Et'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register',
                  arguments: {'userType': 'customer'});
            },
            icon: Icon(Icons.person_add, size: 18),
            label: Text('Hızlı Kayıt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              'Giriş Yap',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Show guest waiter call dialog
  static void showGuestWaiterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.room_service_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Garson Çağır',
                    style:
                        AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Daha iyi hizmet için kayıt olun',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Misafir modunda da garson çağırabilirsiniz, ancak kayıtlı kullanıcılar öncelikli hizmet alır.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kayıtlı Kullanıcı Hizmet Avantajları:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildAdvantageItem('⚡', 'Öncelikli garson hizmeti'),
            _buildAdvantageItem('📱', 'Garson ile direkt iletişim'),
            _buildAdvantageItem('🕐', 'Hizmet süresi takibi'),
            _buildAdvantageItem('⭐', 'Hizmet değerlendirme'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Call waiter as guest
              _callWaiterAsGuest(context);
            },
            icon: Icon(Icons.room_service, size: 18),
            label: Text('Misafir Garson Çağır'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register',
                  arguments: {'userType': 'customer'});
            },
            icon: Icon(Icons.person_add, size: 18),
            label: Text('Kayıt Ol'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show favorite encouragement dialog for guests
  static void showGuestFavoriteDialog(
      BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.favorite_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorilere Ekle',
                    style:
                        AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Beğendiğiniz ürünleri hatırlayın',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$productName" ürününü beğendiniz!',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kayıt olarak favori ürünlerinizi kaydedebilir, bir sonraki ziyaretinizde kolayca bulabilirsiniz.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAdvantageItem(
                '💾', 'Favori ürünleriniz kalıcı olarak kaydedilir'),
            _buildAdvantageItem('🔍', 'Favori ürünlerinizi kolayca bulun'),
            _buildAdvantageItem('🎯', 'Size özel öneriler alın'),
            _buildAdvantageItem('📊', 'Beğenilerinize göre menü önerileri'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Şimdi Değil'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register', arguments: {
                'userType': 'customer',
                'favoriteProduct': productName,
              });
            },
            icon: Icon(Icons.favorite, size: 18),
            label: Text('Kayıt Ol ve Favorile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show order encouragement dialog for guests
  static void showGuestOrderDialog(BuildContext context,
      {int itemCount = 0, double totalPrice = 0.0}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.restaurant_menu_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş Ver',
                    style:
                        AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Güvenli sipariş için kayıt olun',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Sepetinizde $itemCount ürün var',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toplam: ${totalPrice.toStringAsFixed(2)} ₺',
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Misafir kullanıcılar sipariş veremez. Sipariş vermek için sisteme kayıt olmanız gerekmektedir.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kayıtlı Kullanıcı Sipariş Avantajları:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildAdvantageItem('✅', 'Güvenli ve hızlı sipariş verme'),
            _buildAdvantageItem('📱', 'Sipariş durumu takibi'),
            _buildAdvantageItem('🔔', 'Anlık bildirimler'),
            _buildAdvantageItem('💳', 'Güvenli ödeme seçenekleri'),
            _buildAdvantageItem('📋', 'Sipariş geçmişi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register', arguments: {
                'userType': 'customer',
                'returnToCart': true,
              });
            },
            icon: Icon(Icons.person_add, size: 18),
            label: Text('Hızlı Kayıt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              'Giriş Yap',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAdvantageItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _callWaiterAsGuest(BuildContext context) {
    // Implement guest waiter call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Misafir garson çağrısı gönderildi. Kayıtlı kullanıcılar öncelik alır.'),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
