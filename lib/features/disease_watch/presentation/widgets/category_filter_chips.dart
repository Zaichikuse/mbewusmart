import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';

class CategoryFilterChips extends StatefulWidget {
  final DiagnosisCategory? selectedCategory;
  final ValueChanged<DiagnosisCategory?> onCategoryChanged;

  const CategoryFilterChips({
    super.key,
    this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  late DiagnosisCategory? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCategory;
  }

  void _onChipTapped(DiagnosisCategory? category) {
    setState(() {
      _selected = category;
    });
    widget.onCategoryChanged(category);
  }

  Color _getChipColor(DiagnosisCategory? category) {
    if (category == null) return AppTheme.primaryGreen;

    switch (category) {
      case DiagnosisCategory.pest:
        return AppTheme.accentOrange;
      case DiagnosisCategory.disease:
        return AppTheme.errorRed;
      case DiagnosisCategory.deficiency:
        return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // All chip
            FilterChip(
              label: const Text('All'),
              selected: _selected == null,
              onSelected: (selected) {
                _onChipTapped(null);
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
              side: BorderSide(
                color: _selected == null
                    ? AppTheme.primaryGreen
                    : AppTheme.textMuted,
                width: _selected == null ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: _selected == null
                    ? AppTheme.primaryGreen
                    : AppTheme.textDark,
                fontWeight: _selected == null
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            // Pest chip
            FilterChip(
              label: Text('${DiagnosisCategory.pest.icon} Pests'),
              selected: _selected == DiagnosisCategory.pest,
              onSelected: (selected) {
                _onChipTapped(DiagnosisCategory.pest);
              },
              backgroundColor: Colors.transparent,
              selectedColor: _getChipColor(
                DiagnosisCategory.pest,
              ).withValues(alpha: 0.2),
              side: BorderSide(
                color: _selected == DiagnosisCategory.pest
                    ? _getChipColor(DiagnosisCategory.pest)
                    : AppTheme.textMuted,
                width: _selected == DiagnosisCategory.pest ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: _selected == DiagnosisCategory.pest
                    ? _getChipColor(DiagnosisCategory.pest)
                    : AppTheme.textDark,
                fontWeight: _selected == DiagnosisCategory.pest
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            // Disease chip
            FilterChip(
              label: Text('${DiagnosisCategory.disease.icon} Diseases'),
              selected: _selected == DiagnosisCategory.disease,
              onSelected: (selected) {
                _onChipTapped(DiagnosisCategory.disease);
              },
              backgroundColor: Colors.transparent,
              selectedColor: _getChipColor(
                DiagnosisCategory.disease,
              ).withValues(alpha: 0.2),
              side: BorderSide(
                color: _selected == DiagnosisCategory.disease
                    ? _getChipColor(DiagnosisCategory.disease)
                    : AppTheme.textMuted,
                width: _selected == DiagnosisCategory.disease ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: _selected == DiagnosisCategory.disease
                    ? _getChipColor(DiagnosisCategory.disease)
                    : AppTheme.textDark,
                fontWeight: _selected == DiagnosisCategory.disease
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            // Deficiency chip
            FilterChip(
              label: Text('${DiagnosisCategory.deficiency.icon} Deficiencies'),
              selected: _selected == DiagnosisCategory.deficiency,
              onSelected: (selected) {
                _onChipTapped(DiagnosisCategory.deficiency);
              },
              backgroundColor: Colors.transparent,
              selectedColor: _getChipColor(
                DiagnosisCategory.deficiency,
              ).withValues(alpha: 0.2),
              side: BorderSide(
                color: _selected == DiagnosisCategory.deficiency
                    ? _getChipColor(DiagnosisCategory.deficiency)
                    : AppTheme.textMuted,
                width: _selected == DiagnosisCategory.deficiency ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: _selected == DiagnosisCategory.deficiency
                    ? _getChipColor(DiagnosisCategory.deficiency)
                    : AppTheme.textDark,
                fontWeight: _selected == DiagnosisCategory.deficiency
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
