import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../qr_menu/controllers/qr_menu_controller.dart';
import '../qr_menu/widgets/qr_menu_loading.dart';
import '../qr_menu/widgets/qr_menu_error.dart';
import '../qr_menu/widgets/qr_menu_dialogs.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/web_safe_image.dart';
import '../../../core/constants/app_typography.dart';
import '../../../customer/widgets/filter_bottom_sheet.dart';
import '../../../business/models/product.dart';

/// Refactored Universal QR Menu Page using modular architecture
class UniversalQRMenuPage extends StatefulWidget {
  const UniversalQRMenuPage({super.key});

  @override
  State<UniversalQRMenuPage> createState() => _UniversalQRMenuPageState();
}

class _UniversalQRMenuPageState extends State<UniversalQRMenuPage>
    with TickerProviderStateMixin {
  late QRMenuController _controller;
  late ScrollController _scrollController;
  late ScrollController _categoryScrollController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Parse URL and load data when context is available
    if (_controller.state.businessId == null) {
      _controller.parseUrlAndLoadData(context);
    }
  }

  void _initControllers() {
    _controller = QRMenuController();
    _controller.initialize(this);

    _scrollController = ScrollController();
    _categoryScrollController = ScrollController();

    _scrollController.addListener(() {
      _controller.updateHeaderOpacity(_scrollController.offset);
    });

    // Listen to controller changes
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final state = _controller.state;

    if (state.isLoading) {
      return const QRMenuLoading();
    }

    if (state.hasError) {
      return QRMenuError(
        errorMessage: state.errorMessage,
        onRetry: () => _controller.parseUrlAndLoadData(context),
      );
    }

    return _buildMenuContent();
  }

  Widget _buildMenuContent() {
    return AnimatedBuilder(
      animation: _controller.fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Opacity(
          opacity: _controller.fadeAnimation?.value ?? 1.0,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(),
              if (_controller.state.showSearchBar) _buildSearchSection(),
              _buildCategorySection(),
              _buildProductSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader() {
    final state = _controller.state;

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.secondary.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        // Business Avatar
                        Hero(
                          tag: 'business_avatar_${state.businessId}',
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.white,
                                  AppColors.white.withOpacity(0.95),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: state.business?.logoUrl != null
                                  ? WebSafeImage(
                                      imageUrl: state.business!.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          _buildBusinessIcon(),
                                    )
                                  : _buildBusinessIcon(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Business Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.business?.businessName ?? 'Restoran',
                                style: AppTypography.h4.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  state.business?.businessType ?? 'Restoran',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: (state.business?.isOpen == true
                                              ? AppColors.success
                                              : AppColors.error)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: state.business?.isOpen == true
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    state.business?.isOpen == true
                                        ? 'Açık'
                                        : 'Kapalı',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildHeaderButton(
          icon: state.showSearchBar
              ? Icons.search_off_rounded
              : Icons.search_rounded,
          onPressed: _controller.toggleSearchBar,
        ),
        _buildHeaderButton(
          icon: Icons.tune_rounded,
          onPressed: _showFilterBottomSheet,
        ),
        _buildWaiterCallButton(),
        _buildCartHeaderButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBusinessIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        size: 35,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiterCallButton() {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _onWaiterCallPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.success.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.room_service_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartHeaderButton() {
    final state = _controller.state;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _onCartPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
                if (state.cartItemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        state.cartItemCount > 9
                            ? '9+'
                            : state.cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _controller.slideAnimation ??
            const AlwaysStoppedAnimation(Offset.zero),
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.greyLighter.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.greyLight.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextField(
              onChanged: _controller.onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ürün, kategori ara...',
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                suffixIcon: _controller.state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => _controller.onSearchChanged(''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final state = _controller.state;

    if (state.categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _controller.slideAnimation ??
            const AlwaysStoppedAnimation(Offset.zero),
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategoriler',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = state.selectedCategoryId == 'all';
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _controller.onCategorySelected('all'),
                          icon: Icon(Icons.apps_rounded),
                          label: Text('Tümü'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.white,
                            foregroundColor: isSelected
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final category = state.categories[index - 1];
                    final isSelected =
                        state.selectedCategoryId == category.categoryId;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                        onPressed: () =>
                            _controller.onCategorySelected(category.categoryId),
                        child: Text(category.name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? AppColors.primary : AppColors.white,
                          foregroundColor:
                              isSelected ? AppColors.white : AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    final state = _controller.state;

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _controller.slideAnimation ??
            const AlwaysStoppedAnimation(Offset.zero),
        child: Container(
          color: AppColors.background,
          child: state.filteredProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Henüz ürün bulunmuyor',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _controller.parseUrlAndLoadData(context),
                  color: AppColors.primary,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: state.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = state.filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isFavorite =
        _controller.state.favoriteProductIds.contains(product.productId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.greyLighter,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: product.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: WebSafeImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorWidget: (context, url, error) => Center(
                                  child: Icon(Icons.restaurant,
                                      size: 40, color: AppColors.greyDark)),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.restaurant,
                                size: 40, color: AppColors.greyDark)),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _toggleFavorite(product),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.accent
                                : AppColors.greyDark,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Product badges (if any)
                  if (product.tags.contains('popular'))
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Popüler',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.description.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      product.description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(0)} ₺',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.currentPrice != product.price)
                            Text(
                              '${product.currentPrice.toStringAsFixed(0)} ₺',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_controller.state.isGuestMode)
                            ElevatedButton(
                              onPressed: () =>
                                  _showGuestAddToCartDialog(product),
                              child: Icon(Icons.info_outline, size: 16),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: AppColors.white,
                                minimumSize: Size(32, 32),
                                padding: EdgeInsets.zero,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _addToCart(product),
                              child: Icon(Icons.add, size: 16),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                minimumSize: Size(32, 32),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _controller.state.filters,
        onFiltersChanged: _controller.onFiltersChanged,
      ),
    );
  }

  void _onCartPressed() {
    if (_controller.state.isGuestMode) {
      _showGuestCartDialog();
    } else {
      // Navigate to cart
      Navigator.pushNamed(
        context,
        '/customer/cart',
        arguments: {
          'businessId': _controller.state.businessId,
        },
      );
    }
  }

  void _onWaiterCallPressed() {
    if (_controller.state.isGuestMode) {
      QRMenuDialogs.showGuestWaiterDialog(context);
    } else {
      // Authenticated user can call waiter directly
      _showRegisteredWaiterDialog();
    }
  }

  void _showRegisteredWaiterDialog() {
    // For registered users, show direct waiter call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _controller.state.tableNumber != null
                    ? 'Masa ${_controller.state.tableNumber} için garson çağrısı gönderildi!'
                    : 'Garson çağrısı gönderildi!',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showGuestCartDialog() {
    QRMenuDialogs.showGuestCartDialog(context);
  }

  void _toggleFavorite(Product product) {
    if (_controller.state.isGuestMode) {
      QRMenuDialogs.showGuestFavoriteDialog(context, product.name);
    } else {
      // TODO: Implement favorite toggle for registered users
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favori işlemi yakında eklenecek'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _showProductDetail(Product product) {
    // Navigate to product detail page
    Navigator.pushNamed(
      context,
      '/customer/product-detail',
      arguments: {
        'product': product,
        'businessId': _controller.state.businessId,
      },
    );
  }

  void _showGuestAddToCartDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Misafir Kullanıcı'),
          ],
        ),
        content: Text(
          'Misafir kullanıcılar sepete ürün ekleyemez. Sipariş vermek için sisteme kayıt olmanız gerekmektedir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register',
                  arguments: {'userType': 'customer'});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Kayıt Ol',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    try {
      await _controller.addToCart(product);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('${product.name} sepete eklendi')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Sepete Git',
              textColor: AppColors.white,
              onPressed: _onCartPressed,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepete eklenirken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
