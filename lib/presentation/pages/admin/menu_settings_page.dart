import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/data_service.dart';
import '../../../data/models/business.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';

class MenuSettingsPage extends StatefulWidget {
  final String businessId;

  const MenuSettingsPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<MenuSettingsPage> createState() => _MenuSettingsPageState();
}

class _MenuSettingsPageState extends State<MenuSettingsPage> {
  final _dataService = DataService();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  String? _errorMessage;

  // Data
  Business? _business;
  MenuSettings? _originalSettings;

  // Form controllers
  late MenuSettings _currentSettings;

  // Preview state
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _business = await _dataService.getBusiness(widget.businessId);

      if (_business != null) {
        _originalSettings = _business!.menuSettings;
        _currentSettings = _business!.menuSettings;
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('İşletme bulunamadı');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final updatedBusiness = _business!.copyWith(
        menuSettings: _currentSettings,
        updatedAt: DateTime.now(),
      );

      await _dataService.saveBusiness(updatedBusiness);

      _originalSettings = _currentSettings;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menü ayarları başarıyla kaydedildi'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _resetSettings() {
    setState(() {
      _currentSettings =
          _originalSettings ?? BusinessDefaults.defaultMenuSettings;
    });
  }

  void _resetToDefault() {
    setState(() {
      _currentSettings = BusinessDefaults.defaultMenuSettings;
    });
  }

  bool get _hasChanges {
    return _originalSettings?.toMap().toString() !=
        _currentSettings.toMap().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menü Ayarları'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _showPreview ? null : _togglePreview,
            tooltip: 'Önizleme',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasChanges ? _resetSettings : null,
            tooltip: 'Değişiklikleri Geri Al',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _hasError
          ? Center(
              child: ErrorMessage(
                message: _errorMessage ?? 'Bilinmeyen hata',
                onRetry: _loadSettings,
              ),
            )
          : _buildContent(),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            )
          : null,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showPreview) _buildPreviewSection(),
          if (_showPreview) const SizedBox(height: 24),

          _buildThemeSection(),
          const SizedBox(height: 24),

          _buildColorSection(),
          const SizedBox(height: 24),

          _buildTypographySection(),
          const SizedBox(height: 24),

          _buildDisplaySection(),
          const SizedBox(height: 24),

          _buildLanguageSection(),
          const SizedBox(height: 24),

          _buildActionsSection(),
          const SizedBox(height: 100), // FAB için alan
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Önizleme', style: AppTypography.h5),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _togglePreview,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: _getThemeBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: _buildMenuPreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPrimaryColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _business?.businessName ?? 'İşletme Adı',
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: _currentSettings.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sample product
          Expanded(
            child: ListView(
              children: [
                _buildPreviewProductCard(
                  'Örnek Ürün 1',
                  'Lezzetli açıklama metni',
                  '₺25,90',
                ),
                const SizedBox(height: 8),
                _buildPreviewProductCard(
                  'Örnek Ürün 2',
                  'Başka bir lezzetli açıklama',
                  '₺32,50',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewProductCard(
    String name,
    String description,
    String price,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentSettings.showImages)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: AppColors.textSecondary),
            ),
          if (_currentSettings.showImages) const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: _currentSettings.fontFamily,
                    fontSize: _currentSettings.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: _currentSettings.fontFamily,
                    fontSize: _currentSettings.fontSize - 2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (_currentSettings.showPrices)
            Text(
              price,
              style: TextStyle(
                fontFamily: _currentSettings.fontFamily,
                fontSize: _currentSettings.fontSize,
                fontWeight: FontWeight.bold,
                color: _getPrimaryColor(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema', style: AppTypography.h5),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildThemeOption('default', 'Varsayılan', AppColors.primary),
                _buildThemeOption('light', 'Açık Tema', AppColors.info),
                _buildThemeOption('dark', 'Koyu Tema', AppColors.textPrimary),
                _buildThemeOption('elegant', 'Şık Tema', AppColors.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String themeId,
    String themeName,
    Color previewColor,
  ) {
    final isSelected = _currentSettings.theme == themeId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSettings = _currentSettings.copyWith(theme: themeId);
        });
      },
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? previewColor.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? previewColor : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              themeName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? previewColor : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Renk Ayarları', style: AppTypography.h5),
            const SizedBox(height: 16),

            Row(
              children: [
                Text('Ana Renk: ', style: AppTypography.bodyLarge),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPrimaryColor(),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _currentSettings.primaryColor,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('Önceden Tanımlı Renkler:', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorPreset('#FF6B35', 'Turuncu'),
                _buildColorPreset('#2C1810', 'Kahverengi'),
                _buildColorPreset('#1976D2', 'Mavi'),
                _buildColorPreset('#388E3C', 'Yeşil'),
                _buildColorPreset('#F57C00', 'Amber'),
                _buildColorPreset('#7B1FA2', 'Mor'),
                _buildColorPreset('#C62828', 'Kırmızı'),
                _buildColorPreset('#5D4037', 'Kahve'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreset(String colorCode, String colorName) {
    final color = _hexToColor(colorCode);
    final isSelected = _currentSettings.primaryColor == colorCode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSettings = _currentSettings.copyWith(primaryColor: colorCode);
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.borderColor,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: AppColors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildTypographySection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yazı Tipi Ayarları', style: AppTypography.h5),
            const SizedBox(height: 16),

            // Font family
            Row(
              children: [
                Text('Font: ', style: AppTypography.bodyLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _currentSettings.fontFamily,
                    isExpanded: true,
                    onChanged: (String? newFont) {
                      if (newFont != null) {
                        setState(() {
                          _currentSettings = _currentSettings.copyWith(
                            fontFamily: newFont,
                          );
                        });
                      }
                    },
                    items:
                        [
                              'Poppins',
                              'Roboto',
                              'Open Sans',
                              'Lato',
                              'Montserrat',
                              'Inter',
                              'Nunito',
                              'Source Sans Pro',
                            ]
                            .map(
                              (font) => DropdownMenuItem(
                                value: font,
                                child: Text(
                                  font,
                                  style: TextStyle(fontFamily: font),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Font size
            Row(
              children: [
                Text('Boyut: ', style: AppTypography.bodyLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _currentSettings.fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    label: '${_currentSettings.fontSize.round()}px',
                    onChanged: (double value) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          fontSize: value,
                        );
                      });
                    },
                  ),
                ),
                Text('${_currentSettings.fontSize.round()}px'),
              ],
            ),
            const SizedBox(height: 16),

            // Font preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                'Örnek metin görünümü - Sample text preview',
                style: TextStyle(
                  fontFamily: _currentSettings.fontFamily,
                  fontSize: _currentSettings.fontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Görünüm Ayarları', style: AppTypography.h5),
            const SizedBox(height: 16),

            // Show prices
            SwitchListTile(
              title: const Text('Fiyatları Göster'),
              subtitle: const Text('Menüde ürün fiyatlarını gösterir'),
              value: _currentSettings.showPrices,
              onChanged: (bool value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showPrices: value,
                  );
                });
              },
            ),

            // Show images
            SwitchListTile(
              title: const Text('Görselleri Göster'),
              subtitle: const Text('Menüde ürün görsellerini gösterir'),
              value: _currentSettings.showImages,
              onChanged: (bool value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showImages: value,
                  );
                });
              },
            ),

            // Image size
            if (_currentSettings.showImages) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Görsel Boyutu: ', style: AppTypography.bodyLarge),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _currentSettings.imageSize,
                      isExpanded: true,
                      onChanged: (String? newSize) {
                        if (newSize != null) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(
                              imageSize: newSize,
                            );
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'small', child: Text('Küçük')),
                        DropdownMenuItem(value: 'medium', child: Text('Orta')),
                        DropdownMenuItem(value: 'large', child: Text('Büyük')),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 32),

            // Additional display options
            Text(
              'Ek Görünüm Seçenekleri',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Show descriptions
            SwitchListTile(
              title: const Text('Ürün Açıklamalarını Göster'),
              subtitle: const Text('Ürün kartlarında açıklama metni gösterir'),
              value: _currentSettings.showDescriptions ?? true,
              onChanged: (bool value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showDescriptions: value,
                  );
                });
              },
            ),

            // Show categories
            SwitchListTile(
              title: const Text('Kategori Sekmelerini Göster'),
              subtitle: const Text('Menüde kategori sekmelerini gösterir'),
              value: _currentSettings.showCategories ?? true,
              onChanged: (bool value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showCategories: value,
                  );
                });
              },
            ),

            // Show allergens
            SwitchListTile(
              title: const Text('Alerjen Bilgilerini Göster'),
              subtitle: const Text('Ürünlerde alerjen uyarılarını gösterir'),
              value: _currentSettings.showAllergens ?? true,
              onChanged: (bool value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showAllergens: value,
                  );
                });
              },
            ),

            // Show ratings
            SwitchListTile(
              title: const Text('Değerlendirmeleri Göster'),
              subtitle: const Text('Ürün puanlarını ve yorumlarını gösterir'),
              value: _currentSettings.showRatings ?? false,
              onChanged: (bool value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showRatings: value,
                  );
                });
              },
            ),

            const SizedBox(height: 16),

            // Layout style
            Row(
              children: [
                Text('Düzen Stili: ', style: AppTypography.bodyLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _currentSettings.layoutStyle ?? 'card',
                    isExpanded: true,
                    onChanged: (String? newStyle) {
                      if (newStyle != null) {
                        setState(() {
                          _currentSettings = _currentSettings.copyWith(
                            layoutStyle: newStyle,
                          );
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('Kart Görünümü'),
                      ),
                      DropdownMenuItem(
                        value: 'list',
                        child: Text('Liste Görünümü'),
                      ),
                      DropdownMenuItem(
                        value: 'grid',
                        child: Text('Izgara Görünümü'),
                      ),
                      DropdownMenuItem(
                        value: 'compact',
                        child: Text('Kompakt Görünüm'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dil Ayarları', style: AppTypography.h5),
            const SizedBox(height: 16),

            Row(
              children: [
                Text('Menü Dili: ', style: AppTypography.bodyLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _currentSettings.language,
                    isExpanded: true,
                    onChanged: (String? newLanguage) {
                      if (newLanguage != null) {
                        setState(() {
                          _currentSettings = _currentSettings.copyWith(
                            language: newLanguage,
                          );
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eylemler', style: AppTypography.h5),
            const SizedBox(height: 16),

            // Preview and reset buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('Varsayılan Ayarlar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _togglePreview,
                    icon: Icon(
                      _showPreview ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(
                      _showPreview ? 'Önizlemeyi Kapat' : 'Canlı Önizleme',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Advanced options
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportSettings,
                    icon: const Icon(Icons.download),
                    label: const Text('Ayarları Dışa Aktar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importSettings,
                    icon: const Icon(Icons.upload),
                    label: const Text('Ayarları İçe Aktar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Auto-save indicator
            if (_hasChanges)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Değişiklikleriniz otomatik olarak kaydedilecek. Kaydet butonuna basarak hemen uygulayabilirsiniz.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  void _exportSettings() {
    final settingsJson = _currentSettings.toMap();
    final jsonString = jsonEncode(settingsJson);

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menü ayarları panoya kopyalandı'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _importSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarları İçe Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daha önce dışa aktardığınız ayarları buraya yapıştırın:',
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{"theme": "default", ...}',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Store the value for import
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement import logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ayarlar içe aktarma özelliği yakında eklenecek',
                  ),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            child: const Text('İçe Aktar'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renk Seçin'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _getPrimaryColor(),
            onColorChanged: (Color color) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(
                  primaryColor: _colorToHex(color),
                );
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Color _getPrimaryColor() {
    return _hexToColor(_currentSettings.primaryColor);
  }

  Color _getThemeBackgroundColor() {
    switch (_currentSettings.theme) {
      case 'dark':
        return AppColors.textPrimary;
      case 'light':
        return AppColors.white;
      default:
        return AppColors.background;
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF' + hex;
    }
    return Color(int.parse(hex, radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

// Simple color picker widget
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final Function(Color) onColorChanged;

  const BlockPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      '#FF6B35',
      '#2C1810',
      '#1976D2',
      '#388E3C',
      '#F57C00',
      '#7B1FA2',
      '#C62828',
      '#5D4037',
      '#E91E63',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#2196F3',
      '#03A9F4',
      '#00BCD4',
      '#009688',
      '#4CAF50',
      '#8BC34A',
      '#CDDC39',
      '#FFEB3B',
      '#FFC107',
      '#FF9800',
      '#FF5722',
      '#795548',
    ];

    return SizedBox(
      width: 300,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: colors.map((colorCode) {
          final color = _hexToColor(colorCode);
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: pickerColor == color
                      ? Colors.black
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF' + hex;
    }
    return Color(int.parse(hex, radix: 16));
  }
}
