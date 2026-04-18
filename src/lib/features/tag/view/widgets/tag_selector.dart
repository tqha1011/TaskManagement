import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/core/utils/adaptive_color_extension.dart';
import 'package:task_management_app/features/tag/model/tag_model.dart';

import '../../viewmodel/tag_viewmodel.dart';

class TagSelector extends StatefulWidget {
  const TagSelector({super.key});

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _showAddCustomDialog(BuildContext context, TagViewModel viewModel) {
    _customController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo tag mới'),
        content: TextField(
          controller: _customController,
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: 'Tên tag (tối đa 12 ký tự)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await viewModel.addCustomTag(_customController.text);
              if (!context.mounted) return;

              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TagViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: viewModel.isLoading
                  ? null
                  : () => _showAddCustomDialog(context, viewModel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Tạo tag',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (viewModel.tags.isEmpty)
          Text(
            'Chưa có tag. Nhấn "Tạo tag" để thêm.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: viewModel.tags
                .map(
                  (tag) => _TagChip(
                    tag: tag,
                    isSelected: viewModel.isTagSelected(tag),
                    onTap: () => viewModel.toggleTag(tag),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  final TagModel tag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptiveTagColor = tag.color.toAdaptiveColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? adaptiveTagColor
              : adaptiveTagColor.withValues(alpha: 0.15),
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
                color: isSelected ? Colors.white : adaptiveTagColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

