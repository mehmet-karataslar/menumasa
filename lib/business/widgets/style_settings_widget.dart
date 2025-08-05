import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// 🎨 Stil Ayarları Widget'ı
///
/// Bu widget menü görsel stilini özelleştirme özelliklerini sağlar:
/// - Köşe yuvarlaklığı
/// - Gölge ve kenarlık ayarları
/// - Görsel stilleri
/// - Kart görünümü
/// - Spacing kontrolleri
class StyleSettingsWidget extends StatefulWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;

  const StyleSettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<StyleSettingsWidget> createState() => _StyleSettingsWidgetState();
}

class _StyleSettingsWidgetState extends State<StyleSettingsWidget> {
  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          _buildBorderRadiusControls(),
          const SizedBox(height: 24),
          _buildShadowAndBorderControls(),
          const SizedBox(height: 24),
          _buildImageStyleControls(),
          const SizedBox(height: 24),
          _buildSpacingControls(),
          const SizedBox(height: 24),
          _buildStylePreview(),
        ],
      ),
    );
  }

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

  Widget _buildBorderRadiusControls() {
    return _buildSettingsCard(
      title: 'Köşe Yuvarlaklığı',
      child: Column(
        children: [
          _buildSliderSetting(
            label: 'Kart Köşe Yuvarlaklığı',
            value: widget.currentSettings.visualStyle.borderRadius,
            min: 0,
            max: 24,
            divisions: 12,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  borderRadius: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'px',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Buton Köşe Yuvarlaklığı',
            value: widget.currentSettings.visualStyle.buttonRadius,
            min: 0,
            max: 16,
            divisions: 8,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  buttonRadius: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
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
            value: widget.currentSettings.visualStyle.showShadows,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  showShadows: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Kenarlıkları Göster'),
            subtitle: const Text('Kartlara kenarlık ekle'),
            value: widget.currentSettings.visualStyle.showBorders,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  showBorders: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          if (widget.currentSettings.visualStyle.showShadows) ...[
            const SizedBox(height: 16),
            _buildSliderSetting(
              label: 'Gölge Yoğunluğu',
              value: widget.currentSettings.visualStyle.cardElevation,
              min: 0,
              max: 8,
              divisions: 8,
              onChanged: (value) {
                final newSettings = widget.currentSettings.copyWith(
                  visualStyle: widget.currentSettings.visualStyle.copyWith(
                    cardElevation: value,
                  ),
                );
                widget.onSettingsChanged(newSettings);
              },
              suffix: '',
            ),
          ],
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
            value: widget.currentSettings.visualStyle.imageShape,
            items: const [
              DropdownMenuItem(value: 'rectangle', child: Text('Dikdörtgen')),
              DropdownMenuItem(value: 'rounded', child: Text('Yuvarlatılmış')),
              DropdownMenuItem(value: 'circle', child: Text('Daire')),
            ],
            onChanged: (value) {
              if (value != null) {
                final newSettings = widget.currentSettings.copyWith(
                  visualStyle: widget.currentSettings.visualStyle.copyWith(
                    imageShape: value,
                  ),
                );
                widget.onSettingsChanged(newSettings);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Görsel En-Boy Oranı',
            value: widget.currentSettings.visualStyle.imageAspectRatio,
            min: 0.8,
            max: 2.0,
            divisions: 12,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  imageAspectRatio: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: '',
            formatValue: (value) => '${value.toStringAsFixed(1)}:1',
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Görsel Üzerine Kaplama'),
            subtitle: const Text('Görsellerin üzerine karartma efekti'),
            value: widget.currentSettings.visualStyle.showImageOverlay,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  showImageOverlay: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingControls() {
    return _buildSettingsCard(
      title: 'Boşluk ve Düzen',
      child: Column(
        children: [
          _buildSliderSetting(
            label: 'Kartlar Arası Boşluk',
            value: widget.currentSettings.layoutStyle.itemSpacing,
            min: 4,
            max: 24,
            divisions: 10,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                layoutStyle: widget.currentSettings.layoutStyle.copyWith(
                  itemSpacing: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'px',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Sayfa Kenar Boşlukları',
            value: widget.currentSettings.layoutStyle.padding,
            min: 8,
            max: 32,
            divisions: 12,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                layoutStyle: widget.currentSettings.layoutStyle.copyWith(
                  padding: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'px',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Bölüm Arası Boşluk',
            value: widget.currentSettings.layoutStyle.sectionSpacing,
            min: 16,
            max: 48,
            divisions: 8,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                layoutStyle: widget.currentSettings.layoutStyle.copyWith(
                  sectionSpacing: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'px',
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreview() {
    return _buildSettingsCard(
      title: 'Stil Önizlemesi',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            // Örnek kart 1
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.all(widget.currentSettings.layoutStyle.padding),
              margin: EdgeInsets.only(
                  bottom: widget.currentSettings.layoutStyle.itemSpacing),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                    widget.currentSettings.visualStyle.borderRadius),
                border: widget.currentSettings.visualStyle.showBorders
                    ? Border.all(color: AppColors.borderLight)
                    : null,
                boxShadow: widget.currentSettings.visualStyle.showShadows
                    ? [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.1),
                          blurRadius:
                              widget.currentSettings.visualStyle.cardElevation,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Örnek görsel
                  Container(
                    width: 60,
                    height: 60 /
                        widget.currentSettings.visualStyle.imageAspectRatio,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius:
                          widget.currentSettings.visualStyle.imageShape ==
                                  'circle'
                              ? BorderRadius.circular(30)
                              : widget.currentSettings.visualStyle.imageShape ==
                                      'rounded'
                                  ? BorderRadius.circular(8)
                                  : BorderRadius.zero,
                      border: widget.currentSettings.visualStyle.showBorders
                          ? Border.all(color: AppColors.borderLight)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.fastfood,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        if (widget.currentSettings.visualStyle.showImageOverlay)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: widget.currentSettings.visualStyle
                                          .imageShape ==
                                      'circle'
                                  ? BorderRadius.circular(30)
                                  : widget.currentSettings.visualStyle
                                              .imageShape ==
                                          'rounded'
                                      ? BorderRadius.circular(8)
                                      : BorderRadius.zero,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                      width: widget.currentSettings.layoutStyle.itemSpacing),

                  // Örnek metin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Örnek Ürün Adı',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ürün açıklaması burada yer alır...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺25.90',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Örnek kart 2
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.all(widget.currentSettings.layoutStyle.padding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                    widget.currentSettings.visualStyle.borderRadius),
                border: widget.currentSettings.visualStyle.showBorders
                    ? Border.all(color: AppColors.borderLight)
                    : null,
                boxShadow: widget.currentSettings.visualStyle.showShadows
                    ? [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.1),
                          blurRadius:
                              widget.currentSettings.visualStyle.cardElevation,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Örnek görsel
                  Container(
                    width: 60,
                    height: 60 /
                        widget.currentSettings.visualStyle.imageAspectRatio,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius:
                          widget.currentSettings.visualStyle.imageShape ==
                                  'circle'
                              ? BorderRadius.circular(30)
                              : widget.currentSettings.visualStyle.imageShape ==
                                      'rounded'
                                  ? BorderRadius.circular(8)
                                  : BorderRadius.zero,
                      border: widget.currentSettings.visualStyle.showBorders
                          ? Border.all(color: AppColors.borderLight)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.local_drink,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        if (widget.currentSettings.visualStyle.showImageOverlay)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: widget.currentSettings.visualStyle
                                          .imageShape ==
                                      'circle'
                                  ? BorderRadius.circular(30)
                                  : widget.currentSettings.visualStyle
                                              .imageShape ==
                                          'rounded'
                                      ? BorderRadius.circular(8)
                                      : BorderRadius.zero,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                      width: widget.currentSettings.layoutStyle.itemSpacing),

                  // Örnek metin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Başka Bir Ürün',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bu da başka bir ürün açıklaması...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺18.50',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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
}
