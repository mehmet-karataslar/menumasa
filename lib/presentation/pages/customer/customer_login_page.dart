import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({Key? key}) : super(key: key);

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _tableController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  int _selectedMethod = 0; // 0: Phone, 1: Table

  @override
  void dispose() {
    _phoneController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _handleCustomerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String identifier = '';

      if (_selectedMethod == 0) {
        // Telefon numarası girişi
        identifier = _phoneController.text.trim();
      } else {
        // Masa numarası girişi
        identifier = _tableController.text.trim();
        if (!identifier.toLowerCase().startsWith('masa')) {
          identifier = 'masa$identifier';
        }
      }

      final result = await _authService.authenticateUser(identifier, '');

      if (result.success && result.loginType == LoginType.customer) {
        _showSuccessMessage('Giriş başarılı! Menüye yönlendiriliyorsunuz...');

        // Müşteri menüsüne yönlendir
        Navigator.pushReplacementNamed(
          context,
          '/menu',
          arguments: {
            'businessId': 'demo-business-001',
            'customerPhone': result.customerId,
          },
        );
      } else {
        _showErrorMessage(
          'Giriş bilgileri kontrol edilemedi. Lütfen tekrar deneyin.',
        );
      }
    } catch (e) {
      _showErrorMessage('Giriş yapılırken hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Müşteri Girişi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Başlık
                Text(
                  'Hoş Geldiniz!',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Dijital menümüze erişmek için giriş yapın',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Giriş yöntemi seçimi
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Telefon numarası seçeneği
                      RadioListTile<int>(
                        title: const Text('Telefon Numarası ile Giriş'),
                        subtitle: const Text('05xx xxx xx xx'),
                        value: 0,
                        groupValue: _selectedMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedMethod = value!;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),

                      const Divider(height: 1),

                      // Masa numarası seçeneği
                      RadioListTile<int>(
                        title: const Text('Masa Numarası ile Giriş'),
                        subtitle: const Text('Masa 1, Masa 2, vb.'),
                        value: 1,
                        groupValue: _selectedMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedMethod = value!;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Giriş formu
                if (_selectedMethod == 0) ...[
                  // Telefon numarası girişi
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Telefon Numarası',
                      hintText: '05xx xxx xx xx',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+90 ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Telefon numarası gereklidir';
                      }
                      if (value.length < 10) {
                        return 'Geçerli bir telefon numarası girin';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Otomatik format
                      if (value.length == 10 && !value.startsWith('0')) {
                        _phoneController.text = '0$value';
                        _phoneController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _phoneController.text.length),
                        );
                      }
                    },
                  ),
                ] else ...[
                  // Masa numarası girişi
                  TextFormField(
                    controller: _tableController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Masa Numarası',
                      hintText: '1, 2, 3...',
                      prefixIcon: Icon(Icons.table_restaurant),
                      prefixText: 'Masa ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Masa numarası gereklidir';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 1 || number > 999) {
                        return 'Geçerli bir masa numarası girin (1-999)';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Giriş butonu
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCustomerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menüye Git',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // QR kod tarama alternatifi
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/qr-scanner');
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('QR Kod Tara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // İşletme girişi linki
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'İşletme sahibi misiniz? Buradan giriş yapın',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bilgi kutusu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nasıl Giriş Yapılır?',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• QR kodu tarayın (en hızlı yöntem)\n'
                        '• Telefon numaranızı girin\n'
                        '• Masa numaranızı girin\n'
                        '• Giriş yaptıktan sonra menüyü görüntüleyebilirsiniz',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
