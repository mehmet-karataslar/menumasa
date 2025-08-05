import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/url_service.dart';
import '../../../core/mixins/url_mixin.dart';

import '../../widgets/shared/loading_indicator.dart';


class LoginPage extends StatefulWidget {
  final String userType; // 'customer' or 'business'

  const LoginPage({super.key, required this.userType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with UrlMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final AuthService _authService = AuthService();
  final UrlService _urlService = UrlService();

  @override
  void initState() {
    super.initState();
    // Update URL for login page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLoginUrl();
    });
  }

  void _updateLoginUrl() {
    if (widget.userType == 'business') {
      _urlService.updateUrl('/business/login', customTitle: 'İşletme Girişi | MasaMenu');
    } else if (widget.userType == 'admin') {
      _urlService.updateUrl('/admin/login', customTitle: 'Admin Girişi | MasaMenu');
    } else {
      _urlService.updateUrl('/login', customTitle: 'Giriş | MasaMenu');
    }
  }

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
        // Navigate based on user type with URL updates
        if (user.userType.value == 'customer') {
          _urlService.updateCustomerUrl(user.id, 'dashboard', customTitle: 'Müşteri Paneli | MasaMenu');
          Navigator.pushReplacementNamed(
            context,
            '/customer/dashboard',
            arguments: {'userId': user.id},
          );
        } else if (user.userType.value == 'business') {
          _urlService.updateUrl('/business/dashboard', customTitle: 'İşletme Paneli | MasaMenu');
          Navigator.pushReplacementNamed(
            context,
            '/business/dashboard',
          );
        } else if (user.userType.value == 'admin') {
          _urlService.updateAdminUrl('dashboard', customTitle: 'Admin Paneli | MasaMenu');
          Navigator.pushReplacementNamed(
            context,
            '/admin/dashboard',
            arguments: {'adminId': user.id},
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_getPageTitle()),
        backgroundColor: _getAppBarColor(),
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
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

                  const SizedBox(height: 32),

                  // Giriş formu
                  _buildLoginForm(),

                  const SizedBox(height: 24),

                  // Yardımcı linkler
                  _buildHelperLinks(),
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _getAppBarColor(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getHeaderIcon(),
            color: AppColors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getPageTitle(),
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getSubtitle(),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // E-posta alanı
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Şifre alanı
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
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
              ),

              const SizedBox(height: 8),

              // Şifremi unuttum linki
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Şifremi Unuttum'),
                ),
              ),

              const SizedBox(height: 24),

              // Hata mesajı
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Giriş butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getAppBarColor(),
                    foregroundColor: AppColors.white,
                  ),
                  child: _isLoading
                      ? const LoadingIndicator(size: 20)
                      : const Text('Giriş Yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelperLinks() {
    return Column(
      children: [
        // Kayıt ol linki
        if (widget.userType != 'admin') ...[
          TextButton(
            onPressed: () {
              if (widget.userType == 'business') {
                _urlService.updateUrl('/business-register', customTitle: 'İşletme Kaydı | MasaMenu');
                Navigator.pushReplacementNamed(context, '/business-register');
              } else {
                _urlService.updateUrl('/register', customTitle: 'Kayıt Ol | MasaMenu');
                Navigator.pushReplacementNamed(context, '/register');
              }
            },
            child: Text('Hesabınız yok mu? Kayıt olun'),
          ),
        ],

        const SizedBox(height: 8),

        // Diğer giriş türleri
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.userType != 'customer') ...[
              TextButton(
                onPressed: () {
                  _urlService.updateUrl('/login', customTitle: 'Müşteri Girişi | MasaMenu');
                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                    arguments: {'userType': 'customer'},
                  );
                },
                child: const Text('Müşteri Girişi'),
              ),
            ],
            if (widget.userType != 'business') ...[
              const Text(' | '),
              TextButton(
                onPressed: () {
                  _urlService.updateUrl('/business/login', customTitle: 'İşletme Girişi | MasaMenu');
                  Navigator.pushReplacementNamed(
                    context,
                    '/business/login',
                    arguments: {'userType': 'business'},
                  );
                },
                child: const Text('İşletme Girişi'),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Ana sayfaya dön
        TextButton.icon(
          onPressed: () {
            _urlService.updateUrl('/', customTitle: 'Ana Sayfa | MasaMenu');
            Navigator.pushReplacementNamed(context, '/');
          },
          icon: const Icon(Icons.home),
          label: const Text('Ana Sayfaya Dön'),
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (widget.userType) {
      case 'business':
        return 'İşletme Girişi';
      case 'admin':
        return 'Admin Girişi';
      default:
        return 'Müşteri Girişi';
    }
  }

  String _getSubtitle() {
    switch (widget.userType) {
      case 'business':
        return 'İşletme hesabınızla giriş yapın';
      case 'admin':
        return 'Sistem yöneticisi olarak giriş yapın';
      default:
        return 'Müşteri hesabınızla giriş yapın';
    }
  }

  Color _getAppBarColor() {
    switch (widget.userType) {
      case 'business':
        return AppColors.primary;
      case 'admin':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  IconData _getHeaderIcon() {
    switch (widget.userType) {
      case 'business':
        return Icons.business;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}
