import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';
import '../services/business_firestore_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';

// Widget imports
import '../widgets/category_settings_widget.dart';
import '../widgets/theme_settings_widget.dart';
import '../widgets/layout_settings_widget.dart';
import '../widgets/color_settings_widget.dart';
import '../widgets/typography_settings_widget.dart';
import '../widgets/style_settings_widget.dart';
import '../widgets/interaction_settings_widget.dart';

/// 🎨 Gelişmiş Menü Tasarım Ayarları Sayfası
///
/// Bu sayfa işletme sahiplerinin menü görünümünü tamamen özelleştirmesini sağlar:
/// - Tema seçimi (Modern, Klasik, Izgara, Dergi)
/// - Layout düzenlemeleri
/// - Renk paleti özelleştirme
/// - Tipografi ayarları
/// - Görsel stil seçenekleri
/// - Etkileşim ayarları
/// - Kategori stil ayarları
class MenuDesignSettingsPage extends StatefulWidget {
  final String businessId;
  final Business? business;

  const MenuDesignSettingsPage({
    super.key,
    required this.businessId,
    this.business,
  });

  @override
  State<MenuDesignSettingsPage> createState() => _MenuDesignSettingsPageState();
}

class _MenuDesignSettingsPageState extends State<MenuDesignSettingsPage>
    with TickerProviderStateMixin {
  final BusinessFirestoreService _businessService = BusinessFirestoreService();

  Business? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  late TabController _tabController;
  late MenuSettings _currentSettings;
  late MenuSettings _originalSettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadBusinessData();
  }

  void _updateSettings(MenuSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final business = widget.business ??
          await _businessService.getBusinessById(widget.businessId);

      if (business != null) {
        setState(() {
          _business = business;
          _currentSettings = business.menuSettings;
          _originalSettings = business.menuSettings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'İşletme bulunamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_business == null) return;

    try {
      setState(() => _isSaving = true);

      final updatedBusiness = _business!.copyWith(
        menuSettings: _currentSettings,
        updatedAt: DateTime.now(),
      );

      await _businessService.updateBusiness(updatedBusiness);

      setState(() {
        _business = updatedBusiness;
        _originalSettings = _currentSettings;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Tasarım ayarları başarıyla kaydedildi!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kaydetme hatası: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _resetToOriginal() {
    setState(() {
      _currentSettings = _originalSettings;
    });
  }

  bool get _hasChanges => _currentSettings != _originalSettings;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tasarım Ayarları')),
        body: Center(
          child: ErrorMessage(
            message: _errorMessage!,
            onRetry: _loadBusinessData,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          '🎨 Menü Tasarım Ayarları',
          style: AppTypography.headingLarge,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_hasChanges) ...[
            TextButton(
              onPressed: _resetToOriginal,
              child: const Text('Sıfırla'),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton(
            onPressed: _hasChanges ? _saveSettings : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Kaydet'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.palette_rounded), text: 'Tema'),
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Layout'),
            Tab(icon: Icon(Icons.color_lens_rounded), text: 'Renkler'),
            Tab(icon: Icon(Icons.text_fields_rounded), text: 'Yazı Tipi'),
            Tab(icon: Icon(Icons.style_rounded), text: 'Stil'),
            Tab(icon: Icon(Icons.touch_app_rounded), text: 'Etkileşim'),
            Tab(icon: Icon(Icons.category_rounded), text: 'Kategoriler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ThemeSettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
          LayoutSettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
          ColorSettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
            business: _business,
          ),
          TypographySettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
          StyleSettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
          InteractionSettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
          CategorySettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydedilmemiş Değişiklikler'),
        content: const Text(
          'Değişiklikleriniz kaydedilmemiş. Çıkmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Sayfadan çık
            },
            child: const Text(
              'Çık',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              _saveSettings(); // Kaydet
            },
            child: const Text('Kaydet ve Çık'),
          ),
        ],
      ),
    );
  }
}
