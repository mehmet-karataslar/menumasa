import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'kitchen_integration_page.dart';
import 'delivery_management_page.dart';
import 'payment_management_page.dart';
import 'crm_management_page.dart';
import 'hardware_integration_page.dart';
import 'multi_branch_page.dart';
import 'remote_access_page.dart';
import 'legal_compliance_page.dart';
import 'cost_control_page.dart';
import 'ai_prediction_page.dart';
import 'digital_marketing_page.dart';
import 'data_security_page.dart';
import 'analytics_page.dart';
import 'stock_management_page.dart';

class FutureFeaturesTabPage extends StatefulWidget {
  final String businessId;

  const FutureFeaturesTabPage({
    super.key,
    required this.businessId,
  });

  @override
  State<FutureFeaturesTabPage> createState() => _FutureFeaturesTabPageState();
}

class _FutureFeaturesTabPageState extends State<FutureFeaturesTabPage>
    with TickerProviderStateMixin {
  late TabController _subTabController;

  final List<String> _subTabTitles = [
    'Mutfak Entegrasyonu',
    'Teslimat Yönetimi',
    'Ödeme Yönetimi',
    'CRM Yönetimi',
    'Donanım Entegrasyonu',
    'Şube Yönetimi',
    'Uzaktan Erişim',
    'Yasal Uyumluluk',
    'Maliyet Kontrolü',
    'AI Tahminleme',
    'Dijital Pazarlama',
    'Veri Güvenliği',
    'Analitikler',
    'Stok Yönetimi',
  ];

  final List<IconData> _subTabIcons = [
    Icons.kitchen_rounded,
    Icons.delivery_dining_rounded,
    Icons.payment_rounded,
    Icons.people_rounded,
    Icons.devices_rounded,
    Icons.store_mall_directory_rounded,
    Icons.cloud_rounded,
    Icons.gavel_rounded,
    Icons.trending_up_rounded,
    Icons.psychology_rounded,
    Icons.campaign_rounded,
    Icons.security_rounded,
    Icons.analytics_rounded,
    Icons.inventory_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _subTabController =
        TabController(length: _subTabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSubTabBar(),
        Expanded(child: _buildSubTabView()),
      ],
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yakında Gelecek Özellikler',
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'İşletmenizi güçlendirecek gelişmiş özellikler',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _subTabController,
            isScrollable: true,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withBlue(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            labelStyle: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            unselectedLabelStyle: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            dividerColor: Colors.transparent,
            tabs: List.generate(
              _subTabTitles.length,
              (index) => Tab(
                height: 64,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_subTabIcons[index], size: 18),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          _subTabTitles[index],
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabView() {
    return TabBarView(
      controller: _subTabController,
      children: [
        KitchenIntegrationPage(businessId: widget.businessId),
        DeliveryManagementPage(businessId: widget.businessId),
        PaymentManagementPage(businessId: widget.businessId),
        CRMManagementPage(businessId: widget.businessId),
        HardwareIntegrationPage(businessId: widget.businessId),
        MultiBranchPage(businessId: widget.businessId),
        RemoteAccessPage(businessId: widget.businessId),
        LegalCompliancePage(businessId: widget.businessId),
        CostControlPage(businessId: widget.businessId),
        AIPredictionPage(businessId: widget.businessId),
        DigitalMarketingPage(businessId: widget.businessId),
        DataSecurityPage(businessId: widget.businessId),
        AnalyticsPage(businessId: widget.businessId),
        StockManagementPage(businessId: widget.businessId),
      ],
    );
  }
}
