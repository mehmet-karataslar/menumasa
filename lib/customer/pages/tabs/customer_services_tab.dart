import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../payment_page.dart';
import '../loyalty_page.dart';
import '../online_order_page.dart';
import '../reservation_page.dart';
import '../campaigns_page.dart';
import '../feedback_page.dart';
import '../invoice_page.dart';
import '../order_tracking_page.dart';
import '../recommendations_page.dart';
import '../voice_order_page.dart';

/// Müşteri Hizmetleri Sekmesi
class CustomerServicesTab extends StatefulWidget {
  final String? customerId;
  final String? businessId;

  const CustomerServicesTab({
    super.key,
    this.customerId,
    this.businessId,
  });

  @override
  State<CustomerServicesTab> createState() => _CustomerServicesTabState();
}

class _CustomerServicesTabState extends State<CustomerServicesTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hizmetler',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Ödeme ve İşlemler
            _buildServiceSection(
              'Ödeme ve İşlemler',
              [
                _buildServiceCard(
                  'Temassız Ödeme',
                  'QR kod ve mobil ödeme çözümleri',
                  Icons.payment_rounded,
                  AppColors.primary,
                  () => _navigateToPage(const PaymentPage()),
                ),
                _buildServiceCard(
                  'Fatura & Fiş',
                  'Dijital fatura ve fiş talep et',
                  Icons.receipt_rounded,
                  AppColors.info,
                  () => _navigateToPage(const InvoicePage()),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Sadakat ve Kampanyalar
            _buildServiceSection(
              'Sadakat ve Kampanyalar',
              [
                _buildServiceCard(
                  'Puan Sistemi',
                  'Puan biriktir, indirimlerden faydalan',
                  Icons.loyalty_rounded,
                  AppColors.secondary,
                  () => _navigateToPage(LoyaltyPage(customerId: widget.customerId)),
                ),
                _buildServiceCard(
                  'Kampanyalar',
                  'Özel kampanya ve duyuruları gör',
                  Icons.local_offer_rounded,
                  AppColors.success,
                  () => _navigateToPage(CampaignsPage(businessId: widget.businessId)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Sipariş ve Teslimat
            _buildServiceSection(
              'Sipariş ve Teslimat',
              [
                _buildServiceCard(
                  'Online Sipariş',
                  'Paket servis ve teslimat',
                  Icons.delivery_dining_rounded,
                  AppColors.info,
                  () => _navigateToPage(OnlineOrderPage(businessId: widget.businessId)),
                ),
                _buildServiceCard(
                  'Sipariş Takibi',
                  'Canlı teslimat takip et',
                  Icons.local_shipping_rounded,
                  AppColors.warning,
                  () => _navigateToPage(const OrderTrackingPage()),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Rezervasyon ve Öneriler
            _buildServiceSection(
              'Rezervasyon ve Öneriler',
              [
                _buildServiceCard(
                  'Masa Rezervasyonu',
                  'Kolay masa rezervasyon sistemi',
                  Icons.table_restaurant_rounded,
                  AppColors.warning,
                  () => _navigateToPage(ReservationPage(businessId: widget.businessId)),
                ),
                _buildServiceCard(
                  'Kişisel Öneriler',
                  'AI destekli ürün önerileri',
                  Icons.recommend_rounded,
                  AppColors.success,
                  () => _navigateToPage(RecommendationsPage(
                    customerId: widget.customerId,
                    businessId: widget.businessId,
                  )),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Değerlendirme ve Yenilikçi Özellikler
            _buildServiceSection(
              'Değerlendirme ve İnovasyon',
              [
                _buildServiceCard(
                  'Değerlendirme',
                  'Hizmet kalitesini değerlendir',
                  Icons.rate_review_rounded,
                  AppColors.primary,
                  () => _navigateToPage(FeedbackPage(businessId: widget.businessId)),
                ),
                _buildServiceCard(
                  'Sesli Sipariş',
                  'AI destekli sesli sipariş sistemi',
                  Icons.mic_rounded,
                  AppColors.secondary,
                  () => _navigateToPage(VoiceOrderPage(businessId: widget.businessId)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.greyLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
} 