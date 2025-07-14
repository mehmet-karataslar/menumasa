import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';

class LoginPage extends StatefulWidget {
  final String userType; // 'customer' or 'business'

  const LoginPage({super.key, required this.userType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Giriş başarılı, kullanıcı tipine göre yönlendir
        if (widget.userType == 'customer') {
          // Müşteri giriş sonrası - müşteri dashboard'a yönlendir
          Navigator.pushReplacementNamed(
            context,
            '/customer/dashboard',
            arguments: {'userId': user.uid},
          );
        } else {
          // İşletme giriş sonrası - admin dashboarda yönlendir
          Navigator.pushReplacementNamed(
            context,
            '/admin',
            arguments: {'businessId': user.uid},
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta adresinizi girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo ve başlık
                _buildHeader(),

                const SizedBox(height: 48),

                // Giriş formu
                _buildLoginForm(),

                const SizedBox(height: 24),

                // Şifremi unuttum bağlantısı
                _buildForgotPasswordButton(),

                const SizedBox(height: 32),

                // Giriş butonu
                _buildLoginButton(),

                const SizedBox(height: 24),

                // Hata mesajı
                if (_errorMessage != null)
                  ErrorMessage(message: _errorMessage!),

                const SizedBox(height: 32),

                // Kayıt ol bağlantısı
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            widget.userType == 'customer' ? Icons.person : Icons.business,
            color: AppColors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.userType == 'customer' ? 'Müşteri Girişi' : 'İşletme Girişi',
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.userType == 'customer'
              ? 'Menüleri görüntülemek için giriş yapın'
              : 'İşletme yönetim paneline hoş geldiniz',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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

          // Şifre alanı
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
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
            onFieldSubmitted: (_) => _handleLogin(),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _handleForgotPassword,
        child: Text(
          'Şifremi Unuttum',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                'Giriş Yap',
                style: AppTypography.buttonLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabınız yok mu? ',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/register',
                    arguments: {'userType': widget.userType},
                  );
                },
          child: Text(
            'Kayıt Ol',
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
