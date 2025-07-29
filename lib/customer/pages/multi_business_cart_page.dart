import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/cart_service.dart';
import '../../business/services/business_firestore_service.dart';
import '../models/cart.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import 'cart_page.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences

class MultiBusinessCartPage extends StatefulWidget {
  final String userId;

  const MultiBusinessCartPage({Key? key, required this.userId})
      : super(key: key);

  @override
  State<MultiBusinessCartPage> createState() => _MultiBusinessCartPageState();
}

class _MultiBusinessCartPageState extends State<MultiBusinessCartPage> {
  final CartService _cartService = CartService();
  final BusinessFirestoreService _businessFirestoreService =
      BusinessFirestoreService();

  Map<String, Cart> _businessCarts = {};
  Map<String, Business> _businesses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllCarts();

    // Cart değişikliklerini dinle
    _cartService.addCartListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartService.removeCartListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged(Cart cart) {
    if (mounted) {
      _loadAllCarts(); // Tüm sepetleri yeniden yükle
    }
  }

  Future<void> _loadAllCarts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cartService.initialize();

      // STEP 1: Get current cart first (most reliable)
      final prefs = await SharedPreferences.getInstance();
      final currentCartJson = prefs.getString('current_cart');

      if (currentCartJson != null) {
        try {
          final cartData = jsonDecode(currentCartJson);

          final businessId = cartData['businessId'] as String?;
          if (businessId != null && businessId.isNotEmpty) {
            // Load this business cart
            final cart = await _cartService.getCurrentCart(businessId);

            if (cart.items.isNotEmpty) {
              _businessCarts[businessId] = cart;

              // Load business info
              final business =
                  await _businessFirestoreService.getBusiness(businessId);
              if (business != null) {
                _businesses[businessId] = business;
              }
            }
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }

      // STEP 2: Check additional business IDs if any
      final additionalBusinessIds = await _getAdditionalBusinessIds();

      for (final businessId in additionalBusinessIds) {
        if (!_businessCarts.containsKey(businessId)) {
          try {
            final cart = await _cartService.getCurrentCart(businessId);

            if (cart.items.isNotEmpty) {
              _businessCarts[businessId] = cart;

              final business =
                  await _businessFirestoreService.getBusiness(businessId);
              if (business != null) {
                _businesses[businessId] = business;
              }
            }
          } catch (e) {
            // Ignore individual business errors
          }
        }
      }
    } catch (e) {
      // Ignore general errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _getAdditionalBusinessIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessIds = <String>{};

      // Check all keys for cart-related data
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cart_') && key != 'current_cart') {
          final businessId = key.replaceFirst('cart_', '').split('_').first;
          if (businessId.isNotEmpty) {
            businessIds.add(businessId);
          }
        }
      }

      return businessIds.toList();
    } catch (e) {
      print('❌ Error getting additional business IDs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Sepetlerim',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _businessCarts.isEmpty
              ? _buildEmptyState()
              : _buildCartsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Sepetiniz Boş',
        message:
            'Henüz hiçbir işletmeden ürün eklemediniz.\nAlışverişe başlamak için işletmeleri keşfedin!',
        actionText: 'İşletmeleri Keşfet',
        onActionPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCartsList() {
    return RefreshIndicator(
      onRefresh: _loadAllCarts,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _businessCarts.length,
        itemBuilder: (context, index) {
          final businessId = _businessCarts.keys.elementAt(index);
          final cart = _businessCarts[businessId]!;
          final business = _businesses[businessId];

          return _buildBusinessCartCard(businessId, cart, business);
        },
      ),
    );
  }

  Widget _buildBusinessCartCard(
      String businessId, Cart cart, Business? business) {
    final totalAmount = cart.items.fold<double>(
      0,
      (sum, item) => sum + (item.productPrice * item.quantity),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToBusinessCart(businessId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.businessName ?? 'İşletme',
                            style: AppTypography.h6.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cart.items.length} ürün',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₺${totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cart items preview
                Column(
                  children: cart.items.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.productName}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₺${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                if (cart.items.length > 3) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${cart.items.length - 3} ürün daha',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToBusinessCart(businessId),
                    icon: Icon(Icons.shopping_cart_rounded, size: 20),
                    label: const Text('Sepete Git'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBusinessCart(String businessId) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          businessId: businessId,
          userId: widget.userId,
        ),
      ),
    );
  }
}
