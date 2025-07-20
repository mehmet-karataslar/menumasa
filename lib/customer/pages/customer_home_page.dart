import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/models/user.dart' as app_user;
import '../../business/models/business.dart';
import '../../business/models/category.dart' as app_category;
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import 'business_detail_page.dart';
import 'search_page.dart';

class CustomerHomePage extends StatefulWidget {
  final String userId;

  const CustomerHomePage({super.key, required this.userId});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  app_user.User? _user;
  app_user.CustomerData? _customerData;
  List<Business> _businesses = [];
  List<app_category.Category> _categories = [];
  List<Business> _filteredBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  String _userLocation = 'İstanbul'; // Varsayılan konum

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
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
      // Kullanıcı bilgilerini yükle
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        setState(() {
          _user = user;
        });
      }

      // Müşteri verilerini yükle
      await _loadCustomerData();

      // İşletmeleri yükle
      await _loadBusinesses();

      // Kategorileri yükle
      await _loadCategories();

      // Konum bilgisini al (şimdilik varsayılan)
      await _getUserLocation();

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

  Future<void> _loadCustomerData() async {
    try {
      final customerData = await _firestoreService.getCustomerData(widget.userId);
      setState(() {
        _customerData = customerData;
      });
    } catch (e) {
      print('Müşteri verileri yüklenirken hata: $e');
    }
  }

  Future<void> _loadBusinesses() async {
    try {
      final businesses = await _firestoreService.getBusinesses();
      setState(() {
        _businesses = businesses.where((b) => b.isActive).toList();
        _filteredBusinesses = _businesses;
      });
    } catch (e) {
      print('İşletmeler yüklenirken hata: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _firestoreService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Kategoriler yüklenirken hata: $e');
    }
  }

  Future<void> _getUserLocation() async {
    // TODO: Gerçek konum servisi entegrasyonu
    // Şimdilik varsayılan konum kullanıyoruz
    setState(() {
      _userLocation = 'İstanbul';
    });
  }

  void _filterBusinesses() {
    setState(() {
      _filteredBusinesses = _businesses.where((business) {
        // Kategori filtresi
        bool categoryMatch = _selectedCategory == 'Tümü' ||
            business.businessType == _selectedCategory;

        // Arama filtresi
        bool searchMatch = _searchQuery.isEmpty ||
            business.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            business.businessDescription.toLowerCase().contains(_searchQuery.toLowerCase());

        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterBusinesses();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterBusinesses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ana Sayfa'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: ErrorMessage(message: _errorMessage ?? 'Kullanıcı bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildFavoritesTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş geldin, ${_user!.name}',
            style: AppTypography.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _userLocation,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchPage(
                  businesses: _businesses,
                  categories: _categories,
                ),
              ),
            );
          },
          icon: const Icon(Icons.search),
        ),
        IconButton(
          onPressed: () async {
            await _authService.signOut();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(icon: Icon(Icons.home), text: 'Ana Sayfa'),
          Tab(icon: Icon(Icons.favorite), text: 'Favoriler'),
          Tab(icon: Icon(Icons.person), text: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama çubuğu
          _buildSearchBar(),
          
          const SizedBox(height: 16),
          
          // Kategori filtreleri
          _buildCategoryFilters(),
          
          const SizedBox(height: 24),
          
          // İşletme listesi
          _buildBusinessList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'İşletme veya yemek ara...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final allCategories = ['Tümü', ..._categories.map((c) => c.name)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategoriler',
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
              final isSelected = category == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _onCategoryChanged(category);
                    }
                  },
                  backgroundColor: AppColors.greyLighter,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yakındaki İşletmeler',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_filteredBusinesses.length} işletme',
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredBusinesses.isEmpty)
          const EmptyState(
            icon: Icons.store,
            title: 'İşletme bulunamadı',
            message: 'Arama kriterlerinize uygun işletme bulunamadı',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredBusinesses.length,
            itemBuilder: (context, index) {
              return _buildBusinessCard(_filteredBusinesses[index]);
            },
          ),
      ],
    );
  }

  Widget _buildBusinessCard(Business business) {
    final isFavorite = _customerData?.favorites
        .any((f) => f.businessId == business.id) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessDetailPage(
                business: business,
                customerData: _customerData,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İşletme resmi
            if (business.logoUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  business.logoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: AppColors.greyLighter,
                      child: const Icon(
                        Icons.store,
                        color: AppColors.greyLight,
                        size: 60,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.greyLighter,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.store,
                  color: AppColors.greyLight,
                  size: 60,
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İşletme adı ve favori butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          business.businessName,
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _toggleFavorite(business);
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.error : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  
                  // İşletme türü
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      business.businessType,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Açıklama
                  Text(
                    business.businessDescription,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Alt bilgiler
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business.businessAddress,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        business.isOpen ? 'Açık' : 'Kapalı',
                        style: AppTypography.caption.copyWith(
                          color: business.isOpen ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildFavoritesTab() {
    final favorites = _customerData?.favorites ?? [];
    
    return favorites.isEmpty
        ? const EmptyState(
            icon: Icons.favorite_border,
            title: 'Henüz favori işletmeniz yok',
            message: 'Favori işletmelerinizi ekleyerek hızlı erişim sağlayın',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              final business = _businesses.firstWhere(
                (b) => b.id == favorite.businessId,
                orElse: () => Business(
                  id: favorite.businessId,
                  ownerId: '',
                  businessName: favorite.businessName ?? '',
                  businessDescription: '',
                  businessType: 'Restoran',
                  businessAddress: '',
                  address: Address(
                    street: '',
                    city: '',
                    district: '',
                    postalCode: '',
                    coordinates: null,
                  ),
                  contactInfo: ContactInfo(
                    phone: '',
                    email: '',
                  ),
                  menuSettings: MenuSettings(
                    theme: 'light',
                    primaryColor: '#2C1810',
                    fontFamily: 'Poppins',
                    fontSize: 16.0,
                    imageSize: 120.0,
                    showCategories: true,
                    showRatings: false,
                    layoutStyle: 'card',
                    showNutritionInfo: false,
                    showBadges: true,
                    showAvailability: true,
                  ),
                  settings: BusinessSettings.defaultRestaurant(),
                  stats: BusinessStats.empty(),
                  isActive: false,
                  isOpen: false,
                  isApproved: false,
                  status: BusinessStatus.pending,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              
              return _buildBusinessCard(business);
            },
          );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profil kartı
          _buildProfileCard(),
          
          const SizedBox(height: 24),
          
          // Hızlı istatistikler
          _buildQuickStats(),
          
          const SizedBox(height: 24),
          
          // Menü seçenekleri
          _buildMenuOptions(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                style: AppTypography.h3.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user!.email,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = _customerData?.stats ?? app_user.CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      favoriteBusinessCount: 0,
      totalVisits: 0,
      categoryPreferences: {},
      businessSpending: {},
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Toplam Sipariş',
            value: stats.totalOrders.toString(),
            icon: Icons.shopping_bag,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Toplam Harcama',
            value: '${stats.totalSpent.toStringAsFixed(2)} ₺',
            icon: Icons.payment,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Favori İşletmeler',
            value: stats.favoriteBusinessCount.toString(),
            icon: Icons.favorite,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.primary),
            title: const Text('Detaylı Dashboard'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessDetailPage(
                    business: _businesses.firstWhere(
                      (b) => b.id == (_customerData?.recentBusinessIds.isNotEmpty == true ? _customerData!.recentBusinessIds.first : ''),
                      orElse: () => _createDefaultBusiness(),
                    ),
                    customerData: _customerData,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.info),
            title: const Text('Sipariş Geçmişi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Sipariş geçmişi sayfası
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.warning),
            title: const Text('Ayarlar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Ayarlar sayfası
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Business business) async {
    try {
      final isFavorite = _customerData?.favorites
          .any((f) => f.businessId == business.id) ?? false;

      if (isFavorite) {
        // Favorilerden çıkar
        final updatedFavorites = _customerData!.favorites
            .where((f) => f.businessId != business.id)
            .toList();

        final updatedCustomerData = _customerData!.copyWith(
          favorites: updatedFavorites,
        );

        await _firestoreService.updateCustomerData(
          widget.userId,
          updatedCustomerData.toMap(),
        );

        setState(() {
          _customerData = updatedCustomerData;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorilerden çıkarıldı'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } else {
        // Favorilere ekle
        final newFavorite = app_user.CustomerFavorite(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          businessId: business.id,
          customerId: _user!.id,
          createdAt: DateTime.now(),
          businessName: business.businessName,
          businessType: business.businessType,
          businessLogo: business.logoUrl,
          addedDate: DateTime.now(),
          visitCount: 0,
          totalSpent: 0.0,
        );

        await _firestoreService.addCustomerFavorite(
          widget.userId,
          newFavorite,
        );

        // Müşteri verilerini yeniden yükle
        await _loadCustomerData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorilere eklendi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Business _createDefaultBusiness() {
    return Business(
      id: '',
      ownerId: '',
      businessName: 'Bilinmeyen İşletme',
      businessDescription: 'Açıklama bulunamadı',
      businessType: 'Restaurant',
      businessAddress: 'Adres bulunamadı',
      address: Address(
        city: '',
        district: '',
        street: '',
        postalCode: '',
      ),
      contactInfo: ContactInfo(
        phone: '',
        email: '',
        website: '',
      ),
              menuSettings: MenuSettings.defaultRestaurant(),
        settings: BusinessSettings.defaultRestaurant(),
        stats: BusinessStats.empty(),
      isActive: true,
      isOpen: false,
      isApproved: false,
      status: BusinessStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 
