import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/task_viewmodel.dart';

class TagSelector extends StatelessWidget {
  const TagSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaskViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewModel.availableTags.map((tag) {
            final isSelected = viewModel.isTagSelected(tag);
            return GestureDetector(
              onTap: () => viewModel.toggleTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tag.color
                      : tag.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : tag.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
