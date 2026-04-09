import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_management_app/features/main/view/screens/main_screen.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/view/login_view.dart';
import 'features/auth/presentation/view/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'features/tasks/viewmodel/task_viewmodel.dart';

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
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const TaskApp());
}

final supabase = Supabase.instance.client;

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskViewModel(),
      child: MaterialApp(
        title: 'Task Management App',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.backgroundBlue,
          primaryColor: AppColors.primaryBlue,
          useMaterial3: true,
          fontFamily: 'Montserrat',
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            bodyMedium: TextStyle(fontSize: 14, color: AppColors.grayText),
            labelLarge: TextStyle(fontSize: 16, color: AppColors.primaryBlue),
          ),
        ),
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
