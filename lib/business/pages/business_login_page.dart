import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/enums/user_type.dart';
import '../../presentation/widgets/shared/error_message.dart';

class BusinessLoginPage extends StatefulWidget {
  const BusinessLoginPage({super.key});

  @override
  State<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends State<BusinessLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(); // email kullanıyoruz artık
  final _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo ve başlık
                  _buildHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // Login formu
                  _buildLoginForm(),
                  
                  const SizedBox(height: 24),
                  
                  // Hata mesajı
                  if (_errorMessage != null) ...[
                    ErrorMessage(message: _errorMessage!),
                    const SizedBox(height: 24),
                  ],
                  
                  // Giriş butonu
                  _buildLoginButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Alt bilgiler
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.business,
            size: 40,
            color: AppColors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Başlık
        Text(
          'Business Girişi',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'İşletme hesabınıza giriş yapın',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Kullanıcı adı
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-posta',
              hintText: 'E-posta adresinizi girin',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.greyLight,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'E-posta gerekli';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Şifre
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: 'Şifrenizi girin',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.greyLight,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                'Giriş Yap',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Hesabınız yok mu?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textLight,
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextButton(
          onPressed: () {
            // Business kayıt sayfasına yönlendir
            Navigator.pushNamed(context, '/business-register');
          },
          child: Text(
            'Business Hesabı Oluştur',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          '© 2024 MasaMenu. Tüm hakları saklıdır.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔐 Login attempt with email: ${_emailController.text.trim()}');
      
      // Email ile giriş yapmayı dene
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      print('🔐 Login result: ${user != null ? 'SUCCESS' : 'NULL_USER'}');
      
      if (user != null) {
        print('🔐 User type: ${user.userType.value}');
        print('🔐 User UID: ${user.uid}');
        
        if (mounted) {
          // Check if user is business type
          if (user.userType.value == 'business') {
            print('🔐 Redirecting to business dashboard...');
            // Başarılı giriş - Business dashboard'a yönlendir
            Navigator.pushReplacementNamed(context, '/business/dashboard');
          } else {
            print('🔐 User is not business type: ${user.userType.value}');
            setState(() {
              _errorMessage = 'Bu hesap işletme hesabı değil. Lütfen işletme hesabınızla giriş yapın.';
            });
          }
        }
      } else {
        print('🔐 User is null after login');
        setState(() {
          _errorMessage = 'Kullanıcı bulunamadı.';
        });
      }
    } catch (e) {
      print('🔐 Login error: $e');
      setState(() {
        _errorMessage = e.toString().contains('Exception:') 
            ? e.toString().split('Exception: ')[1]
            : 'Giriş yapılırken bir hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 