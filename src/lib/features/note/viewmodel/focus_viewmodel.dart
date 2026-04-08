import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/note_model.dart';

class FocusViewModel extends ChangeNotifier {
  // ==========================================
  // 1. STATE FOR NOTES (LOCAL UI ONLY)
  // ==========================================
  final TextEditingController noteController = TextEditingController();

  // Temporary variable for the selected image
  String? selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  // Mock initial data to populate UI
  List<NoteModel> notes = [
    NoteModel(id: '1', content: 'Hoàn thiện các component cho màn hình Pomodoro, tập trung vào các nút bấm Soft UI.', pinned: true),
    NoteModel(id: '2', content: 'Thiết kế hiệu ứng vòng tròn đếm ngược.'),
  ];

  // Open gallery to pick an image
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImagePath = image.path; // Save local file path
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Clear selected image
  void removeSelectedImage() {
    selectedImagePath = null;
    notifyListeners();
  }

  // Add note (optionally with an image) instantly to the UI
  void addNote() {
    final text = noteController.text.trim();
    if (text.isEmpty && selectedImagePath == null) return; // Skip if both text and image are empty

    notes.insert(0, NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      pinned: false,
      imagePath: selectedImagePath, // Store image in model
    ));

    // Sort to keep pinned notes at the top
    _sortNotes();
    noteController.clear();
    selectedImagePath = null; // Clear temporary image after saving
    notifyListeners();
  }

  // Remove note instantly
  void removeNote(String id) {
    notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  // Pin/unpin note
  void togglePin(String id) {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = NoteModel(
          id: notes[index].id,
          content: notes[index].content,
          pinned: !notes[index].pinned,
          imagePath: notes[index].imagePath // Keep image when pinning
      );
      _sortNotes();
      notifyListeners();
    }
  }

  void _sortNotes() {
    notes.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.id.compareTo(a.id);
    });
  }

  // ==========================================
  // 2. POMODORO TIMER STATE
  // ==========================================
  int pomodoroTime = 25 * 60;
  int shortBreakTime = 5 * 60;

  bool isVibrationEnabled = true;
  int ringtoneType = 1;

  bool isPomodoroMode = true;
  late int totalTime = pomodoroTime;
  late int timeRemaining = pomodoroTime;
  bool isRunning = false;
  Timer? _timer;

  String get timeString {
    String minutes = (timeRemaining ~/ 60).toString().padLeft(2, '0');
    String seconds = (timeRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress => timeRemaining / totalTime;

  void toggleTimer() {
    if (isRunning) {
      _timer?.cancel();
      isRunning = false;
    } else {
      isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          _timer?.cancel();
          isRunning = false;

          if (isVibrationEnabled) HapticFeedback.heavyImpact();
          if (ringtoneType == 1) FlutterRingtonePlayer().playAlarm();
          else if (ringtoneType == 2) FlutterRingtonePlayer().playNotification();
          else if (ringtoneType == 3) FlutterRingtonePlayer().playRingtone();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isRunning = false;
    timeRemaining = totalTime;
    notifyListeners();
  }

  void setMode(bool isPomodoro) {
    _timer?.cancel();
    isRunning = false;
    isPomodoroMode = isPomodoro;
    totalTime = isPomodoro ? pomodoroTime : shortBreakTime;
    timeRemaining = totalTime;
    notifyListeners();
  }

  void skipTimer() => setMode(!isPomodoroMode);

  void updateSettings({required int newPomodoroMinutes, required int newBreakMinutes, required bool vibrate, required int ringtone}) {
    pomodoroTime = newPomodoroMinutes * 60;
    shortBreakTime = newBreakMinutes * 60;
    isVibrationEnabled = vibrate;
    ringtoneType = ringtone;

    _timer?.cancel();
    isRunning = false;
    totalTime = isPomodoroMode ? pomodoroTime : shortBreakTime;
    timeRemaining = totalTime;

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    noteController.dispose();
    super.dispose();
  }
}
