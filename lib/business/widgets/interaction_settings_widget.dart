import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// 🤝 Etkileşim Ayarları Widget'ı
/// 
/// Bu widget kullanıcı etkileşim deneyimini özelleştirme özelliklerini sağlar:
/// - Animasyon kontrolleri
/// - Dokunma hareketleri
/// - Haptic feedback
/// - Hover efektleri
/// - Özellik açma/kapama
class InteractionSettingsWidget extends StatefulWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;

  const InteractionSettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<InteractionSettingsWidget> createState() => _InteractionSettingsWidgetState();
}

class _InteractionSettingsWidgetState extends State<InteractionSettingsWidget> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Etkileşim Ayarları',
            'Kullanıcı deneyimi ve animasyonları ayarlayın',
            Icons.touch_app_rounded,
          ),
          const SizedBox(height: 24),
          
          _buildAnimationControls(),
          const SizedBox(height: 24),
          
          _buildGestureControls(),
          const SizedBox(height: 24),
          
          _buildFeatureControls(),
          const SizedBox(height: 24),
          
          _buildAdvancedControls(),
          const SizedBox(height: 24),
          
          _buildInteractionPreview(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required Widget child,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAnimationControls() {
    return _buildSettingsCard(
      title: 'Animasyonlar',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Animasyonları Etkinleştir'),
            subtitle: const Text('Geçiş ve hover animasyonları'),
            value: widget.currentSettings.visualStyle.enableAnimations,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                visualStyle: widget.currentSettings.visualStyle.copyWith(
                  enableAnimations: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Hover Efektleri'),
            subtitle: const Text('Fare üzerine geldiğinde efektler (Web)'),
            value: widget.currentSettings.interactionSettings.enableHoverEffects,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableHoverEffects: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Tıklama Animasyonları'),
            subtitle: const Text('Dokunma ve tıklama sırasında animasyonlar'),
            value: widget.currentSettings.interactionSettings.enableClickAnimations,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableClickAnimations: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          if (widget.currentSettings.visualStyle.enableAnimations) ...[
            const SizedBox(height: 16),
            _buildSliderSetting(
              label: 'Animasyon Hızı',
              value: widget.currentSettings.interactionSettings.animationDuration,
              min: 100,
              max: 800,
              divisions: 14,
              onChanged: (value) {
                final newSettings = widget.currentSettings.copyWith(
                  interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                    animationDuration: value,
                  ),
                );
                widget.onSettingsChanged(newSettings);
              },
              suffix: 'ms',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGestureControls() {
    return _buildSettingsCard(
      title: 'Dokunma Hareketleri',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Kaydırma Hareketleri'),
            subtitle: const Text('Parmakla kaydırma işlemleri'),
            value: widget.currentSettings.interactionSettings.enableSwipeGestures,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableSwipeGestures: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Haptic Geri Bildirim'),
            subtitle: const Text('Dokunma sırasında titreşim'),
            value: widget.currentSettings.interactionSettings.hapticFeedback,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  hapticFeedback: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Çift Dokunma'),
            subtitle: const Text('Çift dokunarak hızlı işlemler'),
            value: widget.currentSettings.interactionSettings.enableDoubleTap,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableDoubleTap: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Uzun Basma'),
            subtitle: const Text('Uzun basarak bağlam menüsü'),
            value: widget.currentSettings.interactionSettings.enableLongPress,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableLongPress: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureControls() {
    return _buildSettingsCard(
      title: 'Özellik Ayarları',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Hızlı Önizleme'),
            subtitle: const Text('Ürünlere uzun basınca önizleme göster'),
            value: widget.currentSettings.interactionSettings.enableQuickView,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableQuickView: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Favoriler'),
            subtitle: const Text('Kullanıcılar favori ürün ekleyebilsin'),
            value: widget.currentSettings.interactionSettings.enableFavorites,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableFavorites: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Paylaşım'),
            subtitle: const Text('Ürünleri sosyal medyada paylaşma'),
            value: widget.currentSettings.interactionSettings.enableShare,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableShare: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Zoom'),
            subtitle: const Text('Görselleri büyütme özelliği'),
            value: widget.currentSettings.interactionSettings.enableZoom,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableZoom: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedControls() {
    return _buildSettingsCard(
      title: 'Gelişmiş Ayarlar',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Lazy Loading'),
            subtitle: const Text('Görüntüleri ihtiyaç halinde yükle'),
            value: widget.currentSettings.interactionSettings.enableLazyLoading,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  enableLazyLoading: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Otomatik Yenileme'),
            subtitle: const Text('Menüyü otomatik olarak yenile'),
            value: widget.currentSettings.interactionSettings.autoRefresh,
            onChanged: (value) {
              final newSettings = widget.currentSettings.copyWith(
                interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                  autoRefresh: value,
                ),
              );
              widget.onSettingsChanged(newSettings);
            },
            activeColor: AppColors.primary,
          ),
          if (widget.currentSettings.interactionSettings.autoRefresh) ...[
            const SizedBox(height: 16),
            _buildSliderSetting(
              label: 'Yenileme Sıklığı',
              value: widget.currentSettings.interactionSettings.refreshInterval,
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (value) {
                final newSettings = widget.currentSettings.copyWith(
                  interactionSettings: widget.currentSettings.interactionSettings.copyWith(
                    refreshInterval: value,
                  ),
                );
                widget.onSettingsChanged(newSettings);
              },
              suffix: ' dk',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionPreview() {
    return _buildSettingsCard(
      title: 'Etkileşim Önizlemesi',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktif Özellikler:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Özellik listesi
            _buildFeatureChip('Animasyonlar', widget.currentSettings.visualStyle.enableAnimations),
            const SizedBox(height: 8),
            _buildFeatureChip('Hover Efektleri', widget.currentSettings.interactionSettings.enableHoverEffects),
            const SizedBox(height: 8),
            _buildFeatureChip('Haptic Feedback', widget.currentSettings.interactionSettings.hapticFeedback),
            const SizedBox(height: 8),
            _buildFeatureChip('Hızlı Önizleme', widget.currentSettings.interactionSettings.enableQuickView),
            const SizedBox(height: 8),
            _buildFeatureChip('Favoriler', widget.currentSettings.interactionSettings.enableFavorites),
            const SizedBox(height: 8),
            _buildFeatureChip('Paylaşım', widget.currentSettings.interactionSettings.enableShare),
            const SizedBox(height: 8),
            _buildFeatureChip('Zoom', widget.currentSettings.interactionSettings.enableZoom),
            
            const SizedBox(height: 16),
            
            // Performans bilgisi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performans Etkisi',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _getPerformanceImpact(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, bool isEnabled) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.success : AppColors.error,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        if (isEnabled) ...[
          const Spacer(),
          Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 16,
          ),
        ],
      ],
    );
  }

  String _getPerformanceImpact() {
    int enabledFeatures = 0;
    
    if (widget.currentSettings.visualStyle.enableAnimations) enabledFeatures++;
    if (widget.currentSettings.interactionSettings.enableHoverEffects) enabledFeatures++;
    if (widget.currentSettings.interactionSettings.enableClickAnimations) enabledFeatures++;
    if (widget.currentSettings.interactionSettings.enableQuickView) enabledFeatures++;
    if (widget.currentSettings.interactionSettings.enableZoom) enabledFeatures++;
    if (!widget.currentSettings.interactionSettings.enableLazyLoading) enabledFeatures++;
    
    if (enabledFeatures <= 2) {
      return 'Düşük - Hızlı performans';
    } else if (enabledFeatures <= 4) {
      return 'Orta - Dengeli performans';
    } else {
      return 'Yüksek - Daha fazla özellik, daha yavaş performans';
    }
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String suffix = '',
    String Function(double)? formatValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium,
            ),
            Text(
              formatValue?.call(value) ?? '${value.round()}$suffix',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withOpacity(0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}