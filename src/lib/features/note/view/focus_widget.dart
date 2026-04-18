import 'dart:io'; // Import to display image files
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/focus_viewmodel.dart';

// --- Tab Selector Widget ---
class FocusTabSelector extends StatelessWidget {
  const FocusTabSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132544) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBtn(
            context,
            'Pomodoro',
            vm.isPomodoroMode,
            () => vm.setMode(true),
          ),
          _buildTabBtn(
            context,
            'Nghỉ ngắn',
            !vm.isPomodoroMode,
            () => vm.setMode(false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A3D5D)
                  : Theme.of(context).colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// --- Timer Display Widget ---
class TimerDisplayWidget extends StatelessWidget {
  const TimerDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF182C4D)
                  : Theme.of(context).colorScheme.surface,
              width: 14,
            ),
          ),
        ),
        SizedBox(
          width: 280,
          height: 280,
          child: CircularProgressIndicator(
            value: vm.progress,
            strokeWidth: 14,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.transparent,
            strokeCap: StrokeCap.round,
          ),
        ),
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2945) : Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                vm.timeString,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vm.isPomodoroMode ? 'TẬP TRUNG' : 'NGHỈ NGƠI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.85),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Timer Controls Widget ---
class TimerControlsWidget extends StatelessWidget {
  const TimerControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlBtn(
          icon: Icons.replay_rounded,
          bgColor: isDark ? const Color(0xFF1A2B4B) : Theme.of(context).colorScheme.surface,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 60,
          onTap: vm.resetTimer,
        ),
        const SizedBox(width: 30),

        // MAIN BUTTON: CHANGES TO RED WHEN RINGING TO STOP ALARM
        _buildControlBtn(
          icon: vm.isRinging
              ? Icons.notifications_off_rounded // Muted bell icon
              : (vm.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          bgColor: vm.isRinging
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary,
          iconColor: Colors.white,
          size: 85,
          hasShadow: true,
          onTap: vm.toggleTimer, // Stops alarm if ringing, otherwise toggles timer
        ),

        const SizedBox(width: 30),
        _buildControlBtn(
          icon: Icons.skip_next_rounded,
          bgColor: isDark ? const Color(0xFF1A2B4B) : Theme.of(context).colorScheme.surface,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 60,
          onTap: vm.skipTimer,
        ),
      ],
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required double size,
    bool hasShadow = false,
    required VoidCallback onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          if (hasShadow)
            BoxShadow(
              color: bgColor.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          if (!hasShadow)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Icon(icon, color: iconColor, size: size * 0.45),
        ),
      ),
    );
  }
}

// --- Quick Note Card Widget ---
class QuickNoteCard extends StatelessWidget {
  const QuickNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2945) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: isDark
            ? Border.all(color: const Color(0xFF2A3E62), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ghi chú nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Đang thực hiện',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // TEXT INPUT AND IMAGE PREVIEW AREA
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF12223D)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: vm.noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Thêm ý tưởng, tiến độ, hình ảnh...',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.70),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                // SHOW IMAGE PREVIEW IF SELECTED
                if (vm.selectedImagePath != null) ...[
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(vm.selectedImagePath!),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey.shade600,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: -10,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          onPressed: vm.removeSelectedImage,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  // IMAGE PICKER BUTTON
                  GestureDetector(
                    onTap: () => vm.pickImage(),
                    child: Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard
                  context.read<FocusViewModel>().addNote();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text('Lưu ghi chú', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // --- LOCAL NOTE LIST WITH IMAGE SUPPORT ---
          if (vm.notes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: Theme.of(context).colorScheme.outline, height: 1),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.notes.length,
              itemBuilder: (context, index) {
                final note = vm.notes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: note.pinned
                        ? (isDark ? const Color(0xFF4A3B17) : const Color(0xFFFFF8E1))
                        : (isDark
                            ? const Color(0xFF12223D)
                            : Theme.of(context).colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: note.pinned ? Colors.amber.shade200 : Colors.transparent),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CLICK TO REMOVE BUTTON
                      GestureDetector(
                        onTap: () => vm.removeNote(note.id),
                        child: Container(
                          margin: const EdgeInsets.only(top: 2, right: 12),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // CONTENT (TEXT AND IMAGE)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.content.isNotEmpty)
                              Text(
                                note.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  height: 1.4,
                                ),
                              ),

                            // DISPLAY ATTACHED IMAGE IN NOTE
                            if (note.imagePath != null && note.imagePath!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(note.imagePath!),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey.shade600,
                                            size: 50,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // PIN BUTTON
                      GestureDetector(
                        onTap: () => vm.togglePin(note.id),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            color: note.pinned ? Colors.orange : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}