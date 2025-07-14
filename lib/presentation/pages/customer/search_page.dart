import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/business.dart';
import '../../../data/models/category.dart';
import '../../widgets/shared/empty_state.dart';
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Arama'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Arama ve filtreler
          _buildSearchAndFilters(),
          
          // Sonuçlar
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Arama çubuğu
          TextField(
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
              fillColor: AppColors.greyLighter,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filtreler
          Row(
            children: [
              // Kategori filtresi
              Expanded(
                child: _buildFilterDropdown(
                  title: 'Kategori',
                  value: _selectedCategory,
                  items: ['Tümü', ...widget.categories.map((c) => c.categoryName)],
                  onChanged: _onCategoryChanged,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Sıralama
              Expanded(
                child: _buildFilterDropdown(
                  title: 'Sırala',
                  value: _selectedSortBy,
                  items: ['İsim', 'Tür', 'Durum'],
                  onChanged: _onSortChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String title,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.greyLighter,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textLight),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_filteredBusinesses.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Sonuç bulunamadı',
        message: 'Arama kriterlerinize uygun işletme bulunamadı',
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: business.logoUrl != null
                    ? Image.network(
                        business.logoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: AppColors.greyLighter,
                            child: const Icon(
                              Icons.store,
                              color: AppColors.greyLight,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.greyLighter,
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                        ),
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
                    Text(
                      business.businessType,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      business.businessDescription,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
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
              
              // Durum
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: business.isOpen
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      business.isOpen ? 'Açık' : 'Kapalı',
                      style: AppTypography.caption.copyWith(
                        color: business.isOpen
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 