import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/url_service.dart';
import '../../widgets/shared/error_message.dart';

class RegisterPage extends StatefulWidget {
  final String userType; // 'customer' or 'business'

  const RegisterPage({super.key, required this.userType});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();
  final UrlService _urlService = UrlService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Kullanım koşullarını kabul etmelisiniz';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (user != null && mounted) {
        // Kayıt başarılı, müşteri dashboard'a yönlendir
        _urlService.updateCustomerUrl(user.id, 'dashboard', customTitle: 'Müşteri Paneli | MasaMenu');
        Navigator.pushReplacementNamed(context, '/customer/dashboard', 
          arguments: {'userId': user.id});
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kayıt olurken bir hata oluştu. Lütfen tekrar deneyin.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Başlık
                _buildHeader(),

                const SizedBox(height: 32),

                // Kayıt formu
                _buildRegisterForm(),

                const SizedBox(height: 24),

                // Kullanım koşulları
                _buildTermsCheckbox(),

                const SizedBox(height: 32),

                // Kayıt ol butonu
                _buildRegisterButton(),

                const SizedBox(height: 24),

                // Hata mesajı
                if (_errorMessage != null)
                  ErrorMessage(message: _errorMessage!),

                const SizedBox(height: 32),

                // Giriş yap bağlantısı
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.userType == 'customer'
              ? 'Müşteri Hesabı Oluştur'
              : 'İşletme Hesabı Oluştur',
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.userType == 'customer'
              ? 'Menüleri görüntülemek için hesap oluşturun'
              : 'İşletmenizi dijital menü sistemine kaydedin',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Ad Soyad alanı
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad',
              hintText: 'Adınızı ve soyadınızı girin',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ad soyad gerekli';
              }
              if (value.trim().length < 2) {
                return 'Ad soyad en az 2 karakter olmalı';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // E-posta alanı
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'E-posta adresi gerekli';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Telefon alanı
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Telefon (İsteğe bağlı)',
              hintText: '+90 555 123 45 67',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.trim().length < 10) {
                  return 'Geçerli bir telefon numarası girin';
                }
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Şifre alanı
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: 'Şifrenizi girin',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalı';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Şifre tekrar alanı
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Şifre Tekrar',
              hintText: 'Şifrenizi tekrar girin',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarı gerekli';
              }
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleRegister(),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    setState(() {
                      _acceptTerms = !_acceptTerms;
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Devam ederek '),
                    TextSpan(
                      text: 'Kullanım Koşulları',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' ve '),
                    TextSpan(
                      text: 'Gizlilik Politikası',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '\'nı kabul etmiş olursunuz.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Kayıt Ol',
                style: AppTypography.buttonLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı? ',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                    arguments: {'userType': widget.userType},
                  );
                },
          child: Text(
            'Giriş Yap',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
