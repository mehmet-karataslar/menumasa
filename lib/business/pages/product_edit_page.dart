import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../business/models/product.dart';
import '../../core/widgets/web_safe_image.dart';
import '../../../core/services/storage_service.dart';
import '../models/category.dart' as category_model;
import '../services/business_firestore_service.dart';

// Add new image source enum
enum ImageSourceType { url, file }

// Add new image data class
class ImageData {
  final ImageSourceType sourceType;
  final String? url;
  final XFile? file;
  final Uint8List? bytes;

  const ImageData({
    required this.sourceType,
    this.url,
    this.file,
    this.bytes,
  });
}

class ProductEditPage extends StatefulWidget {
  final String businessId;
  final Product? product;
  final List<category_model.Category> categories;
  final VoidCallback onProductSaved;

  const ProductEditPage({
    Key? key,
    required this.businessId,
    this.product,
    required this.categories,
    required this.onProductSaved,
  }) : super(key: key);

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage>
    with TickerProviderStateMixin {
  final BusinessFirestoreService _businessFirestoreService =
      BusinessFirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final PageController _pageController = PageController();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _currentPriceController = TextEditingController();

  // Form state
  String _selectedCategoryId = '';
  bool _isActive = true;
  bool _isAvailable = true;
  List<String> _selectedAllergens = [];
  List<String> _selectedTags = [];
  NutritionInfo? _nutritionInfo;

  // Image handling
  List<ImageData> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isUploadingImages = false;

  // UI state
  int _currentStep = 0;
  bool _isSaving = false;
  String? _errorMessage;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Constants
  final List<String> _commonAllergens = [
    'Gluten',
    'Süt',
    'Yumurta',
    'Soya',
    'Fındık',
    'Fıstık',
    'Susam',
    'Balık',
    'Kabuklu deniz ürünleri',
    'Kükürt dioksit'
  ];

  final List<String> _commonTags = [
    'Popüler',
    'Yeni',
    'Acılı',
    'Vejetaryen',
    'Vegan',
    'Glutensiz',
    'Organik',
    'Ev yapımı',
    'Taze',
    'Özel'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _detailedDescriptionController.text = product.detailedDescription;
      _priceController.text = product.price.toString();
      _currentPriceController.text = product.currentPrice.toString();
      _selectedCategoryId = product.categoryId;
      _isActive = product.isActive;
      _isAvailable = product.isAvailable;
      _selectedAllergens = List.from(product.allergens);
      _selectedTags = List.from(product.tags);
      _nutritionInfo = product.nutritionInfo;
      _existingImageUrls = product.images.map((img) => img.url).toList();
    } else {
      // Set defaults for new product
      // Only set default category if there are categories and no duplicates
      final uniqueCategories = <String, category_model.Category>{};
      for (final category in widget.categories) {
        uniqueCategories[category.categoryId] = category;
      }
      if (uniqueCategories.isNotEmpty) {
        _selectedCategoryId = uniqueCategories.values.first.categoryId;
      }
      _currentPriceController.text = _priceController.text;
    }

    // Listen to price changes to auto-update current price
    _priceController.addListener(() {
      if (_currentPriceController.text.isEmpty ||
          _currentPriceController.text == _priceController.text) {
        _currentPriceController.text = _priceController.text;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _detailedDescriptionController.dispose();
    _priceController.dispose();
    _currentPriceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    final isEditing = widget.product != null;
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Text(isEditing ? 'Ürün Düzenle' : 'Ürün Ekle'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Geri',
      ),
      actions: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _isSaving ? null : _previousStep,
            child: Text(
              'Geri',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        TextButton(
          onPressed: _isSaving ? null : _nextStep,
          child: Text(
            _currentStep == 4 ? 'Kaydet' : 'İleri',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),

        // Error message
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),

        // Page content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBasicInfoPage(),
              _buildDetailsPage(),
              _buildPricingPage(),
              _buildImagesPage(),
              _buildNutritionAndTagsPage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (index) {
              final isActive = index <= _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.greyLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 4) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepTitle(_currentStep),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Temel Bilgiler';
      case 1:
        return 'Detaylı Açıklama';
      case 2:
        return 'Fiyat Bilgileri';
      case 3:
        return 'Ürün Resimleri';
      case 4:
        return 'Beslenme ve Etiketler';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Temel Bilgiler', Icons.info_outline),
          const SizedBox(height: 24),

          // Product name
          _buildTextField(
            controller: _nameController,
            label: 'Ürün Adı',
            hint: 'Örn: Adana Kebap',
            icon: Icons.restaurant_menu,
            required: true,
          ),

          const SizedBox(height: 16),

          // Category selection
          _buildCategoryDropdown(),

          const SizedBox(height: 16),

          // Short description
          _buildTextField(
            controller: _descriptionController,
            label: 'Kısa Açıklama',
            hint: 'Ürününüzün kısa bir açıklaması',
            icon: Icons.description,
            maxLines: 2,
            required: true,
          ),

          const SizedBox(height: 16),

          // Availability switches
          _buildAvailabilitySection(),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Detaylı Bilgiler', Icons.article_outlined),
          const SizedBox(height: 24),

          // Detailed description
          _buildTextField(
            controller: _detailedDescriptionController,
            label: 'Detaylı Açıklama',
            hint:
                'Ürününüzün malzemeleri, hazırlanış şekli, servis bilgileri vb.',
            icon: Icons.article,
            maxLines: 6,
          ),

          const SizedBox(height: 16),

          // Allergens section
          _buildAllergensSection(),
        ],
      ),
    );
  }

  Widget _buildPricingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Fiyat Bilgileri', Icons.price_change),
          const SizedBox(height: 24),

          // Original price
          _buildTextField(
            controller: _priceController,
            label: 'Liste Fiyatı (₺)',
            hint: '0.00',
            icon: Icons.attach_money,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            required: true,
          ),

          const SizedBox(height: 16),

          // Current price (with discount)
          _buildTextField(
            controller: _currentPriceController,
            label: 'Satış Fiyatı (₺)',
            hint: '0.00',
            icon: Icons.price_check,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            required: true,
          ),

          const SizedBox(height: 16),

          // Price difference info
          _buildPriceInfo(),
        ],
      ),
    );
  }

  Widget _buildImagesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ürün Resimleri', Icons.photo_library),
          const SizedBox(height: 8),
          Text(
            'Müşterilerinizin ürününüzü daha iyi görmesi için resimler ekleyin. İlk resim ana resim olarak kullanılacaktır.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Existing images
          if (_existingImageUrls.isNotEmpty) ...[
            Text(
              'Mevcut Resimler',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildExistingImagesGrid(),
            const SizedBox(height: 24),
          ],

          // New images
          if (_selectedImages.isNotEmpty) ...[
            Text(
              'Yeni Resimler',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildNewImagesGrid(),
            const SizedBox(height: 24),
          ],

          // Add image button
          _buildAddImageButton(),
        ],
      ),
    );
  }

  Widget _buildNutritionAndTagsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ek Bilgiler', Icons.local_offer),
          const SizedBox(height: 24),

          // Tags section
          _buildTagsSection(),

          const SizedBox(height: 24),

          // Nutrition info section
          _buildNutritionSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
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
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildCategoryDropdown() {
    // Get unique categories to avoid duplicate values
    final uniqueCategories = <String, category_model.Category>{};
    for (final category in widget.categories) {
      uniqueCategories[category.categoryId] = category;
    }
    final categoriesList = uniqueCategories.values.toList();

    // Check if current selected category exists in the list
    final validSelectedCategoryId = _selectedCategoryId.isNotEmpty &&
            categoriesList.any((cat) => cat.categoryId == _selectedCategoryId)
        ? _selectedCategoryId
        : null;

    return DropdownButtonFormField<String>(
      value: validSelectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Kategori *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      items: categoriesList.map((category) {
        return DropdownMenuItem<String>(
          value: category.categoryId,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategoryId = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kategori seçimi zorunludur';
        }
        return null;
      },
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durum',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Aktif Ürün'),
                subtitle: Text(
                  _isActive ? 'Ürün sistemde aktif' : 'Ürün sistemde pasif',
                  style: TextStyle(
                    color: _isActive ? AppColors.success : AppColors.error,
                  ),
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppColors.success,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Satışta'),
                subtitle: Text(
                  _isAvailable
                      ? 'Müşteriler satın alabilir'
                      : 'Geçici olarak satışta değil',
                  style: TextStyle(
                    color: _isAvailable ? AppColors.success : AppColors.warning,
                  ),
                ),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllergensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerjenler',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ürününüzde bulunan alerjik maddeleri işaretleyin.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonAllergens.map((allergen) {
            final isSelected = _selectedAllergens.contains(allergen);
            return FilterChip(
              label: Text(allergen),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAllergens.add(allergen);
                  } else {
                    _selectedAllergens.remove(allergen);
                  }
                });
              },
              selectedColor: AppColors.warning.withOpacity(0.2),
              checkmarkColor: AppColors.warning,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etiketler',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ürününüzü tanımlayan etiketleri seçin.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    final originalPrice = double.tryParse(_priceController.text) ?? 0.0;
    final currentPrice = double.tryParse(_currentPriceController.text) ?? 0.0;

    if (originalPrice > 0 &&
        currentPrice > 0 &&
        originalPrice != currentPrice) {
      final discount = ((originalPrice - currentPrice) / originalPrice * 100);
      final isDiscount = currentPrice < originalPrice;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDiscount
              ? AppColors.success.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDiscount
                ? AppColors.success.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDiscount ? Icons.trending_down : Icons.trending_up,
              color: isDiscount ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isDiscount
                    ? '${discount.toStringAsFixed(1)}% İndirimli Fiyat'
                    : '${discount.abs().toStringAsFixed(1)}% Fiyat Artışı',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDiscount ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildExistingImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _existingImageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = _existingImageUrls[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: WebSafeImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.greyLighter,
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _existingImageUrls.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            if (index == 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ana',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNewImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        final imageData = _selectedImages[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildImageWidget(imageData),
              ),
            ),
            // Source type indicator
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: imageData.sourceType == ImageSourceType.url
                      ? AppColors.primary
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  imageData.sourceType == ImageSourceType.url ? 'URL' : 'Dosya',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImages.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageWidget(ImageData imageData) {
    if (imageData.sourceType == ImageSourceType.url) {
      return WebSafeImage(
        imageUrl: imageData.url!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (context, error, stackTrace) {
          return Container(
            color: AppColors.greyLighter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: AppColors.error),
                Text('Yüklenemedi', style: TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
        placeholder: (context, url) => Container(
          color: AppColors.greyLighter,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else {
      // File source
      if (kIsWeb && imageData.bytes != null) {
        return Image.memory(
          imageData.bytes!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      } else if (imageData.file != null) {
        return Image.file(
          File(imageData.file!.path),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          color: AppColors.greyLighter,
          child: Icon(Icons.error, color: AppColors.error),
        );
      }
    }
  }

  Widget _buildAddImageButton() {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isUploadingImages ? null : _showImageSourceDialog,
        icon: _isUploadingImages
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.add_photo_alternate),
        label:
            Text(_isUploadingImages ? 'Resimler Yükleniyor...' : 'Resim Ekle'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beslenme Bilgileri',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'İsteğe bağlı beslenme bilgilerini ekleyebilirsiniz.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Column(
            children: [
              Text(
                'Beslenme bilgileri özelliği yakında eklenecek',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resim Kaynağı Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.link),
              title: Text('URL\'den Ekle'),
              subtitle: Text('İnternetten resim bağlantısı girin'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Dosya Yükle'),
              subtitle: Text('Cihazınızdan resim seçin'),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromDevice();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUrlInputDialog() async {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resim URL\'si Girin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Resim URL\'si',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 16),
            Text(
              '• Doğrudan resim URL\'si (örn: https://site.com/image.jpg)\n• Google Images bağlantısı\n• Desteklenen formatlar: .jpg, .png, .gif, .webp, .svg',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                if (_isValidImageUrl(url)) {
                  Navigator.pop(context);
                  _addImageFromUrl(url);
                } else {
                  // Show preview of extracted URL for debugging
                  final extractedUrl = _extractImageUrl(url);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'URL desteklenmiyor. Çıkarılan URL: ${extractedUrl.length > 50 ? extractedUrl.substring(0, 50) + "..." : extractedUrl}'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lütfen bir URL girin')),
                );
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  String _extractImageUrl(String input) {
    // Google Images URL format: imgurl=ENCODED_URL
    if (input.contains('imgurl=')) {
      try {
        final uri = Uri.parse(input);
        final imgUrl = uri.queryParameters['imgurl'];
        if (imgUrl != null && imgUrl.isNotEmpty) {
          return Uri.decodeComponent(imgUrl);
        }
      } catch (e) {
        // If parsing fails, continue with original input
      }
    }

    // Other image hosting services could be added here
    // For now, return the original URL if it's not a Google Images link
    return input;
  }

  bool _isValidImageUrl(String url) {
    try {
      // First extract the actual image URL if it's from Google Images or similar
      final actualUrl = _extractImageUrl(url);
      final uri = Uri.parse(actualUrl);
      final path = uri.path.toLowerCase();

      // Check for common image extensions
      return path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png') ||
          path.endsWith('.gif') ||
          path.endsWith('.webp') ||
          path.endsWith('.bmp') ||
          path.endsWith('.svg');
    } catch (e) {
      return false;
    }
  }

  void _addImageFromUrl(String url) {
    // Extract the actual image URL (handles Google Images and other formats)
    final actualImageUrl = _extractImageUrl(url);

    setState(() {
      _selectedImages.add(ImageData(
        sourceType: ImageSourceType.url,
        url: actualImageUrl,
      ));
    });
  }

  Future<void> _pickImagesFromDevice() async {
    try {
      setState(() {
        _isUploadingImages = true;
      });

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        List<ImageData> newImageData = [];

        for (final image in images) {
          Uint8List? bytes;
          if (kIsWeb) {
            bytes = await image.readAsBytes();
          }

          newImageData.add(ImageData(
            sourceType: ImageSourceType.file,
            file: image,
            bytes: bytes,
          ));
        }

        setState(() {
          _selectedImages.addAll(newImageData);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Resim seçilirken hata: $e';
      });
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 4) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      await _saveProduct();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Ürün adı gerekli';
          });
          return false;
        }
        if (_selectedCategoryId.isEmpty) {
          setState(() {
            _errorMessage = 'Kategori seçimi gerekli';
          });
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Kısa açıklama gerekli';
          });
          return false;
        }
        break;
      case 2:
        final price = double.tryParse(_priceController.text);
        final currentPrice = double.tryParse(_currentPriceController.text);

        if (price == null || price <= 0) {
          setState(() {
            _errorMessage = 'Geçerli bir liste fiyatı girin';
          });
          return false;
        }
        if (currentPrice == null || currentPrice <= 0) {
          setState(() {
            _errorMessage = 'Geçerli bir satış fiyatı girin';
          });
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _saveProduct() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      List<String> allImageUrls = List.from(_existingImageUrls);

      // Process new images
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          final imageData = _selectedImages[i];

          if (imageData.sourceType == ImageSourceType.url) {
            // For URL images, add directly to URLs list
            allImageUrls.add(imageData.url!);
          } else {
            // For file images, upload to storage
            final fileName =
                _storageService.generateFileName('product_image_$i.jpg');
            dynamic imageFile;

            if (kIsWeb && imageData.bytes != null) {
              imageFile = imageData.bytes!; // Uint8List for web
            } else if (imageData.file != null) {
              imageFile = File(imageData.file!.path); // File for mobile
            } else {
              continue; // Skip if no valid data
            }

            final imageUrl = await _storageService.uploadProductImage(
              businessId: widget.businessId,
              productId: widget.product?.productId ??
                  'new_${DateTime.now().millisecondsSinceEpoch}',
              imageFile: imageFile,
              fileName: fileName,
            );
            allImageUrls.add(imageUrl);
          }
        }
      }

      final price = double.parse(_priceController.text);
      final currentPrice = double.parse(_currentPriceController.text);

      if (widget.product == null) {
        // Create new product
        final newProduct = Product(
          productId: '',
          businessId: widget.businessId,
          categoryId: _selectedCategoryId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          detailedDescription: _detailedDescriptionController.text.trim(),
          price: price,
          currentPrice: currentPrice,
          currency: 'TL',
          images: allImageUrls.asMap().entries.map((entry) {
            return ProductImage(
              url: entry.value,
              alt: _nameController.text.trim(),
              isPrimary: entry.key == 0,
            );
          }).toList(),
          nutritionInfo: _nutritionInfo,
          allergens: _selectedAllergens,
          tags: _selectedTags,
          isActive: _isActive,
          isAvailable: _isAvailable,
          sortOrder: 0,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _businessFirestoreService.saveProduct(newProduct);
      } else {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          categoryId: _selectedCategoryId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          detailedDescription: _detailedDescriptionController.text.trim(),
          price: price,
          currentPrice: currentPrice,
          images: allImageUrls.asMap().entries.map((entry) {
            return ProductImage(
              url: entry.value,
              alt: _nameController.text.trim(),
              isPrimary: entry.key == 0,
            );
          }).toList(),
          nutritionInfo: _nutritionInfo,
          allergens: _selectedAllergens,
          tags: _selectedTags,
          isActive: _isActive,
          isAvailable: _isAvailable,
          updatedAt: DateTime.now(),
        );

        await _businessFirestoreService.saveProduct(updatedProduct);
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        widget.onProductSaved();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? '${_nameController.text} ürünü başarıyla eklendi'
                : '${_nameController.text} ürünü başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ürün kaydedilirken hata: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
