import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';

class PrioritySelector extends StatelessWidget {
  const PrioritySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaskViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = viewModel.selectedPriority == priority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => viewModel.setPriority(priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priority.color
                          : const Color(0xFFF1F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? priority.color : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          priority.icon,
                          color: isSelected ? Colors.white : priority.color,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          priority.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : priority.color,
                          ),
                        ),
                      ],
                    ),
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
