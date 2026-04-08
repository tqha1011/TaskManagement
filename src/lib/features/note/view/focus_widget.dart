import 'dart:io'; // Import to display image files
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/focus_viewmodel.dart';

// --- Tab Selector Widget ---
class FocusTabSelector extends StatelessWidget {
  const FocusTabSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FocusViewModel>();

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBtn('Pomodoro', vm.isPomodoroMode, () => vm.setMode(true)),
          _buildTabBtn('Nghỉ ngắn', !vm.isPomodoroMode, () => vm.setMode(false)),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF757575),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 14)),
        ),
        SizedBox(
          width: 280,
          height: 280,
          child: CircularProgressIndicator(
            value: vm.progress,
            strokeWidth: 14,
            color: AppColors.primaryBlue,
            backgroundColor: Colors.transparent,
            strokeCap: StrokeCap.round,
          ),
        ),
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                vm.timeString,
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), letterSpacing: -2),
              ),
              const SizedBox(height: 4),
              Text(
                vm.isPomodoroMode ? 'TẬP TRUNG' : 'NGHỈ NGƠI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue.withOpacity(0.8), letterSpacing: 2),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlBtn(
          icon: Icons.replay_rounded,
          bgColor: Colors.white,
          iconColor: const Color(0xFF757575),
          size: 60,
          onTap: vm.resetTimer,
        ),
        const SizedBox(width: 30),
        _buildControlBtn(
          icon: vm.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          bgColor: AppColors.primaryBlue,
          iconColor: Colors.white,
          size: 85,
          hasShadow: true,
          onTap: vm.toggleTimer,
        ),
        const SizedBox(width: 30),
        _buildControlBtn(
          icon: Icons.skip_next_rounded,
          bgColor: Colors.white,
          iconColor: const Color(0xFF757575),
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
          if (hasShadow) BoxShadow(color: AppColors.primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
          if (!hasShadow) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Ghi chú nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              Text('Đang thực hiện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grayText)),
            ],
          ),
          const SizedBox(height: 15),

          // TEXT INPUT AND IMAGE PREVIEW AREA
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
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
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
                ),

                // SHOW IMAGE PREVIEW IF ANY
                if (vm.selectedImagePath != null) ...[
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(vm.selectedImagePath!), height: 80, width: 80, fit: BoxFit.cover),
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
                  Icon(Icons.attach_file_rounded, color: Colors.grey.shade400, size: 22),
                  const SizedBox(width: 10),
                  // IMAGE PICKER BUTTON
                  GestureDetector(
                    onTap: () => vm.pickImage(),
                    child: Icon(Icons.image_outlined, color: AppColors.primaryBlue, size: 22),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  context.read<FocusViewModel>().addNote();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
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
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Color(0xFFE2E8F0), height: 1)),
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
                    color: note.pinned ? const Color(0xFFFFF8E1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: note.pinned ? Colors.amber.shade200 : Colors.transparent),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CLICK TO REMOVE
                      GestureDetector(
                        onTap: () => vm.removeNote(note.id),
                        child: Container(
                          margin: const EdgeInsets.only(top: 2, right: 12),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryBlue, width: 2)),
                        ),
                      ),
                      // CONTENT (TEXT AND IMAGE)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.content.isNotEmpty)
                              Text(note.content, style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50), height: 1.4)),

                            // DISPLAY IMAGE IN NOTE
                            if (note.imagePath != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(note.imagePath!),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
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
