import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'table_management_page.dart';
import 'kitchen_integration_page.dart' hide AppColors, AppTypography;
import 'delivery_management_page.dart';
import 'payment_management_page.dart';
import 'staff_tracking_page.dart';
import 'crm_management_page.dart';
import 'hardware_integration_page.dart';
import 'multi_branch_page.dart';
import 'remote_access_page.dart';
import 'legal_compliance_page.dart';
import 'cost_control_page.dart';
import 'ai_prediction_page.dart';
import 'digital_marketing_page.dart';
import 'data_security_page.dart';

/// İşletme Özellikler Sayfası
class BusinessFeaturesPage extends StatefulWidget {
  final String businessId;

  const BusinessFeaturesPage({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessFeaturesPage> createState() => _BusinessFeaturesPageState();
}

class _BusinessFeaturesPageState extends State<BusinessFeaturesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Gelişmiş Özellikler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Operasyon'),
            Tab(text: 'Teknoloji'),
            Tab(text: 'Analitik'),
            Tab(text: 'Güvenlik'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOperationTab(),
          _buildTechnologyTab(),
          _buildAnalyticsTab(),
          _buildSecurityTab(),
        ],
      ),
    );
  }

  Widget _buildOperationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureSection(
            'Masa ve Sipariş Yönetimi',
            [
              _buildFeatureCard(
                'Masa Yönetimi',
                'Gerçek zamanlı masa doluluk takibi',
                Icons.table_restaurant_rounded,
                AppColors.primary,
                () => _navigateToPage(TableManagementPage(businessId: widget.businessId)),
              ),
              _buildFeatureCard(
                'Mutfak Entegrasyonu',
                'Kitchen Display System (KDS)',
                Icons.kitchen_rounded,
                AppColors.warning,
                () => _navigateToPage(KitchenIntegrationPage(businessId: widget.businessId)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildFeatureSection(
            'Teslimat ve Ödeme',
            [
              _buildFeatureCard(
                'Teslimat Yönetimi',
                'Kurye ve teslimat takip sistemi',
                Icons.delivery_dining_rounded,
                AppColors.info,
                () => _navigateToPage(DeliveryManagementPage(businessId: widget.businessId)),
              ),
              _buildFeatureCard(
                'Ödeme Yönetimi',
                'POS entegrasyonu ve e-belge',
                Icons.payment_rounded,
                AppColors.success,
                () => _navigateToPage(PaymentManagementPage(businessId: widget.businessId)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildFeatureSection(
            'Personel ve CRM',
            [
              _buildFeatureCard(
                'Personel Takibi',
                'Vardiya ve performans yönetimi',
                Icons.group_rounded,
                AppColors.secondary,
                () => _navigateToPage(StaffTrackingPage(businessId: widget.businessId)),
              ),
              _buildFeatureCard(
                'CRM Yönetimi',
                'Müşteri ilişkileri ve sadakat',
                Icons.people_rounded,
                AppColors.primary,
                () => _navigateToPage(CRMManagementPage(businessId: widget.businessId)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnologyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureSection(
            'Donanım ve Entegrasyon',
            [
              _buildFeatureCard(
                'Donanım Entegrasyonu',
                'POS, yazıcı ve terazi entegrasyonu',
                Icons.devices_rounded,
                AppColors.info,
                () => _navigateToPage(HardwareIntegrationPage(businessId: widget.businessId)),
              ),
              _buildFeatureCard(
                'Şube Yönetimi',
                'Çoklu şube merkezi yönetim',
                Icons.store_mall_directory_rounded,
                AppColors.warning,
                () => _navigateToPage(MultiBranchPage(businessId: widget.businessId)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildFeatureSection(
            'Uzaktan Erişim ve Yasal',
            [
              _buildFeatureCard(
                'Uzaktan Erişim',
                'Bulut tabanlı mobil yönetim',
                Icons.cloud_rounded,
                AppColors.secondary,
                () => _navigateToPage(RemoteAccessPage(businessId: widget.businessId)),
              ),
              _buildFeatureCard(
                'Yasal Uyumluluk',
                'E-fatura ve ÖKC entegrasyonu',
                Icons.gavel_rounded,
                AppColors.error,
                () => _navigateToPage(LegalCompliancePage(businessId: widget.businessId)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureSection(
            'Maliyet ve Kârlılık',
            [
              _buildFeatureCard(
                'Maliyet Kontrolü',
                'Kârlılık analizi ve maliyet takibi',
                Icons.trending_up_rounded,
                AppColors.success,
                () => _navigateToPage(CostControlPage(businessId: widget.businessId)),
              ),
              _buildFeatureCard(
                'AI Tahminleme',
                'Yapay zeka destekli tahminler',
                Icons.psychology_rounded,
                AppColors.primary,
                () => _navigateToPage(AIPredictionPage(businessId: widget.businessId)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildFeatureSection(
            'Pazarlama ve Otomasyon',
            [
              _buildFeatureCard(
                'Dijital Pazarlama',
                'Otomatik kampanya yönetimi',
                Icons.campaign_rounded,
                AppColors.secondary,
                () => _navigateToPage(DigitalMarketingPage(businessId: widget.businessId)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureSection(
            'Veri Güvenliği',
            [
              _buildFeatureCard(
                'Veri Güvenliği',
                'Şifreleme ve yedekleme sistemi',
                Icons.security_rounded,
                AppColors.error,
                () => _navigateToPage(DataSecurityPage(businessId: widget.businessId)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(String title, List<Widget> cards) {
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

  Widget _buildFeatureCard(
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