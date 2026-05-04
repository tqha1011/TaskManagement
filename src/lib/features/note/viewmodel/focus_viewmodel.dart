import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/note_model.dart';

class FocusViewModel extends ChangeNotifier {
  // ==========================================
  // 1. STATE FOR NOTES (LOCAL STORAGE & UI)
  // ==========================================
  final TextEditingController noteController = TextEditingController();

  // Temporary variable for the selected image
  String? selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  // List to hold the notes
  List<NoteModel> notes = [];

  // Constructor: Load saved notes when the ViewModel is initialized
  FocusViewModel() {
    loadNotesFromDisk();
    _focusAudioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // --- LOCAL STORAGE LOGIC ---

  // Save current notes list to device storage
  Future<void> saveNotesToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> noteStrings = notes.map((n) => n.toJson()).toList();
    await prefs.setStringList('saved_notes', noteStrings);
  }

  // Load saved notes from device storage
  Future<void> loadNotesFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? noteStrings = prefs.getStringList('saved_notes');
    if (noteStrings != null) {
      List<NoteModel> loadedNotes = [];
      for (String noteString in noteStrings) {
        try {
          loadedNotes.add(NoteModel.fromJson(noteString));
        } catch (e) {
          debugPrint("Error parsing note JSON: $e");
          // Skip the malformed entry and continue
        }
      }
      notes = loadedNotes;
      notifyListeners();
    }
  }

  // --- NOTE OPERATIONS ---

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

  // Clear selected image before saving
  void removeSelectedImage() {
    selectedImagePath = null;
    notifyListeners();
  }

  // Add note (optionally with an image) instantly to the UI and save to disk
  Future<void> addNote() async {
    final text = noteController.text.trim();
    if (text.isEmpty && selectedImagePath == null)
      return; // Skip if both text and image are empty

    notes.insert(
      0,
      NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        pinned: false,
        imagePath: selectedImagePath, // Store image in model
      ),
    );

    _sortNotes();
    await saveNotesToDisk(); // Persist data
    noteController.clear();
    selectedImagePath = null; // Clear temporary image after saving
    notifyListeners();
  }

  // Remove note instantly and update storage
  Future<void> removeNote(String id) async {
    notes.removeWhere((note) => note.id == id);
    await saveNotesToDisk(); // Persist data
    notifyListeners();
  }

  // Pin/unpin note and update storage
  Future<void> togglePin(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = NoteModel(
        id: notes[index].id,
        content: notes[index].content,
        pinned: !notes[index].pinned,
        imagePath: notes[index].imagePath, // Keep image when pinning
      );
      _sortNotes();
      await saveNotesToDisk(); // Persist data
      notifyListeners();
    }
  }

  // Sort notes: Pinned items at the top, then by ID (newest first)
  void _sortNotes() {
    notes.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.id.compareTo(a.id);
    });
  }

  // ==========================================
  // 2. POMODORO TIMER STATE & LOGIC
  // ==========================================
  int pomodoroTime = 25 * 60;
  int shortBreakTime = 5 * 60;

  // Hardware settings
  bool isVibrationEnabled = true;
  int ringtoneType = 1;
  double focusVolume = 0.35;
  String focusSoundKey = 'rain_soft';
  final AudioPlayer _focusAudioPlayer = AudioPlayer();

  static const Map<String, String> focusSoundAssets = {
    'rain_soft': 'assets/audio/rain_soft.wav',
    'ocean_breeze': 'assets/audio/ocean_breeze.wav',
    'brown_focus': 'assets/audio/brown_focus.wav',
  };

  // Timer states
  bool isPomodoroMode = true;
  late int totalTime = pomodoroTime;
  late int timeRemaining = pomodoroTime;
  bool isRunning = false;
  bool isRinging = false; // Flag to check if alarm is currently ringing
  Timer? _timer;

  // Format time to MM:SS
  String get timeString {
    String minutes = (timeRemaining ~/ 60).toString().padLeft(2, '0');
    String seconds = (timeRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Calculate progress for the circular indicator
  double get progress =>
      totalTime <= 0 ? 0.0 : (timeRemaining / totalTime).clamp(0.0, 1.0);

  // --- TIMER OPERATIONS ---

  // Stop the alarm sound and reset the ringing flag
  void stopAlarm() {
    FlutterRingtonePlayer().stop();
    isRinging = false;
    notifyListeners();
  }

  Future<void> _playFocusAudio() async {
    if (!isPomodoroMode) return;
    final assetPath = focusSoundAssets[focusSoundKey];
    if (assetPath == null) return;
    await _focusAudioPlayer.setVolume(focusVolume);
    await _focusAudioPlayer.play(
      AssetSource(assetPath.replaceFirst('assets/', '')),
    );
  }

  Future<void> _stopFocusAudio() async {
    await _focusAudioPlayer.stop();
  }

  // Start, pause, or handle alarm state
  void toggleTimer() {
    // If alarm is ringing, clicking the main button should only stop the alarm
    if (isRinging) {
      stopAlarm();
      return;
    }

    if (isRunning) {
      _timer?.cancel();
      isRunning = false;
      unawaited(_stopFocusAudio());
    } else {
      isRunning = true;
      unawaited(_playFocusAudio());
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          // Time is up
          _timer?.cancel();
          isRunning = false;
          isRinging = true; // Set flag to change UI button state
          unawaited(_stopFocusAudio());

          // Trigger hardware feedback
          if (isVibrationEnabled) HapticFeedback.heavyImpact();
          if (ringtoneType == 1)
            FlutterRingtonePlayer().playAlarm();
          else if (ringtoneType == 2)
            FlutterRingtonePlayer().playNotification();
          else if (ringtoneType == 3)
            FlutterRingtonePlayer().playRingtone();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // Reset the current timer back to full duration
  void resetTimer() {
    stopAlarm(); // Stop alarm if resetting
    _timer?.cancel();
    unawaited(_stopFocusAudio());
    isRunning = false;
    timeRemaining = totalTime;
    notifyListeners();
  }

  // Switch between Pomodoro and Short Break
  void setMode(bool isPomodoro) {
    stopAlarm(); // Stop alarm if switching modes
    _timer?.cancel();
    unawaited(_stopFocusAudio());
    isRunning = false;
    isPomodoroMode = isPomodoro;
    totalTime = isPomodoro ? pomodoroTime : shortBreakTime;
    timeRemaining = totalTime;
    notifyListeners();
  }

  // Skip current session
  void skipTimer() => setMode(!isPomodoroMode);

  // Update preferences from the settings dialog
  void updateSettings({
    required int newPomodoroMinutes,
    required int newBreakMinutes,
    required bool vibrate,
    required int ringtone,
    required double volume,
    required String soundKey,
  }) {
    if (newPomodoroMinutes <= 0 || newBreakMinutes <= 0) {
      debugPrint(
        'Lỗi: Thời gian cài đặt phải lớn hơn 0 phút. Đã tự động set về 1.',
      );
      newPomodoroMinutes = newPomodoroMinutes <= 0 ? 1 : newPomodoroMinutes;
      newBreakMinutes = newBreakMinutes <= 0 ? 1 : newBreakMinutes;
    }
    stopAlarm(); // Stop alarm if opening settings
    pomodoroTime = newPomodoroMinutes * 60;
    shortBreakTime = newBreakMinutes * 60;
    isVibrationEnabled = vibrate;
    ringtoneType = ringtone;
    focusVolume = volume.clamp(0.0, 1.0);
    focusSoundKey = focusSoundAssets.containsKey(soundKey)
        ? soundKey
        : 'rain_soft';

    _timer?.cancel();
    unawaited(_stopFocusAudio());
    isRunning = false;
    totalTime = isPomodoroMode ? pomodoroTime : shortBreakTime;
    timeRemaining = totalTime;

    notifyListeners();
  }

  // Prevent memory leaks when the ViewModel is destroyed
  @override
  void dispose() {
    stopAlarm(); // Ensure alarm doesn't keep ringing in the background
    _timer?.cancel();
    _focusAudioPlayer.dispose();
    noteController.dispose();
    super.dispose();
  }
}
