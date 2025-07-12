import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/business.dart';
import '../../../core/services/data_service.dart';
import '../../widgets/shared/loading_indicator.dart';

class BusinessInfoPage extends StatefulWidget {
  final String businessId;

  const BusinessInfoPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final DataService _dataService = DataService();
  Business? _business;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataService.initialize();
      final business = await _dataService.getBusiness(widget.businessId);

      setState(() {
        _business = business;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'İşletme Bilgileri',
          style: AppTypography.h3.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _business == null
          ? const Center(child: Text('İşletme bilgileri bulunamadı'))
          : _buildBusinessInfo(),
    );
  }

  Widget _buildBusinessInfo() {
    return SingleChildScrollView(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temel Bilgiler', style: AppTypography.h4),
                  const SizedBox(height: 16),
                  _buildInfoItem('İşletme Adı', _business!.businessName),
                  _buildInfoItem('Açıklama', _business!.businessDescription),
                  _buildInfoItem(
                    'Durumu',
                    _business!.isActive ? 'Aktif' : 'Pasif',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('İletişim Bilgileri', style: AppTypography.h4),
                  const SizedBox(height: 16),
                  _buildInfoItem('Telefon', _business!.contactInfo.phone),
                  _buildInfoItem('E-posta', _business!.contactInfo.email),
                  _buildInfoItem(
                    'Website',
                    _business!.contactInfo.website ?? 'Belirtilmemiş',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Address Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adres Bilgileri', style: AppTypography.h4),
                  const SizedBox(height: 16),
                  _buildInfoItem('Sokak', _business!.address.street),
                  _buildInfoItem('İlçe', _business!.address.district),
                  _buildInfoItem('İl', _business!.address.city),
                  _buildInfoItem('Posta Kodu', _business!.address.postalCode),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _editBusinessInfo,
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareBusinessInfo,
                  icon: const Icon(Icons.share),
                  label: const Text('Paylaş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  void _editBusinessInfo() {
    _showEditBusinessDialog();
  }

  void _shareBusinessInfo() {
    final businessInfo =
        '''
${_business!.businessName}
${_business!.businessDescription}

📍 Adres: ${_business!.address.street}, ${_business!.address.district}, ${_business!.address.city}
📞 Telefon: ${_business!.contactInfo.phone}
📧 E-posta: ${_business!.contactInfo.email}
${_business!.contactInfo.website != null ? '🌐 Website: ${_business!.contactInfo.website}' : ''}

Dijital menümüz: https://menumasa.com/menu/${widget.businessId}
''';

    // Share functionality would go here
    // Share.share(businessInfo);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İşletme bilgileri paylaşıldı'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildSampleLogoButton(
    String label,
    String imageUrl,
    TextEditingController controller,
  ) {
    return ElevatedButton(
      onPressed: () {
        controller.text = imageUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label logosu seçildi'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showLogoPickerDialog(
    BuildContext context,
    Function(String) onLogoSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logo Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL\'den Ekle'),
              subtitle: const Text('İnternetteki bir logo linkini kullan'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog(context, onLogoSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Hazır Logolar'),
              subtitle: const Text('Örnek logolardan seç'),
              onTap: () {
                Navigator.pop(context);
                _showSampleLogosDialog(context, onLogoSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              subtitle: const Text('Yeni fotoğraf çek'),
              onTap: () {
                Navigator.pop(context);
                _pickLogoFromCamera(onLogoSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Dosya Seç'),
              subtitle: const Text('Bilgisayardan logo seç'),
              onTap: () {
                Navigator.pop(context);
                _pickLogoFromFile(onLogoSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog(
    BuildContext context,
    Function(String) onLogoSelected,
  ) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL\'den Logo Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Logo URL\'si',
                hintText: 'https://example.com/logo.jpg',
              ),
            ),
            const SizedBox(height: 16),
            if (urlController.text.isNotEmpty)
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greyLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: AppColors.greyLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                onLogoSelected(urlController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showSampleLogosDialog(
    BuildContext context,
    Function(String) onLogoSelected,
  ) {
    final sampleLogos = [
      {'label': '🍕 Pizza', 'url': 'https://picsum.photos/200/200?random=10'},
      {'label': '🍔 Burger', 'url': 'https://picsum.photos/200/200?random=11'},
      {'label': '☕ Kafe', 'url': 'https://picsum.photos/200/200?random=12'},
      {
        'label': '🍽️ Restoran',
        'url': 'https://picsum.photos/200/200?random=13',
      },
      {'label': '🥘 Yemek', 'url': 'https://picsum.photos/200/200?random=14'},
      {'label': '🧊 Bar', 'url': 'https://picsum.photos/200/200?random=15'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hazır Logolar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: sampleLogos.length,
            itemBuilder: (context, index) {
              final logo = sampleLogos[index];
              return InkWell(
                onTap: () {
                  onLogoSelected(logo['url']!);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Image.network(
                            logo['url']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          logo['label']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLogoEditDialog(
    BuildContext context,
    String logoUrl,
    Function(String) onLogoEdited,
  ) {
    if (logoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir logo ekleyin'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logo Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: AppColors.greyLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Düzenleme özellikleri:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text('Kırp'),
                  avatar: const Icon(Icons.crop, size: 18),
                  onDeleted: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kırpma özelliği yakında eklenecek'),
                      ),
                    );
                  },
                ),
                Chip(
                  label: const Text('Boyutlandır'),
                  avatar: const Icon(Icons.photo_size_select_large, size: 18),
                  onDeleted: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Boyutlandırma özelliği yakında eklenecek',
                        ),
                      ),
                    );
                  },
                ),
                Chip(
                  label: const Text('Filtre'),
                  avatar: const Icon(Icons.filter_alt, size: 18),
                  onDeleted: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filtre özelliği yakında eklenecek'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              onLogoEdited(logoUrl);
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessDialog() {
    final nameController = TextEditingController(text: _business!.businessName);
    final descriptionController = TextEditingController(
      text: _business!.businessDescription,
    );
    final phoneController = TextEditingController(
      text: _business!.contactInfo.phone,
    );
    final emailController = TextEditingController(
      text: _business!.contactInfo.email,
    );
    final websiteController = TextEditingController(
      text: _business!.contactInfo.website ?? '',
    );
    final streetController = TextEditingController(
      text: _business!.address.street,
    );
    final districtController = TextEditingController(
      text: _business!.address.district,
    );
    final cityController = TextEditingController(text: _business!.address.city);
    final postalCodeController = TextEditingController(
      text: _business!.address.postalCode,
    );
    final logoUrlController = TextEditingController(
      text: _business!.logoUrl ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşletme Bilgilerini Düzenle'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'İşletme Adı'),
                ),
                const SizedBox(height: 16),

                // Logo ekleme bölümü
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // Mevcut logo
                    if (_business!.logoUrl != null)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.greyLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _business!.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                size: 40,
                                color: AppColors.greyLight,
                              );
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Logo ekleme seçenekleri
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showLogoPickerDialog(context, (logoUrl) {
                                logoUrlController.text = logoUrl;
                              });
                            },
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Logo Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showLogoEditDialog(
                                context,
                                logoUrlController.text,
                                (editedUrl) {
                                  logoUrlController.text = editedUrl;
                                },
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Düzenle'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Hızlı seçim butonları
                    Text('Hızlı Seçim:', style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildSampleLogoButton(
                          '🍕 Pizza',
                          'https://picsum.photos/200/200?random=10',
                          logoUrlController,
                        ),
                        _buildSampleLogoButton(
                          '🍔 Burger',
                          'https://picsum.photos/200/200?random=11',
                          logoUrlController,
                        ),
                        _buildSampleLogoButton(
                          '☕ Kafe',
                          'https://picsum.photos/200/200?random=12',
                          logoUrlController,
                        ),
                        _buildSampleLogoButton(
                          '🍽️ Restoran',
                          'https://picsum.photos/200/200?random=13',
                          logoUrlController,
                        ),
                        _buildSampleLogoButton(
                          '🥘 Yemek',
                          'https://picsum.photos/200/200?random=14',
                          logoUrlController,
                        ),
                        _buildSampleLogoButton(
                          '🧊 Bar',
                          'https://picsum.photos/200/200?random=15',
                          logoUrlController,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(labelText: 'Sokak'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: districtController,
                  decoration: const InputDecoration(labelText: 'İlçe'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'İl'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: postalCodeController,
                  decoration: const InputDecoration(labelText: 'Posta Kodu'),
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
          ElevatedButton(
            onPressed: () async {
              await _saveBusinessInfo(
                nameController.text.trim(),
                descriptionController.text.trim(),
                phoneController.text.trim(),
                emailController.text.trim(),
                websiteController.text.trim(),
                streetController.text.trim(),
                districtController.text.trim(),
                cityController.text.trim(),
                postalCodeController.text.trim(),
                logoUrlController.text.trim(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBusinessInfo(
    String name,
    String description,
    String phone,
    String email,
    String website,
    String street,
    String district,
    String city,
    String postalCode,
    String logoUrl,
  ) async {
    try {
      final updatedBusiness = _business!.copyWith(
        businessName: name,
        businessDescription: description,
        logoUrl: logoUrl.isEmpty ? null : logoUrl,
        contactInfo: ContactInfo(
          phone: phone,
          email: email,
          website: website.isEmpty ? null : website,
        ),
        address: Address(
          street: street,
          district: district,
          city: city,
          postalCode: postalCode,
        ),
        updatedAt: DateTime.now(),
      );

      await _dataService.saveBusiness(updatedBusiness);

      setState(() {
        _business = updatedBusiness;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşletme bilgileri başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickLogoFromCamera(Function(String) onLogoSelected) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final imagePath = image.path;
        onLogoSelected(imagePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo fotoğrafı başarıyla çekildi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickLogoFromFile(Function(String) onLogoSelected) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Dosya yolunu kullan
        onLogoSelected(image.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo resmi başarıyla seçildi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
