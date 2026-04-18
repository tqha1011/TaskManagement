import 'package:flutter/material.dart';
import 'package:task_management_app/core/utils/adaptive_color_extension.dart';

import '../../model/category_model.dart';

class CategoryChoiceChips extends StatelessWidget {
  const CategoryChoiceChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<CategoryModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final adaptiveColor = category.color.toAdaptiveColor(context);
          final isSelected = category.id == selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(category);
              },
              backgroundColor: adaptiveColor.withValues(alpha: 0.15),
              selectedColor: adaptiveColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : adaptiveColor,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: adaptiveColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

