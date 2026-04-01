import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';

class CropSelector extends StatelessWidget {
  final CropType selectedCrop;
  final ValueChanged<CropType> onCropSelected;

  const CropSelector({
    super.key,
    required this.selectedCrop,
    required this.onCropSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Crop',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: CropType.values.map((crop) {
            final isSelected = crop == selectedCrop;
            return Expanded(
              child: GestureDetector(
                onTap: () => onCropSelected(crop),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        crop.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crop.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
