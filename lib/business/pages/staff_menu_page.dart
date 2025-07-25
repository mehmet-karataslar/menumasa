import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';
import '../../business/models/product.dart';
import '../../business/models/category.dart';
import '../../core/services/data_service.dart';
import '../../data/models/order.dart';
import '../../core/services/order_service.dart';
import '../../customer/models/cart.dart';

class StaffMenuPage extends StatefulWidget {
  final Staff currentStaff;
  
  const StaffMenuPage({
    Key? key,
    required this.currentStaff,
  }) : super(key: key);

  @override
  State<StaffMenuPage> createState() => _StaffMenuPageState();
}

class _StaffMenuPageState extends State<StaffMenuPage> {
  final DataService _dataService = DataService();
  final OrderService _orderService = OrderService();
  
  List<Product> _products = [];
  List<Category> _categories = [];
  List<CartItem> _currentOrder = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  String? _error;
  
  // Müşteri bilgileri
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _tableNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // İşletme menüsünü yükle
      final products = await _dataService.getProducts(businessId: widget.currentStaff.businessId);
      final categories = await _dataService.getCategories(businessId: widget.currentStaff.businessId);

      setState(() {
        _products = products;
        _categories = categories;
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menü - Sipariş Oluştur'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          if (_currentOrder.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _showOrderSummary,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_currentOrder.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _currentOrder.isNotEmpty ? _buildOrderSummaryBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Hata: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMenuData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bu işletmede henüz ürün bulunmuyor'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCustomerInfoCard(),
        _buildCategoryTabs(),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Müşteri Bilgileri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Müşteri Adı',
                      hintText: 'Örn: Ahmet Bey',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tableNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Masa No',
                      hintText: 'Örn: 5',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory?.id == category.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.orange[100],
              checkmarkColor: Colors.orange[700],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    final filteredProducts = _selectedCategory != null
        ? _products.where((p) => p.categoryId == _selectedCategory!.id).toList()
        : _products;

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text('Bu kategoride ürün bulunmuyor'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isInCart = _currentOrder.any((item) => item.productId == product.productId);
    final cartItem = _currentOrder.firstWhere(
      (item) => item.productId == product.productId,
      orElse: () => CartItem(
        cartItemId: '',
        productId: product.productId,
        productName: product.name,
        productPrice: product.price,
        quantity: 0,
        productImage: product.imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.grey[200],
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.fastfood, size: 48, color: Colors.grey[400]);
                          },
                        ),
                      )
                    : Icon(Icons.fastfood, size: 48, color: Colors.grey[400]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange[700],
                          ),
                        ),
                        if (isInCart)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cartItem.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }

  Widget _buildOrderSummaryBar() {
    final totalAmount = _currentOrder.fold<double>(
      0,
      (sum, item) => sum + (item.productPrice * item.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentOrder.length} ürün',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '₺${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _sendOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Siparişi Gönder',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _currentOrder.indexWhere((item) => item.productId == product.productId);
      
      if (existingIndex >= 0) {
        _currentOrder[existingIndex] = _currentOrder[existingIndex].copyWith(
          quantity: _currentOrder[existingIndex].quantity + 1,
        );
      } else {
        _currentOrder.add(CartItem(
          cartItemId: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.productId,
          productName: product.name,
          productPrice: product.price,
          quantity: 1,
          productImage: product.imageUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    });
  }

  void _showOrderSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Sipariş Özeti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _currentOrder.length,
                    itemBuilder: (context, index) {
                      final item = _currentOrder[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Text('${item.quantity}'),
                        ),
                        title: Text(item.productName),
                        subtitle: Text('₺${item.productPrice.toStringAsFixed(2)}'),
                        trailing: Text(
                          '₺${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _removeFromCart(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      final index = _currentOrder.indexWhere((cartItem) => cartItem.cartItemId == item.cartItemId);
      if (index >= 0) {
        if (_currentOrder[index].quantity > 1) {
          _currentOrder[index] = _currentOrder[index].copyWith(
            quantity: _currentOrder[index].quantity - 1,
          );
        } else {
          _currentOrder.removeAt(index);
        }
      }
    });
    Navigator.pop(context);
  }

  Future<void> _sendOrder() async {
    if (_currentOrder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş boş olamaz')),
      );
      return;
    }

    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşteri adı gerekli')),
      );
      return;
    }

    if (_tableNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masa numarası gerekli')),
      );
      return;
    }

    try {
      // Siparişi oluştur
      final order = Order.createStaffOrder(
        businessId: widget.currentStaff.businessId,
        items: _currentOrder,
        customerName: _customerNameController.text.trim(),
        tableNumber: _tableNumberController.text.trim(),
        staffId: widget.currentStaff.staffId,
        staffName: widget.currentStaff.fullName,
        notes: _notesController.text.trim(),
      );

      await _orderService.saveOrder(order);

      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş başarıyla gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );

      // Formu temizle
      setState(() {
        _currentOrder.clear();
        _customerNameController.clear();
        _tableNumberController.clear();
        _notesController.clear();
      });

      // Geri dön
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş gönderilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 