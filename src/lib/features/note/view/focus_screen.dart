import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/focus_viewmodel.dart';
import '../view/focus_widget.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  // Shows the configuration dialog for timer and notification settings
  void _showSettingsDialog(BuildContext context) {
    final vm = context.read<FocusViewModel>();

    double currentPomodoro = (vm.pomodoroTime / 60).toDouble();
    double currentBreak = (vm.shortBreakTime / 60).toDouble();
    bool currentVibrate = vm.isVibrationEnabled;
    int currentRingtone = vm.ringtoneType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pomodoro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${currentPomodoro.toInt()} min', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(value: currentPomodoro, min: 5, max: 60, divisions: 55, activeColor: AppColors.primaryBlue, onChanged: (val) => setStateDialog(() => currentPomodoro = val)),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Short Break', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${currentBreak.toInt()} min', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(value: currentBreak, min: 1, max: 30, divisions: 29, activeColor: Colors.orange, onChanged: (val) => setStateDialog(() => currentBreak = val)),
                    const Divider(height: 30),
                    SwitchListTile(
                      title: const Text('Vibrate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: currentVibrate, activeColor: AppColors.primaryBlue, contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateDialog(() => currentVibrate = val),
                    ),
                    const SizedBox(height: 10),
                    const Text('Sound', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(15)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: currentRingtone,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Alarm (Loud)')),
                            DropdownMenuItem(value: 2, child: Text('Notification (Soft)')),
                            DropdownMenuItem(value: 3, child: Text('Ringtone')),
                          ],
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => currentRingtone = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    vm.updateSettings(newPomodoroMinutes: currentPomodoro.toInt(), newBreakMinutes: currentBreak.toInt(), vibrate: currentVibrate, ringtone: currentRingtone);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d')),
                      SizedBox(width: 15),
                      Text('Focus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showSettingsDialog(context),
                    child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const FocusTabSelector(),
              const SizedBox(height: 30),
              const TimerDisplayWidget(),
              const SizedBox(height: 40),
              const TimerControlsWidget(),
              const SizedBox(height: 40),
              const QuickNoteCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
