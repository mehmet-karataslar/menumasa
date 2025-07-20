import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/data_service.dart';
import '../../../data/models/discount.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';

class DiscountManagementPage extends StatefulWidget {
  final String businessId;

  const DiscountManagementPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<DiscountManagementPage> createState() => _DiscountManagementPageState();
}

class _DiscountManagementPageState extends State<DiscountManagementPage> {
  final DataService _dataService = DataService();

  List<Discount> _discounts = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final futures = await Future.wait([
        _dataService.getDiscountsByBusinessId(widget.businessId),
        _dataService.getCategories(businessId: widget.businessId),
        _dataService.getProducts(businessId: widget.businessId),
      ]);

      setState(() {
        _discounts = futures[0] as List<Discount>;
        _categories = futures[1] as List<Category>;
        _products = futures[2] as List<Product>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: _isLoading ? const LoadingIndicator() : _buildContent(),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'İndirim Yönetimi',
        style: AppTypography.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
    );
  }

  Widget _buildContent() {
    if (_discounts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: AppDimensions.paddingM,
      itemCount: _discounts.length,
      itemBuilder: (context, index) {
        final discount = _discounts[index];
        return _buildDiscountCard(discount);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: 16),
          Text('Henüz İndirim Yok', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            'Yeni indirim ekleyerek başlayabilirsiniz.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(Discount discount) {
    final isActive = discount.isCurrentlyActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.success : AppColors.lightGrey,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(discount.name, style: AppTypography.h5),
                        const SizedBox(height: 4),
                        Text(
                          discount.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Pasif',
                      style: AppTypography.bodySmall.copyWith(
                        color: isActive
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Discount details
              Row(
                children: [
                  _buildDetailChip(
                    icon: Icons.percent,
                    label:
                        '${discount.value}${discount.type == DiscountType.percentage ? '%' : '₺'}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    icon: discount.targetProductIds.isNotEmpty
                        ? Icons.restaurant_menu
                        : Icons.category,
                    label: _getDiscountTargetLabel(discount),
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date and time info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(discount.startDate)} - ${_formatDate(discount.endDate)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Time rules
                  if (discount.timeRules.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getTimeRulesText(discount.timeRules),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.all_inclusive,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tüm gün aktif',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editDiscount(discount),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteDiscount(discount),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Sil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDiscountTargetLabel(Discount discount) {
    if (discount.targetProductIds.isNotEmpty) {
      return '${discount.targetProductIds.length} Ürün';
    } else if (discount.targetCategoryIds.isNotEmpty) {
      return '${discount.targetCategoryIds.length} Kategori';
    } else {
      return 'Tüm Menü';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getTimeRulesText(List<TimeRule> timeRules) {
    if (timeRules.isEmpty) return 'Tüm gün aktif';

    if (timeRules.length == 1) {
      final rule = timeRules.first;
      return '${rule.dayNamesString} ${rule.timeRangeString}';
    } else {
      return '${timeRules.length} farklı saat kuralı';
    }
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _addDiscount,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }

  void _addDiscount() {
    _showDiscountDialog(null);
  }

  void _editDiscount(Discount discount) {
    _showDiscountDialog(discount);
  }

  void _showDiscountDialog(Discount? discount) {
    showDialog(
      context: context,
      builder: (context) => _DiscountDialog(
        discount: discount,
        businessId: widget.businessId,
        categories: _categories,
        products: _products,
        onSave: _saveDiscount,
      ),
    );
  }

  Future<void> _saveDiscount(Discount discount) async {
    try {
      await _dataService.saveDiscount(discount);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${discount.name} kaydedildi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDiscount(Discount discount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İndirim Sil'),
        content: Text(
          '${discount.name} indirimini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dataService.deleteDiscount(discount.discountId);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${discount.name} silindi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _DiscountDialog extends StatefulWidget {
  final Discount? discount;
  final String businessId;
  final List<Category> categories;
  final List<Product> products;
  final Function(Discount) onSave;

  const _DiscountDialog({
    Key? key,
    this.discount,
    required this.businessId,
    required this.categories,
    required this.products,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();

  DiscountType _selectedType = DiscountType.percentage;
  String _selectedTarget = 'all'; // 'all', 'categories', 'products'
  List<String> _selectedCategories = [];
  List<String> _selectedProducts = [];

  // Date and time fields
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  List<TimeRule> _timeRules = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final discount = widget.discount;
    if (discount != null) {
      _nameController.text = discount.name;
      _descriptionController.text = discount.description;
      _valueController.text = discount.value.toString();
      _selectedType = discount.type;
      _startDate = discount.startDate;
      _endDate = discount.endDate;
      _timeRules = List.from(discount.timeRules);

      if (discount.targetProductIds.isNotEmpty) {
        _selectedTarget = 'products';
        _selectedProducts = List.from(discount.targetProductIds);
      } else if (discount.targetCategoryIds.isNotEmpty) {
        _selectedTarget = 'categories';
        _selectedCategories = List.from(discount.targetCategoryIds);
      } else {
        _selectedTarget = 'all';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.discount == null ? 'Yeni İndirim' : 'İndirim Düzenle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'İndirim Adı',
                    hintText: 'Örn: Hafta Sonu Kampanyası',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İndirim adı gereklidir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'İndirim detayları',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Type and Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<DiscountType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'İndirim Türü',
                      ),
                      items: DiscountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == DiscountType.percentage
                                ? 'Yüzde (%)'
                                : 'Sabit (₺)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        labelText: 'İndirim Değeri',
                        suffixText: _selectedType == DiscountType.percentage
                            ? '%'
                            : '₺',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'İndirim değeri gereklidir';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Geçerli bir değer giriniz';
                        }
                        if (_selectedType == DiscountType.percentage &&
                            number > 100) {
                          return 'Yüzde değeri 100\'den büyük olamaz';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İndirim Tarihleri:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Başlangıç Tarihi:'),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                onPressed: () => _selectDate(context, true),
                                child: Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bitiş Tarihi:'),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                onPressed: () => _selectDate(context, false),
                                child: Text(
                                  '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time Rules Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Saat Kuralları:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addTimeRule,
                          icon: const Icon(Icons.add),
                          label: const Text('Ekle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTimeRulesList(),
                  ],
                ),
                const SizedBox(height: 16),

                // Target Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İndirim Hedefi:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Tüm Menü'),
                      value: 'all',
                      groupValue: _selectedTarget,
                      onChanged: (value) {
                        setState(() {
                          _selectedTarget = value!;
                          _selectedCategories.clear();
                          _selectedProducts.clear();
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Belirli Kategoriler'),
                      value: 'categories',
                      groupValue: _selectedTarget,
                      onChanged: (value) {
                        setState(() {
                          _selectedTarget = value!;
                          _selectedProducts.clear();
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Belirli Ürünler'),
                      value: 'products',
                      groupValue: _selectedTarget,
                      onChanged: (value) {
                        setState(() {
                          _selectedTarget = value!;
                          _selectedCategories.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Selection
                if (_selectedTarget == 'categories') ...[
                  Text(
                    'Kategoriler (${widget.categories.length}):',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  widget.categories.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Henüz kategori bulunmamaktadır.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          children: widget.categories.map((category) {
                            final isSelected = _selectedCategories.contains(
                              category.categoryId,
                            );
                            return FilterChip(
                              label: Text(category.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(
                                      category.categoryId,
                                    );
                                  } else {
                                    _selectedCategories.remove(
                                      category.categoryId,
                                    );
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 16),
                ],

                // Product Selection
                if (_selectedTarget == 'products') ...[
                  Text(
                    'Ürünler (${widget.products.length}):',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightGrey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.products.isEmpty
                        ? const Center(
                            child: Text(
                              'Henüz ürün bulunmamaktadır.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: widget.products.length,
                            itemBuilder: (context, index) {
                              final product = widget.products[index];
                              final isSelected = _selectedProducts.contains(
                                product.productId,
                              );
                              return CheckboxListTile(
                                title: Text(product.name),
                                subtitle: Text(
                                  '${product.price.toStringAsFixed(2)} ₺',
                                ),
                                value: isSelected,
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedProducts.add(product.productId);
                                    } else {
                                      _selectedProducts.remove(
                                        product.productId,
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(onPressed: _saveDiscount, child: const Text('Kaydet')),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  void _addTimeRule() {
    showDialog(
      context: context,
      builder: (context) => _TimeRuleDialog(
        onSave: (timeRule) {
          setState(() {
            _timeRules.add(timeRule);
          });
        },
      ),
    );
  }

  Widget _buildTimeRulesList() {
    if (_timeRules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Henüz saat kuralı eklenmedi.\nTüm gün aktif olacak.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _timeRules.length,
        itemBuilder: (context, index) {
          final rule = _timeRules[index];
          return ListTile(
            title: Text(rule.name),
            subtitle: Text(
              '${rule.dayNamesString} • ${rule.timeRangeString}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _timeRules.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  void _saveDiscount() {
    if (_formKey.currentState!.validate()) {
      final discount = Discount(
        discountId:
            widget.discount?.discountId ??
            'discount-${DateTime.now().millisecondsSinceEpoch}',
        businessId: widget.businessId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        value: double.parse(_valueController.text.trim()),
        startDate: _startDate,
        endDate: _endDate,
        targetProductIds: _selectedTarget == 'products'
            ? _selectedProducts
            : [],
        targetCategoryIds: _selectedTarget == 'categories'
            ? _selectedCategories
            : [],
        timeRules: _timeRules,
        minOrderAmount: 0,
        maxDiscountAmount: 0,
        usageLimit: 0,
        usageCount: widget.discount?.usageCount ?? 0,
        isActive: true,
        combineWithOtherDiscounts: false,
        createdAt: widget.discount?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(discount);
      Navigator.pop(context);
    }
  }
}

class _TimeRuleDialog extends StatefulWidget {
  final Function(TimeRule) onSave;

  const _TimeRuleDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  State<_TimeRuleDialog> createState() => _TimeRuleDialogState();
}

class _TimeRuleDialogState extends State<_TimeRuleDialog> {
  final _nameController = TextEditingController();
  final List<bool> _selectedDays = List.filled(7, false);
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  final List<String> _dayNames = [
    'Pazar',
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Saat Kuralı Ekle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Kural Adı',
                  hintText: 'Örn: Sabah İndirimi',
                ),
              ),
              const SizedBox(height: 16),

              // Days selection
              const Text(
                'Geçerli Günler:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: List.generate(7, (index) {
                    return CheckboxListTile(
                      title: Text(_dayNames[index]),
                      value: _selectedDays[index],
                      onChanged: (value) {
                        setState(() {
                          _selectedDays[index] = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Quick day selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _selectAllDays,
                    child: const Text('Tümü'),
                  ),
                  TextButton(
                    onPressed: _selectWeekdays,
                    child: const Text('Hafta İçi'),
                  ),
                  TextButton(
                    onPressed: _selectWeekends,
                    child: const Text('Hafta Sonu'),
                  ),
                  TextButton(
                    onPressed: _clearDays,
                    child: const Text('Temizle'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Başlangıç Saati:'),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text(_formatTime(_startTime)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bitiş Saati:'),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text(_formatTime(_endTime)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Önizleme:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPreviewText(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(onPressed: _saveTimeRule, child: const Text('Kaydet')),
      ],
    );
  }

  void _selectAllDays() {
    setState(() {
      for (int i = 0; i < 7; i++) {
        _selectedDays[i] = true;
      }
    });
  }

  void _selectWeekdays() {
    setState(() {
      for (int i = 0; i < 7; i++) {
        _selectedDays[i] = i >= 1 && i <= 5; // Monday to Friday
      }
    });
  }

  void _selectWeekends() {
    setState(() {
      for (int i = 0; i < 7; i++) {
        _selectedDays[i] = i == 0 || i == 6; // Sunday and Saturday
      }
    });
  }

  void _clearDays() {
    setState(() {
      for (int i = 0; i < 7; i++) {
        _selectedDays[i] = false;
      }
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getPreviewText() {
    if (_nameController.text.isEmpty) {
      return 'Kural adı giriniz';
    }

    final selectedDayNames = <String>[];
    for (int i = 0; i < 7; i++) {
      if (_selectedDays[i]) {
        selectedDayNames.add(_dayNames[i]);
      }
    }

    if (selectedDayNames.isEmpty) {
      return 'Gün seçiniz';
    }

    return '${_nameController.text}\n${selectedDayNames.join(', ')}\n${_formatTime(_startTime)} - ${_formatTime(_endTime)}';
  }

  void _saveTimeRule() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kural adı gereklidir')));
      return;
    }

    final selectedDayIndexes = <int>[];
    for (int i = 0; i < 7; i++) {
      if (_selectedDays[i]) {
        selectedDayIndexes.add(i);
      }
    }

    if (selectedDayIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir gün seçmelisiniz')),
      );
      return;
    }

    // Validate time range
    if (_startTime.hour > _endTime.hour ||
        (_startTime.hour == _endTime.hour &&
            _startTime.minute >= _endTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlangıç saati bitiş saatinden önce olmalıdır'),
        ),
      );
      return;
    }

    // Check for minimum time duration (at least 30 minutes)
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes - startMinutes < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 30 dakika süre belirlemelisiniz')),
      );
      return;
    }

    final timeRule = TimeRule(
      ruleId: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      dayOfWeek: selectedDayIndexes,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      isActive: true,
    );

    widget.onSave(timeRule);
    Navigator.pop(context);
  }
}
