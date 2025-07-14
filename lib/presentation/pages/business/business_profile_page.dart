import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/business.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';

class BusinessProfilePage extends StatefulWidget {
  final String businessId;

  const BusinessProfilePage({super.key, required this.businessId});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Business Info Controllers
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();

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
  final _youtubeController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  int _currentStep = 0;
  File? _selectedImage;
  String? _currentLogoUrl;

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  Business? _business;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
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
    _youtubeController.dispose();
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
    _streetController.text = business.address.street;
    _cityController.text = business.address.city;
    _districtController.text = business.address.district;
    _postalCodeController.text = business.address.postalCode ?? '';
    _phoneController.text = business.contactInfo.phone ?? '';
    _emailController.text = business.contactInfo.email ?? '';
    _websiteController.text = business.contactInfo.website ?? '';
    
    // Handle social media links
    _instagramController.text = business.contactInfo.instagram ?? '';
    _facebookController.text = business.contactInfo.facebook ?? '';
    _twitterController.text = business.contactInfo.twitter ?? '';
    _youtubeController.text = ''; // YouTube not in ContactInfo, add if needed
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
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Resim seçilirken hata: $e';
      });
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
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
    switch (_currentStep) {
      case 0:
        return _validateBusinessInfo();
      case 1:
        return _validateAddress();
      case 2:
        return _validateContactInfo();
      case 3:
        return true; // Social media is optional
      default:
        return false;
    }
  }

  bool _validateBusinessInfo() {
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
    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  bool _validateAddress() {
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
    if (_postalCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Posta kodu gerekli';
      });
      return false;
    }
    setState(() {
      _errorMessage = null;
    });
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
    setState(() {
      _errorMessage = null;
    });
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
      if (_selectedImage != null) {
        final fileName = 'business_logos/${widget.businessId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        logoUrl = await _storageService.uploadFile(_selectedImage!, fileName);
      }

      // Create updated business
      final updatedBusiness = _business!.copyWith(
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('İşletme Bilgileri'),
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
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBusinessInfoPage(),
                    _buildAddressPage(),
                    _buildContactPage(),
                    _buildSocialMediaPage(),
                  ],
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ErrorMessage(message: _errorMessage!),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildStepIndicator(0, 'İşletme'),
          _buildStepConnector(),
          _buildStepIndicator(1, 'Adres'),
          _buildStepConnector(),
          _buildStepIndicator(2, 'İletişim'),
          _buildStepConnector(),
          _buildStepIndicator(3, 'Sosyal Medya'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.primary
                      : AppColors.greyLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textLight,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      height: 2,
      width: 20,
      color: _currentStep > 0 ? AppColors.success : AppColors.greyLight,
    );
  }

  Widget _buildBusinessInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İşletme Bilgileri',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Logo Section
          _buildLogoSection(),

          const SizedBox(height: 24),

          // Business Name
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'İşletme Adı *',
              hintText: 'İşletmenizin adını girin',
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'İşletme adı gerekli';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Business Description
          TextFormField(
            controller: _businessDescriptionController,
            decoration: const InputDecoration(
              labelText: 'İşletme Açıklaması *',
              hintText: 'İşletmeniz hakkında kısa bir açıklama',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'İşletme açıklaması gerekli';
              }
              return null;
            },
          ),
        ],
      ),
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
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.greyLight,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _currentLogoUrl != null
                      ? ClipRRect(
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
                        )
                      : _buildLogoPlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Logoyu değiştirmek için tıklayın',
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32,
          color: AppColors.textLight,
        ),
        const SizedBox(height: 4),
        Text(
          'Logo Ekle',
          style: AppTypography.caption.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adres Bilgileri',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Adres *',
              hintText: 'Sokak ve numara',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Adres gerekli';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Şehir *',
                    hintText: 'Şehir adı',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Şehir gerekli';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'İlçe *',
                    hintText: 'İlçe adı',
                    prefixIcon: Icon(Icons.map),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'İlçe gerekli';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _postalCodeController,
            decoration: const InputDecoration(
              labelText: 'Posta Kodu *',
              hintText: 'Posta kodu',
              prefixIcon: Icon(Icons.mail),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Posta kodu gerekli';
              }
              return null;
            },
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
          Text(
            'İletişim Bilgileri',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon *',
              hintText: 'Telefon numarası',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Telefon numarası gerekli';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta *',
              hintText: 'E-posta adresi',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'E-posta adresi gerekli';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Web Sitesi',
              hintText: 'Web sitesi adresi (opsiyonel)',
              prefixIcon: Icon(Icons.web),
            ),
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
          Text(
            'Sosyal Medya',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sosyal medya hesaplarınızı ekleyin (opsiyonel)',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _instagramController,
            decoration: const InputDecoration(
              labelText: 'Instagram',
              hintText: '@kullaniciadi',
              prefixIcon: Icon(Icons.camera_alt, color: Colors.purple),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _facebookController,
            decoration: const InputDecoration(
              labelText: 'Facebook',
              hintText: 'Facebook sayfa adı',
              prefixIcon: Icon(Icons.facebook, color: Colors.blue),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _twitterController,
            decoration: const InputDecoration(
              labelText: 'Twitter',
              hintText: '@kullaniciadi',
              prefixIcon: Icon(Icons.flutter_dash, color: Colors.lightBlue),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _youtubeController,
            decoration: const InputDecoration(
              labelText: 'YouTube',
              hintText: 'YouTube kanal adı',
              prefixIcon: Icon(Icons.play_circle, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: AppColors.white,
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _nextStep,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Icon(_currentStep == 3 ? Icons.save : Icons.arrow_forward),
            label: Text(_currentStep == 3 ? 'Kaydet' : 'İleri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
