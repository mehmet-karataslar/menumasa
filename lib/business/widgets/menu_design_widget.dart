import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';
import '../services/business_firestore_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';

class MenuDesignWidget extends StatefulWidget {
  final String businessId;
  final Business business;
  final VoidCallback onDesignChanged;

  const MenuDesignWidget({
    super.key,
    required this.businessId,
    required this.business,
    required this.onDesignChanged,
  });

  @override
  State<MenuDesignWidget> createState() => _MenuDesignWidgetState();
}

class _MenuDesignWidgetState extends State<MenuDesignWidget> {
  final BusinessFirestoreService _businessService = BusinessFirestoreService();
  
  bool _isLoading = false;
  bool _isMobile = false;

  // Tasarım ayarları
  String _selectedTheme = 'default';
  String _selectedLayout = 'modern';
  Color _primaryColor = AppColors.primary;
  Color _accentColor = AppColors.secondary;
  String _fontFamily = 'default';
  bool _showImages = true;
  bool _showPrices = true;
  bool _showDescriptions = true;
  bool _showAllergens = true;
  double _borderRadius = 12.0;
  String _imageStyle = 'rounded'; // rounded, square, circle

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'default',
      'name': 'Varsayılan',
      'description': 'Temiz ve modern görünüm',
      'primary': AppColors.primary,
      'accent': AppColors.secondary,
    },
    {
      'id': 'elegant',
      'name': 'Şık',
      'description': 'Lüks ve sofistike tasarım',
      'primary': const Color(0xFF2C3E50),
      'accent': const Color(0xFFE74C3C),
    },
    {
      'id': 'warm',
      'name': 'Sıcak',
      'description': 'Samimi ve davetkar renkler',
      'primary': const Color(0xFFD35400),
      'accent': const Color(0xFFF39C12),
    },
    {
      'id': 'fresh',
      'name': 'Taze',
      'description': 'Doğal ve ferah görünüm',
      'primary': const Color(0xFF27AE60),
      'accent': const Color(0xFF2ECC71),
    },
    {
      'id': 'minimal',
      'name': 'Minimal',
      'description': 'Sade ve odaklanmış tasarım',
      'primary': const Color(0xFF34495E),
      'accent': const Color(0xFF95A5A6),
    },
  ];

  final List<Map<String, dynamic>> _layouts = [
    {
      'id': 'modern',
      'name': 'Modern',
      'description': 'Kartlar halinde düzenli görünüm',
      'icon': Icons.view_module_rounded,
    },
    {
      'id': 'classic',
      'name': 'Klasik',
      'description': 'Geleneksel liste görünümü',
      'icon': Icons.view_list_rounded,
    },
    {
      'id': 'grid',
      'name': 'Izgara',
      'description': 'Kompakt grid düzeni',
      'icon': Icons.grid_view_rounded,
    },
    {
      'id': 'magazine',
      'name': 'Dergi',
      'description': 'Büyük resimlerle magazin stili',
      'icon': Icons.view_quilt_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentDesign();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMobile = MediaQuery.of(context).size.width < 768;
  }

  Future<void> _loadCurrentDesign() async {
    // Mevcut tasarım ayarlarını yükle
    // Bu bilgiler normalde business model'de veya ayrı bir design collection'da saklanır
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _buildDesignSettings(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menü Tasarımı',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Menünüzün görünümünü ve stilini özelleştirin',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _previewDesign,
                icon: const Icon(Icons.preview_rounded),
                label: Text(_isMobile ? 'Önizle' : 'Önizleme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: AppColors.white,
                ),
              ),
              
              const SizedBox(width: 12),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveDesign,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesignSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tema seçimi
          _buildThemeSection(),
          
          const SizedBox(height: 32),
          
          // Layout seçimi
          _buildLayoutSection(),
          
          const SizedBox(height: 32),
          
          // Renk ayarları
          _buildColorSection(),
          
          const SizedBox(height: 32),
          
          // İçerik ayarları
          _buildContentSection(),
          
          const SizedBox(height: 32),
          
          // Stil ayarları
          _buildStyleSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return _buildSection(
      title: 'Tema Seçimi',
      subtitle: 'Menünüz için hazır tema seçin',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isMobile ? 1 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _isMobile ? 3 : 2.5,
        ),
        itemCount: _themes.length,
        itemBuilder: (context, index) {
          final theme = _themes[index];
          final isSelected = _selectedTheme == theme['id'];
          
          return InkWell(
            onTap: () => setState(() {
              _selectedTheme = theme['id'];
              _primaryColor = theme['primary'];
              _accentColor = theme['accent'];
            }),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _primaryColor : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Renk örneği
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme['primary'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme['accent'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: _primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    theme['name'],
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    theme['description'],
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutSection() {
    return _buildSection(
      title: 'Layout Düzeni',
      subtitle: 'Menü düzenini seçin',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isMobile ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _layouts.length,
        itemBuilder: (context, index) {
          final layout = _layouts[index];
          final isSelected = _selectedLayout == layout['id'];
          
          return InkWell(
            onTap: () => setState(() => _selectedLayout = layout['id']),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _primaryColor : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    layout['icon'],
                    color: isSelected ? _primaryColor : AppColors.textSecondary,
                    size: 32,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    layout['name'],
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? _primaryColor : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    layout['description'],
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
          );
        },
      ),
    );
  }

  Widget _buildColorSection() {
    return _buildSection(
      title: 'Renk Ayarları',
      subtitle: 'Menünüzün renklerini özelleştirin',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildColorPicker(
                  'Ana Renk',
                  _primaryColor,
                  (color) => setState(() => _primaryColor = color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildColorPicker(
                  'Vurgu Rengi',
                  _accentColor,
                  (color) => setState(() => _accentColor = color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String title, Color currentColor, Function(Color) onColorChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          InkWell(
            onTap: () => _showColorPicker(currentColor, onColorChanged),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text(
                  '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: currentColor.computeLuminance() > 0.5 
                        ? AppColors.black 
                        : AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return _buildSection(
      title: 'İçerik Ayarları',
      subtitle: 'Menüde gösterilecek bilgileri seçin',
      child: Column(
        children: [
          _buildSwitchTile(
            'Ürün Resimleri',
            'Ürün resimlerini göster',
            _showImages,
            (value) => setState(() => _showImages = value),
            Icons.image_rounded,
          ),
          _buildSwitchTile(
            'Fiyatlar',
            'Ürün fiyatlarını göster',
            _showPrices,
            (value) => setState(() => _showPrices = value),
            Icons.monetization_on_rounded,
          ),
          _buildSwitchTile(
            'Açıklamalar',
            'Ürün açıklamalarını göster',
            _showDescriptions,
            (value) => setState(() => _showDescriptions = value),
            Icons.description_rounded,
          ),
          _buildSwitchTile(
            'Alerjen Bilgileri',
            'Alerjen uyarılarını göster',
            _showAllergens,
            (value) => setState(() => _showAllergens = value),
            Icons.warning_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSection() {
    return _buildSection(
      title: 'Stil Ayarları',
      subtitle: 'Görsel stil özelliklerini ayarlayın',
      child: Column(
        children: [
          // Border radius
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Köşe Yuvarlaklığı',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Slider(
                  value: _borderRadius,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  activeColor: _primaryColor,
                  label: '${_borderRadius.toInt()}px',
                  onChanged: (value) => setState(() => _borderRadius = value),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resim Stili',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _buildImageStyleOption('Yuvarlatılmış', 'rounded', Icons.rounded_corner),
                    _buildImageStyleOption('Kare', 'square', Icons.crop_square),
                    _buildImageStyleOption('Daire', 'circle', Icons.circle),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStyleOption(String title, String style, IconData icon) {
    final isSelected = _imageStyle == style;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _imageStyle = style),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _primaryColor : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? _primaryColor : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? _primaryColor : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? _primaryColor.withOpacity(0.1) : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? _primaryColor : AppColors.textSecondary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          Switch(
            value: value,
            activeColor: _primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renk Seç'),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
            ].map((color) => InkWell(
              onTap: () {
                onColorChanged(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: currentColor == color ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _previewDesign() {
    // Tasarımın önizlemesini göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.preview_rounded, color: AppColors.white),
            const SizedBox(width: 8),
            const Text('Tasarım önizlemesi gösteriliyor...'),
          ],
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _saveDesign() async {
    setState(() => _isLoading = true);

    try {
      // Tasarım ayarlarını kaydet
      // Bu bilgiler business model'e veya ayrı bir design collection'a kaydedilebilir
      
      await Future.delayed(const Duration(seconds: 1)); // Simulated save
      
      widget.onDesignChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.white),
                const SizedBox(width: 8),
                const Text('Tasarım ayarları kaydedildi'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 