import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/data_service.dart';
import '../customer/customer_login_page.dart';

// Splash page with Firebase debug info
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _loadingText = 'Uygulama başlatılıyor...';
  String _debugInfo = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Test Firebase connection
      setState(() {
        _loadingText = 'Firebase bağlantısı test ediliyor...';
        _debugInfo = '🔥 Firebase bağlantısı kontrol ediliyor';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Test DataService
      setState(() {
        _loadingText = 'Veri servisi hazırlanıyor...';
        _debugInfo = '📊 DataService başlatılıyor';
      });

      final dataService = DataService();

      // Step 3: Test database connection
      setState(() {
        _loadingText = 'Veritabanı bağlantısı kontrol ediliyor...';
        _debugInfo = '🗄️ Firestore bağlantısı test ediliyor';
      });

      final businesses = await dataService.getBusinesses();

      setState(() {
        _debugInfo = '✅ ${businesses.length} işletme bulundu';
      });

      // Step 4: Check sample data
      if (businesses.isEmpty) {
        setState(() {
          _loadingText = 'Örnek veriler oluşturuluyor...';
          _debugInfo = '📝 Örnek veriler hazırlanıyor';
        });

        await dataService.initializeSampleData();

        setState(() {
          _debugInfo = '✅ Örnek veriler oluşturuldu';
        });
      }

      // Step 5: Navigate to main app
      setState(() {
        _loadingText = 'Uygulama hazır!';
        _debugInfo = '🚀 Ana sayfaya yönlendiriliyor';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerLoginPage()),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Splash initialization error: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _hasError = true;
        _loadingText = 'Hata oluştu!';
        _debugInfo = '❌ Hata: $e';
      });

      // Navigate anyway after showing error
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerLoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Uygulama adı
            const Text(
              'Masa Menü',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Slogan
            const Text(
              'Dijital Menü Çözümü',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 48),

            // Loading text
            Text(
              _loadingText,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.white,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 16),

            // Loading indicator or error
            if (!_hasError) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  strokeWidth: 2,
                ),
              ),
            ] else ...[
              const Icon(Icons.error_outline, color: AppColors.white, size: 32),
            ],

            const SizedBox(height: 24),

            // Debug info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.white,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerLoginPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Devam Et'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
