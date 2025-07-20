import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/url_service.dart';
import '../../../core/mixins/url_mixin.dart';
import '../../../data/models/business.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';

class BusinessProfilePage extends StatefulWidget {
  final String businessId;

  const BusinessProfilePage({super.key, required this.businessId});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> 
    with TickerProviderStateMixin, UrlMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Business Info Controllers
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessTypeController = TextEditingController();

  // Address Controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Contact Controllers
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Social Media Controllers
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();

  // Working Hours Controllers
  final Map<String, TextEditingController> _openHoursControllers = {};
  final Map<String, TextEditingController> _closeHoursControllers = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  int _currentStep = 0;
  
  // Platform-aware image handling
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _currentLogoUrl;
  bool _isUploadingImage = false;

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final UrlService _urlService = UrlService();
  final ImagePicker _imagePicker = ImagePicker();

  Business? _business;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Business types
  final List<String> _businessTypes = [
    'Restoran',
    'Kafe',
    'Fast Food',
    'Pizzacı',
    'Pastane',
    'Bar',
    'Dondurma',
    'Diğer',
  ];

  // Days of week for working hours
  final List<String> _daysOfWeek = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWorkingHours();
    _loadBusinessData();
    
    // Update URL for business profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlService.updateBusinessUrl(widget.businessId, 'ayarlar');
    });
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

  void _initializeWorkingHours() {
    for (String day in _daysOfWeek) {
      _openHoursControllers[day] = TextEditingController(text: '09:00');
      _closeHoursControllers[day] = TextEditingController(text: '22:00');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessTypeController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    
    for (var controller in _openHoursControllers.values) {
      controller.dispose();
    }
    for (var controller in _closeHoursControllers.values) {
      controller.dispose();
    }
    
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = await _firestoreService.getBusiness(widget.businessId);
      if (business != null) {
        setState(() {
          _business = business;
          _currentLogoUrl = business.logoUrl;
          _populateFields(business);
        });
      } else {
        setState(() {
          _errorMessage = 'İşletme bulunamadı';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'İşletme bilgileri yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields(Business business) {
    _businessNameController.text = business.businessName;
    _businessDescriptionController.text = business.businessDescription;
    _businessTypeController.text = business.businessType;
    
    _streetController.text = business.address.street;
    _cityController.text = business.address.city;
    _districtController.text = business.address.district;
    _postalCodeController.text = business.address.postalCode ?? '';
    
    _phoneController.text = business.contactInfo.phone ?? '';
    _emailController.text = business.contactInfo.email ?? '';
    _websiteController.text = business.contactInfo.website ?? '';
    _instagramController.text = business.contactInfo.instagram ?? '';
    _facebookController.text = business.contactInfo.facebook ?? '';
    _twitterController.text = business.contactInfo.twitter ?? '';

    // Load working hours if available
    if (business.menuSettings.workingHours != null) {
      for (var entry in business.menuSettings.workingHours!.entries) {
        if (_openHoursControllers.containsKey(entry.key)) {
          final hours = entry.value.split('-');
          if (hours.length == 2) {
            _openHoursControllers[entry.key]!.text = hours[0].trim();
            _closeHoursControllers[entry.key]!.text = hours[1].trim();
          }
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          _isUploadingImage = true;
        });

        // Web için bytes'ı da al
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
          });
        }

        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Resim seçilirken hata: $e';
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 4) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      await _saveBusinessInfo();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
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
        return _validateBasicInfo();
      case 1:
        return _validateAddressInfo();
      case 2:
        return _validateContactInfo();
      case 3:
        return true; // Social media is optional
      case 4:
        return true; // Working hours is optional
      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    if (_businessNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'İşletme adı gerekli';
      });
      return false;
    }
    if (_businessDescriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'İşletme açıklaması gerekli';
      });
      return false;
    }
    if (_businessTypeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'İşletme türü seçiniz';
      });
      return false;
    }
    return true;
  }

  bool _validateAddressInfo() {
    if (_streetController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Adres gerekli';
      });
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Şehir gerekli';
      });
      return false;
    }
    if (_districtController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'İlçe gerekli';
      });
      return false;
    }
    return true;
  }

  bool _validateContactInfo() {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Telefon numarası gerekli';
      });
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'E-posta adresi gerekli';
      });
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Geçerli bir e-posta adresi girin';
      });
      return false;
    }
    return true;
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? logoUrl = _currentLogoUrl;

      // Upload new logo if selected
      if (_selectedImageFile != null) {
        setState(() {
          _errorMessage = 'Logo yükleniyor...';
        });
        
        logoUrl = await _storageService.uploadBusinessLogo(
          _selectedImageFile!,
          widget.businessId,
        );
      }

      // Prepare working hours
      Map<String, String> workingHours = {};
      for (String day in _daysOfWeek) {
        final openTime = _openHoursControllers[day]!.text.trim();
        final closeTime = _closeHoursControllers[day]!.text.trim();
        if (openTime.isNotEmpty && closeTime.isNotEmpty) {
          workingHours[day] = '$openTime - $closeTime';
        }
      }

      // Create updated business
      final updatedBusiness = _business!.copyWith(
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
        businessType: _businessTypeController.text.trim(),
        logoUrl: logoUrl,
        address: Address(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          coordinates: _business!.address.coordinates,
        ),
        contactInfo: ContactInfo(
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
          facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
          twitter: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
        ),
        menuSettings: _business!.menuSettings.copyWith(
          workingHours: workingHours,
        ),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestoreService.saveBusiness(updatedBusiness);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşletme bilgileri başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'İşletme bilgileri güncellenirken hata: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İşletme Bilgileri'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: ErrorMessage(message: _errorMessage ?? 'İşletme bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('İşletme Ayarları'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _previousStep,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),

              const SizedBox(height: 20),

              // Page content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBasicInfoPage(),
                      _buildAddressPage(),
                      _buildContactPage(),
                      _buildSocialMediaPage(),
                      _buildWorkingHoursPage(),
                    ],
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                      ],
                    ),
                  ),
                ),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
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
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Temel Bilgiler', Icons.business),
          const SizedBox(height: 24),

          // Logo Section
          _buildLogoSection(),

          const SizedBox(height: 24),

          // Business Name
          _buildTextField(
            controller: _businessNameController,
            label: 'İşletme Adı',
            hint: 'İşletmenizin adını girin',
            icon: Icons.business,
            required: true,
          ),

          const SizedBox(height: 16),

          // Business Description
          _buildTextField(
            controller: _businessDescriptionController,
            label: 'İşletme Açıklaması',
            hint: 'İşletmeniz hakkında kısa bir açıklama',
            icon: Icons.description,
            maxLines: 3,
            required: true,
          ),

          const SizedBox(height: 16),

          // Business Type Dropdown
          _buildBusinessTypeDropdown(),
        ],
      ),
    );
  }

  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Adres Bilgileri', Icons.location_on),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _streetController,
            label: 'Adres',
            hint: 'Tam adresinizi girin',
            icon: Icons.home,
            maxLines: 2,
            required: true,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'Şehir',
                  hint: 'Şehir',
                  icon: Icons.location_city,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _districtController,
                  label: 'İlçe',
                  hint: 'İlçe',
                  icon: Icons.location_on,
                  required: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _postalCodeController,
            label: 'Posta Kodu',
            hint: 'Posta kodu (opsiyonel)',
            icon: Icons.mail,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('İletişim Bilgileri', Icons.contact_phone),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _phoneController,
            label: 'Telefon',
            hint: '+90 XXX XXX XX XX',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            required: true,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _emailController,
            label: 'E-posta',
            hint: 'ornek@email.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            required: true,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _websiteController,
            label: 'Web Sitesi',
            hint: 'https://www.ornek.com (opsiyonel)',
            icon: Icons.web,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sosyal Medya', Icons.share),
          const SizedBox(height: 8),
          Text(
            'Bu bilgiler opsiyoneldir. Müşterilerinizin sizi sosyal medyada bulmasını kolaylaştırır.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _instagramController,
            label: 'Instagram',
            hint: '@kullaniciadi',
            icon: Icons.camera_alt,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _facebookController,
            label: 'Facebook',
            hint: 'facebook.com/sayfaniz',
            icon: Icons.facebook,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _twitterController,
            label: 'Twitter',
            hint: '@kullaniciadi',
            icon: Icons.alternate_email,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Çalışma Saatleri', Icons.access_time),
          const SizedBox(height: 8),
          Text(
            'İşletmenizin açık olduğu saatleri belirtin.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          ..._daysOfWeek.map((day) => _buildWorkingHourRow(day)),
        ],
      ),
    );
  }

  Widget _buildWorkingHourRow(String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    controller: _openHoursControllers[day]!,
                    hint: '09:00',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '-',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeField(
                    controller: _closeHoursControllers[day]!,
                    hint: '22:00',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      keyboardType: TextInputType.text,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          controller.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        }
      },
      readOnly: true,
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
      validator: required ? (value) {
        if (value?.trim().isEmpty ?? true) {
          return '$label gerekli';
        }
        return null;
      } : null,
    );
  }

  Widget _buildBusinessTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _businessTypeController.text.isEmpty ? null : _businessTypeController.text,
      decoration: InputDecoration(
        labelText: 'İşletme Türü *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      items: _businessTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _businessTypeController.text = value;
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'İşletme türü seçiniz';
        }
        return null;
      },
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İşletme Logosu',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _isUploadingImage ? null : _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.greyLight,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isUploadingImage
                  ? const Center(child: LoadingIndicator(size: 30))
                  : _buildLogoContent(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Logo yüklemek için tıklayın',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoContent() {
    if (_selectedImageFile != null) {
      if (kIsWeb && _selectedImageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            _selectedImageBytes!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        );
      } else if (!kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_selectedImageFile!.path),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    
    if (_currentLogoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _currentLogoUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildLogoPlaceholder();
          },
        ),
      );
    }
    
    return _buildLogoPlaceholder();
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 40,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          'Logo\nEkle',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Geri'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_currentStep == 4 ? 'Kaydet' : 'İleri'),
            ),
          ),
        ],
      ),
    );
  }
}
