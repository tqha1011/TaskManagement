import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/focus_viewmodel.dart';
import '../view/focus_widget.dart';
import 'package:task_management_app/features/chatbot/view/widgets/user_avatar.dart';
import 'package:task_management_app/features/user/viewmodel/user_profile_viewmodel.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  _FocusScreenState createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // Shows the configuration dialog for timer and notification settings
  void _showSettingsDialog(BuildContext context) {
    final vm = context.read<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double currentPomodoro = (vm.pomodoroTime / 60).toDouble();
    double currentBreak = (vm.shortBreakTime / 60).toDouble();
    bool currentVibrate = vm.isVibrationEnabled;
    int currentRingtone = vm.ringtoneType;
    double currentVolume = vm.focusVolume;
    String currentSoundKey = vm.focusSoundKey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark
                  ? const Color(0xFF1A2945)
                  : Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Cài đặt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Time Settings ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pomodoro',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${currentPomodoro.toInt()} phút',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: currentPomodoro,
                      min: 5,
                      max: 60,
                      divisions: 55,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) =>
                          setStateDialog(() => currentPomodoro = val),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nghỉ ngắn',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${currentBreak.toInt()} phút',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: currentBreak,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.orange,
                      onChanged: (val) =>
                          setStateDialog(() => currentBreak = val),
                    ),
                    Divider(
                      height: 30,
                      color: Theme.of(context).colorScheme.outline,
                    ),

                    // --- Hardware Settings ---
                    SwitchListTile(
                      title: Text(
                        'Rung',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      value: currentVibrate,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) =>
                          setStateDialog(() => currentVibrate = val),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nhạc nền tập trung',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF12223D)
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: isDark
                              ? const Color(0xFF1A2945)
                              : Theme.of(context).colorScheme.surface,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          isExpanded: true,
                          value: currentSoundKey,
                          items: const [
                            DropdownMenuItem(
                              value: 'mix_all',
                              child: Text('Mix tất cả'),
                            ),
                            DropdownMenuItem(
                              value: 'rain_summer_cars',
                              child: Text('Rain + ambience'),
                            ),
                            DropdownMenuItem(
                              value: 'lofi_chill_girl',
                              child: Text('Lo-fi Chill 1'),
                            ),
                            DropdownMenuItem(
                              value: 'lofi_girl_chill',
                              child: Text('Lo-fi Chill 2'),
                            ),
                            DropdownMenuItem(
                              value: 'the_mountain_lofi',
                              child: Text('The Mountain Lo-fi'),
                            ),
                            DropdownMenuItem(
                              value: 'sunset_drive',
                              child: Text('Sunset Drive'),
                            ),
                            DropdownMenuItem(
                              value: 'golden_hour',
                              child: Text('Golden Hour'),
                            ),
                            DropdownMenuItem(
                              value: 'morning_routine_lofi',
                              child: Text('Morning Routine Lo-fi'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => currentSoundKey = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Âm lượng nhạc',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${(currentVolume * 100).round()}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: currentVolume,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) =>
                          setStateDialog(() => currentVolume = val),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Âm thanh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF12223D)
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          dropdownColor: isDark
                              ? const Color(0xFF1A2945)
                              : Theme.of(context).colorScheme.surface,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          isExpanded: true,
                          value: currentRingtone,
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Chuông (Lớn)'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Thông báo (Nhỏ)'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Nhạc chuông'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => currentRingtone = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update settings in ViewModel
                    vm.updateSettings(
                      newPomodoroMinutes: currentPomodoro.toInt(),
                      newBreakMinutes: currentBreak.toInt(),
                      vibrate: currentVibrate,
                      ringtone: currentRingtone,
                      volume: currentVolume,
                      soundKey: currentSoundKey,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileVm = context.watch<UserProfileViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF08142D),
                    Color(0xFF0B1A38),
                    Color(0xFF0A1834),
                  ],
                )
              : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          size: 44,
                          avatarUrl: profileVm.user?.avatarUrl,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'Tập trung',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    // Settings Icon
                    GestureDetector(
                      onTap: () => _showSettingsDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF172744)
                              : Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Main Content Widgets ---
                const FocusTabSelector(),
                const SizedBox(height: 30),
                const TimerDisplayWidget(),
                const SizedBox(height: 40),
                const TimerControlsWidget(),
                const SizedBox(height: 40),
                const QuickNoteCard(),
                const SizedBox(height: 80), // Padding for bottom nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }
}
