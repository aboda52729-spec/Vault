import 'package:flutter/material.dart';
import '../../../../data/models/category.dart';

class FilterBar extends StatelessWidget {
  final bool isArabic;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const FilterBar({
    super.key,
    required this.isArabic,
    this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _Chip(
            label: isArabic ? 'الكل' : 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategoryChanged(null),
          ),
          const SizedBox(width: 8),
          ...TransactionCategory.defaults.map((cat) {
            return _Chip(
              label: cat.localizedName(isArabic),
              color: Color(cat.colorValue),
              isSelected: selectedCategory == cat.id,
              onTap: () => onCategoryChanged(cat.id),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.blueAccent).withAlpha(51)
              : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? Colors.blueAccent).withAlpha(102)
                : Colors.white.withAlpha(13),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? (color ?? Colors.blueAccent) : Colors.white.withAlpha(128),
          ),
        ),
      ),
    );
  }
}
