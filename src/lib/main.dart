import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/features/auth/presentation/view/auth_gate.dart';
import 'package:task_management_app/features/main/view/screens/main_screen.dart';
import 'package:task_management_app/features/tasks/viewmodel/task_viewmodel.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_management_app/features/tasks/view/screens/create_task_screen.dart';

import 'core/theme/theme_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tải cấu hình từ file .env
  await dotenv.load(fileName: ".env");

  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('Error: SUPABASE_URL or SUPABASE_ANON_KEY is missing');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
      
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            'Lỗi!\n\n${details.exception}\n\nStack Trace:\n${details.stack}',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
          ),
        ),
      ),
    );
  };
  
  runApp(
      MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<TaskViewModel>(
              create: (_) => TaskViewModel(),
            ),
            // ĐÂY LÀ DÒNG CỨU CÁNH CHO ĐẠI VƯƠNG:
            ChangeNotifierProvider(create: (_) => CreateTaskProvider()), 
          ],
      child: const TaskApp()));
}
final supabase = Supabase.instance.client;

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Task Management App',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,         // Bộ màu sáng ông vừa map xong
      darkTheme: AppTheme.darkTheme,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
