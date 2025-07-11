import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/business.dart';
import '../../../core/services/data_service.dart';
import '../../widgets/shared/loading_indicator.dart';

class BusinessInfoPage extends StatefulWidget {
  final String businessId;

  const BusinessInfoPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final DataService _dataService = DataService();
  Business? _business;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataService.initialize();
      final business = await _dataService.getBusiness(widget.businessId);

      setState(() {
        _business = business;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'İşletme Bilgileri',
          style: AppTypography.h3.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _business == null
          ? const Center(child: Text('İşletme bilgileri bulunamadı'))
          : _buildBusinessInfo(),
    );
  }

  Widget _buildBusinessInfo() {
    return SingleChildScrollView(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temel Bilgiler', style: AppTypography.h4),
                  const SizedBox(height: 16),
                  _buildInfoItem('İşletme Adı', _business!.businessName),
                  _buildInfoItem('Açıklama', _business!.businessDescription),
                  _buildInfoItem(
                    'Durumu',
                    _business!.isActive ? 'Aktif' : 'Pasif',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('İletişim Bilgileri', style: AppTypography.h4),
                  const SizedBox(height: 16),
                  _buildInfoItem('Telefon', _business!.contactInfo.phone),
                  _buildInfoItem('E-posta', _business!.contactInfo.email),
                  _buildInfoItem(
                    'Website',
                    _business!.contactInfo.website ?? 'Belirtilmemiş',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Address Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adres Bilgileri', style: AppTypography.h4),
                  const SizedBox(height: 16),
                  _buildInfoItem('Sokak', _business!.address.street),
                  _buildInfoItem('İlçe', _business!.address.district),
                  _buildInfoItem('İl', _business!.address.city),
                  _buildInfoItem('Posta Kodu', _business!.address.postalCode),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _editBusinessInfo,
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareBusinessInfo,
                  icon: const Icon(Icons.share),
                  label: const Text('Paylaş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  void _editBusinessInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İşletme bilgileri düzenleme özelliği yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _shareBusinessInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İşletme bilgileri paylaşıldı'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
