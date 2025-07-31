import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';
import '../services/business_firestore_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';

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

  // Theme seçimi için aktif tema
  MenuThemeType _selectedTheme = MenuThemeType.modern;

  // Color picker için aktif renk
  Color _selectedColor = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadBusinessData();
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
          _selectedTheme = business.menuSettings.designTheme.themeType;
          _selectedColor =
              _hexToColor(business.menuSettings.colorScheme.primaryColor);
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
      _selectedTheme = _originalSettings.designTheme.themeType;
      _selectedColor = _hexToColor(_originalSettings.colorScheme.primaryColor);
    });
  }

  bool get _hasChanges => _currentSettings != _originalSettings;

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThemeTab(),
          _buildLayoutTab(),
          _buildColorTab(),
          _buildTypographyTab(),
          _buildStyleTab(),
          _buildInteractionTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // TEMA SEÇİMİ BÖLÜMÜ
  // ============================================================================

  Widget _buildThemeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Tema Seçimi',
            'Menünüzün genel görünümünü belirleyin',
            Icons.palette_rounded,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: MenuThemeType.values.length,
            itemBuilder: (context, index) {
              final theme = MenuThemeType.values[index];
              final isSelected = _selectedTheme == theme;

              return _buildThemeCard(theme, isSelected);
            },
          ),
          const SizedBox(height: 24),
          _buildThemePreview(),
        ],
      ),
    );
  }

  Widget _buildThemeCard(MenuThemeType theme, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
          _currentSettings = _currentSettings.copyWith(
            designTheme: _getThemeForType(theme),
          );
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildThemePreviewMini(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    theme.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreviewMini(MenuThemeType theme) {
    switch (theme) {
      case MenuThemeType.modern:
        return _buildModernPreview();
      case MenuThemeType.classic:
        return _buildClassicPreview();
      case MenuThemeType.grid:
        return _buildGridPreview();
      case MenuThemeType.magazine:
        return _buildMagazinePreview();
    }
  }

  Widget _buildModernPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassicPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
              3,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildGridPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        children: List.generate(
            4,
            (index) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
      ),
    );
  }

  Widget _buildMagazinePreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MenuDesignTheme _getThemeForType(MenuThemeType type) {
    switch (type) {
      case MenuThemeType.modern:
        return MenuDesignTheme.modern();
      case MenuThemeType.classic:
        return MenuDesignTheme.classic();
      case MenuThemeType.grid:
        return MenuDesignTheme.grid();
      case MenuThemeType.magazine:
        return MenuDesignTheme.magazine();
    }
  }

  Widget _buildThemePreview() {
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
            '📱 Tema Önizlemesi',
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Seçilen tema: ${_selectedTheme.displayName}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Center(
              child: Text(
                '${_selectedTheme.displayName} Tema Önizlemesi\n\n${_selectedTheme.description}',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LAYOUT BÖLÜMÜ
  // ============================================================================

  Widget _buildLayoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Layout Düzeni',
            'Menü öğelerinizin nasıl dizileceğini ayarlayın',
            Icons.dashboard_rounded,
          ),
          const SizedBox(height: 16),
          _buildLayoutTypeSelection(),
          const SizedBox(height: 24),
          _buildLayoutSpacingControls(),
          const SizedBox(height: 24),
          _buildLayoutDisplayOptions(),
        ],
      ),
    );
  }

  Widget _buildLayoutTypeSelection() {
    return _buildSettingsCard(
      title: 'Düzen Tipi',
      child: Column(
        children: MenuLayoutType.values.map((layout) {
          return RadioListTile<MenuLayoutType>(
            title: Text(layout.displayName),
            subtitle: Text(
              layout.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            value: layout,
            groupValue: _currentSettings.layoutStyle.layoutType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    layoutStyle: _currentSettings.layoutStyle.copyWith(
                      layoutType: value,
                    ),
                  );
                });
              }
            },
            activeColor: AppColors.primary,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLayoutSpacingControls() {
    return _buildSettingsCard(
      title: 'Boşluk Ayarları',
      child: Column(
        children: [
          _buildSliderSetting(
            label: 'Sütun Sayısı',
            value: _currentSettings.layoutStyle.columnsCount.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  layoutStyle: _currentSettings.layoutStyle.copyWith(
                    columnsCount: value.round(),
                  ),
                );
              });
            },
            suffix: 'sütun',
          ),
          _buildSliderSetting(
            label: 'Öğe Arası Boşluk',
            value: _currentSettings.layoutStyle.itemSpacing,
            min: 8,
            max: 32,
            divisions: 6,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  layoutStyle: _currentSettings.layoutStyle.copyWith(
                    itemSpacing: value,
                  ),
                );
              });
            },
            suffix: 'px',
          ),
          _buildSliderSetting(
            label: 'Kategori Arası Boşluk',
            value: _currentSettings.layoutStyle.categorySpacing,
            min: 16,
            max: 48,
            divisions: 8,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  layoutStyle: _currentSettings.layoutStyle.copyWith(
                    categorySpacing: value,
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

  Widget _buildLayoutDisplayOptions() {
    return _buildSettingsCard(
      title: 'Görüntüleme Seçenekleri',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Kategori Başlıklarını Göster'),
            subtitle: const Text('Kategori adlarını menüde göster'),
            value: _currentSettings.layoutStyle.showCategoryHeaders,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  layoutStyle: _currentSettings.layoutStyle.copyWith(
                    showCategoryHeaders: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Sabit Başlıklar'),
            subtitle: const Text('Kaydırırken başlıkları sabit tut'),
            value: _currentSettings.layoutStyle.stickyHeaders,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  layoutStyle: _currentSettings.layoutStyle.copyWith(
                    stickyHeaders: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Otomatik Yükseklik'),
            subtitle: const Text('İçeriğe göre kartların yüksekliğini ayarla'),
            value: _currentSettings.layoutStyle.autoHeight,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  layoutStyle: _currentSettings.layoutStyle.copyWith(
                    autoHeight: value,
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
  // RENK BÖLÜMÜ
  // ============================================================================

  Widget _buildColorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Renk Paleti',
            'Menünüzün renk şemasını özelleştirin',
            Icons.color_lens_rounded,
          ),
          const SizedBox(height: 16),
          _buildPrimaryColorPicker(),
          const SizedBox(height: 24),
          _buildColorPresets(),
          const SizedBox(height: 24),
          _buildAdvancedColorControls(),
        ],
      ),
    );
  }

  Widget _buildPrimaryColorPicker() {
    return _buildSettingsCard(
      title: 'Ana Renk',
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 2,
                ),
              ),
            ),
            title: Text(_colorToHex(_selectedColor)),
            subtitle: const Text('Menünüzün ana teması'),
            trailing: ElevatedButton(
              onPressed: () => _showColorPicker(),
              child: const Text('Değiştir'),
            ),
          ),
          const SizedBox(height: 16),
          _buildColorPreviewRow(),
        ],
      ),
    );
  }

  Widget _buildColorPreviewRow() {
    final colors = [
      _selectedColor,
      _selectedColor.withOpacity(0.7),
      _selectedColor.withOpacity(0.3),
      _selectedColor.withOpacity(0.1),
    ];

    return Row(
      children: colors
          .map((color) => Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildColorPresets() {
    final presetColors = [
      const Color(0xFFFF6B35), // Turuncu
      const Color(0xFF2ECC71), // Yeşil
      const Color(0xFF3498DB), // Mavi
      const Color(0xFF9B59B6), // Mor
      const Color(0xFFE74C3C), // Kırmızı
      const Color(0xFFF39C12), // Sarı
      const Color(0xFF1ABC9C), // Turkuaz
      const Color(0xFF34495E), // Gri
    ];

    return _buildSettingsCard(
      title: 'Hazır Renkler',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: presetColors.length,
        itemBuilder: (context, index) {
          final color = presetColors[index];
          final isSelected = _selectedColor.value == color.value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
                _currentSettings = _currentSettings.copyWith(
                  colorScheme: _currentSettings.colorScheme.copyWith(
                    primaryColor: _colorToHex(color),
                  ),
                );
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedColorControls() {
    return _buildSettingsCard(
      title: 'Gelişmiş Renk Ayarları',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Koyu Tema'),
            subtitle: const Text('Koyu tema kullan'),
            value: _currentSettings.colorScheme.isDark,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  colorScheme: _currentSettings.colorScheme.copyWith(
                    isDark: value,
                  ),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          _buildSliderSetting(
            label: 'Saydamlık',
            value: _currentSettings.colorScheme.opacity,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  colorScheme: _currentSettings.colorScheme.copyWith(
                    opacity: value,
                  ),
                );
              });
            },
            suffix: '%',
            formatValue: (value) => '${(value * 100).round()}%',
          ),
        ],
      ),
    );
  }

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
            'Metinlerin görünümünü özelleştirin',
            Icons.text_fields_rounded,
          ),
          const SizedBox(height: 16),
          _buildFontFamilySelection(),
          const SizedBox(height: 24),
          _buildFontSizeControls(),
          const SizedBox(height: 24),
          _buildTypographyPreview(),
        ],
      ),
    );
  }

  Widget _buildFontFamilySelection() {
    final fontFamilies = [
      'Poppins',
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Inter',
    ];

    return _buildSettingsCard(
      title: 'Yazı Tipi',
      child: Column(
        children: fontFamilies.map((font) {
          return RadioListTile<String>(
            title: Text(
              font,
              style: TextStyle(fontFamily: font),
            ),
            value: font,
            groupValue: _currentSettings.typography.fontFamily,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    typography: _currentSettings.typography.copyWith(
                      fontFamily: value,
                    ),
                  );
                });
              }
            },
            activeColor: AppColors.primary,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSizeControls() {
    return _buildSettingsCard(
      title: 'Yazı Boyutları',
      child: Column(
        children: [
          _buildSliderSetting(
            label: 'Başlık Boyutu',
            value: _currentSettings.typography.titleFontSize,
            min: 18,
            max: 32,
            divisions: 14,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  typography: _currentSettings.typography.copyWith(
                    titleFontSize: value,
                  ),
                );
              });
            },
            suffix: 'pt',
          ),
          _buildSliderSetting(
            label: 'Alt Başlık Boyutu',
            value: _currentSettings.typography.headingFontSize,
            min: 14,
            max: 24,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  typography: _currentSettings.typography.copyWith(
                    headingFontSize: value,
                  ),
                );
              });
            },
            suffix: 'pt',
          ),
          _buildSliderSetting(
            label: 'Metin Boyutu',
            value: _currentSettings.typography.bodyFontSize,
            min: 10,
            max: 18,
            divisions: 8,
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  typography: _currentSettings.typography.copyWith(
                    bodyFontSize: value,
                  ),
                );
              });
            },
            suffix: 'pt',
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyPreview() {
    return _buildSettingsCard(
      title: 'Yazı Tipi Önizlemesi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Başlık Metni',
            style: TextStyle(
              fontFamily: _currentSettings.typography.fontFamily,
              fontSize: _currentSettings.typography.titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alt Başlık Metni',
            style: TextStyle(
              fontFamily: _currentSettings.typography.fontFamily,
              fontSize: _currentSettings.typography.headingFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bir örnek gövde metnidir. Menünüzdeki ürün açıklamaları bu şekilde görünecektir.',
            style: TextStyle(
              fontFamily: _currentSettings.typography.fontFamily,
              fontSize: _currentSettings.typography.bodyFontSize,
              fontWeight: FontWeight.w400,
              height: _currentSettings.typography.lineHeight,
            ),
          ),
        ],
      ),
    );
  }

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

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renk Seçin'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _currentSettings = _currentSettings.copyWith(
                  colorScheme: _currentSettings.colorScheme.copyWith(
                    primaryColor: _colorToHex(color),
                  ),
                );
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
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
