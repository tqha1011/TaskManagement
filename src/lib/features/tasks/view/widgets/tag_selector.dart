import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';

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

  void _showAddCustomDialog(BuildContext context, TaskViewModel viewModel) {
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
            onPressed: () {
              final error = viewModel.addCustomTag(_customController.text);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
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
    final viewModel = context.watch<TaskViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),

        // ─── Nhóm 1: Loại công việc ───────────────────────
        _buildTagGroup(
          label: 'Loại công việc',
          tags: viewModel.workTypeTags,
          viewModel: viewModel,
        ),
        const SizedBox(height: 12),

        // ─── Nhóm 2: Thời gian ────────────────────────────
        _buildTagGroup(
          label: 'Thời gian',
          tags: viewModel.timeTags,
          viewModel: viewModel,
        ),
        const SizedBox(height: 12),

        // ─── Nhóm 3: Trạng thái ───────────────────────────
        _buildTagGroup(
          label: 'Trạng thái',
          tags: viewModel.statusTags,
          viewModel: viewModel,
        ),
        const SizedBox(height: 12),

        // ─── Nhóm 4: Custom ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Custom',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            // Nút thêm tag mới
            if (viewModel.customTags.length < 5)
              GestureDetector(
                onTap: () => _showAddCustomDialog(context, viewModel),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F7FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.blue),
                      SizedBox(width: 3),
                      Text(
                        'Tạo tag',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Hiển thị custom tags đã tạo
        viewModel.customTags.isEmpty
            ? const Text(
                'Chưa có tag custom. Nhấn "Tạo tag" để thêm.',
                style: TextStyle(fontSize: 12, color: Colors.black38),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: viewModel.customTags
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

  Widget _buildTagGroup({
    required String label,
    required List<TagModel> tags,
    required TaskViewModel viewModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
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

// ─── Tag Chip Widget ─────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final TagModel tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tag.color : tag.color.withValues(alpha: 0.1),
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
  }
}
