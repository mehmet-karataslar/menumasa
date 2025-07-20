import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
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

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Business> _filteredBusinesses = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _selectedSortBy = 'İsim';

  @override
  void initState() {
    super.initState();
    _filteredBusinesses = widget.businesses;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _filterBusinesses();
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
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterBusinesses();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _selectedSortBy = sortBy;
    });
    _sortBusinesses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Arama'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Arama çubuğu
          _buildSearchBar(),
          
          // Filtreler
          _buildFilters(),
          
          // Sonuçlar
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'İşletme veya yemek ara...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear, color: AppColors.textLight),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final allCategories = ['Tümü', ...widget.categories.map((c) => c.name)];
    final sortOptions = ['İsim', 'Tür', 'Durum'];

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          // Kategori filtreleri
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
          
          // Sıralama
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Sırala: '),
                DropdownButton<String>(
                  value: _selectedSortBy,
                  onChanged: (value) {
                    if (value != null) {
                      _onSortChanged(value);
                    }
                  },
                  items: sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Text(
                  '${_filteredBusinesses.length} sonuç',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_filteredBusinesses.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Sonuç bulunamadı',
        message: _searchQuery.isEmpty 
            ? 'Arama yapmak için bir terim girin'
            : 'Arama kriterlerinize uygun işletme bulunamadı',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBusinesses.length,
      itemBuilder: (context, index) {
        return _buildBusinessCard(_filteredBusinesses[index]);
      },
    );
  }

  Widget _buildBusinessCard(Business business) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessDetailPage(
                business: business,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // İşletme resmi
              if (business.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    business.logoUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.greyLighter,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                          size: 30,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.greyLighter,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.greyLight,
                    size: 30,
                  ),
                ),
              
              const SizedBox(width: 16),
              
              // İşletme bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Durum ve adres
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: business.isOpen ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          business.isOpen ? 'Açık' : 'Kapalı',
                          style: AppTypography.caption.copyWith(
                            color: business.isOpen ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                      ],
                    ),
                  ],
                ),
              ),
              
              // İleri ok
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 