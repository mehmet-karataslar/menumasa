import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/url_service.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import 'business_detail_page.dart';

class SearchPage extends StatefulWidget {
  final List<Business> businesses;
  final List<Category> categories;

  const SearchPage({
    super.key,
    required this.businesses,
    required this.categories,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final UrlService _urlService = UrlService();
  
  List<Business> _filteredBusinesses = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _selectedSortBy = 'İsim';
  bool _isSearchFocused = false;
  bool _showFilters = false;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _searchBarController;
  late AnimationController _filterController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchBarAnimation;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filteredBusinesses = widget.businesses;
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // Initialize animations
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _searchBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    _searchBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchBarController, curve: Curves.easeInOut),
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _searchBarController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _filterBusinesses();
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
    
    if (_isSearchFocused) {
      _searchBarController.forward();
    } else {
      _searchBarController.reverse();
    }
  }

  void _filterBusinesses() {
    setState(() {
      _filteredBusinesses = widget.businesses.where((business) {
        // Kategori filtresi
        bool categoryMatch = _selectedCategory == 'Tümü' ||
            business.businessType == _selectedCategory;

        // Arama filtresi
        bool searchMatch = _searchQuery.isEmpty ||
            business.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            business.businessDescription.toLowerCase().contains(_searchQuery.toLowerCase());

        return categoryMatch && searchMatch;
      }).toList();

      // Sıralama
      _sortBusinesses();
    });
  }

  void _sortBusinesses() {
    switch (_selectedSortBy) {
      case 'İsim':
        _filteredBusinesses.sort((a, b) => a.businessName.compareTo(b.businessName));
        break;
      case 'Tür':
        _filteredBusinesses.sort((a, b) => a.businessType.compareTo(b.businessType));
        break;
      case 'Durum':
        _filteredBusinesses.sort((a, b) {
          if (a.isOpen == b.isOpen) return 0;
          return a.isOpen ? -1 : 1;
        });
        break;
      case 'Popülerlik':
        _filteredBusinesses.sort((a, b) => b.businessName.length.compareTo(a.businessName.length));
        break;
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterBusinesses();
    HapticFeedback.lightImpact();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _selectedSortBy = sortBy;
    });
    _sortBusinesses();
    HapticFeedback.lightImpact();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
    
    HapticFeedback.mediumImpact();
  }

  void _navigateToBusinessDetail(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/search/business/${business.id}?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: '${business.businessName} | MasaMenu');
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BusinessDetailPage(business: business),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'business': business,
            'timestamp': timestamp,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildModernSliverAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildModernSearchSection(),
                    _buildAnimatedFilters(),
                    _buildQuickStats(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: PatternPainter(),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 20,
                left: 72,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keşfet',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.businesses.length} işletme',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
              color: AppColors.white,
            ),
            onPressed: _toggleFilters,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSearchSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _searchBarAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1 + _searchBarAnimation.value * 0.1),
                  blurRadius: 16 + _searchBarAnimation.value * 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'İşletme, yemek veya kategori ara...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: _isSearchFocused ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          // Voice search functionality placeholder
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.mic_rounded, color: AppColors.white),
                                  const SizedBox(width: 12),
                                  Text('Sesli arama özelliği yakında eklenecek!'),
                                ],
                              ),
                              backgroundColor: AppColors.info,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.mic_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.greyLighter.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: AppTypography.bodyMedium,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: _showFilters ? null : 0,
      child: AnimatedBuilder(
        animation: _filterAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + _filterAnimation.value * 0.2,
            child: Opacity(
              opacity: _filterAnimation.value,
              child: _buildFiltersContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersContent() {
    final allCategories = ['Tümü', ...widget.categories.map((c) => c.name)];
    final sortOptions = ['İsim', 'Tür', 'Durum', 'Popülerlik'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories section
          Row(
            children: [
              Icon(Icons.category_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kategoriler',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCategories.map((category) {
              final isSelected = category == _selectedCategory;
              return GestureDetector(
                onTap: () => _onCategoryChanged(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary 
                        : AppColors.greyLighter,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary 
                          : AppColors.greyLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected 
                          ? AppColors.white 
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Sort section
          Row(
            children: [
              Icon(Icons.sort_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sıralama',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greyLighter,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: DropdownButton<String>(
              value: _selectedSortBy,
              onChanged: (value) {
                if (value != null) {
                  _onSortChanged(value);
                }
              },
              items: sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getSortIcon(option),
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSortIcon(String sortBy) {
    switch (sortBy) {
      case 'İsim':
        return Icons.sort_by_alpha_rounded;
      case 'Tür':
        return Icons.category_rounded;
      case 'Durum':
        return Icons.access_time_rounded;
      case 'Popülerlik':
        return Icons.trending_up_rounded;
      default:
        return Icons.sort_rounded;
    }
  }

  Widget _buildQuickStats() {
    final openCount = _filteredBusinesses.where((b) => b.isOpen).length;
    final categoryCount = _filteredBusinesses
        .map((b) => b.businessType)
        .toSet()
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.store_rounded,
              title: 'Toplam',
              value: '${_filteredBusinesses.length}',
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.greyLight,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.access_time_rounded,
              title: 'Açık',
              value: '$openCount',
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.greyLight,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.category_rounded,
              title: 'Kategori',
              value: '$categoryCount',
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_filteredBusinesses.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Sonuç bulunamadı',
          message: _searchQuery.isEmpty 
              ? 'Arama yapmak için bir terim girin'
              : 'Arama kriterlerinize uygun işletme bulunamadı.\nFarklı filtreler deneyebilirsiniz.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _filteredBusinesses.length,
      itemBuilder: (context, index) {
        return _buildModernBusinessCard(_filteredBusinesses[index], index);
      },
    );
  }

  Widget _buildModernBusinessCard(Business business, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToBusinessDetail(business);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Business image with hero animation
                Hero(
                  tag: 'business_${business.id}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: business.logoUrl != null
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primaryLight.withOpacity(0.05),
                              ],
                            ),
                    ),
                    child: business.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              business.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderLogo();
                              },
                            ),
                          )
                        : _buildPlaceholderLogo(),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Business info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business name and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              business.businessName,
                              style: AppTypography.h6.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: business.isOpen 
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: business.isOpen 
                                        ? AppColors.success 
                                        : AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  business.isOpen ? 'Açık' : 'Kapalı',
                                  style: AppTypography.caption.copyWith(
                                    color: business.isOpen 
                                        ? AppColors.success 
                                        : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Business type
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          business.businessType,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        business.businessDescription,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Address with icon
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              business.businessAddress,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Arrow with animation
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Center(
      child: Icon(
        Icons.store_rounded,
        size: 40,
        color: AppColors.primary.withOpacity(0.5),
      ),
    );
  }
}

// Custom painter for background pattern
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 20.0;
    
    // Draw grid pattern
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 