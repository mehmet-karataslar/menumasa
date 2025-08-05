import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// ✍️ Typography Ayarları Widget'ı
///
/// Bu widget menü yazı tiplerini özelleştirme özelliklerini sağlar:
/// - Font ailesi seçimi
/// - Font boyutları
/// - Font ağırlıkları
/// - Satır yüksekliği
/// - Harf aralığı
/// - Yazı renkleri
class TypographySettingsWidget extends StatefulWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;

  const TypographySettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<TypographySettingsWidget> createState() =>
      _TypographySettingsWidgetState();
}

class _TypographySettingsWidgetState extends State<TypographySettingsWidget> {
  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Font ailesi
          _buildFontFamilySelection(),
          const SizedBox(height: 24),

          // Font boyutları
          _buildFontSizeControls(),
          const SizedBox(height: 24),

          // Yazı renkleri
          _buildTextColorControls(),
          const SizedBox(height: 24),

          // Layout kontrolleri
          _buildLayoutControls(),
          const SizedBox(height: 24),

          // Typography önizlemesi
          _buildTypographyPreview(),
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

  Widget _buildFontFamilySelection() {
    final fontFamilies = [
      {'name': 'Poppins', 'display': 'Poppins', 'isGoogle': true},
      {'name': 'Roboto', 'display': 'Roboto', 'isGoogle': true},
      {'name': 'Open Sans', 'display': 'Open Sans', 'isGoogle': true},
      {'name': 'Lato', 'display': 'Lato', 'isGoogle': true},
      {'name': 'Montserrat', 'display': 'Montserrat', 'isGoogle': true},
      {'name': 'Inter', 'display': 'Inter', 'isGoogle': true},
      {
        'name': 'Playfair Display',
        'display': 'Playfair Display',
        'isGoogle': true
      },
      {
        'name': 'Source Sans Pro',
        'display': 'Source Sans Pro',
        'isGoogle': true
      },
      {'name': 'Nunito', 'display': 'Nunito', 'isGoogle': true},
      {'name': 'PT Sans', 'display': 'PT Sans', 'isGoogle': true},
    ];

    return _buildSettingsCard(
      title: 'Yazı Tipi Ailesi',
      child: Column(
        children: [
          ...fontFamilies.map((font) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                title: Text(
                  font['display'] as String,
                  style: GoogleFonts.getFont(
                    font['name'] as String,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Örnek metin - 123 TL',
                  style: GoogleFonts.getFont(
                    font['name'] as String,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: font['name'] as String,
                groupValue: widget.currentSettings.typography.fontFamily,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = widget.currentSettings.copyWith(
                      typography: widget.currentSettings.typography.copyWith(
                        fontFamily: value,
                      ),
                    );
                    widget.onSettingsChanged(newSettings);
                  }
                },
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          }).toList(),
        ],
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
            value: widget.currentSettings.typography.titleFontSize,
            min: 18,
            max: 32,
            divisions: 14,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                typography: widget.currentSettings.typography.copyWith(
                  titleFontSize: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'pt',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Alt Başlık Boyutu',
            value: widget.currentSettings.typography.headingFontSize,
            min: 14,
            max: 24,
            divisions: 10,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                typography: widget.currentSettings.typography.copyWith(
                  headingFontSize: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'pt',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Metin Boyutu',
            value: widget.currentSettings.typography.bodyFontSize,
            min: 10,
            max: 18,
            divisions: 8,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                typography: widget.currentSettings.typography.copyWith(
                  bodyFontSize: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'pt',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Küçük Metin Boyutu',
            value: widget.currentSettings.typography.captionFontSize,
            min: 8,
            max: 14,
            divisions: 6,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                typography: widget.currentSettings.typography.copyWith(
                  captionFontSize: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'pt',
          ),
        ],
      ),
    );
  }

  Widget _buildTextColorControls() {
    return _buildSettingsCard(
      title: 'Yazı Renkleri',
      child: Column(
        children: [
          // Başlık rengi
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(
                    widget.currentSettings.colorScheme.textPrimaryColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Başlık Rengi'),
            subtitle: Text(widget.currentSettings.colorScheme.textPrimaryColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Başlık Rengi Seç',
              currentColor: _parseColor(
                  widget.currentSettings.colorScheme.textPrimaryColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    textPrimaryColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
                widget.onSettingsChanged(newSettings);
              },
            ),
          ),
          const Divider(),
          // Açıklama rengi
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(
                    widget.currentSettings.colorScheme.textSecondaryColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Açıklama Rengi'),
            subtitle:
                Text(widget.currentSettings.colorScheme.textSecondaryColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Açıklama Rengi Seç',
              currentColor: _parseColor(
                  widget.currentSettings.colorScheme.textSecondaryColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    textSecondaryColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
                widget.onSettingsChanged(newSettings);
              },
            ),
          ),
          const Divider(),
          // Fiyat rengi
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    _parseColor(widget.currentSettings.colorScheme.accentColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Fiyat Rengi'),
            subtitle: Text(widget.currentSettings.colorScheme.accentColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Fiyat Rengi Seç',
              currentColor:
                  _parseColor(widget.currentSettings.colorScheme.accentColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    accentColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
                widget.onSettingsChanged(newSettings);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutControls() {
    return _buildSettingsCard(
      title: 'Metin Düzeni',
      child: Column(
        children: [
          _buildSliderSetting(
            label: 'Satır Yüksekliği',
            value: widget.currentSettings.typography.lineHeight,
            min: 1.0,
            max: 2.0,
            divisions: 10,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                typography: widget.currentSettings.typography.copyWith(
                  lineHeight: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: '',
            formatValue: (value) => '${value.toStringAsFixed(1)}x',
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            label: 'Harf Aralığı',
            value: widget.currentSettings.typography.letterSpacing,
            min: -1.0,
            max: 2.0,
            divisions: 30,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                typography: widget.currentSettings.typography.copyWith(
                  letterSpacing: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            suffix: 'px',
            formatValue: (value) => value.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyPreview() {
    return _buildSettingsCard(
      title: 'Yazı Tipi Önizlemesi',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Ana Başlık Metni',
              style: GoogleFonts.getFont(
                widget.currentSettings.typography.fontFamily,
                fontSize: widget.currentSettings.typography.titleFontSize,
                fontWeight: _getFontWeight(
                    widget.currentSettings.typography.titleFontWeight),
                color: _parseColor(
                    widget.currentSettings.colorScheme.textPrimaryColor),
                letterSpacing: widget.currentSettings.typography.letterSpacing,
                height: widget.currentSettings.typography.lineHeight,
              ),
            ),
            const SizedBox(height: 12),

            // Alt başlık
            Text(
              'Alt Başlık ve Kategori İsimleri',
              style: GoogleFonts.getFont(
                widget.currentSettings.typography.fontFamily,
                fontSize: widget.currentSettings.typography.headingFontSize,
                fontWeight: _getFontWeight(
                    widget.currentSettings.typography.headingFontWeight),
                color: _parseColor(
                    widget.currentSettings.colorScheme.textPrimaryColor),
                letterSpacing: widget.currentSettings.typography.letterSpacing,
                height: widget.currentSettings.typography.lineHeight,
              ),
            ),
            const SizedBox(height: 12),

            // Gövde metni
            Text(
              'Bu bir örnek ürün açıklamasıdır. Menünüzdeki ürün detayları ve açıklamalar bu şekilde görünecektir. Lorem ipsum dolor sit amet consectetur adipiscing elit.',
              style: GoogleFonts.getFont(
                widget.currentSettings.typography.fontFamily,
                fontSize: widget.currentSettings.typography.bodyFontSize,
                fontWeight: _getFontWeight(
                    widget.currentSettings.typography.bodyFontWeight),
                color: _parseColor(
                    widget.currentSettings.colorScheme.textSecondaryColor),
                letterSpacing: widget.currentSettings.typography.letterSpacing,
                height: widget.currentSettings.typography.lineHeight,
              ),
            ),
            const SizedBox(height: 12),

            // Fiyat
            Row(
              children: [
                Text(
                  '₺45.90',
                  style: GoogleFonts.getFont(
                    widget.currentSettings.typography.fontFamily,
                    fontSize: widget.currentSettings.typography.headingFontSize,
                    fontWeight: FontWeight.w600,
                    color: _parseColor(
                        widget.currentSettings.colorScheme.accentColor),
                    letterSpacing:
                        widget.currentSettings.typography.letterSpacing,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₺52.90',
                  style: GoogleFonts.getFont(
                    widget.currentSettings.typography.fontFamily,
                    fontSize: widget.currentSettings.typography.captionFontSize,
                    fontWeight: FontWeight.w400,
                    color: _parseColor(
                        widget.currentSettings.colorScheme.textSecondaryColor),
                    letterSpacing:
                        widget.currentSettings.typography.letterSpacing,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Küçük metin
            Text(
              'Kampanya fiyatı • Stokta mevcut',
              style: GoogleFonts.getFont(
                widget.currentSettings.typography.fontFamily,
                fontSize: widget.currentSettings.typography.captionFontSize,
                fontWeight: _getFontWeight(
                    widget.currentSettings.typography.bodyFontWeight),
                color: _parseColor(
                    widget.currentSettings.colorScheme.textSecondaryColor),
                letterSpacing: widget.currentSettings.typography.letterSpacing,
                height: widget.currentSettings.typography.lineHeight,
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

  void _showColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    Color pickerColor = currentColor;

    final colors = [
      Colors.black,
      Colors.grey.shade800,
      Colors.grey.shade600,
      Colors.grey.shade400,
      Colors.grey.shade200,
      Colors.white,
      Colors.red.shade700,
      Colors.red.shade500,
      Colors.red.shade300,
      Colors.pink.shade700,
      Colors.pink.shade500,
      Colors.pink.shade300,
      Colors.purple.shade700,
      Colors.purple.shade500,
      Colors.purple.shade300,
      Colors.blue.shade700,
      Colors.blue.shade500,
      Colors.blue.shade300,
      Colors.cyan.shade700,
      Colors.cyan.shade500,
      Colors.cyan.shade300,
      Colors.teal.shade700,
      Colors.teal.shade500,
      Colors.teal.shade300,
      Colors.green.shade700,
      Colors.green.shade500,
      Colors.green.shade300,
      Colors.yellow.shade700,
      Colors.yellow.shade500,
      Colors.yellow.shade300,
      Colors.orange.shade700,
      Colors.orange.shade500,
      Colors.orange.shade300,
      Colors.brown.shade700,
      Colors.brown.shade500,
      Colors.brown.shade300,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
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
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              },
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

  FontWeight _getFontWeight(String weight) {
    switch (weight) {
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '400':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '700':
        return FontWeight.w700;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }
}
