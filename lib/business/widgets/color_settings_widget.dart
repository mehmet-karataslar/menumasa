import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// 🎨 Renk Ayarları Widget'ı
/// 
/// Bu widget menü renklerini özelleştirme özelliklerini sağlar:
/// - Ana renk paleti
/// - Arkaplan renkleri 
/// - Kart renkleri
/// - Vurgu renkleri
/// - Arka plan fotoğrafı
class ColorSettingsWidget extends StatefulWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;
  final Business? business;

  const ColorSettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
    this.business,
  });

  @override
  State<ColorSettingsWidget> createState() => _ColorSettingsWidgetState();
}

class _ColorSettingsWidgetState extends State<ColorSettingsWidget> {
  
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
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          
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
                color: _parseColor(widget.currentSettings.colorScheme.primaryColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Buton Rengi'),
            subtitle: Text(widget.currentSettings.colorScheme.primaryColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Buton Rengi Seç',
              currentColor:
                  _parseColor(widget.currentSettings.colorScheme.primaryColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    primaryColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
                widget.onSettingsChanged(newSettings);
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
                color: _parseColor(widget.currentSettings.colorScheme.secondaryColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('İkincil Renk'),
            subtitle: Text(widget.currentSettings.colorScheme.secondaryColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'İkincil Renk Seç',
              currentColor:
                  _parseColor(widget.currentSettings.colorScheme.secondaryColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    secondaryColor:
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
                    _parseColor(widget.currentSettings.colorScheme.backgroundColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Arkaplan Rengi'),
            subtitle: Text(widget.currentSettings.colorScheme.backgroundColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Arkaplan Rengi Seç',
              currentColor:
                  _parseColor(widget.currentSettings.colorScheme.backgroundColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    backgroundColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
                widget.onSettingsChanged(newSettings);
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
                color: _parseColor(widget.currentSettings.colorScheme.cardColor),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: const Text('Kart Rengi'),
            subtitle: Text(widget.currentSettings.colorScheme.cardColor),
            trailing: const Icon(Icons.edit),
            onTap: () => _showColorPicker(
              title: 'Kart Rengi Seç',
              currentColor: _parseColor(widget.currentSettings.colorScheme.cardColor),
              onColorChanged: (color) {
                final newSettings = widget.currentSettings.copyWith(
                  colorScheme: widget.currentSettings.colorScheme.copyWith(
                    cardColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
                widget.onSettingsChanged(newSettings);
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
            widget.currentSettings.colorScheme.backgroundColor == bgColor['value'];
        return GestureDetector(
          onTap: () {
            final newSettings = widget.currentSettings.copyWith(
              colorScheme: widget.currentSettings.colorScheme.copyWith(
                backgroundColor: bgColor['value'] as String,
              ),
            );
            widget.onSettingsChanged(newSettings);
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
            widget.currentSettings.colorScheme.cardColor == cardColor['value'];
        return GestureDetector(
          onTap: () {
            final newSettings = widget.currentSettings.copyWith(
              colorScheme: widget.currentSettings.colorScheme.copyWith(
                cardColor: cardColor['value'] as String,
              ),
            );
            widget.onSettingsChanged(newSettings);
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
          if (widget.currentSettings.backgroundSettings.backgroundImage.isNotEmpty &&
              widget.currentSettings.backgroundSettings.type == 'image')
            Container(
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: DecorationImage(
                  image: NetworkImage(
                      widget.currentSettings.backgroundSettings.backgroundImage),
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
                widget.currentSettings.backgroundSettings.backgroundImage.isEmpty
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

          if (widget.currentSettings.backgroundSettings.backgroundImage.isNotEmpty)
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
              widget.currentSettings.backgroundSettings.backgroundImage == bg['url'];

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
      final String filePath = 'background_images/${widget.business?.id}/$fileName';

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
      final newSettings = widget.currentSettings.copyWith(
        backgroundSettings: widget.currentSettings.backgroundSettings.copyWith(
          type: 'image',
          backgroundImage: downloadUrl,
        ),
      );
      widget.onSettingsChanged(newSettings);

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
    final newSettings = widget.currentSettings.copyWith(
      backgroundSettings: widget.currentSettings.backgroundSettings.copyWith(
        type: 'image',
        backgroundImage: imageUrl,
      ),
    );
    widget.onSettingsChanged(newSettings);
  }

  void _removeBackgroundImage() {
    final newSettings = widget.currentSettings.copyWith(
      backgroundSettings: widget.currentSettings.backgroundSettings.copyWith(
        type: 'color',
        backgroundImage: '',
      ),
    );
    widget.onSettingsChanged(newSettings);
  }
}