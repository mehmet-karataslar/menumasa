import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/business.dart';
import '../../../data/models/category.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessRegisterPage extends StatefulWidget {
  const BusinessRegisterPage({super.key});

  @override
  State<BusinessRegisterPage> createState() => _BusinessRegisterPageState();
}

class _BusinessRegisterPageState extends State<BusinessRegisterPage> {
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

  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkUserAuthStatus();
  }

  Future<void> _checkUserAuthStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      // If not logged in, show registration form directly
      // Don't redirect to login page
    } else {
      // If logged in, pre-fill email field with user's email
      final userData = await _authService.getCurrentUserData();
      if (userData != null && mounted) {
        setState(() {
          _emailController.text = userData.email;
          _phoneController.text = userData.phone ?? '';
        });
      }
    }
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 2) {
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
      await _handleBusinessRegister();
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
      default:
        return false;
    }
  }

  bool _validateBusinessInfo() {
    final businessName = _businessNameController.text.trim();
    final businessDescription = _businessDescriptionController.text.trim();
    
    if (businessName.isEmpty) {
      setState(() {
        _errorMessage = 'İşletme adı gerekli';
      });
      return false;
    }
    if (businessDescription.isEmpty) {
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
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    
    if (street.isEmpty) {
      setState(() {
        _errorMessage = 'Adres gerekli';
      });
      return false;
    }
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Şehir gerekli';
      });
      return false;
    }
    if (district.isEmpty) {
      setState(() {
        _errorMessage = 'İlçe gerekli';
      });
      return false;
    }
    if (postalCode.isEmpty) {
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
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Telefon numarası gerekli';
      });
      return false;
    }
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'E-posta adresi gerekli';
      });
      return false;
    }
    if (!RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    ).hasMatch(email)) {
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

  Future<void> _handleBusinessRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      // If user is not logged in, create account first
      await _createUserAccount();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get trimmed values
      final businessName = _businessNameController.text.trim();
      final businessDescription = _businessDescriptionController.text.trim();
      final street = _streetController.text.trim();
      final city = _cityController.text.trim();
      final district = _districtController.text.trim();
      final postalCode = _postalCodeController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final website = _websiteController.text.trim();
      
      // Create business model
      final business = Business(
        businessId: '', // Will be auto-generated by Firestore
        ownerId: currentUser.uid,
        businessName: businessName,
        businessDescription: businessDescription,
        logoUrl: null,
        address: Address(
          street: street,
          city: city,
          district: district,
          postalCode: postalCode,
          coordinates: null,
        ),
        contactInfo: ContactInfo(
          phone: phone,
          email: email,
          website: website.isEmpty ? null : website,
          socialMedia: null,
        ),
        qrCodeUrl: null,
        menuSettings: MenuSettings(
          theme: 'default',
          primaryColor: '#2C1810',
          fontFamily: 'Poppins',
          fontSize: 16.0,
          showPrices: true,
          showImages: true,
          imageSize: 'medium',
          language: 'tr',
          showDescriptions: true,
          showCategories: true,
          showAllergens: true,
          showRatings: false,
          layoutStyle: 'card',
          showNutritionInfo: false,
          showBadges: true,
          showAvailability: true,
        ),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save business to Firestore
      final businessId = await _firestoreService.saveBusiness(business);

      if (businessId.isNotEmpty) {
        // Create default categories
        await _createDefaultCategories(businessId);
      }

      if (mounted) {
        // Registration successful, navigate to admin dashboard
        Navigator.pushReplacementNamed(
          context,
          '/admin',
          arguments: {'businessId': businessId},
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Firebase hatası: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'İşletme kaydedilirken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get trimmed values
      final email = _emailController.text.trim();
      final businessName = _businessNameController.text.trim();
      final phone = _phoneController.text.trim();
      
      // Create user account with email and password
      final user = await _authService.createUserWithEmailAndPassword(
        email,
        '123456', // Default password
        businessName,
        phone.isEmpty ? null : phone,
      );

      if (user != null) {
        // Now proceed with business registration
        await _handleBusinessRegister();
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hesap oluşturulurken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultCategories(String businessId) async {
    // Create default categories for the business
    try {
      final categories = [
        Category(
          categoryId: '',
          businessId: businessId,
          name: 'Ana Yemekler',
          description: 'Restaurantımızın özel ana yemekleri',
          sortOrder: 1,
          isActive: true,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Category(
          categoryId: '',
          businessId: businessId,
          name: 'Tatlılar',
          description: 'Tatlı çeşitlerimiz',
          sortOrder: 2,
          isActive: true,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Category(
          categoryId: '',
          businessId: businessId,
          name: 'İçecekler',
          description: 'Sıcak ve soğuk içecekler',
          sortOrder: 3,
          isActive: true,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Save each category to Firestore
      for (final category in categories) {
        await _firestoreService.saveCategory(category);
      }
    } catch (e) {
      print('Error creating default categories: $e');
      // Don't throw error here, as the business is already created
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'İşletme Kaydı',
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: _currentStep == 0
              ? () => Navigator.pop(context)
              : _previousStep,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'İşletme Bilgileri'),
                    _buildStepConnector(),
                    _buildStepIndicator(1, 'Adres Bilgileri'),
                    _buildStepConnector(),
                    _buildStepIndicator(2, 'İletişim Bilgileri'),
                  ],
                ),
              ),

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
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _previousStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Geri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _nextStep,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : Icon(
                              _currentStep < 2
                                  ? Icons.arrow_forward
                                  : Icons.check,
                            ),
                      label: Text(_currentStep < 2 ? 'İleri' : 'Kaydet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.success
                  : isActive
                  ? AppColors.primary
                  : AppColors.greyLight,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive || isCompleted
                  ? AppColors.textPrimary
                  : AppColors.textLight,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(width: 30, height: 2, color: AppColors.greyLight);
  }

  Widget _buildBusinessInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'İşletme Bilgileri',
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Müşterilerinizin göreceği temel işletme bilgilerinizi ekleyin.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),

          // Business name field
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'İşletme Adı',
              hintText: 'Lezzet Cafe',
              prefixIcon: Icon(Icons.business),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'İşletme adı gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Business description field
          TextFormField(
            controller: _businessDescriptionController,
            decoration: const InputDecoration(
              labelText: 'İşletme Açıklaması',
              hintText: 'Kısa işletme açıklaması girin',
              prefixIcon: Icon(Icons.description),
            ),
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'İşletme açıklaması gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Adres Bilgileri',
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'İşletmenizin fiziksel adres bilgilerini ekleyin.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),

          // Street field
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Adres',
              hintText: 'Cadde, sokak, bina no, daire no',
              prefixIcon: Icon(Icons.location_on),
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Adres gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // City field
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'Şehir',
              hintText: 'İstanbul',
              prefixIcon: Icon(Icons.location_city),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Şehir gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // District field
          TextFormField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'İlçe',
              hintText: 'Beyoğlu',
              prefixIcon: Icon(Icons.map),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'İlçe gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Postal code field
          TextFormField(
            controller: _postalCodeController,
            decoration: const InputDecoration(
              labelText: 'Posta Kodu',
              hintText: '34000',
              prefixIcon: Icon(Icons.markunread_mailbox),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Posta kodu gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'İletişim Bilgileri',
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Müşterilerin size ulaşabileceği iletişim bilgilerinizi ekleyin.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),

          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              hintText: '+90 555 123 45 67',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Telefon gerekli';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'info@isletme.com',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'E-posta gerekli';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Website field
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Web Sitesi (İsteğe bağlı)',
              hintText: 'www.isletme.com',
              prefixIcon: Icon(Icons.web),
            ),
            keyboardType: TextInputType.url,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
