import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/customer_profile.dart';
import '../services/customer_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({Key? key}) : super(key: key);

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isImageUploading = false;
  DateTime? _selectedBirthdate;
  String? _selectedGender;
  CustomerProfile? _profile;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnimationController, curve: Curves.elasticOut),
    );

    // Load profile data
    _loadProfile();
    
    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final customer = _customerService.currentCustomer;
      if (customer != null) {
        _profile = await _customerService.getCustomerProfile(customer.customerId);
        if (_profile != null) {
          _loadProfileData();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Profil yüklenemedi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadProfileData() {
    if (_profile != null) {
      _firstNameController.text = _profile!.firstName ?? '';
      _lastNameController.text = _profile!.lastName ?? '';
      _emailController.text = _profile!.email ?? '';
      _phoneController.text = _profile!.phone ?? '';
      _selectedGender = _profile!.gender;
      
      if (_profile!.birthDate != null) {
        _selectedBirthdate = _profile!.birthDate;
        _birthdateController.text = _formatDate(_profile!.birthDate!);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildModernSliverAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _isLoading ? 
                    const Center(child: LoadingIndicator()) :
                    _buildProfileContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.secondary.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: CirclePatternPainter(),
                  ),
                ),
              ),
              
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildProfileAvatar(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profile?.displayName ?? 'Profil Bilgileri',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_profile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _profile!.email ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isEditing ? Icons.save_rounded : Icons.edit_rounded,
              color: AppColors.white,
            ),
            onPressed: _toggleEditMode,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _isEditing ? _pickAndUploadImage : null,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.white.withOpacity(0.3),
                  AppColors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.white.withOpacity(0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: _profile?.hasProfileImage == true
                  ? Image.network(
                      _profile!.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          
          if (_isImageUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            
          // Edit button
          if (_isEditing && !_isImageUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withOpacity(0.3),
            AppColors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 50,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Section - özet bilgiler
            if (_profile != null) _buildStatisticsSection(),
            
            const SizedBox(height: 20),

            // Personal Information Section - temel profil bilgileri
            _buildSectionCard(
              title: 'Kişisel Bilgiler',
              icon: Icons.person_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _firstNameController,
                        label: 'Ad',
                        icon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Ad gereklidir';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _lastNameController,
                        label: 'Soyad',
                        icon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Soyad gereklidir';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  icon: Icons.email_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_isEditing && (value == null || value.isEmpty)) {
                      return 'E-posta gereklidir';
                    }
                    if (_isEditing && value != null && value.isNotEmpty && 
                        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _phoneController,
                  label: 'Telefon',
                  icon: Icons.phone_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDatePickerField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGenderDropdown()),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Adres Bilgileri
            if (_profile?.addresses.isNotEmpty == true)
              _buildSectionCard(
                title: 'Adres Bilgileri',
                icon: Icons.location_on_rounded,
                children: [
                  ..._profile!.addresses.take(1).map((address) => // Sadece varsayılan adresi göster
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            address.isDefault ? Icons.home_rounded : Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address.fullAddress,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    TextButton.icon(
                      onPressed: () => _navigateToAddressManagement(),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Adres Yönetimi'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 30),

            // Kaydet butonu (sadece edit modunda)
            if (_isEditing)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded),
                      const SizedBox(width: 8),
                      Text(
                        'Değişiklikleri Kaydet',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final stats = _profile!.statistics;
    
    return _buildSectionCard(
      title: 'Özet Bilgiler',
      icon: Icons.analytics_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Sipariş',
                '${stats.totalOrders}',
                Icons.receipt_long_rounded,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Harcama',
                '₺${stats.totalSpent.toStringAsFixed(2)}',
                Icons.payments_rounded,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ziyaret Sayısı',
                '${stats.totalVisits}',
                Icons.location_on_rounded,
                AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Favori İşletme',
                '${stats.favoriteBusinessIds.length}',
                Icons.favorite_rounded,
                AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Bu metodlar kaldırıldı - ayarlar artık ayrı sayfalarda

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.greyLighter),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: enabled ? AppColors.white : AppColors.greyLighter.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _isEditing ? _selectBirthdate : null,
      child: AbsorbPointer(
        child: _buildModernTextField(
          controller: _birthdateController,
          label: 'Doğum Tarihi',
          icon: Icons.calendar_today_outlined,
          enabled: _isEditing,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return GestureDetector(
      onTap: _isEditing ? _selectGender : null,
      child: AbsorbPointer(
        child: _buildModernTextField(
          controller: TextEditingController(text: _getGenderDisplayText()),
          label: 'Cinsiyet',
          icon: Icons.person_outline_rounded,
          enabled: _isEditing,
        ),
      ),
    );
  }

  String _getGenderDisplayText() {
    switch (_selectedGender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      case 'other':
        return 'Diğer';
      case 'prefer_not_to_say':
        return 'Belirtmek istemiyorum';
      default:
        return '';
    }
  }

  Future<void> _selectGender() async {
    final selectedGender = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Cinsiyet Seçin',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...[
                    {'value': 'male', 'label': 'Erkek'},
                    {'value': 'female', 'label': 'Kadın'},
                    {'value': 'other', 'label': 'Diğer'},
                    {'value': 'prefer_not_to_say', 'label': 'Belirtmek istemiyorum'},
                  ].map((option) => ListTile(
                    leading: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(option['label']!),
                    selected: _selectedGender == option['value'],
                    selectedTileColor: AppColors.primary.withOpacity(0.1),
                    onTap: () => Navigator.pop(context, option['value']),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedGender != null) {
      setState(() {
        _selectedGender = selectedGender;
      });
      HapticFeedback.lightImpact();
    }
  }

  // Kullanılmayan widget helper metodları kaldırıldı - artık gereksiz

  void _toggleEditMode() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() {
        _isEditing = true;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _customerService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        birthDate: _selectedBirthdate,
        gender: _selectedGender,
      );

      // Güncellenmiş profili yükle
      await _loadProfile();

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                const Text('Profil başarıyla güncellendi!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Profil güncellenemedi: $e');
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _loadProfileData(); // Reload original data
    HapticFeedback.lightImpact();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isImageUploading = true);
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        await _customerService.uploadProfileImage(imageFile);
        
        // Profili yeniden yükle
        await _loadProfile();
        
        HapticFeedback.mediumImpact();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.white),
                  const SizedBox(width: 12),
                  const Text('Profil fotoğrafı başarıyla güncellendi!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Profil resmi yüklenemedi: $e');
    } finally {
      setState(() => _isImageUploading = false);
    }
  }

  // Ayar güncelleme metodları kaldırıldı - artık ayrı sayfalarda yapılacak

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = _formatDate(picked);
      });
      HapticFeedback.lightImpact();
    }
  }

  // Navigation metodları kaldırıldı - bu özellikler profil sekmesindeki alt menülerden erişilecek

  void _navigateToAddressManagement() {
    // TODO: Implement navigation to address management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adres yönetimi sayfasına yönlendiriliyorsunuz...')),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// Custom painter for circle pattern
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 40.0;
    const double radius = 15.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 