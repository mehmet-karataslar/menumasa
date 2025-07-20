import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../services/business_service.dart';
import '../models/business_user.dart';
import '../../../presentation/widgets/shared/loading_indicator.dart';
import '../../../presentation/widgets/shared/error_message.dart';
import '../../../presentation/widgets/shared/empty_state.dart';
import '../../../presentation/pages/business/business_home_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import 'dart:html' as html;

class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  final BusinessService _businessService = BusinessService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _redirectToBusinessHome();
  }

  Future<void> _redirectToBusinessHome() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        // User not authenticated, redirect to login
        Navigator.pushReplacementNamed(context, '/business/login');
        return;
      }

      // Check if user has business data
      if (currentUser.businessData?.businessIds.isNotEmpty == true) {
        final businessId = currentUser.businessData!.businessIds.first;
        
        // Get current URL to extract tab if any
        final currentUrl = html.window.location.href;
        final uri = Uri.parse(currentUrl);
        
        String? initialTab;
        if (uri.pathSegments.length >= 3 && uri.pathSegments[0] == 'business') {
          final potentialTab = uri.pathSegments[2];
          final validTabs = [
            'genel-bakis', 'siparisler', 'kategoriler', 
            'urunler', 'indirimler', 'qr-kodlar', 'ayarlar'
          ];
          if (validTabs.contains(potentialTab)) {
            initialTab = potentialTab;
          }
        }

        // Navigate to business home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessHomePage(
              businessId: businessId,
              initialTab: initialTab,
            ),
          ),
        );
      } else {
        // User doesn't have business data, try to load from Firestore
        final businesses = await _firestoreService.getBusinessesByOwnerId(currentUser.id);
        
        if (businesses.isNotEmpty) {
          final businessId = businesses.first.id;
          
          // Navigate to business home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessHomePage(
                businessId: businessId,
              ),
            ),
          );
        } else {
          // No business found, redirect to business registration
          setState(() {
            _errorMessage = 'Henüz kayıtlı bir işletmeniz bulunmamaktadır.';
          });
        }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicator(),
              SizedBox(height: 16),
              Text(
                'İşletme paneline yönlendiriliyor...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('İşletme Yönetimi'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ErrorMessage(message: _errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/business-register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('İşletme Kaydı Yap'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/business/login');
                },
                child: const Text('Giriş Sayfasına Dön'),
              ),
            ],
          ),
        ),
      );
    }

    // This should not be reached, but just in case
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: EmptyState(
          icon: Icons.business,
          title: 'İşletme Bulunamadı',
          message: 'İşletme bilgileri yüklenemedi',
        ),
      ),
    );
  }
}
