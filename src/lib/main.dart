import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/login_view.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundBlue,
        primaryColor: AppColors.primaryBlue,
        useMaterial3: true,
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.grayText),
          labelLarge: TextStyle(fontSize: 16, color: AppColors.primaryBlue),
        ),
      ),
      home: const LoginView(),
      debugShowCheckedModeBanner: false,
    );
  }
}