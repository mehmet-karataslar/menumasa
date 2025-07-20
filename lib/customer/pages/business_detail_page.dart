import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/firestore_service.dart';
import '../../data/models/business.dart';
import '../../data/models/user.dart' as app_user;
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import 'menu_page.dart';

class BusinessDetailPage extends StatefulWidget {
  final Business business;
  final app_user.CustomerData? customerData;

  const BusinessDetailPage({
    super.key,
    required this.business,
    this.customerData,
  });

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ürünleri yükle
      await _loadProducts();

      // Kategorileri yükle
      await _loadCategories();

    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _firestoreService.getProducts(
        businessId: widget.business.id,
      );
      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Ürünler yüklenirken hata: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _firestoreService.getCategories(
        businessId: widget.business.id,
      );
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Kategoriler yüklenirken hata: $e');
    }
  }

  void _checkFavoriteStatus() {
    if (widget.customerData?.favorites != null) {
      setState(() {
        _isFavorite = widget.customerData!.favorites
            .any((f) => f.businessId == widget.business.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App bar
          _buildSliverAppBar(),
          
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Genel Bilgiler'),
                  Tab(text: 'Menü'),
                  Tab(text: 'Galeri'),
                ],
              ),
            ),
          ),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildMenuTab(),
                _buildGalleryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuPage(
                businessId: widget.business.id,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.menu_book),
        label: const Text('Menüyü Görüntüle'),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.business.businessName,
          style: AppTypography.h5.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // İşletme resmi
            if (widget.business.logoUrl != null)
              Image.network(
                widget.business.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.greyLighter,
                    child: const Icon(
                      Icons.store,
                      color: AppColors.greyLight,
                      size: 80,
                    ),
                  );
                },
              )
            else
              Container(
                color: AppColors.greyLighter,
                child: const Icon(
                  Icons.store,
                  color: AppColors.greyLight,
                  size: 80,
                ),
              ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Paylaş
          },
          icon: const Icon(Icons.share),
        ),
        IconButton(
          onPressed: () {
            // Favori toggle
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? AppColors.error : AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İşletme bilgileri kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İşletme Bilgileri',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Açıklama
                  if (widget.business.businessDescription.isNotEmpty) ...[
                    Text(
                      widget.business.businessDescription,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // İşletme türü
                  Row(
                    children: [
                      const Icon(Icons.category, size: 20, color: AppColors.textLight),
                      const SizedBox(width: 8),
                      Text(
                        'Tür: ${widget.business.businessType}',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Adres
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: AppColors.textLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.business.businessAddress,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Telefon
                  if (widget.business.phone != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Text(
                          widget.business.phone!,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Durum
                  Row(
                    children: [
                      Icon(
                        Icons.access_time, 
                        size: 20, 
                        color: widget.business.isOpen ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.business.isOpen ? 'Açık' : 'Kapalı',
                        style: AppTypography.bodyMedium.copyWith(
                          color: widget.business.isOpen ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Özellikler kartı
          if (widget.business.settings != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Özellikler',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildFeatureChips(widget.business.settings!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: ErrorMessage(message: _errorMessage!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategoriler
          if (_categories.isNotEmpty) ...[
            Text(
              'Kategoriler (${_categories.length})',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(category.name),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      labelStyle: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Ürünler
          Text(
            'Ürünler (${_products.length})',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_products.isEmpty)
            const EmptyState(
              icon: Icons.restaurant_menu,
              title: 'Henüz ürün yok',
              message: 'Bu işletme henüz ürün eklenmemiş',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _products.take(6).length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.greyLighter,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: product.images != null && product.images!.isNotEmpty
                              ? Image.network(
                                  product.images!.first.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.restaurant,
                                      color: AppColors.greyLight,
                                      size: 40,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.restaurant,
                                  color: AppColors.greyLight,
                                  size: 40,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${product.price.toStringAsFixed(2)} ₺',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          if (_products.length > 6) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuPage(
                        businessId: widget.business.id,
                      ),
                    ),
                  );
                },
                child: const Text('Tüm ürünleri görüntüle'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    return const Center(
      child: EmptyState(
        icon: Icons.photo_library,
        title: 'Galeri',
        message: 'Henüz fotoğraf eklenmemiş',
      ),
    );
  }

  List<Widget> _buildFeatureChips(BusinessSettings settings) {
    List<Widget> chips = [];
    
    if (settings.enableReviews) {
      chips.add(Chip(
        label: Text('Değerlendirmeler'),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.primary),
      ));
    }
    
    if (settings.enableLoyaltyProgram) {
      chips.add(Chip(
        label: Text('Sadakat Programı'),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.primary),
      ));
    }
    
    if (settings.autoAcceptOrders) {
      chips.add(Chip(
        label: Text('Otomatik Onay'),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.primary),
      ));
    }
    
    if (settings.enableNotifications) {
      chips.add(Chip(
        label: Text('Bildirimler'),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.primary),
      ));
    }
    
    return chips;
  }
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 