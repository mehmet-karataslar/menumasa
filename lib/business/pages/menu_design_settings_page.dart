import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

/// 🎨 Gelişmiş Menü Tasarım Ayarları Sayfası
///
/// Bu sayfa işletme sahiplerinin menü görünümünü tamamen özelleştirmesini sağlar:
/// - Tema seçimi (Modern, Klasik, Izgara, Dergi)
/// - Layout düzenlemeleri
/// - Renk paleti özelleştirme
/// - Tipografi ayarları
/// - Görsel stil seçenekleri
/// - Etkileşim ayarları
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
    _tabController =
        TabController(length: 7, vsync: this); // Kategori sekmesi eklendi
    _loadBusinessData();
  }

  void _updateSettings(MenuSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
  }

  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary; // Fallback color
    }
  }

  /// Tüm mevcut renkleri getir
  List<Color> _getAllColors() {
    final quickColors = [
      const Color(0xFFE53E3E), // Kırmızı
      const Color(0xFFDD6B20), // Turuncu
      const Color(0xFFD69E2E), // Sarı
      const Color(0xFF38A169), // Yeşil
      const Color(0xFF3182CE), // Mavi
      const Color(0xFF805AD5), // Mor
      const Color(0xFFD53F8C), // Pembe
      const Color(0xFF319795), // Teal
      const Color(0xFF2B6CB0), // Lacivert
      const Color(0xFF2D3748), // Koyu gri
      const Color(0xFF4A5568), // Gri
      const Color(0xFF718096), // Açık gri
    ];

    final materialColors = [
      Colors.red.shade300,
      Colors.red.shade500,
      Colors.red.shade700,
      Colors.pink.shade300,
      Colors.pink.shade500,
      Colors.pink.shade700,
      Colors.purple.shade300,
      Colors.purple.shade500,
      Colors.purple.shade700,
      Colors.deepPurple.shade300,
      Colors.deepPurple.shade500,
      Colors.deepPurple.shade700,
      Colors.indigo.shade300,
      Colors.indigo.shade500,
      Colors.indigo.shade700,
      Colors.blue.shade300,
      Colors.blue.shade500,
      Colors.blue.shade700,
      Colors.lightBlue.shade300,
      Colors.lightBlue.shade500,
      Colors.lightBlue.shade700,
      Colors.cyan.shade300,
      Colors.cyan.shade500,
      Colors.cyan.shade700,
      Colors.teal.shade300,
      Colors.teal.shade500,
      Colors.teal.shade700,
      Colors.green.shade300,
      Colors.green.shade500,
      Colors.green.shade700,
      Colors.lightGreen.shade300,
      Colors.lightGreen.shade500,
      Colors.lightGreen.shade700,
      Colors.lime.shade300,
      Colors.lime.shade500,
      Colors.lime.shade700,
      Colors.yellow.shade300,
      Colors.yellow.shade500,
      Colors.yellow.shade700,
      Colors.amber.shade300,
      Colors.amber.shade500,
      Colors.amber.shade700,
      Colors.orange.shade300,
      Colors.orange.shade500,
      Colors.orange.shade700,
      Colors.deepOrange.shade300,
      Colors.deepOrange.shade500,
      Colors.deepOrange.shade700,
      Colors.brown.shade300,
      Colors.brown.shade500,
      Colors.brown.shade700,
      Colors.grey.shade300,
      Colors.grey.shade500,
      Colors.grey.shade700,
      Colors.blueGrey.shade300,
      Colors.blueGrey.shade500,
      Colors.blueGrey.shade700,
    ];

    return [...quickColors, ...materialColors];
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

      // İşletme ayarlarını güncelle
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
          _buildColorTab(),
          _buildTypographyTab(),
          _buildStyleTab(),
          _buildInteractionTab(),
          CategorySettingsWidget(
            currentSettings: _currentSettings,
            onSettingsChanged: _updateSettings,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // KALAN WIDGET'LAR (Henüz ayrılmamış)
  // ============================================================================

  Widget _buildColorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Renk Ayarları',
            'Menünüzün renklerini özelleştirin',
            Icons.color_lens_rounded,
          ),
          // Ana renk seçimi
          _buildAccentColorControls(),
          const SizedBox(height: 24),

          // Arkaplan renkleri
          _buildBackgroundColorControls(),
          const SizedBox(height: 24),

          // Arkaplan fotoğrafı
          _buildBackgroundImageControls(),
        ],
      ),
    );
  }

  // Tema ayarları artık ThemeSettingsWidget'ta yönetiliyor

  // ============================================================================
  // TİPOGRAFİ BÖLÜMÜ
  // ============================================================================

  Widget _buildTypographyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Yazı Tipi Ayarları',
            'Menünüzün yazı tiplerini özelleştirin',
            Icons.text_fields_rounded,
          ),
          const SizedBox(height: 24),

          // Font ayarları buraya eklenecek
          Text('Typography ayarları henüz eklenmedi'),
        ],
      ),
    );
  }

  // ============================================================================
  // LAYOUT BÖLÜMÜ
  // ============================================================================

  // Layout ayarları artık LayoutSettingsWidget'ta yönetiliyor

  // ============================================================================
  // STİL BÖLÜMÜ
  // ============================================================================

  Widget _buildStyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Görsel Stil',
            'Kartlar ve görsellerin stilini ayarlayın',
            Icons.style_rounded,
          ),
          const SizedBox(height: 16),
          _buildBorderRadiusControls(),
          const SizedBox(height: 24),
          _buildShadowAndBorderControls(),
          const SizedBox(height: 24),
          _buildImageStyleControls(),
        ],
      ),
    );
  }

  Widget _buildBorderRadiusControls() {
    return _buildSettingsCard(
      title: 'Köşe Yuvarlaklığı',
      child: Column(
        children: [
          _buildSliderSetting(
            label: 'Kart Köşe Yuvarlaklığı',
            value: _currentSettings.visualStyle.borderRadius,
            min: 0,
            max: 24,
            divisions: 12,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    borderRadius: value,
                  ),
                );
              });
            },
            suffix: 'px',
          ),
          _buildSliderSetting(
            label: 'Buton Köşe Yuvarlaklığı',
            value: _currentSettings.visualStyle.buttonRadius,
            min: 0,
            max: 16,
            divisions: 8,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    buttonRadius: value,
                  ),
                );
              });
            },
            suffix: 'px',
          ),
        ],
      ),
    );
  }

  Widget _buildShadowAndBorderControls() {
    return _buildSettingsCard(
      title: 'Gölge ve Kenarlık',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Gölgeleri Göster'),
            subtitle: const Text('Kartlara gölge efekti ekle'),
            value: _currentSettings.visualStyle.showShadows,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    showShadows: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Kenarlıkları Göster'),
            subtitle: const Text('Kartlara kenarlık ekle'),
            value: _currentSettings.visualStyle.showBorders,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    showBorders: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_currentSettings.visualStyle.showShadows)
            _buildSliderSetting(
              label: 'Gölge Yoğunluğu',
              value: _currentSettings.visualStyle.cardElevation,
              min: 0,
              max: 8,
              divisions: 8,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    visualStyle: _currentSettings.visualStyle.copyWith(
                      cardElevation: value,
                    ),
                  );
                });
              },
              suffix: '',
            ),
        ],
      ),
    );
  }

  Widget _buildImageStyleControls() {
    return _buildSettingsCard(
      title: 'Görsel Stili',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Görsel Şekli',
              border: OutlineInputBorder(),
            ),
            value: _currentSettings.visualStyle.imageShape,
            items: const [
              DropdownMenuItem(value: 'rectangle', child: Text('Dikdörtgen')),
              DropdownMenuItem(value: 'rounded', child: Text('Yuvarlatılmış')),
              DropdownMenuItem(value: 'circle', child: Text('Daire')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    visualStyle: _currentSettings.visualStyle.copyWith(
                      imageShape: value,
                    ),
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Görsel En-Boy Oranı',
            value: _currentSettings.visualStyle.imageAspectRatio,
            min: 0.8,
            max: 2.0,
            divisions: 12,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    imageAspectRatio: value,
                  ),
                );
              });
            },
            suffix: '',
            formatValue: (value) => '${value.toStringAsFixed(1)}:1',
          ),
          SwitchListTile(
            title: const Text('Görsel Üzerine Kaplama'),
            subtitle: const Text('Görsellerin üzerine karartma efekti'),
            value: _currentSettings.visualStyle.showImageOverlay,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    showImageOverlay: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ETKİLEŞİM BÖLÜMÜ
  // ============================================================================

  Widget _buildInteractionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Etkileşim Ayarları',
            'Kullanıcı deneyimi ve animasyonları ayarlayın',
            Icons.touch_app_rounded,
          ),
          const SizedBox(height: 16),
          _buildAnimationControls(),
          const SizedBox(height: 24),
          _buildGestureControls(),
          const SizedBox(height: 24),
          _buildFeatureControls(),
        ],
      ),
    );
  }

  Widget _buildAnimationControls() {
    return _buildSettingsCard(
      title: 'Animasyonlar',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Animasyonları Etkinleştir'),
            subtitle: const Text('Geçiş ve hover animasyonları'),
            value: _currentSettings.visualStyle.enableAnimations,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  visualStyle: _currentSettings.visualStyle.copyWith(
                    enableAnimations: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Hover Efektleri'),
            subtitle: const Text('Fare üzerine geldiğinde efektler (Web)'),
            value: _currentSettings.interactionSettings.enableHoverEffects,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableHoverEffects: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Tıklama Animasyonları'),
            subtitle: const Text('Dokunma ve tıklama sırasında animasyonlar'),
            value: _currentSettings.interactionSettings.enableClickAnimations,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableClickAnimations: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_currentSettings.visualStyle.enableAnimations)
            _buildSliderSetting(
              label: 'Animasyon Hızı',
              value: _currentSettings.interactionSettings.animationDuration,
              min: 100,
              max: 800,
              divisions: 14,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    interactionSettings:
                        _currentSettings.interactionSettings.copyWith(
                      animationDuration: value,
                    ),
                  );
                });
              },
              suffix: 'ms',
            ),
        ],
      ),
    );
  }

  Widget _buildGestureControls() {
    return _buildSettingsCard(
      title: 'Dokunma Hareketleri',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Kaydırma Hareketleri'),
            subtitle: const Text('Parmakla kaydırma işlemleri'),
            value: _currentSettings.interactionSettings.enableSwipeGestures,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableSwipeGestures: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Haptic Geri Bildirim'),
            subtitle: const Text('Dokunma sırasında titreşim'),
            value: _currentSettings.interactionSettings.hapticFeedback,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    hapticFeedback: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureControls() {
    return _buildSettingsCard(
      title: 'Özellik Ayarları',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Hızlı Önizleme'),
            subtitle: const Text('Ürünlere uzun basınca önizleme göster'),
            value: _currentSettings.interactionSettings.enableQuickView,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableQuickView: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Favoriler'),
            subtitle: const Text('Kullanıcılar favori ürün ekleyebilsin'),
            value: _currentSettings.interactionSettings.enableFavorites,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableFavorites: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Paylaşım'),
            subtitle: const Text('Ürünleri sosyal medyada paylaşma'),
            value: _currentSettings.interactionSettings.enableShare,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableShare: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Zoom'),
            subtitle: const Text('Görselleri büyütme özelliği'),
            value: _currentSettings.interactionSettings.enableZoom,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  interactionSettings:
                      _currentSettings.interactionSettings.copyWith(
                    enableZoom: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // YARDIMCI WIDGETler
  // ============================================================================

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
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
                  style: AppTypography.headingMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String suffix = '',
    String Function(double)? formatValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium,
            ),
            Text(
              formatValue?.call(value) ?? '${value.round()}$suffix',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withOpacity(0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    Color pickerColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basit renk seçim grid'i
                Container(
                  height: 280,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _getAllColors().length,
                    itemBuilder: (context, index) {
                      final color = _getAllColors()[index];
                      final isSelected = color.value == pickerColor.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            pickerColor = color;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pickerColor,
              foregroundColor: pickerColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
            ),
            child: const Text('Seç'),
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

  Widget _buildBackgroundColorControls() {
    return _buildSettingsCard(
      title: 'Arkaplan Renkleri',
      child: Column(
        children: [
          // Ana arkaplan rengi
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    _parseColor(_currentSettings.colorScheme.backgroundColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Arkaplan Rengi'),
            subtitle: Text(_currentSettings.colorScheme.backgroundColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Arkaplan Rengi Seç',
              currentColor:
                  _parseColor(_currentSettings.colorScheme.backgroundColor),
              onColorChanged: (color) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    colorScheme: _currentSettings.colorScheme.copyWith(
                      backgroundColor:
                          '#${color.value.toRadixString(16).substring(2)}',
                    ),
                  );
                });
              },
            ),
          ),
          const Divider(),
          // Kart arkaplan rengi
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(_currentSettings.colorScheme.cardColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Kart Rengi'),
            subtitle: Text(_currentSettings.colorScheme.cardColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Kart Rengi Seç',
              currentColor: _parseColor(_currentSettings.colorScheme.cardColor),
              onColorChanged: (color) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    colorScheme: _currentSettings.colorScheme.copyWith(
                      cardColor:
                          '#${color.value.toRadixString(16).substring(2)}',
                    ),
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Hızlı Kart Renkleri
          Text(
            'Hızlı Kart Renkleri:',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildQuickCardColors(),
          const SizedBox(height: 16),
          // Hızlı Arka Plan Renkleri
          Text(
            'Hızlı Arka Plan Renkleri:',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildQuickBackgroundColors(),
        ],
      ),
    );
  }

  Widget _buildQuickBackgroundColors() {
    final quickBackgroundColors = [
      {'name': 'Beyaz', 'color': Colors.white, 'value': '#FFFFFF'},
      {'name': 'Açık Gri', 'color': Colors.grey.shade50, 'value': '#FAFAFA'},
      {'name': 'Krem', 'color': Colors.orange.shade50, 'value': '#FFF7ED'},
      {'name': 'Açık Mavi', 'color': Colors.blue.shade50, 'value': '#EFF6FF'},
      {'name': 'Açık Yeşil', 'color': Colors.green.shade50, 'value': '#F0FDF4'},
      {'name': 'Açık Pembe', 'color': Colors.pink.shade50, 'value': '#FDF2F8'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: quickBackgroundColors.map((bgColor) {
        final isSelected =
            _currentSettings.colorScheme.backgroundColor == bgColor['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentSettings = _currentSettings.copyWith(
                colorScheme: _currentSettings.colorScheme.copyWith(
                  backgroundColor: bgColor['value'] as String,
                ),
              );
            });
          },
          child: Container(
            width: 60,
            height: 45,
            decoration: BoxDecoration(
              color: bgColor['color'] as Color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
                const SizedBox(height: 2),
                Text(
                  bgColor['name'] as String,
                  style: AppTypography.caption.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickCardColors() {
    final quickCardColors = [
      {'name': 'Beyaz', 'color': Colors.white, 'value': '#FFFFFF'},
      {'name': 'Açık Gri', 'color': Colors.grey.shade100, 'value': '#F5F5F5'},
      {'name': 'Krem', 'color': Colors.orange.shade50, 'value': '#FFF7ED'},
      {'name': 'Açık Mavi', 'color': Colors.blue.shade50, 'value': '#EFF6FF'},
      {'name': 'Açık Yeşil', 'color': Colors.green.shade50, 'value': '#F0FDF4'},
      {'name': 'Açık Pembe', 'color': Colors.pink.shade50, 'value': '#FDF2F8'},
      {'name': 'Açık Mor', 'color': Colors.purple.shade50, 'value': '#FAF5FF'},
      {'name': 'Açık Sarı', 'color': Colors.yellow.shade50, 'value': '#FEFCE8'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: quickCardColors.map((cardColor) {
        final isSelected =
            _currentSettings.colorScheme.cardColor == cardColor['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentSettings = _currentSettings.copyWith(
                colorScheme: _currentSettings.colorScheme.copyWith(
                  cardColor: cardColor['value'] as String,
                ),
              );
            });
          },
          child: Container(
            width: 60,
            height: 45,
            decoration: BoxDecoration(
              color: cardColor['color'] as Color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
                const SizedBox(height: 2),
                Text(
                  cardColor['name'] as String,
                  style: AppTypography.caption.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackgroundImageControls() {
    return _buildSettingsCard(
      title: 'Arka Plan Fotoğrafı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Background Image Preview
          if (_currentSettings.backgroundSettings.backgroundImage.isNotEmpty &&
              _currentSettings.backgroundSettings.type == 'image')
            Container(
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: DecorationImage(
                  image: NetworkImage(
                      _currentSettings.backgroundSettings.backgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.photo,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

          // Upload Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectBackgroundImage,
              icon: const Icon(Icons.cloud_upload),
              label: Text(
                _currentSettings.backgroundSettings.backgroundImage.isEmpty
                    ? 'Arka Plan Fotoğrafı Seç'
                    : 'Fotoğrafı Değiştir',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Preset Background Images
          Text(
            'Hazır Arka Planlar:',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildPresetBackgrounds(),

          if (_currentSettings.backgroundSettings.backgroundImage.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _removeBackgroundImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Arka Plan Fotoğrafını Kaldır'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPresetBackgrounds() {
    final presetBackgrounds = [
      {
        'name': 'Ahşap',
        'url':
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&q=80',
        'preview':
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=150&q=80',
      },
      {
        'name': 'Mermer',
        'url':
            'https://images.unsplash.com/photo-1540553016722-983e48a2cd10?w=800&q=80',
        'preview':
            'https://images.unsplash.com/photo-1540553016722-983e48a2cd10?w=150&q=80',
      },
      {
        'name': 'Kağıt',
        'url':
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        'preview':
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=150&q=80',
      },
      {
        'name': 'Beton',
        'url':
            'https://images.unsplash.com/photo-1553395297-9c4296f7d21e?w=800&q=80',
        'preview':
            'https://images.unsplash.com/photo-1553395297-9c4296f7d21e?w=150&q=80',
      },
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presetBackgrounds.length,
        itemBuilder: (context, index) {
          final bg = presetBackgrounds[index];
          final isSelected =
              _currentSettings.backgroundSettings.backgroundImage == bg['url'];

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _selectPresetBackground(bg['url']!),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(bg['preview']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: isSelected
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bg['name']!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectBackgroundImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Platform bazında kaynak seçimi
      ImageSource? source;

      if (kIsWeb) {
        // Web'de sadece galeri seçeneği
        source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fotoğraf Seç'),
            content: const Text('Web tarayıcısından fotoğraf seçin'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: const Text('Dosya Seç'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
            ],
          ),
        );
      } else {
        // Mobile'da hem galeri hem kamera
        source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fotoğraf Seç'),
            content: const Text('Fotoğrafı nereden seçmek istiyorsunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: const Text('Galeriden Seç'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                child: const Text('Kamera'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
            ],
          ),
        );
      }

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Fotoğraf yükleniyor...'),
              ],
            ),
          ),
        );
      }

      // Upload to Firebase Storage
      final String fileName =
          'background_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'background_images/${_business!.id}/$fileName';

      final Reference storageRef =
          FirebaseStorage.instance.ref().child(filePath);

      // Universal upload - Hem web hem mobile için Uint8List kullan
      print(
          '📱 Platform: ${kIsWeb ? "Web" : "Mobile"} - Uint8List kullanılıyor');

      final Uint8List fileBytes = await pickedFile.readAsBytes();
      final UploadTask uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'originalName': pickedFile.name,
            'platform': kIsWeb ? 'web' : 'mobile',
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update settings
      setState(() {
        _currentSettings = _currentSettings.copyWith(
          backgroundSettings: _currentSettings.backgroundSettings.copyWith(
            type: 'image',
            backgroundImage: downloadUrl,
          ),
        );
      });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Arka plan fotoğrafı başarıyla yüklendi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPresetBackground(String imageUrl) {
    setState(() {
      _currentSettings = _currentSettings.copyWith(
        backgroundSettings: _currentSettings.backgroundSettings.copyWith(
          type: 'image',
          backgroundImage: imageUrl,
        ),
      );
    });
  }

  void _removeBackgroundImage() {
    setState(() {
      _currentSettings = _currentSettings.copyWith(
        backgroundSettings: _currentSettings.backgroundSettings.copyWith(
          type: 'color',
          backgroundImage: '',
        ),
      );
    });
  }

  Widget _buildAccentColorControls() {
    return _buildSettingsCard(
      title: 'Vurgu Renkleri',
      child: Column(
        children: [
          // Buton rengi
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(_currentSettings.colorScheme.primaryColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Buton Rengi'),
            subtitle: Text(_currentSettings.colorScheme.primaryColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Buton Rengi Seç',
              currentColor:
                  _parseColor(_currentSettings.colorScheme.primaryColor),
              onColorChanged: (color) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    colorScheme: _currentSettings.colorScheme.copyWith(
                      primaryColor:
                          '#${color.value.toRadixString(16).substring(2)}',
                    ),
                  );
                });
              },
            ),
          ),
          const Divider(),
          // İkincil renk
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(_currentSettings.colorScheme.secondaryColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('İkincil Renk'),
            subtitle: Text(_currentSettings.colorScheme.secondaryColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'İkincil Renk Seç',
              currentColor:
                  _parseColor(_currentSettings.colorScheme.secondaryColor),
              onColorChanged: (color) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    colorScheme: _currentSettings.colorScheme.copyWith(
                      secondaryColor:
                          '#${color.value.toRadixString(16).substring(2)}',
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Kategori ayarları artık CategorySettingsWidget'ta yönetiliyor

  // Kategori metodları CategorySettingsWidget'a taşındı
}

// Color picker için ek import gerekiyor
// pubspec.yaml'a eklenecek: flutter_colorpicker: ^1.0.3
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    return Container(
      width: 300,
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      pickerColor == color ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              child: pickerColor == color
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
